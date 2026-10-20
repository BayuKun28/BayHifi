import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:baydev_hifi/audio_engine/soloud_controller.dart';
import 'package:baydev_hifi/features/player/domain/playback_state.dart';
import 'package:baydev_hifi/features/player/domain/track.dart';
import 'package:baydev_hifi/features/player/presentation/controllers/player_controller.dart';
import 'package:baydev_hifi/features/player/presentation/now_playing_screen.dart';
import 'package:baydev_hifi/features/player/presentation/widgets/dual_pane_workstation_pane.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testTrack1 = Track(
    id: 'test_track_1',
    title: 'Comfortably Numb',
    artist: 'Pink Floyd',
    album: 'The Wall',
    duration: const Duration(minutes: 6, seconds: 22),
    filePath: '/music/the_wall.flac',
    format: AudioFormat.flac,
    bitDepth: 24,
    sampleRate: 96000,
  );

  final testTrack2 = Track(
    id: 'test_track_2',
    title: 'Time',
    artist: 'Pink Floyd',
    album: 'The Dark Side of the Moon',
    duration: const Duration(minutes: 6, seconds: 53),
    filePath: '/music/time.flac',
    format: AudioFormat.flac,
    bitDepth: 24,
    sampleRate: 96000,
  );

  testWidgets('NowPlayingScreen tablet dual-pane layout renders uncluttered Minimalist deck and synchronizes workstation tabs', (tester) async {
    // Set tablet landscape screen dimensions
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    bool proQOpened = false;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playerControllerProvider.overrideWith((ref) {
            final notifier = PlayerController(SoLoudController.instance);
            notifier.state = PlaybackState(
              currentTrack: testTrack1,
              queue: [testTrack1, testTrack2],
              queueIndex: 0,
              status: PlaybackStatus.playing,
              position: const Duration(minutes: 1, seconds: 30),
              duration: const Duration(minutes: 6, seconds: 22),
            );
            return notifier;
          }),
        ],
        child: MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: NowPlayingScreen(
              onCollapse: () {},
              onOpenProQStudio: () => proQOpened = true,
              onOpenDspRack: () {},
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // 1. Verify Top Bar in Tablet Landscape Mode
    // Top bar has clean minimalist layout: Collapse, Album + SOLOUD, Sleep timer, Heart, More
    expect(find.byIcon(LucideIcons.chevronDown), findsOneWidget);
    expect(find.text('THE WALL'), findsOneWidget);
    expect(find.text('• SOLOUD'), findsOneWidget);
    expect(find.byIcon(LucideIcons.heart), findsOneWidget);
    expect(find.byIcon(LucideIcons.moreVertical), findsOneWidget);

    // Verify removed redundant icons are NOT present in the top bar
    expect(find.byIcon(LucideIcons.folderOpen), findsNothing);
    expect(find.byIcon(LucideIcons.gauge), findsNothing);
    expect(find.byIcon(LucideIcons.car), findsNothing);
    expect(find.byIcon(LucideIcons.info), findsNothing);

    // 2. Verify Left Hero Pane elements (also queued in right workstation pane)
    expect(find.text('Comfortably Numb'), findsNWidgets(2));
    expect(find.textContaining('Pink Floyd'), findsWidgets);

    // 3. Verify Tablet Studio Auxiliary Bar elements (Overhauled for maximum visual clarity & zero redundancy)
    expect(find.text('FLAC'), findsOneWidget);
    expect(find.textContaining('96.0kHz'), findsOneWidget);
    expect(find.text('PRO-Q'), findsOneWidget);
    expect(find.text('AUTO-EQ'), findsOneWidget);
    expect(find.text('POWERED BY SOLOUD ENGINE'), findsOneWidget);

    // 4. Verify DualPaneWorkstationPane is present on the right pane
    expect(find.byType(DualPaneWorkstationPane), findsOneWidget);
    // Initially on UP NEXT queue tab
    expect(find.text('UP NEXT'), findsOneWidget);
    expect(find.text('2 Tracks'), findsOneWidget);
    expect(find.text('DSP RACK'), findsOneWidget);

    // 5. Test Workstation Tab Switching via DSP RACK Tab in Workstation Pane
    final dspRackTab = find.text('DSP RACK');
    await tester.tap(dspRackTab);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify right pane has switched to DSP RACK
    expect(find.byKey(const ValueKey('tab_dsprack')), findsOneWidget);

    // Tap Lyrics tab in the right workstation pane header (LucideIcons.type / LYRICS)
    final lyricsTab = find.text('LYRICS');
    expect(lyricsTab, findsOneWidget);
    await tester.tap(lyricsTab);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify right pane has switched to LYRICS tab
    expect(find.byKey(const ValueKey('tab_lyrics')), findsOneWidget);

    // Tap Up Next Queue tab in the right workstation pane header
    final queueTab = find.text('UP NEXT');
    expect(queueTab, findsOneWidget);
    await tester.tap(queueTab);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify returned to UP NEXT tab
    expect(find.byKey(const ValueKey('tab_queue_list')), findsOneWidget);
    expect(find.text('2 Tracks'), findsOneWidget);

    // 6. Test Pro-Q button (LucideIcons.audioLines) triggers onOpenProQStudio
    final proQAuxBtn = find.byIcon(LucideIcons.audioLines);
    expect(proQAuxBtn, findsOneWidget);
    await tester.tap(proQAuxBtn);
    await tester.pump();
    expect(proQOpened, isTrue);
  });
}
