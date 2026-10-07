import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:baydev_hifi/audio_engine/soloud_controller.dart';
import 'package:baydev_hifi/features/player/domain/playback_state.dart';
import 'package:baydev_hifi/features/player/domain/track.dart';
import 'package:baydev_hifi/features/player/presentation/controllers/player_controller.dart';
import 'package:baydev_hifi/features/player/presentation/widgets/now_playing_queue_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final List<Track> mockTracks = List.generate(
    6,
    (i) => Track(
      id: 'track_$i',
      title: 'Lossless Track $i',
      artist: 'Artist $i',
      album: 'Studio Album $i',
      duration: const Duration(minutes: 4),
      filePath: '/music/track_$i.flac',
      format: AudioFormat.flac,
    ),
  );

  test('PlayerController shuffleQueue pins currently playing track at index 0', () {
    final controller = PlayerController(SoLoudController.instance);
    final initialTracks = List<Track>.from(mockTracks);

    controller.state = controller.state.copyWith(
      queue: initialTracks,
      queueIndex: 2,
      currentTrack: initialTracks[2],
      isShuffle: false,
    );

    expect(controller.state.currentTrack?.id, 'track_2');
    expect(controller.state.queue[controller.state.queueIndex].id, 'track_2');

    // Perform shuffle keeping current track first
    controller.shuffleQueue(keepCurrentTrackFirst: true);

    expect(controller.state.isShuffle, isTrue);
    expect(controller.state.queueIndex, 0);
    expect(controller.state.queue.first.id, 'track_2');
    expect(controller.state.queue.length, initialTracks.length);

    // All original tracks must still be in the queue
    final queueIds = controller.state.queue.map((t) => t.id).toSet();
    expect(queueIds, initialTracks.map((t) => t.id).toSet());
  });

  testWidgets('NowPlayingQueueSheet renders lean index numbers and triggers shuffle', (tester) async {
    final controller = PlayerController(SoLoudController.instance);
    controller.state = PlaybackState(
      queue: mockTracks,
      queueIndex: 0,
      currentTrack: mockTracks[0],
      status: PlaybackStatus.playing,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playerControllerProvider.overrideWith((ref) => controller),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: NowPlayingQueueSheet(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify queue header
    expect(find.text('UP NEXT QUEUE'), findsOneWidget);
    expect(find.text('1 of 6 Tracks'), findsOneWidget);

    // Verify lean track numbers
    expect(find.text('02'), findsOneWidget);
    expect(find.text('03'), findsOneWidget);

    // Verify clear queue button exists
    expect(find.byWidgetPredicate((w) => w is M3EIconButton && w.tooltip == 'Clear Queue'), findsOneWidget);

    // Tap shuffle button
    await tester.tap(find.byWidgetPredicate((w) => w is M3EIconButton && w.tooltip == 'Shuffle Queue'));
    await tester.pumpAndSettle();

    expect(controller.state.isShuffle, isTrue);
    expect(controller.state.queue.first.id, 'track_0');
  });
}
