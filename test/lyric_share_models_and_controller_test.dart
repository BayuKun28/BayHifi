import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baydev_hifi/features/lyrics_share/domain/models/lyric_card_theme.dart';
import 'package:baydev_hifi/features/lyrics_share/domain/models/lyric_share_config.dart';
import 'package:baydev_hifi/features/lyrics_share/presentation/controllers/lyric_share_controller.dart';
import 'package:baydev_hifi/features/player/domain/lyrics_line.dart';
import 'package:baydev_hifi/features/player/domain/track.dart';

void main() {
  group('LyricCardTheme & Ratio Tests', () {
    test('LyricCardRatio aspect ratios and labels are correct', () {
      expect(LyricCardRatio.story_9_16.aspectRatio, closeTo(9 / 16, 0.001));
      expect(LyricCardRatio.square_1_1.aspectRatio, 1.0);
      expect(LyricCardRatio.portrait_4_5.aspectRatio, closeTo(4 / 5, 0.001));
      expect(LyricCardRatio.landscape_16_9.aspectRatio, closeTo(16 / 9, 0.001));
    });

    test('LyricCardFontFamily labels and font families are valid', () {
      expect(LyricCardFontFamily.sans.label, 'Studio Sans');
      expect(LyricCardFontFamily.serif.fontFamily, 'serif');
      expect(LyricCardFontFamily.monospace.fontFamily, 'monospace');
      expect(LyricCardFontFamily.cursive.fontFamily, 'cursive');
    });

    test('LyricCardColors fromPreset generates distinct studio palettes', () {
      final oled = LyricCardColors.fromPreset(LyricCardThemePreset.studioOledBlack);
      expect(oled.backgroundColor, const Color(0xFF000000));
      expect(oled.primaryTextColor, const Color(0xFFFFFFFF));

      final mint = LyricCardColors.fromPreset(LyricCardThemePreset.precisionMint);
      expect(mint.backgroundColor, const Color(0xFF0C1713));
      expect(mint.accentColor, const Color(0xFF34D399));

      final sky = LyricCardColors.fromPreset(LyricCardThemePreset.skyStudio);
      expect(sky.backgroundColor, const Color(0xFF0B1320));

      final amber = LyricCardColors.fromPreset(LyricCardThemePreset.warmAmber);
      expect(amber.accentColor, const Color(0xFFF59E0B));

      final rose = LyricCardColors.fromPreset(LyricCardThemePreset.mutedRose);
      expect(rose.accentColor, const Color(0xFFFB7185));
    });

    test('LyricCardColors dynamic, blurred, and custom factories operate correctly', () {
      final dyn = LyricCardColors.fromDynamicColor(const Color(0xFF204060));
      expect(dyn.backgroundColor, isNotNull);
      expect(dyn.surfaceColor, isNotNull);
      expect(dyn.primaryTextColor, const Color(0xFFFFFFFF));

      final blurred = LyricCardColors.forBlurredArtwork(accentColor: const Color(0xFF38BDF8));
      expect(blurred.accentColor, const Color(0xFF38BDF8));
      expect(blurred.primaryTextColor, const Color(0xFFFFFFFF));

      final custom = LyricCardColors.fromCustomColor(const Color(0xFF8B0000));
      expect(custom.backgroundColor, isNotNull);
      expect(custom.primaryTextColor, const Color(0xFFFFFFFF));
    });
  });

  group('LyricShareConfig Tests', () {
    const testTrack = Track(
      id: 't1',
      title: 'Studio Song',
      artist: 'Studio Artist',
      album: 'Studio Album',
      duration: Duration(minutes: 3),
      format: AudioFormat.flac,
    );

    const l1 = LyricsLine(timestamp: Duration(seconds: 10), text: 'Line 1');
    const l2 = LyricsLine(timestamp: Duration(seconds: 15), text: 'Line 2');

    test('LyricShareConfig properties and copyWith', () {
      const config = LyricShareConfig(
        track: testTrack,
        selectedLines: [l1, l2],
        ratio: LyricCardRatio.square_1_1,
        backgroundMode: LyricCardBackgroundMode.blurredArtwork,
        preset: LyricCardThemePreset.precisionMint,
        fontFamily: LyricCardFontFamily.serif,
        fontSizeMultiplier: 1.2,
        fontWeight: FontWeight.w800,
        isItalic: true,
        textAlign: TextAlign.center,
        customAudioSpec: 'CUSTOM LOSSLESS MASTER',
      );

      expect(config.hasSelection, isTrue);
      expect(config.plainTextQuote, 'Line 1\nLine 2');
      expect(config.backgroundMode, LyricCardBackgroundMode.blurredArtwork);
      expect(config.fontFamily, LyricCardFontFamily.serif);
      expect(config.fontSizeMultiplier, 1.2);
      expect(config.fontWeight, FontWeight.w800);
      expect(config.isItalic, isTrue);
      expect(config.textAlign, TextAlign.center);
      expect(config.customAudioSpec, 'CUSTOM LOSSLESS MASTER');

      final updated = config.copyWith(
        ratio: LyricCardRatio.landscape_16_9,
        backgroundMode: LyricCardBackgroundMode.customColor,
        customBackgroundColor: const Color(0xFF0F172A),
        fontFamily: LyricCardFontFamily.monospace,
        textAlign: TextAlign.right,
        showAudioSpecsBadge: false,
      );

      expect(updated.ratio, LyricCardRatio.landscape_16_9);
      expect(updated.backgroundMode, LyricCardBackgroundMode.customColor);
      expect(updated.customBackgroundColor, const Color(0xFF0F172A));
      expect(updated.fontFamily, LyricCardFontFamily.monospace);
      expect(updated.textAlign, TextAlign.right);
      expect(updated.showAudioSpecsBadge, isFalse);
      expect(updated.selectedLines.length, 2);
    });
  });

  group('LyricShareController State Tests', () {
    const testTrack = Track(
      id: 't1',
      title: 'Studio Song',
      artist: 'Studio Artist',
      album: 'Studio Album',
      duration: Duration(minutes: 3),
      format: AudioFormat.flac,
    );

    final allLines = [
      const LyricsLine(timestamp: Duration(seconds: 5), text: 'Intro line'),
      const LyricsLine(timestamp: Duration(seconds: 10), text: 'First chorus line'),
      const LyricsLine(timestamp: Duration(seconds: 15), text: 'Second chorus line'),
      const LyricsLine(timestamp: Duration(seconds: 20), text: 'Third chorus line'),
      const LyricsLine(timestamp: Duration(seconds: 25), text: 'Fourth chorus line'),
      const LyricsLine(timestamp: Duration(seconds: 30), text: 'Fifth chorus line'),
      const LyricsLine(timestamp: Duration(seconds: 35), text: 'Outro line'),
    ];

    test('Initial state correctly sets initial selected line', () {
      final controller = LyricShareController(
        track: testTrack,
        allLines: allLines,
        initialSelectedLine: allLines[1],
        audioSpec: 'FLAC 96kHz / 24-bit',
      );

      expect(controller.state.config.selectedLines.length, 1);
      expect(controller.state.config.selectedLines.first.text, 'First chorus line');
      expect(controller.state.config.customAudioSpec, 'FLAC 96kHz / 24-bit');
    });

    test('toggleLineSelection calculates contiguous range up to maxSelectedLines', () {
      final controller = LyricShareController(
        track: testTrack,
        allLines: allLines,
        initialSelectedLine: allLines[1],
      );

      // Select line 3 (index 3) while line 1 (index 1) is selected -> range 1..3 should be selected (lines 1, 2, 3)
      controller.toggleLineSelection(allLines[3]);
      expect(controller.state.config.selectedLines.length, 3);
      expect(controller.state.config.selectedLines[0], allLines[1]);
      expect(controller.state.config.selectedLines[1], allLines[2]);
      expect(controller.state.config.selectedLines[2], allLines[3]);

      // Select line 6 (index 6, distance > 5 lines) -> should reset to single selection of line 6
      controller.toggleLineSelection(allLines[6]);
      expect(controller.state.config.selectedLines.length, 1);
      expect(controller.state.config.selectedLines.first, allLines[6]);
    });

    test('Background mode switcher, palette swatches, and custom colors update cleanly', () {
      final controller = LyricShareController(
        track: testTrack,
        allLines: allLines,
      );

      controller.setBackgroundMode(LyricCardBackgroundMode.blurredArtwork);
      expect(controller.state.config.backgroundMode, LyricCardBackgroundMode.blurredArtwork);

      controller.selectPaletteColor(const Color(0xFF1E3A8A));
      expect(controller.state.config.backgroundMode, LyricCardBackgroundMode.albumPalette);
      expect(controller.state.config.selectedPaletteColor, const Color(0xFF1E3A8A));

      controller.setCustomColor(const Color(0xFF4C0519));
      expect(controller.state.config.backgroundMode, LyricCardBackgroundMode.customColor);
      expect(controller.state.config.customBackgroundColor, const Color(0xFF4C0519));
    });

    test('Typography methods (fontFamily, size, weight, italic, align, customAudioSpec) update cleanly', () {
      final controller = LyricShareController(
        track: testTrack,
        allLines: allLines,
      );

      controller.setFontFamily(LyricCardFontFamily.serif);
      expect(controller.state.config.fontFamily, LyricCardFontFamily.serif);

      controller.setFontSizeMultiplier(1.3);
      expect(controller.state.config.fontSizeMultiplier, 1.3);

      controller.setFontWeight(FontWeight.w400);
      expect(controller.state.config.fontWeight, FontWeight.w400);

      controller.toggleBold();
      expect(controller.state.config.fontWeight, FontWeight.w700);

      controller.toggleItalic(true);
      expect(controller.state.config.isItalic, isTrue);

      controller.setTextAlign(TextAlign.center);
      expect(controller.state.config.textAlign, TextAlign.center);

      controller.setCustomAudioSpec('VINYL 192kHz MASTER');
      expect(controller.state.config.customAudioSpec, 'VINYL 192kHz MASTER');

      controller.setCustomAudioSpec(null);
      expect(controller.state.config.customAudioSpec, isNull);
    });

    test('Toggles and settings update state cleanly', () {
      final controller = LyricShareController(
        track: testTrack,
        allLines: allLines,
      );

      controller.setRatio(LyricCardRatio.landscape_16_9);
      expect(controller.state.config.ratio, LyricCardRatio.landscape_16_9);

      controller.setPreset(LyricCardThemePreset.warmAmber);
      expect(controller.state.config.preset, LyricCardThemePreset.warmAmber);
      expect(controller.state.colors.accentColor, const Color(0xFFF59E0B));

      controller.toggleAudioSpecs(false);
      expect(controller.state.config.showAudioSpecsBadge, isFalse);

      controller.toggleBranding(false);
      expect(controller.state.config.showBranding, isFalse);

      controller.toggleRomanized(true);
      expect(controller.state.config.showRomanized, isTrue);
    });
  });
}
