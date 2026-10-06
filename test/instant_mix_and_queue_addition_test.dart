import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baydev_hifi/features/hardware_dac/domain/models/dac_device.dart';
import 'package:baydev_hifi/features/hardware_dac/presentation/controllers/dac_bridge_controller.dart';
import 'package:baydev_hifi/features/hardware_dac/presentation/controllers/dac_bridge_state.dart';
import 'package:baydev_hifi/features/library/presentation/widgets/instant_mix_config_sheet.dart';
import 'package:baydev_hifi/features/player/domain/track.dart';
import 'package:baydev_hifi/features/player/presentation/controllers/player_controller.dart';
import 'package:baydev_hifi/features/player/presentation/widgets/add_tracks_to_queue_sheet.dart';
import 'package:baydev_hifi/features/player/presentation/widgets/studio_dsp_bento_capsule.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testTrack1 = Track(
    id: 'track_1',
    title: 'Comfortably Numb',
    artist: 'Pink Floyd',
    album: 'The Wall',
    duration: Duration(minutes: 6, seconds: 22),
    genre: 'Progressive Rock',
    year: 1979,
    format: AudioFormat.flac,
  );

  const testTrack2 = Track(
    id: 'track_2',
    title: 'Time',
    artist: 'Pink Floyd',
    album: 'The Dark Side of the Moon',
    duration: Duration(minutes: 7, seconds: 6),
    genre: 'Progressive Rock',
    year: 1973,
    format: AudioFormat.flac,
  );

  const testTrack3 = Track(
    id: 'track_3',
    title: 'Money',
    artist: 'Pink Floyd',
    album: 'The Dark Side of the Moon',
    duration: Duration(minutes: 6, seconds: 22),
    genre: 'Progressive Rock',
    year: 1973,
    format: AudioFormat.flac,
  );

  group('PlayerController Instant Mix & Batch Queue Unit Tests', () {
    test('startInstantMix sets queue with seed track at index 0 and starts playing', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(playerControllerProvider.notifier);
      await controller.startInstantMix(testTrack1, [testTrack2, testTrack3]);

      final state = container.read(playerControllerProvider);
      expect(state.queue.length, equals(3));
      expect(state.queue[0].id, equals(testTrack1.id));
      expect(state.queue[1].id, equals(testTrack2.id));
      expect(state.queue[2].id, equals(testTrack3.id));
      expect(state.queueIndex, equals(0));
      expect(state.currentTrack?.id, equals(testTrack1.id));
    });

    test('addTracksToQueue appends tracks to end when playNext is false', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(playerControllerProvider.notifier);
      await controller.setQueue([testTrack1], autoPlay: false);

      controller.addTracksToQueue([testTrack2, testTrack3], playNext: false);

      final state = container.read(playerControllerProvider);
      expect(state.queue.length, equals(3));
      expect(state.queue.last.id, equals(testTrack3.id));
    });

    test('addTracksToQueue inserts tracks up next when playNext is true', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(playerControllerProvider.notifier);
      await controller.setQueue([testTrack1, testTrack3], initialIndex: 0, autoPlay: false);

      controller.addTracksToQueue([testTrack2], playNext: true);

      final state = container.read(playerControllerProvider);
      expect(state.queue.length, equals(3));
      expect(state.queue[1].id, equals(testTrack2.id));
      expect(state.queue[2].id, equals(testTrack3.id));
    });
  });

  group('InstantMixConfigSheet Widget Tests', () {
    testWidgets('Renders seed track preview, mix criteria chips, and track count selector', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: InstantMixConfigSheet(seedTrack: testTrack1),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Instant Mix Studio'), findsOneWidget);
      expect(find.text('Comfortably Numb'), findsOneWidget);
      expect(find.text('Pink Floyd • The Wall'), findsOneWidget);
      expect(find.text('Genre'), findsOneWidget);
      expect(find.text('Mood'), findsOneWidget);
      expect(find.text('Artist & Era'), findsOneWidget);
      expect(find.text('Random'), findsOneWidget);
      expect(find.text('10'), findsOneWidget); // Default 10 tracks
      expect(find.textContaining('START INSTANT MIX'), findsOneWidget);
    });
  });

  group('AddTracksToQueueSheet Widget Tests', () {
    testWidgets('Renders source mode options, default 10 count, and placement selector', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AddTracksToQueueSheet(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Add Tracks to Queue'), findsOneWidget);
      expect(find.text('Random'), findsOneWidget);
      expect(find.text('Mood & Vibe'), findsOneWidget);
      expect(find.text('Similar'), findsOneWidget);
      expect(find.text('Favorites'), findsOneWidget);
      expect(find.text('Append to End'), findsOneWidget);
      expect(find.text('Play Next'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      expect(find.textContaining('ADD 10 TRACKS TO END'), findsOneWidget);
    });
  });

  group('StudioDspBentoCapsule 3-Stage Signal Chain Widget Tests', () {
    testWidgets('Renders 3-stage signal chain (AutoEQ -> DSP Rack -> Hardware DAC)', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: StudioDspBentoCapsule(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('AutoEQ'), findsOneWidget);
      expect(find.textContaining('DSP'), findsOneWidget);
      expect(find.textContaining('DAC Direct'), findsOneWidget);
    });

    testWidgets('Displays active DAC model name when hardware DAC is connected', (tester) async {
      final container = ProviderContainer(
        overrides: [
          dacBridgeControllerProvider.overrideWith(
            (ref) => _FakeDacController(
              DacBridgeState(
                status: DacBridgeStatus.connected,
                device: const DacDevice(
                  id: '/dev/hidraw0',
                  vendorId: 0x3302,
                  productId: 0x20E3,
                  productName: 'Kiwi Ears AD1',
                  chipset: DacChipset.kt0211l,
                ),
              ),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: Center(
                child: StudioDspBentoCapsule(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('DAC • AD1'), findsOneWidget);
    });
  });
}

class _FakeDacController extends StateNotifier<DacBridgeState> implements DacBridgeController {
  _FakeDacController(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
