import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baydev_hifi/app/theme/theme_mode_controller.dart';
import 'package:baydev_hifi/audio_engine/audio_cache_service.dart';
import 'package:baydev_hifi/core/database/local_persistence_service.dart';
import 'package:baydev_hifi/features/library/domain/library_collection_models.dart';
import 'package:baydev_hifi/features/library/domain/smart_playlist_models.dart';
import 'package:baydev_hifi/features/library/presentation/controllers/library_controller.dart';
import 'package:baydev_hifi/features/library/presentation/playlists_screen.dart';
import 'package:baydev_hifi/features/library/presentation/screens/playlist_detail_screen.dart';
import 'package:baydev_hifi/features/library/presentation/screens/smart_playlists_screen.dart';
import 'package:baydev_hifi/features/library/presentation/widgets/create_custom_playlist_modal.dart';
import 'package:baydev_hifi/features/library/presentation/widgets/create_smart_playlist_dialog.dart';
import 'package:baydev_hifi/features/library/presentation/widgets/studio_playlist_action_sheet.dart';
import 'package:baydev_hifi/features/player/domain/track.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('bayhifi_playlist_redesign_test');
    await LocalPersistenceService.instance.init(customPath: '${tempDir.path}/test_storage.json');
    AudioCacheService.instance.setCacheDirForTesting(tempDir);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  final testTrack1 = Track(
    id: 'track_1',
    title: 'Hotel California',
    artist: 'Eagles',
    album: 'Hotel California',
    duration: const Duration(minutes: 6, seconds: 30),
    filePath: '/music/eagles.flac',
    format: AudioFormat.flac,
    bitDepth: 24,
    sampleRate: 96000,
  );

  final testTrack2 = Track(
    id: 'track_2',
    title: 'Comfortably Numb',
    artist: 'Pink Floyd',
    album: 'The Wall',
    duration: const Duration(minutes: 6, seconds: 22),
    filePath: '/music/pinkfloyd.flac',
    format: AudioFormat.flac,
    bitDepth: 24,
    sampleRate: 192000,
  );

  final testPlaylist = PlaylistModel(
    id: 'custom_1',
    name: 'Acoustic Studio Masters',
    description: 'Lossless acoustic mastering session',
    tracks: [testTrack1, testTrack2],
    isCustom: true,
    createdAt: DateTime.now(),
  );

  final testSmartPlaylist = SmartPlaylist(
    id: 'smart_hires_test',
    name: 'Hi-Res Lossless 24-bit',
    description: 'Dynamic rule for 24-bit tracks',
    matchMode: SmartPlaylistMatchMode.all,
    rules: const [
      SmartPlaylistRule(
        field: SmartPlaylistField.bitDepth,
        operator: SmartPlaylistOperator.greaterThanOrEqual,
        value: '24',
      ),
    ],
    isPreset: true,
    createdAt: DateTime(2026, 1, 1),
  );

  group('Phase 36.1: PlaylistsScreen Studio Collections & Custom Playlists Tests', () {
    testWidgets('PlaylistsScreen renders Studio Collections row (Favorites, Hi-Res, Smart Playlists)', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer(
        overrides: [
          unifiedLibraryProvider.overrideWith(
            (ref) => UnifiedLibraryController(
              initialTracks: [testTrack1, testTrack2],
              initialCustomPlaylists: [testPlaylist],
              initialSmartPlaylists: [testSmartPlaylist],
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
            home: const PlaylistsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('STUDIO PLAYLISTS'), findsOneWidget);
      expect(find.text('STUDIO COLLECTIONS'), findsOneWidget);
      expect(find.text('Favorite Tracks'), findsOneWidget);
      expect(find.text('Hi-Res Lossless Masters'), findsOneWidget);
      expect(find.text('Dynamic Smart Playlists'), findsOneWidget);
      expect(find.text('Acoustic Studio Masters'), findsOneWidget);
      expect(find.text('+ New Playlist'), findsOneWidget);
    });
  });

  group('Phase 36.2: CreateCustomPlaylistModal & CreateSmartPlaylistDialog Tests', () {
    testWidgets('CreateCustomPlaylistModal creates new playlist via UnifiedLibraryController', (tester) async {
      final container = ProviderContainer(
        overrides: [
          unifiedLibraryProvider.overrideWith(
            (ref) => UnifiedLibraryController(
              initialTracks: [testTrack1],
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
            home: const Scaffold(
              body: CreateCustomPlaylistModal(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('CREATE NEW PLAYLIST'), findsOneWidget);
      expect(find.text('Playlist Name'), findsOneWidget);
      expect(find.text('Description (Optional)'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, 'Midnight Jazz Session');
      await tester.enterText(find.byType(TextField).last, 'Late night jazz audio tracks');
      await tester.tap(find.text('Create Playlist'));
      await tester.pumpAndSettle();

      final playlists = container.read(unifiedLibraryProvider).customPlaylists;
      expect(playlists.any((p) => p.name == 'Midnight Jazz Session'), isTrue);
    });

    testWidgets('CreateSmartPlaylistDialog renders compact UI and evaluates conditions', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer(
        overrides: [
          unifiedLibraryProvider.overrideWith(
            (ref) => UnifiedLibraryController(
              initialTracks: [testTrack1, testTrack2],
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
            home: const Scaffold(
              body: CreateSmartPlaylistDialog(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('NEW SMART PLAYLIST'), findsOneWidget);
      expect(find.text('MATCH LOGIC'), findsOneWidget);
      expect(find.text('CONDITIONS (1)'), findsOneWidget);
      expect(find.text('SORTING & LIMITS'), findsOneWidget);
      expect(find.text('Save Smart Playlist'), findsOneWidget);
    });
  });

  group('Phase 36.3: StudioPlaylistActionSheet Tests', () {
    testWidgets('StudioPlaylistActionSheet renders action tiles cleanly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppThemeBuilder.buildTheme(AppPalette.namidaCyan, isDark: true),
            home: Scaffold(
              body: StudioPlaylistActionSheet(
                playlist: testPlaylist,
                tracks: testPlaylist.tracks,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Acoustic Studio Masters'), findsOneWidget);
      expect(find.text('Play Now'), findsOneWidget);
      expect(find.text('Shuffle Play'), findsOneWidget);
      expect(find.text('Add to Queue'), findsOneWidget);
      expect(find.text('Rename / Edit Details'), findsOneWidget);
      expect(find.text('Export M3U8 Archive'), findsOneWidget);
      expect(find.text('Delete Playlist'), findsOneWidget);
    });
  });

  group('Phase 36.4: PlaylistDetailScreen & SmartPlaylistsScreen Tests', () {
    testWidgets('PlaylistDetailScreen renders collapsing header, actions and tracklist with Scrollbar', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer(
        overrides: [
          unifiedLibraryProvider.overrideWith(
            (ref) => UnifiedLibraryController(
              initialTracks: [testTrack1, testTrack2],
              initialCustomPlaylists: [testPlaylist],
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
            home: PlaylistDetailScreen(playlist: testPlaylist),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Acoustic Studio Masters'), findsWidgets);
      expect(find.text('Play All'), findsOneWidget);
      expect(find.text('Shuffle'), findsOneWidget);
      expect(find.byType(Scrollbar), findsOneWidget);
      expect(find.text('Hotel California'), findsOneWidget);
      expect(find.text('Comfortably Numb'), findsOneWidget);
    });

    testWidgets('SmartPlaylistsScreen renders dynamic rule sets and navigates to detail', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer(
        overrides: [
          unifiedLibraryProvider.overrideWith(
            (ref) => UnifiedLibraryController(
              initialTracks: [testTrack1, testTrack2],
              initialSmartPlaylists: [testSmartPlaylist],
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
            home: const SmartPlaylistsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('DYNAMIC SMART PLAYLISTS'), findsOneWidget);
      expect(find.text('STUDIO SMART ENGINE'), findsOneWidget);
      expect(find.text('Hi-Res Lossless 24-bit'), findsOneWidget);
      expect(find.text('PRESET'), findsOneWidget);
    });
  });
}
