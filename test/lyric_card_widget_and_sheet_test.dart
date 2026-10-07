import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baydev_hifi/features/lyrics_share/domain/models/lyric_card_layout_style.dart';
import 'package:baydev_hifi/features/lyrics_share/domain/models/lyric_card_theme.dart';
import 'package:baydev_hifi/features/lyrics_share/domain/models/lyric_share_config.dart';
import 'package:baydev_hifi/features/lyrics_share/presentation/widgets/lyric_card_fullscreen_lightbox.dart';
import 'package:baydev_hifi/features/lyrics_share/presentation/widgets/lyric_card_widget.dart';
import 'package:baydev_hifi/features/lyrics_share/presentation/widgets/lyric_share_sheet.dart';
import 'package:baydev_hifi/features/player/domain/lyrics_line.dart';
import 'package:baydev_hifi/features/player/domain/track.dart';

void main() {
  const testTrack = Track(
    id: 't_share',
    title: 'Bohemian Rhapsody',
    artist: 'Queen',
    album: 'A Night at the Opera',
    duration: Duration(minutes: 5, seconds: 55),
    format: AudioFormat.flac,
  );

  final testLines = [
    const LyricsLine(timestamp: Duration(seconds: 1), text: 'Is this the real life?'),
    const LyricsLine(timestamp: Duration(seconds: 4), text: 'Is this just fantasy?'),
    const LyricsLine(timestamp: Duration(seconds: 8), text: 'Caught in a landslide'),
    const LyricsLine(timestamp: Duration(seconds: 12), text: 'No escape from reality'),
  ];

  testWidgets('LyricCardWidget renders track info, quotes, and branding', (tester) async {
    const config = LyricShareConfig(
      track: testTrack,
      selectedLines: [
        LyricsLine(timestamp: Duration(seconds: 1), text: 'Is this the real life?'),
        LyricsLine(timestamp: Duration(seconds: 4), text: 'Is this just fantasy?'),
      ],
      layoutStyle: LyricCardLayoutStyle.classicMinimal,
      ratio: LyricCardRatio.story_9_16,
      preset: LyricCardThemePreset.studioOledBlack,
      showAudioSpecsBadge: true,
      showBranding: true,
    );

    final colors = LyricCardColors.fromPreset(LyricCardThemePreset.studioOledBlack);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              height: 640,
              child: LyricCardWidget(
                config: config,
                colors: colors,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('BAYDEV HIFI'), findsOneWidget);
    expect(find.text('Is this the real life?'), findsOneWidget);
    expect(find.text('Is this just fantasy?'), findsOneWidget);
    expect(find.text('Bohemian Rhapsody'), findsOneWidget);
    expect(find.text('Queen • A Night at the Opera'), findsOneWidget);
    expect(find.text('LOSSLESS MASTER • FLAC'), findsOneWidget);
  });

  testWidgets('LyricShareSheet renders 4-tab studio navigation and handles line selection', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: LyricShareSheet(
              track: testTrack,
              allLines: testLines,
              initialSelectedLine: testLines[0],
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title & Subtitle
    expect(find.text('Lyric Studio Share'), findsOneWidget);
    expect(find.text('Bohemian Rhapsody'), findsAtLeast(1));

    // Verify 4 Tab Pills
    expect(find.text('Studio'), findsOneWidget);
    expect(find.text('Lines (1/6)'), findsOneWidget);
    expect(find.text('Telemetry'), findsWidgets);
    expect(find.text('Style'), findsOneWidget);

    // Switch to Select Lines Tab
    await tester.tap(find.text('Lines (1/6)'));
    await tester.pumpAndSettle();

    // Verify lines in list
    expect(find.text('Is this the real life?'), findsOneWidget);
    expect(find.text('Is this just fantasy?'), findsOneWidget);
    expect(find.text('Caught in a landslide'), findsOneWidget);
    expect(find.text('No escape from reality'), findsOneWidget);

    // Tap on second line to select range 0..1
    await tester.tap(find.text('Is this just fantasy?'));
    await tester.pumpAndSettle();

    expect(find.text('Lines (2/6)'), findsOneWidget);

    // Switch to Style Tab
    await tester.tap(find.text('Style'));
    await tester.pumpAndSettle();

    // Verify Typography Controls
    expect(find.text('TYPOGRAPHY & FONT WEIGHT'), findsOneWidget);
    expect(find.text('TEXT STYLES & HIGHLIGHTS'), findsOneWidget);
    expect(find.text('Studio Sans'), findsOneWidget);
    expect(find.text('Editorial Serif'), findsOneWidget);
    expect(find.text('Studio Mono'), findsOneWidget);
    expect(find.text('Script Flow'), findsOneWidget);

    // Scroll to and tap on Editorial Serif
    await tester.ensureVisible(find.text('Editorial Serif'));
    await tester.tap(find.text('Editorial Serif'));
    await tester.pumpAndSettle();

    // Verify Action Buttons
    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Share to Socials'), findsOneWidget);
  });

  testWidgets('LyricCardWidget renders landscape 16:9 dedicated two-column layout', (tester) async {
    const config = LyricShareConfig(
      track: testTrack,
      selectedLines: [
        LyricsLine(timestamp: Duration(seconds: 1), text: 'Is this the real life?'),
      ],
      layoutStyle: LyricCardLayoutStyle.classicMinimal,
      ratio: LyricCardRatio.landscape_16_9,
      preset: LyricCardThemePreset.studioOledBlack,
      showAudioSpecsBadge: true,
      showBranding: true,
    );

    final colors = LyricCardColors.fromPreset(LyricCardThemePreset.studioOledBlack);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 533,
              height: 300,
              child: LyricCardWidget(
                config: config,
                colors: colors,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('BAYDEV HIFI'), findsOneWidget);
    expect(find.text('Is this the real life?'), findsOneWidget);
    expect(find.text('Bohemian Rhapsody'), findsOneWidget);
    expect(find.text('Queen'), findsOneWidget);
  });

  testWidgets('LyricCardFullScreenLightbox renders interactive preview with ratio pill and actions', (tester) async {
    const config = LyricShareConfig(
      track: testTrack,
      selectedLines: [
        LyricsLine(timestamp: Duration(seconds: 1), text: 'Is this the real life?'),
      ],
      layoutStyle: LyricCardLayoutStyle.waveformQuote,
      ratio: LyricCardRatio.portrait_4_5,
      preset: LyricCardThemePreset.studioOledBlack,
      showBranding: true,
    );

    final colors = LyricCardColors.fromPreset(LyricCardThemePreset.studioOledBlack);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LyricCardFullScreenLightbox(
            config: config,
            colors: colors,
          ),
        ),
      ),
    );

    expect(find.byType(LyricCardFullScreenLightbox), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.text('Portrait (4:5) • WAVEFORM TIMELINE'), findsOneWidget);
  });

  testWidgets('LyricShareSheet displays Full Screen badge and opens lightbox on tap', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: LyricShareSheet(
              track: testTrack,
              allLines: testLines,
              initialSelectedLine: testLines[0],
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Full Screen badge in Studio preview tab
    expect(find.text('Full Screen'), findsOneWidget);

    // Tap on Full Screen badge
    await tester.tap(find.text('Full Screen'));
    await tester.pumpAndSettle();

    // Verify Lightbox is pushed on navigator
    expect(find.byType(LyricCardFullScreenLightbox), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsOneWidget);
  });
}
