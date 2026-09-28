import 'package:baydev_hifi/app/theme/theme_mode_controller.dart';
import 'package:baydev_hifi/features/library/domain/library_collection_models.dart';
import 'package:baydev_hifi/features/library/presentation/controllers/library_controller.dart';
import 'package:baydev_hifi/features/library/presentation/screens/album_detail_screen.dart';
import 'package:baydev_hifi/features/library/presentation/screens/artist_detail_screen.dart';
import 'package:baydev_hifi/features/library/presentation/screens/folder_detail_screen.dart';
import 'package:baydev_hifi/features/library/presentation/screens/genre_detail_screen.dart';
import 'package:baydev_hifi/features/player/domain/track.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleTracks = [
    Track(
      id: 'track_01',
      title: 'Acoustic Sunrise',
      artist: 'Acoustic Studio Lab',
      album: 'Morning HiFi Sessions',
      duration: const Duration(seconds: 245),
      format: AudioFormat.flac,
      filePath: '/storage/emulated/0/Music/HiFi/track_01.flac',
      genre: 'Acoustic',
      bitDepth: 24,
      sampleRate: 96000,
    ),
    Track(
      id: 'track_02',
      title: 'Midnight Resonance',
      artist: 'Acoustic Studio Lab',
      album: 'Morning HiFi Sessions',
      duration: const Duration(seconds: 198),
      format: AudioFormat.mp3,
      filePath: '/storage/emulated/0/Music/HiFi/track_02.mp3',
      genre: 'Acoustic',
      bitDepth: 16,
      sampleRate: 44100,
    ),
    Track(
      id: 'track_03',
      title: 'Vinyl Nostalgia',
      artist: 'Acoustic Studio Lab',
      album: 'Analog Dreams EP',
      duration: const Duration(seconds: 310),
      format: AudioFormat.wav,
      filePath: '/storage/emulated/0/Music/HiFi/track_03.wav',
      genre: 'Acoustic',
      bitDepth: 16,
      sampleRate: 44100,
    ),
  ];

  final sampleAlbum = AlbumModel(
    name: 'Morning HiFi Sessions',
    artist: 'Acoustic Studio Lab',
    year: 2024,
    tracks: [sampleTracks[0], sampleTracks[1]],
  );

  final sampleArtist = ArtistModel(
    name: 'Acoustic Studio Lab',
    tracks: sampleTracks,
  );

  final sampleGenre = GenreModel(
    name: 'Acoustic',
    tracks: sampleTracks,
  );

  final sampleFolder = FolderModel(
    path: '/storage/emulated/0/Music/HiFi',
    name: 'HiFi',
    tracks: sampleTracks,
  );

  Widget createTestWidget({
    required Widget child,
    List<Override> overrides = const [],
  }) {
    return ProviderScope(
      overrides: [
        unifiedLibraryProvider.overrideWith((ref) {
          final notifier = UnifiedLibraryController();
          notifier.state = notifier.state.copyWith(
            tracks: sampleTracks,
          );
          return notifier;
        }),
        ...overrides,
      ],
      child: MaterialApp(
        theme: AppThemeBuilder.buildTheme(AppPalette.namidaCyan, isDark: true),
        home: child,
      ),
    );
  }

  group('Phase 26: Dedicated Detail Screens Tests', () {
    testWidgets('AlbumDetailScreen renders metadata, ordered tracks, and triggers play', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestWidget(
        child: AlbumDetailScreen(album: sampleAlbum),
      ));
      await tester.pumpAndSettle();

      // Verify Header Info
      expect(find.text('Morning HiFi Sessions'), findsOneWidget);
      expect(find.text('Acoustic Studio Lab'), findsWidgets);
      expect(find.text('HI-RES LOSSLESS'), findsOneWidget);
      expect(find.text('Play All'), findsOneWidget);
      expect(find.text('Shuffle'), findsOneWidget);

      // Verify Tracks
      expect(find.text('Acoustic Sunrise'), findsOneWidget);
      expect(find.text('Midnight Resonance'), findsOneWidget);
      expect(find.text('01'), findsOneWidget);
      expect(find.text('02'), findsOneWidget);

      // Tap Play All
      await tester.tap(find.text('Play All'));
      await tester.pump();
    });

    testWidgets('ArtistDetailScreen renders discography carousel and tracks', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestWidget(
        child: ArtistDetailScreen(artist: sampleArtist),
      ));
      await tester.pumpAndSettle();

      // Verify Artist Header
      expect(find.text('Acoustic Studio Lab'), findsOneWidget);
      expect(find.text('ARTIST DISCOGRAPHY'), findsOneWidget);

      // Verify Discography Albums
      expect(find.textContaining('ALBUMS & RELEASES'), findsOneWidget);
      expect(find.text('Morning HiFi Sessions'), findsOneWidget);
      expect(find.text('Analog Dreams EP'), findsOneWidget);

      // Verify All Songs
      expect(find.textContaining('ALL SONGS'), findsOneWidget);
      expect(find.text('Acoustic Sunrise'), findsOneWidget);
      expect(find.text('Midnight Resonance'), findsOneWidget);
      expect(find.text('Vinyl Nostalgia'), findsOneWidget);
    });

    testWidgets('GenreDetailScreen renders category header and tracks', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestWidget(
        child: GenreDetailScreen(genre: sampleGenre),
      ));
      await tester.pumpAndSettle();

      expect(find.text('GENRE COLLECTION'), findsOneWidget);
      expect(find.text('Acoustic'), findsOneWidget);
      expect(find.text('Play All'), findsOneWidget);
      expect(find.text('Shuffle'), findsOneWidget);
      expect(find.text('Acoustic Sunrise'), findsOneWidget);
    });

    testWidgets('FolderDetailScreen renders directory path and tracks', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestWidget(
        child: FolderDetailScreen(folder: sampleFolder),
      ));
      await tester.pumpAndSettle();

      expect(find.text('AUDIO FOLDER'), findsOneWidget);
      expect(find.text('HiFi'), findsOneWidget);
      expect(find.text('/storage/emulated/0/Music/HiFi'), findsOneWidget);
      expect(find.text('Play All'), findsOneWidget);
      expect(find.text('Shuffle'), findsOneWidget);
      expect(find.text('Acoustic Sunrise'), findsOneWidget);
    });

    testWidgets('Seamless Bidirectional Navigation (Artist -> Album -> Artist)', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestWidget(
        child: ArtistDetailScreen(artist: sampleArtist),
      ));
      await tester.pumpAndSettle();

      // Tap album in discography
      await tester.tap(find.text('Morning HiFi Sessions').first);
      await tester.pumpAndSettle();

      // Now on AlbumDetailScreen
      expect(find.text('HI-RES LOSSLESS'), findsOneWidget);
      expect(find.text('Acoustic Sunrise'), findsOneWidget);

      // Tap artist name on AlbumDetailScreen
      await tester.tap(find.text('Acoustic Studio Lab').first);
      await tester.pumpAndSettle();

      // Now back on new ArtistDetailScreen instance
      expect(find.text('ARTIST DISCOGRAPHY'), findsOneWidget);
    });

    testWidgets('Collapsing Sliver Parallax & Sticky Action Bar remain accessible during scroll', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Create album with many tracks to allow extensive scrolling
      final manyTracks = List.generate(
        30,
        (i) => Track(
          id: 'track_$i',
          title: 'Track #$i',
          artist: 'Acoustic Studio Lab',
          album: 'Morning HiFi Sessions',
          duration: const Duration(seconds: 200),
          format: AudioFormat.flac,
          sampleRate: 96000,
          bitDepth: 24,
          filePath: '/storage/emulated/0/Music/HiFi/track_$i.flac',
        ),
      );
      final largeAlbum = AlbumModel(
        name: 'Morning HiFi Sessions',
        artist: 'Acoustic Studio Lab',
        tracks: manyTracks,
      );

      await tester.pumpWidget(createTestWidget(
        child: AlbumDetailScreen(album: largeAlbum),
      ));
      await tester.pumpAndSettle();

      // Initially expanded
      expect(find.text('HI-RES LOSSLESS'), findsOneWidget);
      expect(find.text('Play All'), findsOneWidget);
      expect(find.text('Shuffle'), findsOneWidget);

      // Scroll down 400px
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
      await tester.pumpAndSettle();

      // Pinned Action Bar still visible!
      expect(find.text('Play All'), findsOneWidget);
      expect(find.text('Shuffle'), findsOneWidget);

      // Tap Play All while collapsed
      await tester.tap(find.text('Play All'));
      await tester.pump(const Duration(milliseconds: 200));
    });
  });
}

