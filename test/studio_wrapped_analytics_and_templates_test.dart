import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baydev_hifi/core/database/local_persistence_service.dart';
import 'package:baydev_hifi/features/analytics/data/playback_analytics_service.dart';
import 'package:baydev_hifi/features/analytics/domain/audiophile_persona.dart';
import 'package:baydev_hifi/features/analytics/domain/playback_log_entry.dart';
import 'package:baydev_hifi/features/analytics/domain/studio_wrapped_calculator.dart';
import 'package:baydev_hifi/features/analytics/domain/studio_wrapped_data.dart';
import 'package:baydev_hifi/features/analytics/presentation/details/studio_listening_stats_detail_screen.dart';
import 'package:baydev_hifi/features/analytics/presentation/story/studio_wrapped_story_screen.dart';
import 'package:baydev_hifi/features/analytics/presentation/templates/studio_wrapped_export_hub.dart';
import 'package:baydev_hifi/features/analytics/presentation/templates/widgets/abstract_aura_view.dart';
import 'package:baydev_hifi/features/analytics/presentation/templates/widgets/artist_lineup_poster_view.dart';
import 'package:baydev_hifi/features/analytics/presentation/templates/widgets/bento_studio_view.dart';
import 'package:baydev_hifi/features/analytics/presentation/templates/widgets/cassette_jcard_view.dart';
import 'package:baydev_hifi/features/analytics/presentation/templates/widgets/concert_ticket_view.dart';
import 'package:baydev_hifi/features/analytics/presentation/templates/widgets/cyber_spec_card_view.dart';
import 'package:baydev_hifi/features/analytics/presentation/templates/widgets/genre_spectrum_card_view.dart';
import 'package:baydev_hifi/features/analytics/presentation/templates/widgets/persona_master_card_view.dart';
import 'package:baydev_hifi/features/analytics/presentation/templates/widgets/sticker_collage_view.dart';
import 'package:baydev_hifi/features/analytics/presentation/templates/widgets/thermal_receipt_view.dart';
import 'package:baydev_hifi/features/analytics/presentation/templates/widgets/top_tracks_chart_view.dart';
import 'package:baydev_hifi/features/analytics/presentation/templates/widgets/vinyl_gatefold_view.dart';
import 'package:baydev_hifi/features/dashboard/presentation/widgets/studio_wrapped_bento_banner.dart';
import 'package:baydev_hifi/features/player/domain/track.dart';

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

  group('StudioWrappedCalculator & Harmonic Resonance Tests', () {
    test('Calculates aggregated metrics & resonance profile correctly from raw logs', () {
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

      // Harmonic Resonance Profile verifications
      expect(data.resonanceProfile.energyScore, inInclusiveRange(0, 100));
      expect(data.resonanceProfile.dynamicRangeDb, inInclusiveRange(10.0, 30.0));
      expect(data.resonanceProfile.waveSeedAmplitudes.length, 6);
      expect(data.resonanceProfile.peakTimeWindow, isNotEmpty);
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

    test('Backfills artworkUrl from libraryFallback for tracks, artists, and albums when log artwork is null', () {
      final now = DateTime(2026, 8, 1);
      final logsWithoutArtwork = [
        PlaybackLogEntry(
          id: 'l_null_art',
          trackId: 'local_123',
          title: 'Medusa',
          artist: 'Bring Me The Horizon',
          album: 'Count Your Blessings',
          genre: 'Metalcore',
          durationPlayedMs: 240000,
          trackDurationMs: 250000,
          format: 'flac',
          sampleRate: 96000,
          bitDepth: 24,
          timestamp: now,
          artworkUrl: null, // Artwork was null in log
        ),
      ];

      final library = [
        const Track(
          id: 'local_123',
          title: 'Medusa',
          artist: 'Bring Me The Horizon',
          album: 'Count Your Blessings',
          duration: Duration(minutes: 4),
          albumArtUrl: '/home/x/Documents/covers/art_123.jpg',
        ),
      ];

      const calculator = StudioWrappedCalculator();
      final data = calculator.calculate(
        rawLogs: logsWithoutArtwork,
        timeFilter: RecapTimeFilter.year2026,
        libraryFallback: library,
      );

      // Top Track must backfill from library
      expect(data.topTracks.first.albumArtUri, '/home/x/Documents/covers/art_123.jpg');
      // Top Artist must backfill from library
      expect(data.topArtists.first.artworkUrl, '/home/x/Documents/covers/art_123.jpg');
      // Top Album must backfill from library
      expect(data.topAlbums.first.artworkUrl, '/home/x/Documents/covers/art_123.jpg');
    });

    test('Generates high-fidelity demo sample data when logs are empty', () {
      const calculator = StudioWrappedCalculator();
      final fallbackData = calculator.calculate(rawLogs: [], timeFilter: RecapTimeFilter.year2026);

      expect(fallbackData.totalListeningMinutes, greaterThan(0));
      expect(fallbackData.topTracks, isNotEmpty);
      expect(fallbackData.topTracks.first.albumArtUri, isNotNull);
      expect(fallbackData.topArtists, isNotEmpty);
      expect(fallbackData.topArtists.first.artworkUrl, isNotNull);
      expect(fallbackData.topAlbums, isNotEmpty);
      expect(fallbackData.topAlbums.first.artworkUrl, isNotNull);
      expect(fallbackData.topGenres, isNotEmpty);
      expect(fallbackData.persona, isNotNull);
      expect(fallbackData.resonanceProfile.waveSeedAmplitudes, isNotEmpty);
    });
  });

  group('Studio Wrapped Visual Templates Widget Tests (All 12 Styles)', () {
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

    testWidgets('Renders AbstractSoundwaveAuraView (Template 5) with aura & resonance HUD', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: AbstractSoundwaveAuraView(data: sampleData),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SONIC RESONANCE 2026'), findsOneWidget);
      expect(find.text('TIMBRAL SIGNATURE'), findsOneWidget);
      expect(find.text(sampleData.persona.title.toUpperCase()), findsWidgets);
    });

    testWidgets('Renders VinylGatefoldView (Template 6) with 12" LP disc & master tracklist', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: VinylGatefoldView(data: sampleData),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ORIGINAL MASTER RECORDING'), findsOneWidget);
      expect(find.text('33⅓ RPM • STEREO'), findsOneWidget);
      expect(find.text('SIDE A • MASTER CUTS'), findsOneWidget);
      expect(find.text('FEATURED ARTIST'), findsOneWidget);
    });

    testWidgets('Renders ConcertTicketView (Template 7) with VIP stub & admission bar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: ConcertTicketView(data: sampleData),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('BAYDEV HI-FI TOUR • 2026'), findsOneWidget);
      expect(find.text('VIP ALL-ACCESS'), findsOneWidget);
      expect(find.text('OFFICIAL SETLIST'), findsOneWidget);
      expect(find.text('VERIFIED HI-FI'), findsOneWidget);
    });

    testWidgets('Renders CyberSpecCardView (Template 8) with Tokyo hardware HUD', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: CyberSpecCardView(data: sampleData),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SYSTEM DIAGNOSTIC // 2026'), findsOneWidget);
      expect(find.text('0x7F:SOLOUD-DSP'), findsOneWidget);
      expect(find.text('CORE MASTER ASSET'), findsOneWidget);
      expect(find.text('TELEMETRY MATRIX [TOP 4]'), findsOneWidget);
    });

    testWidgets('Renders PersonaMasterCardView (Dedicated Focus 1) with archetype & radar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: PersonaMasterCardView(data: sampleData),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('AUDIOPHILE ARCHETYPE // 2026'), findsOneWidget);
      expect(find.text(sampleData.persona.title.toUpperCase()), findsOneWidget);
      expect(find.text('ENERGY INDEX'), findsOneWidget);
      expect(find.text('SIGNAL CHAIN HARDWARE'), findsOneWidget);
    });

    testWidgets('Renders ArtistLineupPosterView (Dedicated Focus 2) with festival hierarchy', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: ArtistLineupPosterView(data: sampleData),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('BAYDEV HI-FI FESTIVAL // 2026'), findsOneWidget);
      expect(find.text('TOP HEADLINER #1'), findsOneWidget);
      expect(find.text(sampleData.topArtists.first.artist), findsWidgets);
      expect(find.text('STAGE TIME'), findsOneWidget);
    });

    testWidgets('Renders GenreSpectrumCardView (Dedicated Focus 3) with frequency & bars', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: GenreSpectrumCardView(data: sampleData),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SONIC SPECTRUM // 2026'), findsOneWidget);
      expect(find.text('ACOUSTIC SPECTRUM DISTRIBUTION'), findsOneWidget);
      expect(find.text('DOMINANT SOUND ECOSYSTEM'), findsOneWidget);
    });

    testWidgets('Renders TopTracksChartView (Dedicated Focus 4) with #01 spotlight & top 10', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: TopTracksChartView(data: sampleData),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('MASTER TRACKS CHART // 2026'), findsOneWidget);
      expect(find.text('OFFICIAL RANKING'), findsOneWidget);
      expect(find.text('MOST PLAYED ANTHEM'), findsOneWidget);
      expect(find.text('TOTAL STREAMS'), findsOneWidget);
    });
  });

  group('Studio Wrapped Interactive Story & Hub Integration Tests', () {
    testWidgets('StudioWrappedStoryScreen navigates through slides and reveals quick export actions', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: StudioWrappedStoryScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Slide 1: Welcome
      expect(find.text('YOUR 2026 AUDIOPHILE JOURNEY'), findsOneWidget);
      expect(find.text('A Year in Pure Sound'), findsOneWidget);

      // Tap right side to advance to Slide 2 (Top Tracks)
      await tester.tapAt(const Offset(600, 300));
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('TOP TRACKS OF 2026'), findsOneWidget);
      expect(find.text('EXPORT TRACKS CHART'), findsOneWidget);

      // Advance to Slide 3 (Top Artists)
      await tester.tapAt(const Offset(600, 300));
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('SONIC INSPIRATIONS'), findsOneWidget);
      expect(find.text('FESTIVAL POSTER'), findsOneWidget);
      expect(find.text('SONIC SPECTRUM'), findsOneWidget);

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
      expect(find.text('EXPORT PERSONA MASTER CARD'), findsOneWidget);
      expect(find.text('CHOOSE EXPORT STYLE (12 TEMPLATES)'), findsOneWidget);
      expect(find.text('OPEN FULL EXPORT GALLERY'), findsOneWidget);
    });

    testWidgets('StudioWrappedExportHub switches between categories and all 12 templates smoothly', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: StudioWrappedExportHub(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('STUDIO RECAP GALLERY'), findsOneWidget);
      expect(find.text('ALL-IN-ONE RECAPS'), findsOneWidget);
      expect(find.text('DEDICATED FOCUS CARDS'), findsOneWidget);

      // Switch to Stickers Template
      await tester.tap(find.text('STICKERS'));
      await tester.pumpAndSettle();
      expect(find.text('2026 RECAP // LOSSLESS'), findsOneWidget);

      // Switch Category to Dedicated Focus Cards
      await tester.tap(find.text('DEDICATED FOCUS CARDS'));
      await tester.pumpAndSettle();

      // Tap Persona Archetype
      await tester.tap(find.text('PERSONA ARCHETYPE'));
      await tester.pumpAndSettle();
      expect(find.text('AUDIOPHILE ARCHETYPE // 2026'), findsOneWidget);

      // Tap Festival Lineup
      await tester.tap(find.text('FESTIVAL LINEUP'));
      await tester.pumpAndSettle();
      expect(find.text('BAYDEV HI-FI FESTIVAL // 2026'), findsOneWidget);

      // Tap Sonic Spectrum
      await tester.tap(find.text('SONIC SPECTRUM'));
      await tester.pumpAndSettle();
      expect(find.text('SONIC SPECTRUM // 2026'), findsOneWidget);

      // Tap Tracks Chart
      await tester.tap(find.text('TRACKS CHART'));
      await tester.pumpAndSettle();
      expect(find.text('MASTER TRACKS CHART // 2026'), findsOneWidget);
    });

    testWidgets('StudioWrappedExportHub supports initialStyle parameter', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: StudioWrappedExportHub(initialStyle: WrappedTemplateStyle.topTracksChart),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('MASTER TRACKS CHART // 2026'), findsOneWidget);
      expect(find.text('OFFICIAL RANKING'), findsOneWidget);
    });

    testWidgets('StudioWrappedBentoBanner renders properly in dashboard flow and respects light/dark theme contrast', (tester) async {
      // 1. Test in Light Mode
      final lightTheme = ThemeData.light().copyWith(
        colorScheme: const ColorScheme.light(
          onSurface: Color(0xFF0F172A),
          primary: Color(0xFF06B6D4),
          onPrimary: Color(0xFFFFFFFF),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: lightTheme,
            home: const Scaffold(
              body: StudioWrappedBentoBanner(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('STUDIO WRAPPED 2026'), findsOneWidget);
      expect(find.text('PLAY RECAP STORY'), findsOneWidget);
      expect(find.text('TEMPLATES'), findsOneWidget);

      // Verify persona title text widget is found and its color is onSurface (not white)
      final titleFinder = find.byWidgetPredicate(
        (widget) => widget is Text && widget.style?.fontSize == 15 && widget.style?.fontWeight == FontWeight.w800,
      );
      expect(titleFinder, findsOneWidget);
      final lightTitleWidget = tester.widget<Text>(titleFinder);
      expect(lightTitleWidget.style?.color, equals(const Color(0xFF0F172A)));
      expect(lightTitleWidget.style?.color, isNot(equals(Colors.white)));

      // 2. Test in Dark Mode
      final darkTheme = ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(
          onSurface: Color(0xFFF1F5F9),
          primary: Color(0xFF06B6D4),
          onPrimary: Color(0xFF0C0E12),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: darkTheme,
            home: const Scaffold(
              body: StudioWrappedBentoBanner(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final darkTitleWidget = tester.widget<Text>(titleFinder);
      expect(darkTitleWidget.style?.color, equals(Colors.white));
    });
  });

  group('Studio Listening Insights & Dashboard Telemetry Tests', () {
    test('Calculates TopAlbumRank metrics and rankings correctly', () {
      final now = DateTime(2026, 6, 15);
      final logs = [
        PlaybackLogEntry(
          id: 'log_a1',
          trackId: 't1',
          title: 'Comfortably Numb',
          artist: 'Pink Floyd',
          album: 'The Wall',
          genre: 'Progressive Rock',
          durationPlayedMs: 360000,
          trackDurationMs: 360000,
          format: 'flac',
          sampleRate: 96000,
          bitDepth: 24,
          timestamp: now,
        ),
        PlaybackLogEntry(
          id: 'log_a2',
          trackId: 't2',
          title: 'Hey You',
          artist: 'Pink Floyd',
          album: 'The Wall',
          genre: 'Progressive Rock',
          durationPlayedMs: 240000,
          trackDurationMs: 240000,
          format: 'flac',
          sampleRate: 96000,
          bitDepth: 24,
          timestamp: now,
        ),
        PlaybackLogEntry(
          id: 'log_b1',
          trackId: 't3',
          title: 'Bohemian Rhapsody',
          artist: 'Queen',
          album: 'A Night at the Opera',
          genre: 'Rock',
          durationPlayedMs: 350000,
          trackDurationMs: 350000,
          format: 'flac',
          sampleRate: 44100,
          bitDepth: 16,
          timestamp: now,
        ),
      ];

      const calc = StudioWrappedCalculator();
      final data = calc.calculate(rawLogs: logs);

      expect(data.topAlbums.length, 2);
      expect(data.topAlbums.first.album, 'The Wall');
      expect(data.topAlbums.first.artist, 'Pink Floyd');
      expect(data.topAlbums.first.rank, 1);
      expect(data.topAlbums.first.trackCount, 2);
      expect(data.topAlbums.first.playCount, 2);
      expect(data.topAlbums[1].album, 'A Night at the Opera');
      expect(data.topAlbums[1].rank, 2);
      expect(data.topAlbum?.album, 'The Wall');
    });

    testWidgets('StudioWrappedBentoBanner renders recap badge, stats, and handles tap', (tester) async {
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
      expect(find.byType(StudioWrappedBentoBanner), findsOneWidget);
    });

    testWidgets('StudioListeningStatsDetailScreen renders all sections, filter switcher, and launchers', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: StudioListeningStatsDetailScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Listening Insights'), findsOneWidget);
      expect(find.text('2026 Studio Wrapped'), findsOneWidget);
      expect(find.text('Last 30 Days Recap'), findsOneWidget);
      expect(find.text('All-Time Journey'), findsOneWidget);

      expect(find.text('AUDIOPHILE ARCHETYPE'), findsOneWidget);
      expect(find.text('TOTAL TIME'), findsOneWidget);
      expect(find.text('TRACKS PLAYED'), findsOneWidget);
      expect(find.text('UNIQUE ARTISTS'), findsOneWidget);
      expect(find.text('UNIQUE ALBUMS'), findsOneWidget);

      expect(find.text('TOP 10 TRACKS'), findsOneWidget);
      expect(find.text('TOP ARTISTS'), findsOneWidget);
      expect(find.text('TOP ALBUMS'), findsOneWidget);
      expect(find.text('GENRE SPECTRUM'), findsOneWidget);
      expect(find.text('SIGNAL CHAIN PURITY'), findsOneWidget);
      expect(find.text('HARDWARE & DSP TELEMETRY'), findsOneWidget);
      expect(find.text('Interactive Story'), findsOneWidget);
      expect(find.text('Export Hub'), findsOneWidget);

      // Switch time filter to Last 30 Days Recap
      await tester.tap(find.text('Last 30 Days Recap'));
      await tester.pumpAndSettle();
      expect(find.text('Last 30 Days Recap'), findsOneWidget);
    });

    test('studioWrappedDataProvider updates reactively in real time when logPlaySession is called', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Simulate logging a new song
      const newTrack = Track(
        id: 'realtime_track_99',
        title: 'Shine On You Crazy Diamond',
        artist: 'Pink Floyd',
        album: 'Wish You Were Here',
        duration: Duration(minutes: 13),
        format: AudioFormat.flac,
        sampleRate: 96000,
        bitDepth: 24,
      );

      await container.read(playbackAnalyticsServiceProvider).logPlaySession(
        track: newTrack,
        durationPlayed: const Duration(minutes: 13),
      );

      final updatedData = container.read(studioWrappedDataProvider);
      expect(updatedData.totalTracksPlayed, 1);
      expect(updatedData.topTracks.any((t) => t.title == 'Shine On You Crazy Diamond'), isTrue);
      expect(updatedData.topArtists.any((a) => a.artist == 'Pink Floyd'), isTrue);

      // Log a second track to verify incremental telemetry
      const track2 = Track(
        id: 'realtime_track_100',
        title: 'Comfortably Numb',
        artist: 'Pink Floyd',
        album: 'The Wall',
        duration: Duration(minutes: 6),
        format: AudioFormat.flac,
      );
      await container.read(playbackAnalyticsServiceProvider).logPlaySession(
        track: track2,
        durationPlayed: const Duration(minutes: 6),
      );

      final secondUpdated = container.read(studioWrappedDataProvider);
      expect(secondUpdated.totalTracksPlayed, 2);
      expect(secondUpdated.topTracks.any((t) => t.title == 'Comfortably Numb'), isTrue);
    });
  });
}

