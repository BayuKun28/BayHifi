import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baydev_hifi/app/theme/theme_mode_controller.dart';
import 'package:baydev_hifi/core/database/local_persistence_service.dart';
import 'package:baydev_hifi/core/lyrics/east_asian_romanizer.dart';
import 'package:baydev_hifi/features/player/domain/track.dart';
import 'package:baydev_hifi/features/player/domain/lyrics_line.dart';
import 'package:baydev_hifi/features/library/data/library_indexer_service.dart';
import 'package:baydev_hifi/features/library/data/metadata_tagger_service.dart';
import 'package:baydev_hifi/features/library/data/storage_cache_manager.dart';
import 'package:baydev_hifi/features/library/domain/smart_playlist_models.dart';
import 'package:baydev_hifi/features/library/domain/smart_playlist_evaluator.dart';
import 'package:baydev_hifi/features/pro_q_studio/domain/auto_eq_optimizer.dart';
import 'package:baydev_hifi/features/pro_q_studio/domain/fr_curve_data.dart';
import 'package:baydev_hifi/features/settings/data/backup_restore_service.dart';
import 'package:baydev_hifi/audio_engine/virtual_dsp_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return '/tmp/bayhifi_master_test_dir';
    });
  });

  group('Master End-to-End Pipeline Integration Tests', () {
    test('1. Full Lifecycle Pipeline: Scan -> Index -> Duplicate Check -> Relink', () async {
      final indexer = LibraryIndexerService.instance;

      const trackHiRes = Track(
        id: 'trk_001',
        title: 'Clair de Lune',
        artist: 'Claude Debussy',
        album: 'Suite Bergamasque',
        duration: Duration(minutes: 5),
        format: AudioFormat.flac,
        bitDepth: 24,
        sampleRate: 96000,
        bitrate: 4608,
      );

      const trackDuplicateLossy = Track(
        id: 'trk_002',
        title: 'Clair de Lune',
        artist: 'Claude Debussy',
        album: 'Suite Bergamasque',
        duration: Duration(minutes: 5),
        format: AudioFormat.mp3,
        bitDepth: 16,
        sampleRate: 44100,
        bitrate: 320,
      );

      const trackUnique = Track(
        id: 'trk_003',
        title: 'Gymnopédie No. 1',
        artist: 'Erik Satie',
        album: 'Piano Classics',
        duration: Duration(minutes: 3, seconds: 30),
        format: AudioFormat.flac,
        bitDepth: 16,
        sampleRate: 44100,
      );

      final tracks = [trackHiRes, trackDuplicateLossy, trackUnique];

      // A. Quality scoring
      final hiResScore = indexer.computeQualityScore(trackHiRes);
      final lossyScore = indexer.computeQualityScore(trackDuplicateLossy);
      expect(hiResScore, greaterThan(lossyScore));

      // B. Duplicate detection & preservation of high-res copy
      final duplicates = indexer.findDuplicates(tracks);
      expect(duplicates.length, 1);
      expect(duplicates.first.bestTrack.id, 'trk_001');
      expect(duplicates.first.redundantTracks.first.id, 'trk_002');
    });

    test('2. Audio DSP & AutoEQ Mastering Math Pipeline', () {
      final dsp = VirtualDspService.instance;

      // A. Safe Headroom Pre-Amp Calculation (takes List<double> of band gains with -0.5 dB inter-sample headroom)
      const bandGains = [6.0, 4.5, -2.0, 0.0, 3.0];
      final preamp = dsp.calculateSafePreamp(bandGains);
      expect(preamp, lessThanOrEqualTo(0.0));
      expect(preamp, closeTo(-6.5, 0.1));

      // B. AutoEQ Curve Parser & Optimization
      const rewMeasurement = '''* Measurement
* Freq(Hz) SPL(dB)
20.0 80.0
60.0 82.0
1000.0 75.0
3000.0 88.0
8000.0 70.0
20000.0 65.0''';

      const csvTarget = '''20,85.0
60,85.0
1000,75.0
3000,82.0
8000,75.0
20000,68.0''';

      final driverData = FrCurveData.autoDetectAndParse(rewMeasurement, name: 'Sennheiser HD 600');
      final targetData = FrCurveData.autoDetectAndParse(csvTarget, name: 'Harman Target 2018');

      expect(driverData.frequencies.length, equals(6));
      expect(targetData.frequencies.length, equals(6));

      final result = AutoEqOptimizer.optimize(
        driverFr: driverData,
        targetFr: targetData,
        resolution: BandResolution.b10,
        mode: TuningMode.safe,
      );

      expect(result.bands, isNotEmpty);
      expect(result.bands.length, equals(10));
      expect(result.safePreampDb, lessThanOrEqualTo(0.0));
    });

    test('3. East Asian Lyrics Transliteration & Time Synchronizer Pipeline', () {
      // A. Japanese Romaji
      const japaneseLyrics = '夜に駆ける (Yoasobi)';
      final romanizedJa = EastAsianRomanizer.romanizeJapanese(japaneseLyrics);
      expect(romanizedJa, isNotEmpty);
      expect(romanizedJa.contains('kakeru') || romanizedJa.contains('ni'), isTrue);

      // B. Korean Romaja
      const koreanLyrics = '봄날 (Spring Day)';
      final romanizedKo = EastAsianRomanizer.romanizeKorean(koreanLyrics);
      expect(romanizedKo, isNotEmpty);

      // C. Chinese Pinyin
      const chineseLyrics = '青花瓷';
      final romanizedZh = EastAsianRomanizer.romanizeChinese(chineseLyrics);
      expect(romanizedZh, isNotEmpty);

      // D. LRC Parsing & Timing Offset Adjuster
      const sampleLrc = '''
[00:00.00]First Line
[00:05.50]Second Line
[00:12.00]Third Line
''';
      final parsedLines = LrcParser.parse(sampleLrc);
      expect(parsedLines.length, 3);
      expect(parsedLines[1].timestamp.inMilliseconds, 5500);

      // Active index search
      final activeIndex = LrcParser.findActiveIndex(
        parsedLines,
        const Duration(seconds: 7),
      );
      expect(activeIndex, 1);
    });

    test('4. Physical Metadata Tagging & Serialization Pipeline', () {
      const sampleTrack = Track(
        id: 't_meta',
        title: 'Original Title',
        artist: 'Original Artist',
        album: 'Original Album',
        duration: Duration(minutes: 3),
        format: AudioFormat.flac,
        genre: 'Rock',
        year: 2021,
        trackNumber: 1,
        trackTotal: 10,
        discNumber: 1,
        discTotal: 1,
        lyrics: 'Line 1\nLine 2',
      );

      final tagData = AudioTagData.fromTrack(sampleTrack);
      expect(tagData.title, 'Original Title');
      expect(tagData.artist, 'Original Artist');
      expect(tagData.album, 'Original Album');
      expect(tagData.genre, 'Rock');
      expect(tagData.year, 2021);
      expect(tagData.trackNumber, 1);
      expect(tagData.trackTotal, 10);
      expect(tagData.lyrics, 'Line 1\nLine 2');

      final updatedTagData = tagData.copyWith(
        title: 'Remastered Master Title',
        artist: 'Studio Legend',
        album: 'HiFi Collection',
        year: 2026,
        trackNumber: 5,
        genre: 'Audiophile Master',
      );

      final updatedTrack = updatedTagData.applyToTrack(sampleTrack);
      expect(updatedTrack.title, 'Remastered Master Title');
      expect(updatedTrack.artist, 'Studio Legend');
      expect(updatedTrack.album, 'HiFi Collection');
      expect(updatedTrack.year, 2026);
      expect(updatedTrack.trackNumber, 5);
      expect(updatedTrack.genre, 'Audiophile Master');
      expect(updatedTrack.duration, sampleTrack.duration);
    });

    test('5. Dynamic Smart Playlists Multi-Rule Evaluator Pipeline', () {
      const hiResTrack = Track(
        id: 't_hr',
        title: 'Master Symphony',
        artist: 'Philharmonic',
        album: 'HiRes Master',
        duration: Duration(minutes: 6),
        format: AudioFormat.flac,
        bitDepth: 24,
        sampleRate: 96000,
        bitrate: 4608,
      );

      const mp3Track = Track(
        id: 't_mp3',
        title: 'Pop Acoustic',
        artist: 'Indie Artist',
        album: 'Acoustic Sessions',
        duration: Duration(minutes: 2, seconds: 45),
        format: AudioFormat.mp3,
        bitDepth: 16,
        sampleRate: 44100,
        bitrate: 256,
      );

      final allTracks = [hiResTrack, mp3Track];
      const evaluator = SmartPlaylistEvaluator();

      // Smart rule: BitDepth >= 24 and SampleRate >= 96000
      final smartPlaylist = SmartPlaylist(
        id: 'smart_hr',
        name: 'Studio Masters Only',
        description: 'Auto-populated 96kHz+ 24-bit files',
        rules: const [
          SmartPlaylistRule(
            field: SmartPlaylistField.bitDepth,
            operator: SmartPlaylistOperator.greaterThanOrEqual,
            value: '24',
          ),
          SmartPlaylistRule(
            field: SmartPlaylistField.sampleRate,
            operator: SmartPlaylistOperator.greaterThanOrEqual,
            value: '96000',
          ),
        ],
        matchMode: SmartPlaylistMatchMode.all,
        limit: 50,
        createdAt: DateTime(2026, 1, 1),
      );

      final evaluated = evaluator.evaluate(
        playlist: smartPlaylist,
        allTracks: allTracks,
      );
      expect(evaluated.length, 1);
      expect(evaluated.first.id, 't_hr');
    });

    test('6. Storage Cache Quota & .bayhifi Backup Archive Pipeline', () async {
      final storageManager = StorageCacheManager.instance;
      final backupService = BackupRestoreService.instance;
      final persistence = LocalPersistenceService.instance;

      // A. Storage breakdown calculation
      final breakdown = await storageManager.calculateStorageUsage();
      expect(breakdown.totalCacheBytes, greaterThanOrEqualTo(0));

      // B. Save settings & state into persistence
      await persistence.saveThemeSettings(
        paletteId: 'amber_tube',
        themeModeIndex: AppThemeMode.dark.index,
        customAccentColorValue: 0xFFF59E0B,
        dynamicAlbumArtEnabled: false,
      );

      await persistence.saveFavoriteTrackIds({'trk_fav_1', 'trk_fav_2'});

      // C. Export Backup JSON
      final backupJson = backupService.createBackupJson(
        includeHistory: true,
        includeLibrary: true,
      );

      expect(backupJson, isNotEmpty);
      final validation = backupService.validateBackup(backupJson);
      expect(validation.isValid, isTrue);

      // D. Restore from Backup JSON
      final restoreResult = await backupService.restoreFromBackupJson(backupJson);
      expect(restoreResult.success, isTrue);
      expect(restoreResult.restoredFavoritesCount, 2);

      // Verify theme state persisted
      final themeSettings = persistence.getThemeSettings();
      expect(themeSettings['palette_id'], 'amber_tube');
    });

    test('7. Studio Theme Engine & Palette Presets Integrity', () {
      final allPresets = AppPalette.allPresets;
      expect(allPresets.length, greaterThanOrEqualTo(6));

      for (final palette in allPresets) {
        // Verify Dark & Light ThemeData builds without errors
        final darkTheme = AppThemeBuilder.buildTheme(palette, isDark: true);
        final lightTheme = AppThemeBuilder.buildTheme(palette, isDark: false);

        expect(darkTheme.brightness, Brightness.dark);
        expect(lightTheme.brightness, Brightness.light);
        expect(darkTheme.colorScheme.primary, palette.primary);
        expect(lightTheme.colorScheme.primary, palette.primary);
      }
    });
  });
}
