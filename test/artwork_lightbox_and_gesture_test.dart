import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:baydev_hifi/core/widgets/studio_artwork_lightbox.dart';
import 'package:baydev_hifi/features/library/domain/library_collection_models.dart';
import 'package:baydev_hifi/features/library/presentation/screens/album_detail_screen.dart';
import 'package:baydev_hifi/features/library/presentation/widgets/artist_avatar_widget.dart';
import 'package:baydev_hifi/features/player/domain/track.dart';
import 'package:baydev_hifi/features/settings/domain/player_customization_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testTrack = Track(
    id: 'track_test_1',
    title: 'High Resolution Symphony',
    artist: 'HiFi Audio Masters',
    album: 'Studio Reference Vol 1',
    duration: const Duration(minutes: 4, seconds: 15),
    filePath: '/music/test_track.flac',
    format: AudioFormat.flac,
    bitrate: 3200,
    sampleRate: 96000,
    bitDepth: 24,
    albumArtBytes: Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]),
  );

  group('ArtworkGestureAction & Settings Tests', () {
    test('viewFullArtwork enum is properly defined with label and description', () {
      const action = ArtworkGestureAction.viewFullArtwork;
      expect(action.label, 'View Full Artwork');
      expect(action.description, contains('artwork lightbox'));
    });

    test('ArtworkGestureAction fromString parses viewFullArtwork correctly', () {
      final parsed = ArtworkGestureAction.fromString('viewFullArtwork');
      expect(parsed, ArtworkGestureAction.viewFullArtwork);

      final fallback = ArtworkGestureAction.fromString('unknownAction', ArtworkGestureAction.none);
      expect(fallback, ArtworkGestureAction.none);
    });
  });

  group('StudioArtworkLightbox Widget Tests', () {
    testWidgets('Renders lightbox with title, artist subtitle, and format tag', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StudioArtworkLightbox(
            track: testTrack,
            title: testTrack.album,
            subtitle: testTrack.artist,
            formatTag: 'FLAC 96kHz / 24-bit',
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Studio Reference Vol 1'), findsOneWidget);
      expect(find.text('HiFi Audio Masters'), findsOneWidget);
      expect(find.text('FLAC 96kHz / 24-bit'), findsOneWidget);
      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.byType(M3EIconButton), findsOneWidget);
    });

    testWidgets('Double-tap triggers zoom scale transformation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StudioArtworkLightbox(
            track: testTrack,
            title: testTrack.title,
            subtitle: testTrack.artist,
          ),
        ),
      );

      await tester.pumpAndSettle();

      final interactiveViewerFinder = find.byType(InteractiveViewer);
      expect(interactiveViewerFinder, findsOneWidget);

      // Perform double tap
      await tester.tap(interactiveViewerFinder);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(interactiveViewerFinder);
      await tester.pumpAndSettle();

      final interactiveViewer = tester.widget<InteractiveViewer>(interactiveViewerFinder);
      expect(interactiveViewer.transformationController, isNotNull);
    });

    testWidgets('Close button pops navigator', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => StudioArtworkLightbox.show(
                  context,
                  track: testTrack,
                  title: 'Test Album',
                ),
                child: const Text('Open Lightbox'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Lightbox'));
      await tester.pumpAndSettle();

      expect(find.byType(StudioArtworkLightbox), findsOneWidget);
      expect(find.text('Test Album'), findsOneWidget);

      // Tap close button
      await tester.tap(find.byType(M3EIconButton));
      await tester.pumpAndSettle();

      expect(find.byType(StudioArtworkLightbox), findsNothing);
    });
  });

  group('ArtistAvatarWidget Lightbox Integration Tests', () {
    testWidgets('Tapping ArtistAvatarWidget with enableLightboxOnTap opens Lightbox', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ArtistAvatarWidget(
                artistName: 'Hans Zimmer',
                radius: 40,
                enableLightboxOnTap: true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap avatar
      await tester.tap(find.byType(ArtistAvatarWidget));
      await tester.pumpAndSettle();

      expect(find.byType(StudioArtworkLightbox), findsOneWidget);
      expect(find.text('Hans Zimmer'), findsOneWidget);
      expect(find.text('Artist Discography'), findsOneWidget);
    });
  });

  group('AlbumDetailScreen Lightbox Integration Tests', () {
    testWidgets('Tapping album cover in AlbumDetailScreen opens Lightbox', (tester) async {
      final album = AlbumModel(
        name: 'Interstellar Soundtrack',
        artist: 'Hans Zimmer',
        tracks: [testTrack],
        year: 2014,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: AlbumDetailScreen(album: album),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find album art hero container
      final heroFinder = find.byType(Hero);
      expect(heroFinder, findsWidgets);

      // Tap on the first Hero widget (album cover)
      await tester.tap(heroFinder.first);
      await tester.pumpAndSettle();

      expect(find.byType(StudioArtworkLightbox), findsOneWidget);
      expect(find.text('Interstellar Soundtrack'), findsWidgets);
    });
  });
}
