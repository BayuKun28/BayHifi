import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baydev_hifi/features/library/presentation/controllers/library_controller.dart';
import 'package:baydev_hifi/features/library/presentation/playlists_screen.dart';
import 'package:baydev_hifi/features/player/domain/track.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('PlaylistsScreen renders Smart Playlists and allows creating custom playlist', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final sampleTracks = [
      const Track(
        id: 't1',
        title: 'Kind of Blue',
        artist: 'Miles Davis',
        album: 'Kind of Blue',
        duration: Duration(minutes: 5, seconds: 30),
        filePath: '/music/track1.flac',
        format: AudioFormat.flac,
        sampleRate: 96000,
        bitDepth: 24,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          unifiedLibraryProvider.overrideWith(
            (ref) => UnifiedLibraryController(initialTracks: sampleTracks),
          ),
        ],
        child: const MaterialApp(
          home: PlaylistsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Screen Title
    expect(find.text('STUDIO PLAYLISTS'), findsOneWidget);

    // Verify Smart Playlists
    expect(find.text('Favorite Tracks'), findsOneWidget);
    expect(find.text('Hi-Res Lossless Masters'), findsOneWidget);

    // Verify Create Playlist Action is visible
    expect(find.text('CREATE PLAYLIST'), findsWidgets);
  });
}
