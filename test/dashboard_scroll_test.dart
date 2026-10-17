import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:baydev_hifi/features/dashboard/presentation/dashboard_screen.dart';
import 'package:baydev_hifi/core/widgets/two_tone_header.dart';
import 'package:baydev_hifi/features/player/domain/playback_state.dart';
import 'package:baydev_hifi/features/player/presentation/controllers/player_controller.dart';

class _FakePlayerController extends StateNotifier<PlaybackState> implements PlayerController {
  _FakePlayerController() : super(const PlaybackState());
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('DashboardScreen renders clean high-density cards and scroll physics', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playerControllerProvider.overrideWith((ref) => _FakePlayerController()),
        ],
        child: MaterialApp(
          home: DashboardScreen(
            onNavigateToPlayer: () {},
            onNavigateToLibrary: () {},
            onNavigateToDsp: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify Dashboard renders header and YouTube HiFi launcher
    expect(find.text('WELCOME TO BAYDEV HIFI'), findsOneWidget);
    expect(find.byType(TwoToneHeader), findsWidgets);
    expect(find.textContaining('Explore YouTube Music HiFi'), findsOneWidget);

    // Verify removed redundant cards are not present on Dashboard
    expect(find.text('UNIFIED MUSIC LIBRARY'), findsNothing);
    expect(find.text('STUDIO DESK & CAR DOCKING'), findsNothing);

    // Verify SingleChildScrollView exists and has AlwaysScrollableScrollPhysics
    final scrollFinder = find.byType(SingleChildScrollView).first;
    expect(scrollFinder, findsOneWidget);

    final scrollWidget = tester.widget<SingleChildScrollView>(scrollFinder);
    expect(scrollWidget.physics, isA<AlwaysScrollableScrollPhysics>());

    // Test dragging to scroll down
    await tester.drag(scrollFinder, const Offset(0, -300));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify scroll view persists and handles gesture
    expect(scrollFinder, findsOneWidget);
  });
}
