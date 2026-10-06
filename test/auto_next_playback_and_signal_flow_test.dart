import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baydev_hifi/features/hardware_dac/domain/models/dac_device.dart';
import 'package:baydev_hifi/features/hardware_dac/presentation/controllers/dac_bridge_controller.dart';
import 'package:baydev_hifi/features/hardware_dac/presentation/controllers/dac_bridge_state.dart';
import 'package:baydev_hifi/features/player/domain/playback_state.dart';
import 'package:baydev_hifi/features/player/domain/track.dart';
import 'package:baydev_hifi/features/player/presentation/controllers/player_controller.dart';
import 'package:baydev_hifi/features/player/presentation/widgets/studio_dsp_bento_capsule.dart';
import 'package:baydev_hifi/features/pro_q_studio/domain/fr_curve_data.dart';
import 'package:baydev_hifi/features/pro_q_studio/presentation/controllers/eq_controller.dart';
import 'package:baydev_hifi/features/pro_q_studio/presentation/controllers/eq_state.dart';

class _FakeDacController extends StateNotifier<DacBridgeState>
    implements DacBridgeController {
  _FakeDacController(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeEqController extends StateNotifier<EqState> implements EqController {
  _FakeEqController(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

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

  group('StudioDspBentoCapsule String Formatters Unit Tests', () {
    test('formatAutoEqLabel formats multi-word driver name with ellipsis', () {
      expect(
        StudioDspBentoCapsule.formatAutoEqLabel('KZ Castor Bass Black Dudu R'),
        equals('KZ CASTOR...'),
      );
      expect(
        StudioDspBentoCapsule.formatAutoEqLabel('Moondrop Chu II DSP'),
        equals('MOONDROP CHU...'),
      );
      expect(
        StudioDspBentoCapsule.formatAutoEqLabel('Sennheiser HD600'),
        equals('SENNHEISER...'),
      );
      expect(
        StudioDspBentoCapsule.formatAutoEqLabel('Aria'),
        equals('ARIA'),
      );
      expect(
        StudioDspBentoCapsule.formatAutoEqLabel(null),
        equals('AutoEQ'),
      );
    });

    test('formatDacLabel outputs brand and model cleanly', () {
      const device = DacDevice(
        id: '/dev/hidraw0',
        vendorId: 0x3302,
        productId: 0x20E3,
        productName: 'Kiwi Ears AD1',
        chipset: DacChipset.kt0211l,
      );

      expect(
        StudioDspBentoCapsule.formatDacLabel(device),
        equals('DAC • KIWI AD1'),
      );
      expect(
        StudioDspBentoCapsule.formatDacLabel(null),
        equals('DAC Direct'),
      );
    });
  });

  group('StudioDspBentoCapsule Widget & Animation Tests', () {
    testWidgets('Renders 1-row compact capsule and animated signal connectors', (tester) async {
      final container = ProviderContainer(
        overrides: [
          eqControllerProvider.overrideWith(
            (ref) => _FakeEqController(
              const EqState(
                bands: [],
                isAutoEqActive: true,
                driverFr: FrCurveData(
                  name: 'KZ Castor Bass Black Dudu R',
                  frequencies: [],
                  splDb: [],
                ),
              ),
            ),
          ),
          dacBridgeControllerProvider.overrideWith(
            (ref) => _FakeDacController(
              const DacBridgeState(
                status: DacBridgeStatus.connected,
                device: DacDevice(
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
      addTearDown(container.dispose);

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

      await tester.pump();

      // Check truncated AutoEQ label
      expect(find.text('KZ CASTOR...'), findsOneWidget);

      // Check DSP label
      expect(find.textContaining('DSP'), findsOneWidget);

      // Check DAC label with brand & model
      expect(find.text('DAC • KIWI AD1'), findsOneWidget);

      // Verify animated pulse frames advance without errors
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
    });
  });

  group('PlayerController Auto-Next Lifecycle & Queue Advance Tests', () {
    test('skipNext advances to next track in queue deterministically', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(playerControllerProvider.notifier);
      await controller.setQueue([testTrack1, testTrack2, testTrack3], initialIndex: 0, autoPlay: false);

      expect(container.read(playerControllerProvider).queueIndex, equals(0));
      expect(container.read(playerControllerProvider).currentTrack?.id, equals(testTrack1.id));

      await controller.skipNext(autoPlay: false);
      expect(container.read(playerControllerProvider).queueIndex, equals(1));
      expect(container.read(playerControllerProvider).currentTrack?.id, equals(testTrack2.id));

      await controller.skipNext(autoPlay: false);
      expect(container.read(playerControllerProvider).queueIndex, equals(2));
      expect(container.read(playerControllerProvider).currentTrack?.id, equals(testTrack3.id));
    });

    test('skipNext stops at end of queue when repeat is off', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(playerControllerProvider.notifier);
      await controller.setQueue([testTrack1, testTrack2], initialIndex: 1, autoPlay: false);
      container.read(playerControllerProvider.notifier).setRepeatMode(PlaybackRepeatMode.off);

      await controller.skipNext(autoPlay: false);
      expect(container.read(playerControllerProvider).status, equals(PlaybackStatus.stopped));
    });

    test('skipNext loops to index 0 when repeatMode is all', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(playerControllerProvider.notifier);
      await controller.setQueue([testTrack1, testTrack2], initialIndex: 1, autoPlay: false);
      container.read(playerControllerProvider.notifier).setRepeatMode(PlaybackRepeatMode.all);

      await controller.skipNext(autoPlay: false);
      expect(container.read(playerControllerProvider).queueIndex, equals(0));
      expect(container.read(playerControllerProvider).currentTrack?.id, equals(testTrack1.id));
    });
  });
}
