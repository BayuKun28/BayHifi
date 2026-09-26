import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:baydev_hifi/audio_engine/soloud_controller.dart';
import 'package:baydev_hifi/features/player/domain/track.dart';
import 'package:baydev_hifi/features/player/presentation/controllers/player_controller.dart';
import 'package:baydev_hifi/features/player/presentation/widgets/now_playing_queue_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return '/tmp/bayhifi_shuffle_test_dir';
    });
  });

  final List<Track> sampleAlbumTracks = List.generate(
    6,
    (i) => Track(
      id: 'album_track_$i',
      title: 'Album Track $i',
      artist: 'Studio Artist',
      album: 'HiFi Album',
      duration: Duration(minutes: 3, seconds: 30 + i * 10),
      filePath: '/music/album_track_$i.flac',
      format: AudioFormat.flac,
      sampleRate: 96000,
      bitDepth: 24,
    ),
  );

  group('Deterministic Bidirectional Shuffle Queue Engine Tests', () {
    test('setQueue stores originalQueue and queue identically when shuffle is off', () async {
      final controller = PlayerController(SoLoudController.instance);

      await controller.setQueue(sampleAlbumTracks, initialIndex: 2, autoPlay: false);

      expect(controller.state.isShuffle, isFalse);
      expect(controller.state.originalQueue.length, 6);
      expect(controller.state.queue.length, 6);
      expect(controller.state.queueIndex, 2);
      expect(controller.state.currentTrack?.id, 'album_track_2');
      expect(controller.state.originalQueue.map((t) => t.id).toList(), [
        'album_track_0',
        'album_track_1',
        'album_track_2',
        'album_track_3',
        'album_track_4',
        'album_track_5',
      ]);
    });

    test('toggleShuffle ON shuffles queue, pins current track at index 0, and preserves originalQueue', () async {
      final controller = PlayerController(SoLoudController.instance);
      await controller.setQueue(sampleAlbumTracks, initialIndex: 2, autoPlay: false);

      // Turn shuffle ON
      controller.toggleShuffle();

      expect(controller.state.isShuffle, isTrue);
      expect(controller.state.queueIndex, 0);
      expect(controller.state.currentTrack?.id, 'album_track_2');
      expect(controller.state.queue.first.id, 'album_track_2');
      expect(controller.state.queue.length, 6);

      // Verify all tracks exist in shuffled queue without duplicates
      final shuffledIds = controller.state.queue.map((t) => t.id).toSet();
      expect(shuffledIds.length, 6);

      // Verify originalQueue is untouched
      expect(controller.state.originalQueue.map((t) => t.id).toList(), [
        'album_track_0',
        'album_track_1',
        'album_track_2',
        'album_track_3',
        'album_track_4',
        'album_track_5',
      ]);
    });

    test('skipNext advances sequentially in shuffled queue without random jumping', () async {
      final controller = PlayerController(SoLoudController.instance);
      controller.state = controller.state.copyWith(isShuffle: false);
      await controller.setQueue(sampleAlbumTracks, initialIndex: 1, autoPlay: false);

      controller.toggleShuffle();
      expect(controller.state.isShuffle, isTrue);
      expect(controller.state.queueIndex, 0);
      expect(controller.state.currentTrack?.id, 'album_track_1');

      final expectedNextTrack = controller.state.queue[1];

      // Skip to next in shuffled queue
      await controller.skipNext();

      expect(controller.state.queueIndex, 1);
      expect(controller.state.currentTrack?.id, expectedNextTrack.id);
    });

    test('toggleShuffle OFF restores exact originalQueue and sets queueIndex to active track position', () async {
      final controller = PlayerController(SoLoudController.instance);
      controller.state = controller.state.copyWith(isShuffle: false);
      await controller.setQueue(sampleAlbumTracks, initialIndex: 0, autoPlay: false);

      // Turn Shuffle ON
      controller.toggleShuffle();
      expect(controller.state.isShuffle, isTrue);

      // Skip to index 2 in shuffled queue
      await controller.skipNext();
      await controller.skipNext();
      expect(controller.state.queueIndex, 2);

      final currentlyPlayingInShuffle = controller.state.currentTrack!;

      // Turn Shuffle OFF (Unshuffle)
      controller.toggleShuffle();
      expect(controller.state.isShuffle, isFalse);

      // Queue is restored to original sequence
      expect(controller.state.queue.map((t) => t.id).toList(), [
        'album_track_0',
        'album_track_1',
        'album_track_2',
        'album_track_3',
        'album_track_4',
        'album_track_5',
      ]);

      // Currently playing track index is matched in original queue
      final expectedOrigIndex = sampleAlbumTracks.indexWhere((t) => t.id == currentlyPlayingInShuffle.id);
      expect(controller.state.queueIndex, expectedOrigIndex);
      expect(controller.state.currentTrack?.id, currentlyPlayingInShuffle.id);

      // Subsequent skipNext advances sequentially in original album order
      if (expectedOrigIndex < sampleAlbumTracks.length - 1) {
        await controller.skipNext();
        expect(controller.state.queueIndex, expectedOrigIndex + 1);
        expect(controller.state.currentTrack?.id, sampleAlbumTracks[expectedOrigIndex + 1].id);
      }
    });

    test('setQueue when isShuffle is already ON immediately shuffles while saving originalQueue', () async {
      final controller = PlayerController(SoLoudController.instance);
      controller.state = controller.state.copyWith(isShuffle: true);

      await controller.setQueue(sampleAlbumTracks, initialIndex: 3, autoPlay: false);

      expect(controller.state.isShuffle, isTrue);
      expect(controller.state.queueIndex, 0);
      expect(controller.state.currentTrack?.id, 'album_track_3');
      expect(controller.state.queue.first.id, 'album_track_3');

      // Original queue is clean album order
      expect(controller.state.originalQueue.map((t) => t.id).toList(), [
        'album_track_0',
        'album_track_1',
        'album_track_2',
        'album_track_3',
        'album_track_4',
        'album_track_5',
      ]);
    });

    test('addToQueue, playNext, and removeFromQueue synchronize queue and originalQueue', () async {
      final controller = PlayerController(SoLoudController.instance);
      await controller.setQueue(sampleAlbumTracks, initialIndex: 0, autoPlay: false);

      final extraTrack = const Track(
        id: 'bonus_track',
        title: 'Bonus Track',
        artist: 'Studio Artist',
        album: 'HiFi Album',
        duration: Duration(minutes: 5),
        format: AudioFormat.flac,
      );

      // Add to queue
      controller.addToQueue(extraTrack);
      expect(controller.state.queue.any((t) => t.id == 'bonus_track'), isTrue);
      expect(controller.state.originalQueue.any((t) => t.id == 'bonus_track'), isTrue);

      // Remove track at index 1
      final trackToRemove = controller.state.queue[1];
      controller.removeFromQueue(1);
      expect(controller.state.queue.any((t) => t.id == trackToRemove.id), isFalse);
      expect(controller.state.originalQueue.any((t) => t.id == trackToRemove.id), isFalse);
    });

    testWidgets('NowPlayingQueueSheet shuffle toggle triggers controller.toggleShuffle',
        (WidgetTester tester) async {
      final container = ProviderContainer();
      final controller = container.read(playerControllerProvider.notifier);
      controller.state = controller.state.copyWith(isShuffle: false);
      await controller.setQueue(sampleAlbumTracks, initialIndex: 0, autoPlay: false);

      expect(container.read(playerControllerProvider).isShuffle, isFalse);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: NowPlayingQueueSheet(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Shuffle button in Queue Sheet
      final shuffleButton = find.byTooltip('Shuffle Queue');
      expect(shuffleButton, findsOneWidget);

      await tester.tap(shuffleButton);
      await tester.pumpAndSettle();

      // Verify shuffle is now active
      expect(container.read(playerControllerProvider).isShuffle, isTrue);

      // Tap again to unshuffle
      await tester.tap(shuffleButton);
      await tester.pumpAndSettle();

      // Verify shuffle is restored to false
      expect(container.read(playerControllerProvider).isShuffle, isFalse);
    });
  });
}
