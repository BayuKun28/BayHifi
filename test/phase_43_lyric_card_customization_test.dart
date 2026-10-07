import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baydev_hifi/features/lyrics_share/domain/models/lyric_card_theme.dart';
import 'package:baydev_hifi/features/lyrics_share/domain/models/lyric_share_config.dart';
import 'package:baydev_hifi/features/lyrics_share/presentation/controllers/lyric_share_controller.dart';
import 'package:baydev_hifi/features/lyrics_share/presentation/widgets/lyric_card_widget.dart';
import 'package:baydev_hifi/features/lyrics_share/presentation/widgets/lyric_share_sheet.dart';
import 'package:baydev_hifi/features/player/domain/lyrics_line.dart';
import 'package:baydev_hifi/features/player/domain/track.dart';

void main() {
  const testTrack = Track(
    id: 't_custom_share',
    title: 'Starboy',
    artist: 'The Weeknd',
    album: 'Starboy',
    duration: Duration(minutes: 3, seconds: 50),
    format: AudioFormat.flac,
  );

  final testLines = [
    const LyricsLine(timestamp: Duration(seconds: 10), text: 'I am in love with the music'),
    const LyricsLine(timestamp: Duration(seconds: 15), text: 'Lost in the studio session'),
    const LyricsLine(timestamp: Duration(seconds: 20), text: 'Every frequency so clean'),
  ];

  group('Phase 43: Lyric Card Highlight & Styling Domain Models', () {
    test('LyricCardHighlightStyle enums and labels are defined', () {
      expect(LyricCardHighlightStyle.none.label, 'Clean');
      expect(LyricCardHighlightStyle.stroke.label, 'Text Stroke');
      expect(LyricCardHighlightStyle.highlighterPill.label, 'Instagram Pill');
      expect(LyricCardHighlightStyle.dropShadow.label, 'Spotify Glow');
      expect(LyricCardHighlightStyle.values.length, 4);
    });

    test('LyricShareConfig copyWith supports new font weight, stroke, and atmospheric parameters', () {
      const config = LyricShareConfig(
        track: testTrack,
        selectedLines: [],
      );

      expect(config.highlightStyle, LyricCardHighlightStyle.none);
      expect(config.strokeWidth, 2.5);
      expect(config.backgroundBlurSigma, 30.0);
      expect(config.backgroundDimOpacity, 0.65);
      expect(config.lineSpacingMultiplier, 1.0);
      expect(config.letterSpacing, -0.2);

      final updated = config.copyWith(
        highlightStyle: LyricCardHighlightStyle.stroke,
        strokeWidth: 4.0,
        backgroundBlurSigma: 45.0,
        backgroundDimOpacity: 0.85,
        lineSpacingMultiplier: 1.3,
        letterSpacing: 0.8,
        fontWeight: FontWeight.w900,
      );

      expect(updated.highlightStyle, LyricCardHighlightStyle.stroke);
      expect(updated.strokeWidth, 4.0);
      expect(updated.backgroundBlurSigma, 45.0);
      expect(updated.backgroundDimOpacity, 0.85);
      expect(updated.lineSpacingMultiplier, 1.3);
      expect(updated.letterSpacing, 0.8);
      expect(updated.fontWeight, FontWeight.w900);
    });
  });

  group('Phase 43: LyricShareController State Updates', () {
    test('Controller handles highlight style, stroke width, and blur/dim adjustments', () {
      final controller = LyricShareController(
        track: testTrack,
        allLines: testLines,
      );

      controller.setHighlightStyle(LyricCardHighlightStyle.highlighterPill);
      expect(controller.state.config.highlightStyle, LyricCardHighlightStyle.highlighterPill);

      controller.setStrokeWidth(3.5);
      expect(controller.state.config.strokeWidth, 3.5);

      controller.setBackgroundBlurSigma(50.0);
      expect(controller.state.config.backgroundBlurSigma, 50.0);

      controller.setBackgroundDimOpacity(0.80);
      expect(controller.state.config.backgroundDimOpacity, 0.80);

      controller.setLineSpacingMultiplier(1.3);
      expect(controller.state.config.lineSpacingMultiplier, 1.3);

      controller.setLetterSpacing(0.8);
      expect(controller.state.config.letterSpacing, 0.8);

      controller.setFontWeight(FontWeight.w900);
      expect(controller.state.config.fontWeight, FontWeight.w900);
    });
  });

  group('Phase 43: LyricCardWidget Rendering with Styles', () {
    testWidgets('Renders text stroke with dual-layer stack', (tester) async {
      const config = LyricShareConfig(
        track: testTrack,
        selectedLines: [
          LyricsLine(timestamp: Duration(seconds: 10), text: 'Stroke text line'),
        ],
        highlightStyle: LyricCardHighlightStyle.stroke,
        strokeWidth: 3.0,
      );

      final colors = LyricCardColors.fromPreset(LyricCardThemePreset.studioOledBlack);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 500,
                child: LyricCardWidget(
                  config: config,
                  colors: colors,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Stroke text line'), findsNWidgets(2)); // Stroke + Fill stack
    });

    testWidgets('Renders Instagram highlighter pill container', (tester) async {
      const config = LyricShareConfig(
        track: testTrack,
        selectedLines: [
          LyricsLine(timestamp: Duration(seconds: 10), text: 'Highlighter line'),
        ],
        highlightStyle: LyricCardHighlightStyle.highlighterPill,
      );

      final colors = LyricCardColors.fromPreset(LyricCardThemePreset.precisionMint);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 500,
                child: LyricCardWidget(
                  config: config,
                  colors: colors,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Highlighter line'), findsOneWidget);
    });

    testWidgets('Renders Spotify glow drop shadow', (tester) async {
      const config = LyricShareConfig(
        track: testTrack,
        selectedLines: [
          LyricsLine(timestamp: Duration(seconds: 10), text: 'Glow line'),
        ],
        highlightStyle: LyricCardHighlightStyle.dropShadow,
      );

      final colors = LyricCardColors.fromPreset(LyricCardThemePreset.skyStudio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 500,
                child: LyricCardWidget(
                  config: config,
                  colors: colors,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Glow line'), findsOneWidget);
    });
  });

  group('Phase 43: LyricShareSheet Interactive Editing Controls', () {
    testWidgets('Renders Font Weight chips and Text Highlight styles', (tester) async {
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
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Switch to Style tab
      await tester.tap(find.text('Style'));
      await tester.pumpAndSettle();

      // Check Typography & Font Weight section
      expect(find.text('TYPOGRAPHY & FONT WEIGHT'), findsOneWidget);
      expect(find.text('Regular'), findsOneWidget);
      expect(find.text('SemiBold'), findsOneWidget);
      expect(find.text('Bold'), findsOneWidget);
      expect(find.text('Black'), findsOneWidget);

      // Check Text Styles & Highlights section
      expect(find.text('TEXT STYLES & HIGHLIGHTS'), findsOneWidget);
      expect(find.text('Clean'), findsOneWidget);
      expect(find.text('Text Stroke'), findsOneWidget);
      expect(find.text('Instagram Pill'), findsOneWidget);
      expect(find.text('Spotify Glow'), findsOneWidget);

      // Tap on Text Stroke
      await tester.tap(find.text('Text Stroke'));
      await tester.pumpAndSettle();

      // Tap on Instagram Pill
      await tester.tap(find.text('Instagram Pill'));
      await tester.pumpAndSettle();

      // Tap on Black font weight
      await tester.tap(find.text('Black'));
      await tester.pumpAndSettle();

      // Check Spacing options
      expect(find.text('Line Spacing'), findsOneWidget);
      expect(find.text('Letter Spacing'), findsOneWidget);
      expect(find.text('Compact'), findsOneWidget);
      expect(find.text('Normal'), findsWidgets);
      expect(find.text('Relaxed'), findsOneWidget);
    });
  });
}
