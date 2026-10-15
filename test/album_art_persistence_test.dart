import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baydev_hifi/core/widgets/studio_artwork_widget.dart';
import 'package:baydev_hifi/features/player/domain/track.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Album Art Persistence & Rendering Tests', () {
    test('Track toMap and fromMap preserves albumArtUrl across hot restart and serialization', () {
      const originalTrack = Track(
        id: 'test_track_1',
        title: 'Lossless Master',
        artist: 'Studio Artist',
        album: 'Audiophile Album',
        duration: Duration(minutes: 4, seconds: 12),
        filePath: '/storage/music/song.flac',
        albumArtUrl: '/data/user/0/com.baydev.baydev_hifi/app_flutter/covers/art_123.jpg',
      );

      final map = originalTrack.toMap();
      expect(map['albumArtUrl'], equals('/data/user/0/com.baydev.baydev_hifi/app_flutter/covers/art_123.jpg'));

      final restored = Track.fromMap(map);
      expect(restored.id, equals(originalTrack.id));
      expect(restored.title, equals(originalTrack.title));
      expect(restored.albumArtUrl, equals(originalTrack.albumArtUrl));
    });

    test('StudioArtworkWidget.getImageProvider returns correct ImageProvider for memory, network and file', () {
      // 1. Memory bytes
      final memTrack = Track(
        id: 'mem_1',
        title: 'Mem Track',
        artist: 'Artist',
        album: 'Album',
        duration: const Duration(minutes: 3),
        albumArtBytes: Uint8List.fromList([1, 2, 3, 4]),
      );
      final memProvider = StudioArtworkWidget.getImageProvider(memTrack);
      expect(memProvider, isA<MemoryImage>());

      // 2. Network URL
      const netTrack = Track(
        id: 'net_1',
        title: 'Net Track',
        artist: 'Artist',
        album: 'Album',
        duration: Duration(minutes: 3),
        albumArtUrl: 'https://images.example.com/cover.jpg',
      );
      final netProvider = StudioArtworkWidget.getImageProvider(netTrack);
      expect(netProvider, isA<NetworkImage>());

      // 3. Local file paths (Linux / Android)
      const localTrackAndroid = Track(
        id: 'local_android_1',
        title: 'Local Android Track',
        artist: 'Artist',
        album: 'Album',
        duration: Duration(minutes: 3),
        albumArtUrl: '/data/user/0/com.baydev.baydev_hifi/app_flutter/covers/art_123.jpg',
      );
      final localProviderAndroid = StudioArtworkWidget.getImageProvider(localTrackAndroid);
      expect(localProviderAndroid, isA<FileImage>());

      const localTrackLinux = Track(
        id: 'local_linux_1',
        title: 'Local Linux Track',
        artist: 'Artist',
        album: 'Album',
        duration: Duration(minutes: 3),
        albumArtUrl: '/home/user/.local/share/bayhifi/covers/art_456.jpg',
      );
      final localProviderLinux = StudioArtworkWidget.getImageProvider(localTrackLinux);
      expect(localProviderLinux, isA<FileImage>());

      // 4. Server relative path
      const serverTrack = Track(
        id: 'server_1',
        title: 'Server Track',
        artist: 'Artist',
        album: 'Album',
        duration: Duration(minutes: 3),
        albumArtUrl: '/api/library/cover/srv_123',
      );
      final serverProvider = StudioArtworkWidget.getImageProvider(serverTrack);
      expect(serverProvider, isA<NetworkImage>());

      // 5. Null track
      expect(StudioArtworkWidget.getImageProvider(null), isNull);
    });

    testWidgets('StudioArtworkWidget renders gracefully with fallback icon when artwork is absent', (WidgetTester tester) async {
      const emptyTrack = Track(
        id: 'empty_1',
        title: 'No Cover Song',
        artist: 'Artist',
        album: 'Album',
        duration: Duration(minutes: 3),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StudioArtworkWidget(
              track: emptyTrack,
              width: 50,
              height: 50,
            ),
          ),
        ),
      );

      expect(find.byType(StudioArtworkWidget), findsOneWidget);
    });
  });
}
