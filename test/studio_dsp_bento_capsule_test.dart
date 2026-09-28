import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:baydev_hifi/features/dsp_rack/presentation/dsp_rack_screen.dart';
import 'package:baydev_hifi/features/player/presentation/now_playing_screen.dart';
import 'package:baydev_hifi/features/player/presentation/widgets/studio_dsp_bento_capsule.dart';
import 'package:baydev_hifi/features/pro_q_studio/presentation/widgets/auto_eq_modal_dialog.dart';

void main() {
  group('StudioDspBentoCapsule Option 2 Ultra-Compact Slim Chips Tests', () {
    testWidgets('StudioDspBentoCapsule renders dual slim chips with icons and micro labels',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: EdgeInsets.all(16),
                child: StudioDspBentoCapsule(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify Left Slim Chip (AutoEQ Profile)
      expect(find.textContaining('AutoEQ'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
            (w) => w is HugeIcon && w.icon == HugeIcons.strokeRoundedHeadphones),
        findsOneWidget,
      );

      // 2. Verify Right Slim Chip (Mastering DSP Rack)
      expect(find.textContaining('DSP'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
            (w) => w is HugeIcon && w.icon == HugeIcons.strokeRoundedSlidersVertical),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
            (w) => w is HugeIcon && w.icon == HugeIcons.strokeRoundedArrowRight01),
        findsOneWidget,
      );
    });

    testWidgets('Tapping AutoEQ slim chip opens AutoEQ modal dialog', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

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

      // Tap the AutoEQ chip
      await tester.tap(find.textContaining('AutoEQ'));
      await tester.pumpAndSettle();

      // Verify AutoEQ modal dialog is shown
      expect(find.byType(AutoEqModalDialog), findsOneWidget);
    });

    testWidgets('Tapping DSP slim chip navigates to DspRackScreen', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

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

      // Tap the DSP chip
      await tester.tap(find.textContaining('DSP'));
      await tester.pumpAndSettle();

      // Verify DspRackScreen is pushed
      expect(find.byType(DspRackScreen), findsOneWidget);
    });

    testWidgets('NowPlayingScreen displays streamlined StudioDspBentoCapsule slim chips',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 850);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: NowPlayingScreen(
              onOpenProQStudio: () {},
              onCollapse: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify StudioDspBentoCapsule is present inside NowPlayingScreen
      expect(find.byType(StudioDspBentoCapsule), findsOneWidget);
      expect(find.text('NOW PLAYING'), findsOneWidget);
      expect(find.textContaining('AutoEQ'), findsOneWidget);
      expect(find.textContaining('DSP'), findsOneWidget);
    });
  });
}
