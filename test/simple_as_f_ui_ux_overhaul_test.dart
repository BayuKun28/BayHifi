import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:baydev_hifi/app/theme/simple_as_f_theme.dart';
import 'package:baydev_hifi/app/theme/theme_mode_controller.dart';
import 'package:baydev_hifi/core/widgets/meta_tracking_label.dart';
import 'package:baydev_hifi/core/widgets/two_tone_header.dart';
import 'package:baydev_hifi/features/library/presentation/widgets/download_toggle_row.dart';
import 'package:baydev_hifi/features/library/presentation/widgets/track_tile.dart';
import 'package:baydev_hifi/features/player/domain/track.dart';
import 'package:baydev_hifi/features/player/presentation/widgets/custom_time_bar.dart';
import 'package:baydev_hifi/features/player/presentation/widgets/now_playing_options_sheet.dart';
import 'package:baydev_hifi/features/settings/domain/player_customization_settings.dart';
import 'package:baydev_hifi/features/settings/domain/player_playback_settings.dart';

void main() {
  group('Simple-As-F UI/UX Overhaul Unit & Widget Tests', () {
    test('1. SimpleAsFTheme tokens match Dribbble 27089924 design reference', () {
      expect(SimpleAsFTheme.forestCanvas, const Color(0xFF0D0E12));
      expect(SimpleAsFTheme.forestGlow, const Color(0xFF12141A));
      expect(SimpleAsFTheme.emeraldMint, const Color(0xFF10B981));
      expect(SimpleAsFTheme.sageSlate, const Color(0xFF94A3B8));
      expect(SimpleAsFTheme.surfaceActiveCapsule, const Color(0xFF1E212B));
      expect(SimpleAsFTheme.textWhite, const Color(0xFFFFFFFF));
    });

    test('2. Default AppPalette is simpleAsF and default accent is emerald mint', () {
      expect(AppPalette.simpleAsF.primary, const Color(0xFF10B981));
      expect(AppPalette.simpleAsF.name, 'Simple as F*** (Matte Obsidian)');
      expect(AppPalette.allPresets.first.name, 'Simple as F*** (Matte Obsidian)');
    });

    test('3. PlayerCustomizationSettings default to squircle and waveform', () {
      const settings = PlayerCustomizationSettings();
      expect(settings.albumArtStyle, AlbumArtStyle.squircle);
      expect(settings.timeBarStyle, TimeBarStyle.waveform);
    });

    testWidgets('4. TwoToneHeader renders white keyword and accent keyword dynamically from Theme',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: const ColorScheme.dark(
              primary: SimpleAsFTheme.emeraldMint,
            ),
          ),
          home: const Scaffold(
            body: TwoToneHeader(
              primaryText: 'RECENTLY',
              accentText: 'PLAYED',
              fontSize: 22,
            ),
          ),
        ),
      );

      final textFinder = find.byType(Text);
      expect(textFinder, findsOneWidget);

      final textWidget = tester.widget<Text>(textFinder);
      final textSpan = textWidget.textSpan! as TextSpan;

      expect(textSpan.children, isNotNull);
      expect(textSpan.children!.length, 2);

      final span1 = textSpan.children![0] as TextSpan;
      final span2 = textSpan.children![1] as TextSpan;

      expect(span1.text, 'RECENTLY ');
      expect(span1.style?.color, const Color(0xFFFFFFFF));

      expect(span2.text, 'PLAYED');
      expect(span2.style?.color, SimpleAsFTheme.emeraldMint);
    });

    testWidgets('5. MetaTrackingLabel renders uppercase spaced text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: MetaTrackingLabel(
              'welcome, matt',
              fontSize: 12,
              letterSpacing: 2.0,
            ),
          ),
        ),
      );

      expect(find.text('WELCOME, MATT'), findsOneWidget);
      final textWidget = tester.widget<Text>(find.text('WELCOME, MATT'));
      expect(textWidget.style?.letterSpacing, 2.0);
      expect(textWidget.style?.color, SimpleAsFTheme.sageSlate);
    });

    testWidgets('6. DownloadToggleRow renders label and handles switch toggle',
        (tester) async {
      bool isDownloaded = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return DownloadToggleRow(
                  isDownloaded: isDownloaded,
                  onToggle: (val) => setState(() => isDownloaded = val),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('DOWNLOAD'), findsOneWidget);
      expect(find.byType(DownloadToggleRow), findsOneWidget);

      // Tap toggle
      await tester.tap(find.byType(GestureDetector));
      await tester.pumpAndSettle();

      expect(isDownloaded, isTrue);
    });

    testWidgets('7. TrackTile renders active capsule when playing and uncarded when inactive',
        (tester) async {
      final testTrack = Track(
        id: 'track_test_1',
        title: 'Lost in Space',
        artist: 'Polo G',
        album: 'Hall of Fame',
        duration: const Duration(minutes: 3, seconds: 45),
        filePath: '/storage/emulated/0/Music/lost_in_space.flac',
        format: AudioFormat.flac,
      );

      final waveformFinder = find.byWidgetPredicate(
        (w) => w is Icon && w.icon == LucideIcons.audioLines,
      );

      // Test active playing tile
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TrackTile(
                track: testTrack,
                isPlaying: true,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Lost in Space'), findsOneWidget);
      expect(waveformFinder, findsOneWidget);

      // Test inactive tile
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TrackTile(
                track: testTrack,
                isPlaying: false,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Lost in Space'), findsOneWidget);
      expect(waveformFinder, findsNothing);
    });

    testWidgets('8. NowPlayingOptionsSheet renders all studio options cleanly',
        (tester) async {
      final testTrack = Track(
        id: 'opt_track',
        title: 'Nevermind',
        artist: 'Nirvana',
        album: 'Nevermind',
        duration: const Duration(minutes: 4, seconds: 12),
        filePath: '/music/nevermind.flac',
        format: AudioFormat.flac,
      );

      bool proQOpened = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NowPlayingOptionsSheet(
              track: testTrack,
              onOpenProQStudio: () => proQOpened = true,
              onOpenSpeedPitch: () {},
              onOpenDeskMode: () {},
              onOpenSleepTimer: () {},
              onOpenInspector: () {},
              onToggleLyrics: () {},
              onOpenFile: () {},
              onOpenLightbox: () {},
              isLyricsActive: false,
            ),
          ),
        ),
      );

      expect(find.text('PLAYBACK OPTIONS'), findsOneWidget);
      expect(find.text('Pro-Q Studio Equalizer'), findsOneWidget);
      expect(find.text('Synchronized Lyrics'), findsOneWidget);
      expect(find.text('Sleep Timer'), findsOneWidget);
      expect(find.text('Speed & Pitch Semitone Engine'), findsOneWidget);
      expect(find.text('Studio Desk & Car Docking Mode'), findsOneWidget);

      await tester.tap(find.text('Pro-Q Studio Equalizer'));
      await tester.pump();
      expect(proQOpened, isTrue);
    });

    testWidgets('9. CustomTimeBar renders waveform style with tabular timestamps',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTimeBar(
              position: const Duration(minutes: 1, seconds: 25),
              duration: const Duration(minutes: 3, seconds: 45),
              style: TimeBarStyle.waveform,
              primaryColor: SimpleAsFTheme.emeraldMint,
              timeDisplayMode: TimeDisplayMode.remaining,
              onSeek: (_) {},
              onToggleTimeDisplayMode: () {},
            ),
          ),
        ),
      );

      expect(find.byType(CustomTimeBar), findsOneWidget);
      expect(find.text('01:25'), findsOneWidget);
      expect(find.text('-02:20'), findsOneWidget);
    });

    testWidgets('10. SimpleAsFTheme dynamically resolves to selected custom palette (Amber Tube)',
        (tester) async {
      const amberAccent = Color(0xFFF59E0B);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            scaffoldBackgroundColor: const Color(0xFF141009),
            colorScheme: const ColorScheme.dark(
              primary: amberAccent,
              surfaceContainer: Color(0xFF282115),
            ),
          ),
          home: Builder(
            builder: (context) {
              final accent = SimpleAsFTheme.accent(context);
              final canvas = SimpleAsFTheme.canvas(context);
              final activeCapsule = SimpleAsFTheme.surfaceActive(context);

              expect(accent, amberAccent);
              expect(canvas, const Color(0xFF141009));
              expect(activeCapsule, SimpleAsFTheme.surfaceActiveCapsule);

              return Scaffold(
                body: TwoToneHeader(
                  primaryText: 'AMBER',
                  accentText: 'STUDIO',
                  fontSize: 20,
                ),
              );
            },
          ),
        ),
      );

      final textFinder = find.byType(Text);
      final textWidget = tester.widget<Text>(textFinder);
      final textSpan = textWidget.textSpan! as TextSpan;
      final span2 = textSpan.children![1] as TextSpan;

      expect(span2.text, 'STUDIO');
      expect(span2.style?.color, amberAccent);
    });

    testWidgets('11. SimpleAsFTheme decorators and colors adapt dynamically to Midnight Sapphire',
        (tester) async {
      const sapphireAccent = Color(0xFF2563EB);
      const sapphireCanvas = Color(0xFF0A0F1D);
      const sapphireContainer = Color(0xFF131D36);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            scaffoldBackgroundColor: sapphireCanvas,
            colorScheme: const ColorScheme.dark(
              primary: sapphireAccent,
              surfaceContainer: sapphireContainer,
            ),
          ),
          home: Builder(
            builder: (context) {
              final accent = SimpleAsFTheme.accent(context);
              final canvas = SimpleAsFTheme.canvas(context);
              final surfaceContainer = SimpleAsFTheme.surfaceContainer(context);
              final unplayedBar = SimpleAsFTheme.unplayedBarColor(context);
              final ambientGlow = SimpleAsFTheme.ambientGlow(context);
              final capsuleDecoration = SimpleAsFTheme.activeTrackCapsuleDecoration(context);

              expect(accent, sapphireAccent);
              expect(canvas, sapphireCanvas);
              expect(surfaceContainer, sapphireContainer);
              expect(unplayedBar, const Color(0xFF252834));
              expect(ambientGlow, const Color(0xFF12141A));
              expect(capsuleDecoration.color, const Color(0xFF1E212B));

              return const Scaffold(body: SizedBox());
            },
          ),
        ),
      );
    });

    test('12. Quality Gate: No emojis in theme definitions or typography tokens', () {
      final emojiRegex = RegExp(
        r'[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{1F700}-\u{1F77F}\u{1F780}-\u{1F7FF}\u{1F800}-\u{1F8FF}\u{1F900}-\u{1F9FF}\u{1FA00}-\u{1FA6F}\u{1FA70}-\u{1FAFF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]',
        unicode: true,
      );

      for (final palette in AppPalette.allPresets) {
        expect(emojiRegex.hasMatch(palette.name), isFalse,
            reason: 'Palette name ${palette.name} must not contain emojis');
      }
    });
  });
}
