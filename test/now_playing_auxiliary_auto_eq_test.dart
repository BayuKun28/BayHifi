import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:baydev_hifi/audio_engine/soloud_controller.dart';
import 'package:baydev_hifi/features/dsp_rack/domain/dsp_models.dart';
import 'package:baydev_hifi/features/dsp_rack/presentation/controllers/dsp_rack_controller.dart';
import 'package:baydev_hifi/features/player/domain/playback_state.dart';
import 'package:baydev_hifi/features/player/domain/track.dart';
import 'package:baydev_hifi/features/player/presentation/controllers/player_controller.dart';
import 'package:baydev_hifi/features/player/presentation/now_playing_screen.dart';
import 'package:baydev_hifi/features/pro_q_studio/domain/fr_curve_data.dart';
import 'package:baydev_hifi/features/pro_q_studio/presentation/controllers/eq_controller.dart';
import 'package:baydev_hifi/features/pro_q_studio/presentation/widgets/auto_eq_modal_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testTrack = Track(
    id: 'test_audiophile_track_1',
    title: 'Symphony in D Minor',
    artist: 'Baydev Orchestra',
    album: 'Audiophile Collection Vol 1',
    duration: const Duration(minutes: 5, seconds: 20),
    filePath: '/music/test.flac',
    format: AudioFormat.flac,
    bitDepth: 24,
    sampleRate: 96000,
  );

  group('NowPlayingScreen Auxiliary Bar Unified AutoEQ Tests', () {
    testWidgets('Auxiliary bar renders Pro-Q spectrum audioLines, AutoEQ sparkles, and DSP Rack shortcuts', (tester) async {
      tester.view.physicalSize = const Size(400, 850);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool proQOpened = false;
      bool dspRackOpened = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            playerControllerProvider.overrideWith((ref) {
              final notifier = PlayerController(SoLoudController.instance);
              notifier.state = PlaybackState(
                currentTrack: testTrack,
                status: PlaybackStatus.playing,
                position: const Duration(seconds: 45),
                duration: const Duration(minutes: 5, seconds: 20),
              );
              return notifier;
            }),
          ],
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: Scaffold(
              body: NowPlayingScreen(
                onOpenProQStudio: () => proQOpened = true,
                onOpenDspRack: () => dspRackOpened = true,
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 1. Verify Audio Format Specs tag
      expect(find.text('FLAC'), findsOneWidget);
      expect(find.text('96.0kHz'), findsOneWidget);

      // 2. Verify Pro-Q Studio EQ button uses LucideIcons.audioLines (representing spectrum/audio curves)
      final proQButton = find.byIcon(LucideIcons.audioLines);
      expect(proQButton, findsOneWidget);

      // Tap Pro-Q Studio button and verify callback
      await tester.tap(proQButton);
      await tester.pump();
      expect(proQOpened, isTrue);

      // 3. Verify Unified AutoEQ button (LucideIcons.sparkles)
      final autoEqButton = find.byWidgetPredicate(
        (w) => w is Icon && w.icon == LucideIcons.sparkles,
      );
      expect(autoEqButton, findsOneWidget);

      // 4. Verify Mastering DSP Rack shortcut button (LucideIcons.slidersHorizontal)
      final dspRackButton = find.byIcon(LucideIcons.slidersHorizontal);
      expect(dspRackButton, findsOneWidget);

      // Tap DSP Rack button and verify callback
      await tester.tap(dspRackButton);
      await tester.pump();
      expect(dspRackOpened, isTrue);

      // 5. Verify separate Driver (headphones) and Target (target) icons are NOT in auxiliary bar
      expect(find.byIcon(LucideIcons.headphones), findsNothing);
      expect(find.byIcon(LucideIcons.target), findsNothing);

      // 6. Verify Tooltip message starts with AutoEQ
      final autoEqTooltipFinder = find.byWidgetPredicate(
        (w) => w is Tooltip && (w.message?.startsWith('AutoEQ') ?? false),
      );
      expect(autoEqTooltipFinder, findsOneWidget);

      // 7. Tap AutoEQ button and verify AutoEqModalDialog is displayed
      await tester.tap(autoEqButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AutoEqModalDialog), findsOneWidget);
      expect(find.text('AUTO EQ STUDIO & TARGET MATCHING'), findsOneWidget);
    });

    testWidgets('Auxiliary bar displays active driver & target name in tooltip when selected', (tester) async {
      tester.view.physicalSize = const Size(400, 850);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const dummyDriver = FrCurveData(
        name: 'Sennheiser HD600',
        frequencies: [20.0, 1000.0, 20000.0],
        splDb: [0.0, 0.0, 0.0],
      );

      const dummyTarget = FrCurveData(
        name: 'Harman In-Ear 2019',
        frequencies: [20.0, 1000.0, 20000.0],
        splDb: [5.0, 0.0, -2.0],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            playerControllerProvider.overrideWith((ref) {
              final notifier = PlayerController(SoLoudController.instance);
              notifier.state = PlaybackState(
                currentTrack: testTrack,
                status: PlaybackStatus.playing,
                position: const Duration(seconds: 45),
                duration: const Duration(minutes: 5, seconds: 20),
              );
              return notifier;
            }),
            eqControllerProvider.overrideWith((ref) {
              final notifier = EqController();
              notifier.selectDriver(dummyDriver);
              notifier.selectTarget(dummyTarget);
              return notifier;
            }),
          ],
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: Scaffold(
              body: NowPlayingScreen(
                onOpenProQStudio: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify dynamic tooltip with Driver and Target names
      expect(find.byTooltip('AutoEQ: Sennheiser HD600 → Harman In-Ear 2019'), findsOneWidget);
    });

    testWidgets('DSP Rack button displays active module count in tooltip when modules enabled', (tester) async {
      tester.view.physicalSize = const Size(400, 850);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            playerControllerProvider.overrideWith((ref) {
              final notifier = PlayerController(SoLoudController.instance);
              notifier.state = PlaybackState(
                currentTrack: testTrack,
                status: PlaybackStatus.playing,
              );
              return notifier;
            }),
            dspRackControllerProvider.overrideWith((ref) {
              final controller = DspRackController();
              controller.state = const DspRackState(
                isBypassed: false,
                tubeExciterEnabled: true,
                bassBoostEnabled: true,
                compressorEnabled: true,
                stereoWidthEnabled: false,
                limiterEnabled: false,
              );
              return controller;
            }),
          ],
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: Scaffold(
              body: NowPlayingScreen(
                onOpenProQStudio: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify tooltip shows 'Mastering DSP Rack (3 Active)'
      expect(find.byTooltip('Mastering DSP Rack (3 Active)'), findsOneWidget);
    });
  });
}

