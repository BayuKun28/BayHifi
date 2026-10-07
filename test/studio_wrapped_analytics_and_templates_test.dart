import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baydev_hifi/core/database/local_persistence_service.dart';
import 'package:baydev_hifi/features/analytics/domain/audiophile_persona.dart';
import 'package:baydev_hifi/features/analytics/domain/playback_log_entry.dart';
import 'package:baydev_hifi/features/analytics/domain/studio_wrapped_calculator.dart';
import 'package:baydev_hifi/features/analytics/domain/studio_wrapped_data.dart';
import 'package:baydev_hifi/features/analytics/presentation/story/studio_wrapped_story_screen.dart';
import 'package:baydev_hifi/features/analytics/presentation/templates/studio_wrapped_export_hub.dart';
import 'package:baydev_hifi/features/analytics/presentation/templates/widgets/bento_studio_view.dart';
import 'package:baydev_hifi/features/analytics/presentation/templates/widgets/cassette_jcard_view.dart';
import 'package:baydev_hifi/features/analytics/presentation/templates/widgets/sticker_collage_view.dart';
import 'package:baydev_hifi/features/analytics/presentation/templates/widgets/thermal_receipt_view.dart';
import 'package:baydev_hifi/features/dashboard/presentation/widgets/studio_wrapped_bento_banner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('baydev_wrapped_test_');
    await LocalPersistenceService.instance.init(customPath: '${tempDir.path}/test_storage.json');
  });

  tearDown(() async {
    await LocalPersistenceService.instance.clearPlaybackHistoryLogs();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('PlaybackLogEntry and Serialization Tests', () {
    test('PlaybackLogEntry roundtrip toMap and fromMap', () {
      final now = DateTime.now();
      final log = PlaybackLogEntry(
        id: 'test_log_1',
        trackId: 'track_123',
        title: 'Time (2023 Remaster)',
        artist: 'Pink Floyd',
        album: 'The Dark Side of the Moon',
        genre: 'Progressive Rock',
        durationPlayedMs: 240000,
        trackDurationMs: 420000,
        format: 'flac',
        sampleRate: 96000,
        bitDepth: 24,
        timestamp: now,
        driverName: 'Sennheiser HD600',
        targetName: 'Harman 2019 OE',
        isAutoEqActive: true,
        activeDspCount: 3,
        dacDeviceName: 'Fiio KA13',
      );

      final map = log.toMap();
      final restored = PlaybackLogEntry.fromMap(map);

      expect(restored.id, 'test_log_1');
      expect(restored.trackId, 'track_123');
      expect(restored.title, 'Time (2023 Remaster)');
      expect(restored.artist, 'Pink Floyd');
      expect(restored.format, 'flac');
      expect(restored.isLossless, isTrue);
      expect(restored.isHiRes, isTrue);
      expect(restored.sampleRate, 96000);
      expect(restored.bitDepth, 24);
      expect(restored.driverName, 'Sennheiser HD600');
      expect(restored.targetName, 'Harman 2019 OE');
      expect(restored.isAutoEqActive, isTrue);
      expect(restored.dacDeviceName, 'Fiio KA13');
    });

    test('LocalPersistenceService playback logs persistence', () async {
      final logs = LocalPersistenceService.instance.getPlaybackHistoryLogs();
      expect(logs, isEmpty);

      final entry1 = {
        'id': 'log_1',
        'trackId': 't1',
        'title': 'Hotel California',
        'artist': 'Eagles',
        'durationPlayedMs': 300000,
        'format': 'flac',
        'timestamp': DateTime.now().toIso8601String(),
      };

      await LocalPersistenceService.instance.logPlaybackSession(entry1);
      final fetched = LocalPersistenceService.instance.getPlaybackHistoryLogs();
      expect(fetched.length, 1);
      expect(fetched.first['title'], 'Hotel California');

      await LocalPersistenceService.instance.clearPlaybackHistoryLogs();
      expect(LocalPersistenceService.instance.getPlaybackHistoryLogs(), isEmpty);
    });
  });

  group('AudiophilePersona Classifier Tests', () {
    test('Classifies Analog Tube Connoisseur when tube warmth is predominant', () {
      final persona = AudiophilePersona.determine(
        flacRatio: 0.5,
        tubeWarmthHours: 45.0,
        totalDacHours: 10.0,
        highestSampleRate: 96000,
        topAutoEqTarget: 'Harman 2019',
        peqBandsEngaged: 4,
        bassBoostHours: 5.0,
        intimateHours: 12.0,
      );
      expect(persona.type, AudiophilePersonaType.tubeConnoisseur);
      expect(persona.title, 'The Analog Tube Connoisseur');
      expect(persona.soundSignatureTags, contains('2nd Harmonic Warmth'));
    });

    test('Classifies Bit-Perfect Purist when lossless ratio and sample rate are elite', () {
      final persona = AudiophilePersona.determine(
        flacRatio: 0.95,
        tubeWarmthHours: 1.0,
        totalDacHours: 25.0,
        highestSampleRate: 192000,
        topAutoEqTarget: 'Diffuse Field',
        peqBandsEngaged: 2,
        bassBoostHours: 0.0,
        intimateHours: 5.0,
      );
      expect(persona.type, AudiophilePersonaType.analyticalPurist);
      expect(persona.title, 'The Bit-Perfect Purist');
    });

    test('Classifies Sub-Bass Holographic Explorer when bass boost is heavy', () {
      final persona = AudiophilePersona.determine(
        flacRatio: 0.4,
        tubeWarmthHours: 2.0,
        totalDacHours: 5.0,
        highestSampleRate: 44100,
        topAutoEqTarget: 'None',
        peqBandsEngaged: 3,
        bassBoostHours: 35.0,
        intimateHours: 4.0,
      );
      expect(persona.type, AudiophilePersonaType.subBassExplorer);
    });

    test('Classifies Hardware DAC Artisan when DAC bridge hours dominate', () {
      final persona = AudiophilePersona.determine(
        flacRatio: 0.6,
        tubeWarmthHours: 4.0,
        totalDacHours: 60.0,
        highestSampleRate: 96000,
        topAutoEqTarget: 'SoundID Reference',
        peqBandsEngaged: 5,
        bassBoostHours: 2.0,
        intimateHours: 5.0,
      );
      expect(persona.type, AudiophilePersonaType.dacArtisan);
    });
  });

  group('StudioWrappedCalculator Tests', () {
    test('Calculates aggregated metrics correctly from raw logs', () {
      final now = DateTime(2026, 6, 15, 14, 0);
      final logs = [
        PlaybackLogEntry(
          id: 'l1',
          trackId: 't1',
          title: 'Comfortably Numb',
          artist: 'Pink Floyd',
          album: 'The Wall',
          genre: 'Progressive Rock',
          durationPlayedMs: 360000,
          trackDurationMs: 380000,
          format: 'flac',
          sampleRate: 192000,
          bitDepth: 24,
          timestamp: now,
          driverName: 'Moondrop Blessing 3',
          targetName: 'Harman 2019 IE',
          isAutoEqActive: true,
          activeDspCount: 2,
          dacDeviceName: 'Fiio KA13',
        ),
        PlaybackLogEntry(
          id: 'l2',
          trackId: 't1',
          title: 'Comfortably Numb',
          artist: 'Pink Floyd',
          album: 'The Wall',
          genre: 'Progressive Rock',
          durationPlayedMs: 360000,
          trackDurationMs: 380000,
          format: 'flac',
          sampleRate: 192000,
          bitDepth: 24,
          timestamp: now.add(const Duration(days: 1)),
          driverName: 'Moondrop Blessing 3',
          targetName: 'Harman 2019 IE',
          isAutoEqActive: true,
          activeDspCount: 2,
          dacDeviceName: 'Fiio KA13',
        ),
        PlaybackLogEntry(
          id: 'l3',
          trackId: 't2',
          title: 'Get Lucky',
          artist: 'Daft Punk',
          album: 'Random Access Memories',
          genre: 'Nu-Disco / Electronic',
          durationPlayedMs: 240000,
          trackDurationMs: 250000,
          format: 'opus',
          sampleRate: 48000,
          bitDepth: 16,
          timestamp: now.add(const Duration(days: 2)),
          driverName: 'Sennheiser HD600',
          targetName: 'Diffuse Field',
          isAutoEqActive: false,
          activeDspCount: 1,
        ),
      ];

      const calculator = StudioWrappedCalculator();
      final data = calculator.calculate(rawLogs: logs, timeFilter: RecapTimeFilter.year2026);

      expect(data.totalTracksPlayed, 3);
      expect(data.totalListeningMinutes, (360000 + 360000 + 240000) ~/ 60000);
      expect(data.totalUniqueArtists, 2);
      expect(data.topTracks.first.title, 'Comfortably Numb');
      expect(data.topTracks.first.playCount, 2);
      expect(data.topArtists.first.artist, 'Pink Floyd');
      expect(data.topAutoEqTarget, 'Harman 2019 IE');
      expect(data.favoriteHeadphoneProfile, 'Moondrop Blessing 3');
      expect(data.favoriteDacDevice, 'Fiio KA13');
      expect(data.audioPurityReport.losslessFlacRatio, greaterThan(0.5));
      expect(data.audioPurityReport.highestSampleRate, '192 kHz / 24-bit');
    });

    test('Propagates artworkUrl to TopTrackRank, TopArtistRank, and supports libraryFallback', () {
      final now = DateTime(2026, 7, 1);
      final logsWithArtwork = [
        PlaybackLogEntry(
          id: 'l_art_1',
          trackId: 't_art_1',
          title: 'Starboy',
          artist: 'The Weeknd',
          album: 'Starboy',
          genre: 'R&B / Synthpop',
          durationPlayedMs: 210000,
          trackDurationMs: 230000,
          format: 'flac',
          sampleRate: 44100,
          bitDepth: 16,
          timestamp: now,
          artworkUrl: 'https://example.com/starboy.jpg',
        ),
      ];

      const calculator = StudioWrappedCalculator();
      final data = calculator.calculate(rawLogs: logsWithArtwork, timeFilter: RecapTimeFilter.year2026);
      expect(data.topTracks.first.albumArtUri, 'https://example.com/starboy.jpg');
      expect(data.topArtists.first.artworkUrl, 'https://example.com/starboy.jpg');
    });

    test('Generates high-fidelity demo sample data when logs are empty', () {
      const calculator = StudioWrappedCalculator();
      final fallbackData = calculator.calculate(rawLogs: [], timeFilter: RecapTimeFilter.year2026);

      expect(fallbackData.totalListeningMinutes, greaterThan(0));
      expect(fallbackData.topTracks, isNotEmpty);
      expect(fallbackData.topArtists, isNotEmpty);
      expect(fallbackData.topGenres, isNotEmpty);
      expect(fallbackData.persona, isNotNull);
    });
  });

  group('Studio Wrapped Recap Visual Templates Widget Tests', () {
    const calculator = StudioWrappedCalculator();
    final sampleData = calculator.calculate(rawLogs: [], timeFilter: RecapTimeFilter.year2026);

    testWidgets('Renders ThermalReceiptView in dark and light paper modes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: ThermalReceiptView(data: sampleData, isDarkMode: true),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('BAYDEV HIFI STORE'), findsOneWidget);
      expect(find.text('ORDER #2026-RECAP'), findsOneWidget);
      expect(find.text('ITEM / TRACK DESCRIPTION'), findsOneWidget);
      expect(find.text('TOTAL TRACKS PLAYED:'), findsOneWidget);
      expect(find.text('>>> ${sampleData.persona.title} <<<'), findsWidgets);

      // Re-pump with light mode paper
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: ThermalReceiptView(data: sampleData, isDarkMode: false),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('BAYDEV HIFI STORE'), findsOneWidget);
    });

    testWidgets('Renders StickerCollageView with 3D tilted stickers', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: StickerCollageView(data: sampleData),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('BAYDEV HIFI'), findsOneWidget);
      expect(find.text('2026 RECAP // LOSSLESS'), findsOneWidget);
      expect(find.text('${sampleData.totalListeningMinutes} MINS'), findsOneWidget);
      expect(find.text(sampleData.persona.title), findsWidgets);
      expect(find.text('HEAVY ROTATION'), findsOneWidget);
    });

    testWidgets('Renders BentoStudioView with M3 Expressive Bento cards', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: BentoStudioView(data: sampleData),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('BAYDEV HIFI'), findsOneWidget);
      expect(find.text('${sampleData.totalMinutes}'), findsOneWidget);
      expect(find.text('HI-RES PURITY'), findsOneWidget);
      expect(find.text(sampleData.persona.title), findsWidgets);
    });

    testWidgets('Renders CassetteJCardView with analog cassette tape card', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: CassetteJCardView(data: sampleData),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('BAYDEV'), findsOneWidget);
      expect(find.text('2026 MASTER TAPE REEL'), findsOneWidget);
      expect(find.text(sampleData.persona.title.toUpperCase()), findsWidgets);
    });
  });

  group('Studio Wrapped Interactive Story & Hub Integration Tests', () {
    testWidgets('StudioWrappedStoryScreen navigates through slides and reveals persona', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: StudioWrappedStoryScreen(),
          ),
        ),
      );
      // Pump single frame to initialize
      await tester.pump(const Duration(milliseconds: 100));

      // Slide 1: Welcome
      expect(find.text('YOUR 2026 AUDIOPHILE JOURNEY'), findsOneWidget);
      expect(find.text('A Year in Pure Sound'), findsOneWidget);

      // Tap right side to advance to Slide 2 (Top Tracks)
      await tester.tapAt(const Offset(600, 300));
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('TOP TRACKS OF 2026'), findsOneWidget);

      // Advance to Slide 3 (Top Artists)
      await tester.tapAt(const Offset(600, 300));
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('SONIC INSPIRATIONS'), findsOneWidget);

      // Advance to Slide 4 (Audio Purity)
      await tester.tapAt(const Offset(600, 300));
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('SIGNAL INTEGRITY & PURITY'), findsOneWidget);

      // Advance to Slide 5 (DSP Mastery)
      await tester.tapAt(const Offset(600, 300));
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('DSP & ACOUSTIC TUNING'), findsOneWidget);

      // Advance to Slide 6 (Hardware & DAC)
      await tester.tapAt(const Offset(600, 300));
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('HARDWARE & DAC BRIDGE'), findsOneWidget);

      // Advance to Slide 7 (Persona Grand Reveal)
      await tester.tapAt(const Offset(600, 300));
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('YOUR 2026 AUDIOPHILE ARCHETYPE'), findsOneWidget);
      expect(find.text('EXPORT & SHARE RECAP CARDS'), findsOneWidget);
    });

    testWidgets('StudioWrappedExportHub switches templates smoothly', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: StudioWrappedExportHub(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('STUDIO RECAP GALLERY'), findsOneWidget);
      expect(find.text('SHARE RECAP STORY'), findsOneWidget);

      // Switch to Stickers Template
      await tester.tap(find.text('STICKERS'));
      await tester.pumpAndSettle();
      expect(find.text('2026 RECAP // LOSSLESS'), findsOneWidget);

      // Switch to Bento Template
      await tester.tap(find.text('BENTO'));
      await tester.pumpAndSettle();
      expect(find.text('HI-RES PURITY'), findsOneWidget);

      // Switch to Cassette Template
      await tester.tap(find.text('CASSETTE'));
      await tester.pumpAndSettle();
      expect(find.text('2026 MASTER TAPE REEL'), findsOneWidget);
    });

    testWidgets('StudioWrappedBentoBanner renders properly in dashboard flow', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: StudioWrappedBentoBanner(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('STUDIO WRAPPED 2026'), findsOneWidget);
      expect(find.text('PLAY RECAP STORY'), findsOneWidget);
      expect(find.text('TEMPLATES'), findsOneWidget);
    });
  });
}
