// ignore_for_file: prefer_initializing_formals
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../player/domain/lyrics_line.dart';
import '../../../player/domain/track.dart';
import 'audiophile_stamp_config.dart';
import 'lyric_card_layout_style.dart';
import 'lyric_card_theme.dart';
import 'lyric_sticker_model.dart';

/// Configuration state for building and rendering a studio lyric share card
@immutable
class LyricShareConfig {
  final Track track;
  final List<LyricsLine> selectedLines;
  final LyricCardLayoutStyle layoutStyle;
  final LyricCardRatio ratio;
  final LyricCardBackgroundMode backgroundMode;
  final LyricCardThemePreset preset;
  final LyricCardFontFamily fontFamily;
  final double fontSizeMultiplier;
  final FontWeight fontWeight;
  final bool isItalic;
  final TextAlign textAlign;
  final LyricCardHighlightStyle? _highlightStyle;
  LyricCardHighlightStyle get highlightStyle => _highlightStyle ?? LyricCardHighlightStyle.none;

  final double? _strokeWidth;
  double get strokeWidth => _strokeWidth ?? 2.5;

  final double? _backgroundBlurSigma;
  double get backgroundBlurSigma => _backgroundBlurSigma ?? 30.0;

  final double? _backgroundDimOpacity;
  double get backgroundDimOpacity => _backgroundDimOpacity ?? 0.65;

  final double? _lineSpacingMultiplier;
  double get lineSpacingMultiplier => _lineSpacingMultiplier ?? 1.0;

  final double? _letterSpacing;
  double get letterSpacing => _letterSpacing ?? -0.2;

  final Color? selectedPaletteColor;
  final Color? customBackgroundColor;
  final bool showAudioSpecsBadge;
  final bool showBranding;
  final bool showArtwork;
  final bool showRomanized;
  final bool showDualLineRomanized;
  final String? customAudioSpec; // e.g. "FLAC 96kHz / 24-bit • Studio Master"
  final AudiophileStampConfig audiophileStamp;
  final List<LyricStickerType> selectedStickers;
  final String? personalNote;
  final bool showQrCode;

  const LyricShareConfig({
    required this.track,
    required this.selectedLines,
    this.layoutStyle = LyricCardLayoutStyle.classicMinimal,
    this.ratio = LyricCardRatio.story_9_16,
    this.backgroundMode = LyricCardBackgroundMode.blurredArtwork,
    this.preset = LyricCardThemePreset.dynamicAlbumArt,
    this.fontFamily = LyricCardFontFamily.sans,
    this.fontSizeMultiplier = 1.0,
    this.fontWeight = FontWeight.w700,
    this.isItalic = false,
    this.textAlign = TextAlign.left,
    LyricCardHighlightStyle? highlightStyle,
    double? strokeWidth,
    double? backgroundBlurSigma,
    double? backgroundDimOpacity,
    double? lineSpacingMultiplier,
    double? letterSpacing,
    this.selectedPaletteColor,
    this.customBackgroundColor,
    this.showAudioSpecsBadge = true,
    this.showBranding = true,
    this.showArtwork = true,
    this.showRomanized = false,
    this.showDualLineRomanized = false,
    this.customAudioSpec,
    this.audiophileStamp = const AudiophileStampConfig(),
    this.selectedStickers = const [],
    this.personalNote,
    this.showQrCode = false,
  })  : _highlightStyle = highlightStyle,
        _strokeWidth = strokeWidth,
        _backgroundBlurSigma = backgroundBlurSigma,
        _backgroundDimOpacity = backgroundDimOpacity,
        _lineSpacingMultiplier = lineSpacingMultiplier,
        _letterSpacing = letterSpacing;

  /// Maximum number of selectable lines to maintain clean layout & legibility
  static const int maxSelectedLines = 6;

  /// Returns true if at least one line is selected
  bool get hasSelection => selectedLines.isNotEmpty;

  /// Combined plain text of all selected lines for fallback clipboard/sharing
  String get plainTextQuote {
    return selectedLines.map((l) => l.text).join('\n');
  }

  LyricShareConfig copyWith({
    Track? track,
    List<LyricsLine>? selectedLines,
    LyricCardLayoutStyle? layoutStyle,
    LyricCardRatio? ratio,
    LyricCardBackgroundMode? backgroundMode,
    LyricCardThemePreset? preset,
    LyricCardFontFamily? fontFamily,
    double? fontSizeMultiplier,
    FontWeight? fontWeight,
    bool? isItalic,
    TextAlign? textAlign,
    LyricCardHighlightStyle? highlightStyle,
    double? strokeWidth,
    double? backgroundBlurSigma,
    double? backgroundDimOpacity,
    double? lineSpacingMultiplier,
    double? letterSpacing,
    Color? selectedPaletteColor,
    Color? customBackgroundColor,
    bool? showAudioSpecsBadge,
    bool? showBranding,
    bool? showArtwork,
    bool? showRomanized,
    bool? showDualLineRomanized,
    String? customAudioSpec,
    bool clearCustomAudioSpec = false,
    AudiophileStampConfig? audiophileStamp,
    List<LyricStickerType>? selectedStickers,
    String? personalNote,
    bool clearPersonalNote = false,
    bool? showQrCode,
  }) {
    return LyricShareConfig(
      track: track ?? this.track,
      selectedLines: selectedLines ?? this.selectedLines,
      layoutStyle: layoutStyle ?? this.layoutStyle,
      ratio: ratio ?? this.ratio,
      backgroundMode: backgroundMode ?? this.backgroundMode,
      preset: preset ?? this.preset,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSizeMultiplier: fontSizeMultiplier ?? this.fontSizeMultiplier,
      fontWeight: fontWeight ?? this.fontWeight,
      isItalic: isItalic ?? this.isItalic,
      textAlign: textAlign ?? this.textAlign,
      highlightStyle: highlightStyle ?? this.highlightStyle,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      backgroundBlurSigma: backgroundBlurSigma ?? this.backgroundBlurSigma,
      backgroundDimOpacity: backgroundDimOpacity ?? this.backgroundDimOpacity,
      lineSpacingMultiplier: lineSpacingMultiplier ?? this.lineSpacingMultiplier,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      selectedPaletteColor: selectedPaletteColor ?? this.selectedPaletteColor,
      customBackgroundColor: customBackgroundColor ?? this.customBackgroundColor,
      showAudioSpecsBadge: showAudioSpecsBadge ?? this.showAudioSpecsBadge,
      showBranding: showBranding ?? this.showBranding,
      showArtwork: showArtwork ?? this.showArtwork,
      showRomanized: showRomanized ?? this.showRomanized,
      showDualLineRomanized: showDualLineRomanized ?? this.showDualLineRomanized,
      customAudioSpec: clearCustomAudioSpec ? null : (customAudioSpec ?? this.customAudioSpec),
      audiophileStamp: audiophileStamp ?? this.audiophileStamp,
      selectedStickers: selectedStickers ?? this.selectedStickers,
      personalNote: clearPersonalNote ? null : (personalNote ?? this.personalNote),
      showQrCode: showQrCode ?? this.showQrCode,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LyricShareConfig &&
          runtimeType == other.runtimeType &&
          track == other.track &&
          listEquals(selectedLines, other.selectedLines) &&
          layoutStyle == other.layoutStyle &&
          ratio == other.ratio &&
          backgroundMode == other.backgroundMode &&
          preset == other.preset &&
          fontFamily == other.fontFamily &&
          fontSizeMultiplier == other.fontSizeMultiplier &&
          fontWeight == other.fontWeight &&
          isItalic == other.isItalic &&
          textAlign == other.textAlign &&
          highlightStyle == other.highlightStyle &&
          strokeWidth == other.strokeWidth &&
          backgroundBlurSigma == other.backgroundBlurSigma &&
          backgroundDimOpacity == other.backgroundDimOpacity &&
          lineSpacingMultiplier == other.lineSpacingMultiplier &&
          letterSpacing == other.letterSpacing &&
          selectedPaletteColor == other.selectedPaletteColor &&
          customBackgroundColor == other.customBackgroundColor &&
          showAudioSpecsBadge == other.showAudioSpecsBadge &&
          showBranding == other.showBranding &&
          showArtwork == other.showArtwork &&
          showRomanized == other.showRomanized &&
          showDualLineRomanized == other.showDualLineRomanized &&
          customAudioSpec == other.customAudioSpec &&
          audiophileStamp == other.audiophileStamp &&
          listEquals(selectedStickers, other.selectedStickers) &&
          personalNote == other.personalNote &&
          showQrCode == other.showQrCode;

  @override
  int get hashCode =>
      track.hashCode ^
      Object.hashAll(selectedLines) ^
      layoutStyle.hashCode ^
      ratio.hashCode ^
      backgroundMode.hashCode ^
      preset.hashCode ^
      fontFamily.hashCode ^
      fontSizeMultiplier.hashCode ^
      fontWeight.hashCode ^
      isItalic.hashCode ^
      textAlign.hashCode ^
      highlightStyle.hashCode ^
      strokeWidth.hashCode ^
      backgroundBlurSigma.hashCode ^
      backgroundDimOpacity.hashCode ^
      lineSpacingMultiplier.hashCode ^
      letterSpacing.hashCode ^
      (selectedPaletteColor?.hashCode ?? 0) ^
      (customBackgroundColor?.hashCode ?? 0) ^
      showAudioSpecsBadge.hashCode ^
      showBranding.hashCode ^
      showArtwork.hashCode ^
      showRomanized.hashCode ^
      showDualLineRomanized.hashCode ^
      (customAudioSpec?.hashCode ?? 0) ^
      audiophileStamp.hashCode ^
      Object.hashAll(selectedStickers) ^
      (personalNote?.hashCode ?? 0) ^
      showQrCode.hashCode;
}
