import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons/hugeicons.dart';
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
      expect(SimpleAsFTheme.forestCanvas, const Color(0xFF0B110E));
      expect(SimpleAsFTheme.forestGlow, const Color(0xFF12231A));
      expect(SimpleAsFTheme.emeraldMint, const Color(0xFF2EE672));
      expect(SimpleAsFTheme.sageSlate, const Color(0xFF8A9A90));
      expect(SimpleAsFTheme.surfaceActiveCapsule, const Color(0xFF16241C));
      expect(SimpleAsFTheme.textWhite, const Color(0xFFFFFFFF));
    });

    test('2. Default AppPalette is simpleAsF and default accent is emerald mint', () {
      expect(AppPalette.simpleAsF.primary, const Color(0xFF2EE672));
      expect(AppPalette.simpleAsF.name, 'Simple as F*** (Obsidian Emerald)');
      expect(AppPalette.allPresets.first.name, 'Simple as F*** (Obsidian Emerald)');
    });

    test('3. PlayerCustomizationSettings default to squircle and waveform', () {
      const settings = PlayerCustomizationSettings();
      expect(settings.albumArtStyle, AlbumArtStyle.squircle);
      expect(settings.timeBarStyle, TimeBarStyle.waveform);
    });

    testWidgets('4. TwoToneHeader renders white keyword and accent keyword in RichText',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
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
        const MaterialApp(
          home: Scaffold(
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
        (w) => w is HugeIcon && w.icon == HugeIcons.strokeRoundedAudioWaveform,
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
  });
}
