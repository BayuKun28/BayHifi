import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:baydev_hifi/core/desktop/studio_desktop_title_bar.dart';
import 'package:baydev_hifi/features/player/domain/playback_state.dart';
import 'package:baydev_hifi/features/player/domain/track.dart';
import 'package:baydev_hifi/features/player/presentation/controllers/player_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final dummyTrack = const Track(
    id: 'track_test_1',
    title: 'Time',
    artist: 'Pink Floyd',
    album: 'The Dark Side of the Moon',
    duration: Duration(minutes: 6, seconds: 53),
    format: AudioFormat.flac,
  );

  testWidgets('StudioDesktopTitleBar renders branding, track metadata, and window control buttons', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final container = ProviderContainer(
      overrides: [
        playerControllerProvider.overrideWith((ref) => FakePlayerController(
          PlaybackState(
            currentTrack: dummyTrack,
            status: PlaybackStatus.playing,
          ),
        )),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            appBar: StudioDesktopTitleBar(),
            body: Center(child: Text('Desktop Stage')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verify Branding & Format Badge
    expect(find.text('BAYDEV HiFi'), findsOneWidget);
    expect(find.text('FLAC'), findsOneWidget);

    // 2. Verify Center Track Title
    expect(find.text('Time — Pink Floyd'), findsOneWidget);

    // 3. Verify Window Control Action Buttons (3 Essential Buttons: Minimize, Maximize, Close)
    expect(find.byWidgetPredicate((w) => w is HugeIcon && w.icon == HugeIcons.strokeRoundedMinusSign), findsOneWidget);
    expect(find.byWidgetPredicate((w) => w is HugeIcon && w.icon == HugeIcons.strokeRoundedSquare), findsOneWidget);
    expect(find.byWidgetPredicate((w) => w is HugeIcon && w.icon == HugeIcons.strokeRoundedCancel01), findsOneWidget);
    expect(find.byWidgetPredicate((w) => w is HugeIcon && w.icon == HugeIcons.strokeRoundedMaximize02), findsNothing);
  });

  testWidgets('StudioDesktopTitleBar renders default workstation title when idle', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final container = ProviderContainer(
      overrides: [
        playerControllerProvider.overrideWith((ref) => FakePlayerController(
          const PlaybackState(
            currentTrack: null,
            status: PlaybackStatus.stopped,
          ),
        )),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            appBar: StudioDesktopTitleBar(),
            body: Center(child: Text('Desktop Stage')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Branding
    expect(find.text('BAYDEV HiFi'), findsOneWidget);
    expect(find.text('Studio Audiophile Workstation'), findsOneWidget);
  });
}

class FakePlayerController extends StateNotifier<PlaybackState> implements PlayerController {
  FakePlayerController(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

