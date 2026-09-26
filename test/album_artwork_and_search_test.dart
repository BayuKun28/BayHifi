import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baydev_hifi/features/library/domain/library_collection_models.dart';
import 'package:baydev_hifi/features/library/presentation/controllers/library_controller.dart';
import 'package:baydev_hifi/features/library/presentation/unified_library_screen.dart';
import 'package:baydev_hifi/features/player/domain/track.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Album Model & Artwork Tests', () {
    test('AlbumModel exposes firstTrack fallback', () {
      final t = const Track(
        id: 't1',
        title: 'Song 1',
        artist: 'Artist 1',
        album: 'Album 1',
        duration: Duration(minutes: 4),
        filePath: '/storage/music/song1.flac',
      );

      final album = AlbumModel(
        name: 'Album 1',
        artist: 'Artist 1',
        tracks: [t],
      );

      expect(album.firstTrack, isNotNull);
      expect(album.firstTrack?.title, 'Song 1');
      expect(album.firstTrack?.filePath, '/storage/music/song1.flac');
    });

    testWidgets('UnifiedLibraryScreen search toggle opens compact search bar without duplicate close button', (tester) async {
      final mockTracks = [
        const Track(
          id: '1',
          title: 'Comfortably Numb',
          artist: 'Pink Floyd',
          album: 'The Wall',
          duration: Duration(minutes: 6, seconds: 22),
          filePath: '/music/pink_floyd.flac',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            unifiedLibraryProvider.overrideWith((ref) {
              final notifier = UnifiedLibraryController();
              notifier.state = notifier.state.copyWith(tracks: mockTracks);
              return notifier;
            }),
          ],
          child: const MaterialApp(
            home: UnifiedLibraryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find search toggle button and tap
      final searchButton = find.byTooltip('Search Library');
      expect(searchButton, findsOneWidget);
      await tester.tap(searchButton);
      await tester.pumpAndSettle();

      // Search field should be visible
      expect(find.byKey(const ValueKey('search_field')), findsOneWidget);
      expect(find.byTooltip('Close Search'), findsOneWidget);
    });
  });
}
