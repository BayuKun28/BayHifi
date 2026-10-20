import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baydev_hifi/features/dsp_rack/presentation/dsp_rack_screen.dart';
import 'package:baydev_hifi/features/dsp_rack/presentation/controllers/dsp_rack_controller.dart';
import 'package:baydev_hifi/features/dsp_rack/domain/dsp_models.dart';
import 'package:baydev_hifi/features/dsp_rack/presentation/widgets/vu_level_meter.dart';
import 'package:baydev_hifi/features/dsp_rack/presentation/widgets/tube_glow_indicator.dart';
import 'package:baydev_hifi/features/dsp_rack/presentation/widgets/gain_reduction_meter.dart';
import 'package:baydev_hifi/features/dsp_rack/presentation/widgets/soundstage_width_visualizer.dart';
import 'package:baydev_hifi/features/player/presentation/controllers/player_controller.dart';
import 'package:baydev_hifi/features/player/domain/playback_state.dart';

class _FakePlayerController extends StateNotifier<PlaybackState> implements PlayerController {
  _FakePlayerController() : super(const PlaybackState(status: PlaybackStatus.playing));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('DspRackScreen isolates high-frequency visualizers with RepaintBoundary', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playerControllerProvider.overrideWith((ref) => _FakePlayerController()),
          dspRackControllerProvider.overrideWith((ref) {
            final controller = DspRackController();
            controller.state = const DspRackState(
              isBypassed: false,
              preampDb: 2.0,
              tubeExciterEnabled: true,
              tubeDrive: 1.5,
              tubeWarmth: 0.6,
              compressorEnabled: true,
              compRatio: 4.0,
              compThreshold: -10.0,
              stereoWidthEnabled: true,
              stereoWidth: 1.4,
            );
            return controller;
          }),
        ],
        child: MaterialApp(
          theme: ThemeData.dark(),
          home: const DspRackScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify VuLevelMeter is rendered and wrapped in RepaintBoundary
    final vuMeterFinder = find.byType(VuLevelMeter);
    expect(vuMeterFinder, findsOneWidget);
    final vuParent = find.ancestor(
      of: vuMeterFinder,
      matching: find.byType(RepaintBoundary),
    );
    expect(vuParent, findsWidgets);

    // Verify TubeGlowIndicator is rendered and wrapped in RepaintBoundary
    final tubeFinder = find.byType(TubeGlowIndicator);
    expect(tubeFinder, findsOneWidget);
    final tubeParent = find.ancestor(
      of: tubeFinder,
      matching: find.byType(RepaintBoundary),
    );
    expect(tubeParent, findsWidgets);

    // Verify GainReductionMeter is rendered and wrapped in RepaintBoundary
    final grMeterFinder = find.byType(GainReductionMeter);
    expect(grMeterFinder, findsOneWidget);
    final grParent = find.ancestor(
      of: grMeterFinder,
      matching: find.byType(RepaintBoundary),
    );
    expect(grParent, findsWidgets);

    // Verify SoundstageWidthVisualizer is rendered and wrapped in RepaintBoundary
    final soundstageFinder = find.byType(SoundstageWidthVisualizer);
    expect(soundstageFinder, findsOneWidget);
    final soundstageParent = find.ancestor(
      of: soundstageFinder,
      matching: find.byType(RepaintBoundary),
    );
    expect(soundstageParent, findsWidgets);
  });
}
