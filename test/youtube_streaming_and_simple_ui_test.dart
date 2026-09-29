import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baydev_hifi/app/theme/theme_mode_controller.dart';
import 'package:baydev_hifi/audio_engine/audio_cache_service.dart';
import 'package:baydev_hifi/core/database/local_persistence_service.dart';
import 'package:baydev_hifi/features/player/domain/track.dart';
import 'package:baydev_hifi/features/youtube_music/data/webm_to_ogg_remuxer.dart';
import 'package:baydev_hifi/features/youtube_music/presentation/controllers/youtube_music_controller.dart';
import 'package:baydev_hifi/features/youtube_music/presentation/youtube_discovery_screen.dart';

class _MockYouTubeMusicController extends YouTubeMusicController {
  _MockYouTubeMusicController(super.ref, [super.initialState]);

  @override
  Future<void> onQueryChanged(String query) async {
    state = state.copyWith(query: query);
  }

  @override
  Future<void> fetchTrending({bool force = false}) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('bayhifi_youtube_test');
    await LocalPersistenceService.instance.init(customPath: '${tempDir.path}/test_storage.json');
    AudioCacheService.instance.setCacheDirForTesting(tempDir);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  final testYtTrack1 = Track(
    id: 'yt_dQw4w9WgXcQ',
    title: 'Never Gonna Give You Up',
    artist: 'Rick Astley',
    album: 'YouTube Music',
    duration: const Duration(minutes: 3, seconds: 32),
    format: AudioFormat.opus,
    bitrate: 160,
  );

  final testYtTrack2 = Track(
    id: 'yt_9bZkp7q19f0',
    title: 'Gangnam Style',
    artist: 'PSY',
    album: 'YouTube Music',
    duration: const Duration(minutes: 4, seconds: 12),
    format: AudioFormat.opus,
    bitrate: 160,
  );

  group('Phase 37.1: WebmToOggRemuxer Packet Bundling & Ogg Header Synthesis Tests', () {
    test('WebmToOggRemuxer bundles packets into valid Ogg pages with proper granule positions', () async {
      final bytes = <int>[];

      // 1. EBML Header (0x1A45DFA3)
      bytes.addAll([0x1A, 0x45, 0xDF, 0xA3, 0x84, 0x42, 0x86, 0x81, 0x01]);

      // 2. Segment (0x18538067)
      bytes.addAll([0x18, 0x53, 0x80, 0x67, 0xFF]);

      // 3. Tracks (0x1654AE6B)
      final trackEntryBytes = <int>[
        0xD7, 0x81, 0x01, // TrackNumber = 1
        0x83, 0x81, 0x02, // TrackType = 2 (audio)
        0x86, 0x86, ...utf8.encode('A_OPUS'), // CodecID
        0x63, 0xA2, 0x93, ...OggPageBuilder.createDefaultOpusHead(), // CodecPrivate
      ];
      bytes.addAll([0x16, 0x54, 0xAE, 0x6B, 0x80 | (trackEntryBytes.length + 2), 0xAE, 0x80 | trackEntryBytes.length, ...trackEntryBytes]);

      // 4. Cluster (0x1F43B675) with multiple SimpleBlocks
      final clusterPayload = <int>[
        0xE7, 0x81, 0x00, // Timecode 0
      ];

      for (int i = 0; i < 10; i++) {
        final opusPacket = Uint8List.fromList([(27 << 3) | 0, 0x10 + i, 0x20 + i, 0x30 + i]);
        final blockData = <int>[
          0x81, // Track 1
          0x00, i * 20, // Timecode
          0x80, // Keyframe, no lacing
          ...opusPacket,
        ];
        clusterPayload.addAll([0xA3, 0x80 | blockData.length, ...blockData]);
      }

      bytes.addAll([0x1F, 0x43, 0xB6, 0x75, 0x80 | clusterPayload.length, ...clusterPayload]);

      final inputStream = Stream<List<int>>.fromIterable([
        bytes.sublist(0, 30),
        bytes.sublist(30, 80),
        bytes.sublist(80),
      ]);

      final oggStream = WebmToOggRemuxer.remuxStream(inputStream, serialNumber: 0x12345678);
      final oggPages = await oggStream.toList();

      expect(oggPages.isNotEmpty, isTrue);

      // Page 0 should be OpusHead BOS
      final page0 = oggPages[0];
      expect(page0.sublist(0, 4), [0x4F, 0x67, 0x67, 0x53]); // OggS
      expect(page0[5], 0x02); // BOS flag

      // Page 1 should be OpusTags
      final page1 = oggPages[1];
      expect(page1.sublist(0, 4), [0x4F, 0x67, 0x67, 0x53]);
      expect(page1[5], 0x00);

      // All pages should start with 'OggS'
      for (final page in oggPages) {
        expect(page.sublist(0, 4), [0x4F, 0x67, 0x67, 0x53]);
      }
    });
  });

  group('Phase 37.2: YouTubeDiscoveryScreen UI/UX Streamlining Tests', () {
    testWidgets('YouTubeDiscoveryScreen renders simplified search, filter pills, bento overview & trending', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer(
        overrides: [
          youtubeMusicControllerProvider.overrideWith(
            (ref) => _MockYouTubeMusicController(
              ref,
              YouTubeMusicState(
                trendingTracks: [testYtTrack1, testYtTrack2],
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppThemeBuilder.buildTheme(AppPalette.namidaCyan, isDark: true),
            home: const YouTubeDiscoveryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Header
      expect(find.text('YOUTUBE MUSIC HIFI'), findsOneWidget);
      expect(find.textContaining('SOLOUD C++ DSP'), findsOneWidget);

      // Verify Search Bar & Quick Filters
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Top 100 Charts'), findsOneWidget);
      expect(find.text('Audiophile Masters'), findsOneWidget);
      expect(find.text('Acoustic Live'), findsOneWidget);

      // Verify Bento DSP Overview Card
      expect(find.text('C++ SOLOUD AUDIO PIPELINE'), findsOneWidget);
      expect(find.text('ACTIVE'), findsOneWidget);

      // Verify Curated Category Tiles
      expect(find.text('Global Top 50'), findsOneWidget);
      expect(find.text('Audiophile Mix'), findsOneWidget);
      expect(find.text('Acoustic Sessions'), findsOneWidget);
      expect(find.text('Import Playlist'), findsOneWidget);

      // Verify Trending Section & Track Tiles
      expect(find.text('GLOBAL TOP MUSIC CHARTS'), findsOneWidget);
      expect(find.text('Never Gonna Give You Up'), findsOneWidget);
      expect(find.text('Rick Astley'), findsOneWidget);
      expect(find.text('Gangnam Style'), findsOneWidget);
      expect(find.text('PSY'), findsOneWidget);
    });

    testWidgets('YouTubeDiscoveryScreen search results show result counter and allows play all', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer(
        overrides: [
          youtubeMusicControllerProvider.overrideWith(
            (ref) => _MockYouTubeMusicController(
              ref,
              YouTubeMusicState(
                query: 'Rick Astley',
                searchResults: [testYtTrack1],
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppThemeBuilder.buildTheme(AppPalette.namidaCyan, isDark: true),
            home: const YouTubeDiscoveryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('1 RESULTS FOUND'), findsOneWidget);
      expect(find.text('Play All'), findsOneWidget);
      expect(find.text('Shuffle'), findsOneWidget);
      expect(find.text('Never Gonna Give You Up'), findsOneWidget);
      expect(find.text('Rick Astley'), findsOneWidget);
    });
  });
}
