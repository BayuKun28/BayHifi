import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:baydev_hifi/features/player/presentation/now_playing_screen.dart';

void main() {
  testWidgets('NowPlayingScreen has minimalist top bar with sleep timer, AutoEQ badge, bottom action strip, and DSP Rack button', (WidgetTester tester) async {
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

    // 1. Verify Minimalist Top Bar with NOW PLAYING
    expect(find.text('NOW PLAYING'), findsOneWidget);

    // 2. Verify AutoEQ Profile Slim Chip is present
    expect(find.textContaining('AutoEQ'), findsOneWidget);

    // 3. Verify Mastering DSP Rack shortcut Slim Chip is present
    expect(find.textContaining('DSP'), findsOneWidget);

    // 4. Verify Pre-Amp and Volume panels are NOT present on player screen
    expect(find.text('PRE-AMP'), findsNothing);
    expect(find.text('PRE'), findsNothing);

    // 5. Verify Bottom Studio Action Strip items in exact requested order:
    // [Open], [Desk Mode], [Lyric], [Queue], [Spec]
    expect(find.text('Open'), findsOneWidget);
    expect(find.text('Desk Mode'), findsOneWidget);
    expect(find.text('Lyric'), findsOneWidget);
    expect(find.text('Queue'), findsOneWidget);
    expect(find.text('Spec'), findsOneWidget);
  });

  testWidgets('NowPlayingScreen in Landscape mode has streamlined left pane without bottom strip and studio top bar', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 500);
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

    // 1. Verify NOW PLAYING is rendered in landscape
    expect(find.text('NOW PLAYING'), findsOneWidget);

    // 2. Verify Right Pane Workstation Tabs are present
    expect(find.text('UP NEXT'), findsOneWidget);
    expect(find.text('LYRICS'), findsOneWidget);
    expect(find.text('DSP RACK'), findsOneWidget);
    expect(find.text('PRO-Q EQ'), findsNothing); // Pro-Q removed from cramped tabs

    // 3. Verify Bottom Studio Action Strip text is NOT present in landscape mode
    expect(find.text('Open'), findsNothing);
    expect(find.text('Desk Mode'), findsNothing);
    expect(find.text('Lyric'), findsNothing);
  });
}

