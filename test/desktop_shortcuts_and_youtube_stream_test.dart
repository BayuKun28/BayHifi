import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:baydev_hifi/app/theme/theme_mode_controller.dart';
import 'package:baydev_hifi/audio_engine/soloud_controller.dart';
import 'package:baydev_hifi/core/desktop/desktop_shortcuts_dispatcher.dart';
import 'package:baydev_hifi/core/widgets/studio_artwork_widget.dart';
import 'package:baydev_hifi/features/player/domain/playback_state.dart';
import 'package:baydev_hifi/features/player/domain/track.dart';
import 'package:baydev_hifi/features/player/presentation/controllers/player_controller.dart';
import 'package:baydev_hifi/features/youtube_music/data/youtube_music_service.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class _MockPlayerController extends PlayerController {
  _MockPlayerController(super.engine, [PlaybackState? initial]) {
    if (initial != null) state = initial;
  }

  bool playPauseToggled = false;
  bool skipNextCalled = false;
  bool skipPreviousCalled = false;
  bool seekCalled = false;
  double lastSetVolume = -1;

  @override
  Future<void> togglePlayPause() async {
    playPauseToggled = true;
    if (state.status == PlaybackStatus.playing) {
      state = state.copyWith(status: PlaybackStatus.paused);
    } else {
      state = state.copyWith(status: PlaybackStatus.playing);
    }
  }

  @override
  Future<void> skipNext({bool autoPlay = true}) async {
    skipNextCalled = true;
  }

  @override
  Future<void> skipPrevious({bool autoPlay = true}) async {
    skipPreviousCalled = true;
  }

  @override
  Future<void> seek(Duration position) async {
    seekCalled = true;
    state = state.copyWith(position: position);
  }

  @override
  Future<void> setVolume(double volume) async {
    lastSetVolume = volume;
    state = state.copyWith(volume: volume);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final dummyTrack = Track(
    id: 'yt_abc123',
    title: 'Test Song',
    artist: 'Test Artist',
    album: 'YouTube Music',
    duration: const Duration(minutes: 3, seconds: 30),
    format: AudioFormat.opus,
  );

  group('Phase 50.1: Desktop Keyboard Shortcuts Focus Protection Tests', () {
    testWidgets('When TextField is focused, keystrokes (Space, L, Q, E, M, Arrows) are NOT intercepted as shortcuts', (tester) async {
      final mockPlayer = _MockPlayerController(
        SoLoudController.instance,
        PlaybackState(
          currentTrack: dummyTrack,
          status: PlaybackStatus.playing,
          duration: const Duration(minutes: 3, seconds: 30),
          position: const Duration(seconds: 45),
          volume: 0.8,
        ),
      );

      final textController = TextEditingController();
      final textFocusNode = FocusNode();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            playerControllerProvider.overrideWith((ref) => mockPlayer),
          ],
          child: MaterialApp(
            theme: AppThemeBuilder.buildTheme(AppPalette.namidaCyan, isDark: true),
            home: Scaffold(
              body: DesktopShortcutsDispatcher(
                child: Column(
                  children: [
                    TextField(
                      controller: textController,
                      focusNode: textFocusNode,
                    ),
                    const Text('Body Content'),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Focus the TextField
      textFocusNode.requestFocus();
      await tester.pumpAndSettle();
      expect(textFocusNode.hasFocus, isTrue);

      // 1. Send Space key -> should type into TextField, NOT toggle play/pause
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(mockPlayer.playPauseToggled, isFalse, reason: 'Space must not trigger play/pause while typing in TextField');

      // 2. Send Key L -> should not open lyrics modal or trigger action
      await tester.sendKeyEvent(LogicalKeyboardKey.keyL);
      await tester.pump();

      // 3. Send Key M -> should not mute player
      await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
      await tester.pump();
      expect(mockPlayer.lastSetVolume, equals(-1), reason: 'M key must not mute player while typing in TextField');

      // 4. Send Key Q & E -> should not navigate or open sheets
      await tester.sendKeyEvent(LogicalKeyboardKey.keyQ);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyE);
      await tester.pump();

      // 5. Send Arrow keys -> should not seek or change volume
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(mockPlayer.seekCalled, isFalse, reason: 'Arrow keys must not seek while typing in TextField');
      expect(mockPlayer.lastSetVolume, equals(-1), reason: 'Arrow keys must not change volume while typing in TextField');
    });

    testWidgets('When TextField is NOT focused, shortcuts trigger studio player actions', (tester) async {
      final mockPlayer = _MockPlayerController(
        SoLoudController.instance,
        PlaybackState(
          currentTrack: dummyTrack,
          status: PlaybackStatus.playing,
          duration: const Duration(minutes: 3, seconds: 30),
          position: const Duration(seconds: 45),
          volume: 0.8,
        ),
      );

      bool searchRequested = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            playerControllerProvider.overrideWith((ref) => mockPlayer),
          ],
          child: MaterialApp(
            theme: AppThemeBuilder.buildTheme(AppPalette.namidaCyan, isDark: true),
            home: Scaffold(
              body: DesktopShortcutsDispatcher(
                onSearchRequested: () {
                  searchRequested = true;
                },
                child: const Center(
                  child: Text('Desktop Studio Canvas'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Press Space -> Toggles play/pause
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(mockPlayer.playPauseToggled, isTrue);

      // 2. Press M -> Toggles mute
      await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
      await tester.pump();
      expect(mockPlayer.lastSetVolume, equals(0.0));

      // 3. Press Arrow Right -> Seeks forward
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(mockPlayer.seekCalled, isTrue);

      // 4. Press Slash -> Requests search focus
      await tester.sendKeyEvent(LogicalKeyboardKey.slash);
      await tester.pump();
      expect(searchRequested, isTrue);
    });

    testWidgets('DesktopShortcutsDispatcher cheatsheet dialog displays all studio shortcuts', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppThemeBuilder.buildTheme(AppPalette.namidaCyan, isDark: true),
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => showDesktopShortcutsCheatsheet(context),
                child: const Text('Open Cheatsheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Cheatsheet'));
      await tester.pumpAndSettle();

      expect(find.text('Studio Keyboard Shortcuts'), findsOneWidget);
      expect(find.text('Toggle Play / Pause'), findsOneWidget);
      expect(find.text('Space'), findsOneWidget);
      expect(find.byType(M3EButton), findsOneWidget);

      await tester.tap(find.byType(M3EButton));
      await tester.pumpAndSettle();
      expect(find.text('Studio Keyboard Shortcuts'), findsNothing);
    });
  });

  group('Phase 50.2: YouTube Engine & Metadata Cleaning Tests', () {
    test('YouTubeMusicService cleanMetadata handles various artist/title formats and noise', () {
      final res1 = YouTubeMusicService.cleanMetadata(
        'Queen - Bohemian Rhapsody (Official Video Remastered)',
        'Queen Official',
      );
      expect(res1.artist, equals('Queen'));
      expect(res1.title, equals('Bohemian Rhapsody'));

      final res2 = YouTubeMusicService.cleanMetadata(
        'YOASOBI「Idol」Official Music Video',
        'Ayase / YOASOBI',
      );
      expect(res2.artist, equals('Ayase / YOASOBI'));
      expect(res2.title, contains('Idol'));

      final res3 = YouTubeMusicService.cleanMetadata(
        '01. Cyberpunk 2077 - I Really Want to Stay at Your House',
        'Rosa Walton - Topic',
      );
      expect(res3.artist, equals('Cyberpunk 2077'));
      expect(res3.title, contains('I Really Want to Stay at Your House'));

      final res4 = YouTubeMusicService.cleanMetadata(
        'Waiting For The End (Official Music Video) [4K Upgrade] - Linkin Park',
        'Linkin Park',
      );
      expect(res4.artist, equals('Linkin Park'));
      expect(res4.title, equals('Waiting For The End'));

      final res5 = YouTubeMusicService.cleanMetadata(
        "Vietsub | Where'd You Go - Fort Minor (feat. Holly Brook & Jonah Matranga) | Lyrics Video",
        "Vietsub Music Channel",
      );
      expect(res5.artist, contains('Fort Minor'));
      expect(res5.title, equals("Where'd You Go"));
    });

    test('StudioArtworkWidget normalizeArtworkUrl converts YouTube AVIF URLs to clean JPEG', () {
      const avifUrl = 'https://i.ytimg.com/vi/5qF_qbaWt3Q/hq720.jpg?sqp=-oaymwEnCNAFEJQDSFryq4qpAxkIARUAAIhCGAHYAQHiAQoIGBACGAY4AUAB&rs=AOn4CLCzZ1oLU2m49b_DhBOTFsNJ3GQvkw';
      final clean = StudioArtworkWidget.normalizeArtworkUrl(avifUrl);
      expect(clean, equals('https://i.ytimg.com/vi/5qF_qbaWt3Q/hqdefault.jpg'));
    });

    test('In-Tree YoutubeApiClient contains required streaming clients', () {
      expect(YoutubeApiClient.androidSdkless, isNotNull);
      expect(YoutubeApiClient.ios, isNotNull);
      expect(YoutubeApiClient.androidMusic, isNotNull);
      expect(YoutubeApiClient.tv, isNotNull);
      expect(YoutubeApiClient.safari, isNotNull);

      expect(YoutubeApiClient.androidSdkless.payload['context']['client']['clientName'], equals('ANDROID'));
      expect(YoutubeApiClient.ios.payload['context']['client']['clientName'], equals('IOS'));
      expect(YoutubeApiClient.androidMusic.payload['context']['client']['clientName'], equals('ANDROID_MUSIC'));
    });
  });
}
