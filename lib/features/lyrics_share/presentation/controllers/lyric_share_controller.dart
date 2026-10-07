import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette_generator/palette_generator.dart';
import '../../../../core/widgets/studio_artwork_widget.dart';
import '../../../player/domain/lyrics_line.dart';
import '../../../player/domain/track.dart';
import '../../domain/models/audiophile_stamp_config.dart';
import '../../domain/models/lyric_card_layout_style.dart';
import '../../domain/models/lyric_card_theme.dart';
import '../../domain/models/lyric_share_config.dart';
import '../../domain/models/lyric_sticker_model.dart';
import '../services/lyric_image_generator.dart';

/// State of the Lyric Share Sheet & Generator
@immutable
class LyricShareState {
  final LyricShareConfig config;
  final List<LyricsLine> allLines;
  final LyricCardColors colors;
  final Color? dominantAlbumColor;
  final Color? vibrantAlbumColor;
  final Color? lightVibrantAlbumColor;
  final List<Color> extractedPaletteSwatches;
  final bool isExtractingPalette;
  final bool isRendering;
  final String? errorMessage;
  final String? successMessage;
  final String? savedFilePath;
  final bool isMissingPlugin;

  const LyricShareState({
    required this.config,
    required this.allLines,
    required this.colors,
    this.dominantAlbumColor,
    this.vibrantAlbumColor,
    this.lightVibrantAlbumColor,
    this.extractedPaletteSwatches = const [],
    this.isExtractingPalette = false,
    this.isRendering = false,
    this.errorMessage,
    this.successMessage,
    this.savedFilePath,
    this.isMissingPlugin = false,
  });

  LyricShareState copyWith({
    LyricShareConfig? config,
    List<LyricsLine>? allLines,
    LyricCardColors? colors,
    Color? dominantAlbumColor,
    Color? vibrantAlbumColor,
    Color? lightVibrantAlbumColor,
    List<Color>? extractedPaletteSwatches,
    bool? isExtractingPalette,
    bool? isRendering,
    String? errorMessage,
    String? successMessage,
    String? savedFilePath,
    bool? isMissingPlugin,
    bool clearStatus = false,
  }) {
    return LyricShareState(
      config: config ?? this.config,
      allLines: allLines ?? this.allLines,
      colors: colors ?? this.colors,
      dominantAlbumColor: dominantAlbumColor ?? this.dominantAlbumColor,
      vibrantAlbumColor: vibrantAlbumColor ?? this.vibrantAlbumColor,
      lightVibrantAlbumColor: lightVibrantAlbumColor ?? this.lightVibrantAlbumColor,
      extractedPaletteSwatches: extractedPaletteSwatches ?? this.extractedPaletteSwatches,
      isExtractingPalette: isExtractingPalette ?? this.isExtractingPalette,
      isRendering: isRendering ?? this.isRendering,
      errorMessage: clearStatus ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearStatus ? null : (successMessage ?? this.successMessage),
      savedFilePath: clearStatus ? null : (savedFilePath ?? this.savedFilePath),
      isMissingPlugin: isMissingPlugin ?? this.isMissingPlugin,
    );
  }
}

/// Controller managing lyric line selections, theme tweaking, and image generation
class LyricShareController extends StateNotifier<LyricShareState> {
  LyricShareController({
    required Track track,
    required List<LyricsLine> allLines,
    LyricsLine? initialSelectedLine,
    Color? dominantColor,
    Color? vibrantColor,
    Color? lightVibrantColor,
    String? audioSpec,
  }) : super(_createInitialState(
          track: track,
          allLines: allLines,
          initialSelectedLine: initialSelectedLine,
          dominantColor: dominantColor,
          vibrantColor: vibrantColor,
          lightVibrantColor: lightVibrantColor,
          audioSpec: audioSpec,
        )) {
    // Automatically extract palette swatches asynchronously on initialization
    extractPaletteFromTrack(track);
  }

  static LyricShareState _createInitialState({
    required Track track,
    required List<LyricsLine> allLines,
    LyricsLine? initialSelectedLine,
    Color? dominantColor,
    Color? vibrantColor,
    Color? lightVibrantColor,
    String? audioSpec,
  }) {
    final selected = initialSelectedLine != null
        ? [initialSelectedLine]
        : (allLines.isNotEmpty ? [allLines.first] : <LyricsLine>[]);

    final config = LyricShareConfig(
      track: track,
      selectedLines: selected,
      ratio: LyricCardRatio.story_9_16,
      backgroundMode: LyricCardBackgroundMode.blurredArtwork,
      preset: LyricCardThemePreset.dynamicAlbumArt,
      showAudioSpecsBadge: true,
      showBranding: true,
      showRomanized: false,
      customAudioSpec: audioSpec,
    );

    final colors = LyricCardColors.forBlurredArtwork(
      accentColor: vibrantColor ?? lightVibrantColor,
    );

    return LyricShareState(
      config: config,
      allLines: allLines,
      colors: colors,
      dominantAlbumColor: dominantColor,
      vibrantAlbumColor: vibrantColor,
      lightVibrantAlbumColor: lightVibrantColor,
    );
  }

  /// Extract palette colors asynchronously from album artwork
  Future<void> extractPaletteFromTrack(Track track) async {
    final provider = StudioArtworkWidget.getImageProvider(track);
    if (provider == null) return;

    state = state.copyWith(isExtractingPalette: true);

    try {
      final generator = await PaletteGenerator.fromImageProvider(
        ResizeImage(provider, width: 96, height: 96),
        maximumColorCount: 16,
      );

      final swatches = <Color>[];
      void addIfValid(Color? c) {
        if (c != null && !swatches.any((existing) => _isColorClose(existing, c))) {
          swatches.add(c);
        }
      }

      addIfValid(generator.dominantColor?.color);
      addIfValid(generator.vibrantColor?.color);
      addIfValid(generator.lightVibrantColor?.color);
      addIfValid(generator.darkVibrantColor?.color);
      addIfValid(generator.mutedColor?.color);
      addIfValid(generator.darkMutedColor?.color);
      addIfValid(generator.lightMutedColor?.color);

      final dominant = generator.dominantColor?.color ?? state.dominantAlbumColor;
      final vibrant = generator.vibrantColor?.color ?? state.vibrantAlbumColor;
      final lightVibrant = generator.lightVibrantColor?.color ?? state.lightVibrantAlbumColor;

      // If current mode is dynamic palette or blurred, update resolved colors with extracted accent
      LyricCardColors updatedColors = state.colors;
      if (state.config.backgroundMode == LyricCardBackgroundMode.blurredArtwork) {
        updatedColors = LyricCardColors.forBlurredArtwork(accentColor: vibrant ?? lightVibrant);
      } else if (state.config.backgroundMode == LyricCardBackgroundMode.albumPalette) {
        final base = state.config.selectedPaletteColor ?? dominant ?? const Color(0xFF1E222B);
        updatedColors = LyricCardColors.fromDynamicColor(base, accentColor: vibrant ?? lightVibrant);
      }

      state = state.copyWith(
        dominantAlbumColor: dominant,
        vibrantAlbumColor: vibrant,
        lightVibrantAlbumColor: lightVibrant,
        extractedPaletteSwatches: swatches,
        colors: updatedColors,
        isExtractingPalette: false,
      );
    } catch (e) {
      debugPrint('[LyricShareController] Palette extraction error: $e');
      state = state.copyWith(isExtractingPalette: false);
    }
  }

  static bool _isColorClose(Color a, Color b) {
    final dr = ((a.r * 255.0) - (b.r * 255.0)).abs();
    final dg = ((a.g * 255.0) - (b.g * 255.0)).abs();
    final db = ((a.b * 255.0) - (b.b * 255.0)).abs();
    return (dr + dg + db) < 35.0;
  }

  /// Change card background visual mode
  void setBackgroundMode(LyricCardBackgroundMode mode) {
    LyricCardColors newColors;
    switch (mode) {
      case LyricCardBackgroundMode.blurredArtwork:
        newColors = LyricCardColors.forBlurredArtwork(
          accentColor: state.vibrantAlbumColor ?? state.lightVibrantAlbumColor,
        );
        break;

      case LyricCardBackgroundMode.albumPalette:
        final base = state.config.selectedPaletteColor ??
            state.dominantAlbumColor ??
            (state.extractedPaletteSwatches.isNotEmpty
                ? state.extractedPaletteSwatches.first
                : const Color(0xFF1E222B));
        newColors = LyricCardColors.fromDynamicColor(
          base,
          accentColor: state.vibrantAlbumColor ?? state.lightVibrantAlbumColor,
        );
        break;

      case LyricCardBackgroundMode.studioPreset:
        newColors = LyricCardColors.fromPreset(
          state.config.preset,
          dominantAlbumColor: state.dominantAlbumColor,
          vibrantAlbumColor: state.vibrantAlbumColor,
          lightVibrantAlbumColor: state.lightVibrantAlbumColor,
        );
        break;

      case LyricCardBackgroundMode.customColor:
        final custom = state.config.customBackgroundColor ?? const Color(0xFF1E293B);
        newColors = LyricCardColors.fromCustomColor(custom);
        break;
    }

    final newConfig = state.config.copyWith(backgroundMode: mode);
    state = state.copyWith(
      config: newConfig,
      colors: newColors,
      clearStatus: true,
    );
  }

  /// Select a specific palette swatch extracted from album artwork
  void selectPaletteColor(Color color) {
    final newConfig = state.config.copyWith(
      backgroundMode: LyricCardBackgroundMode.albumPalette,
      selectedPaletteColor: color,
    );
    final newColors = LyricCardColors.fromDynamicColor(
      color,
      accentColor: state.vibrantAlbumColor ?? state.lightVibrantAlbumColor,
    );
    state = state.copyWith(
      config: newConfig,
      colors: newColors,
      clearStatus: true,
    );
  }

  /// Select a custom solid background color
  void setCustomColor(Color color) {
    final newConfig = state.config.copyWith(
      backgroundMode: LyricCardBackgroundMode.customColor,
      customBackgroundColor: color,
    );
    final newColors = LyricCardColors.fromCustomColor(color);
    state = state.copyWith(
      config: newConfig,
      colors: newColors,
      clearStatus: true,
    );
  }

  /// Toggle selection for a given line, keeping selection within 1-5 contiguous lines
  void toggleLineSelection(LyricsLine line) {
    final current = List<LyricsLine>.from(state.config.selectedLines);
    final all = state.allLines;

    if (current.contains(line)) {
      if (current.length > 1) {
        current.remove(line);
      } else {
        // Keep at least one line or toggle off
        current.clear();
      }
    } else {
      if (current.isEmpty) {
        current.add(line);
      } else {
        // If adding a line, calculate contiguous range between minimum and maximum index
        final lineIndex = all.indexOf(line);
        if (lineIndex != -1) {
          final indices = current.map((l) => all.indexOf(l)).where((i) => i != -1).toList();
          indices.add(lineIndex);
          indices.sort();

          final minIdx = indices.first;
          final maxIdx = indices.last;

          // Limit to maxSelectedLines (5 lines)
          if ((maxIdx - minIdx + 1) <= LyricShareConfig.maxSelectedLines) {
            current.clear();
            for (int i = minIdx; i <= maxIdx; i++) {
              if (i < all.length) {
                current.add(all[i]);
              }
            }
          } else {
            // If clicked line is far away, start a new single selection
            current.clear();
            current.add(line);
          }
        }
      }
    }

    final newConfig = state.config.copyWith(selectedLines: current);
    state = state.copyWith(config: newConfig, clearStatus: true);
  }

  /// Change card aspect ratio (9:16 Story vs 1:1 Square vs 4:5 Portrait)
  void setRatio(LyricCardRatio ratio) {
    final newConfig = state.config.copyWith(ratio: ratio);
    state = state.copyWith(config: newConfig, clearStatus: true);
  }

  /// Change theme preset (Dynamic, OLED, Mint, Sky, Warm Amber, Rose)
  void setPreset(LyricCardThemePreset preset) {
    final newConfig = state.config.copyWith(
      preset: preset,
      backgroundMode: LyricCardBackgroundMode.studioPreset,
    );
    final newColors = LyricCardColors.fromPreset(
      preset,
      dominantAlbumColor: state.dominantAlbumColor,
      vibrantAlbumColor: state.vibrantAlbumColor,
      lightVibrantAlbumColor: state.lightVibrantAlbumColor,
    );
    state = state.copyWith(
      config: newConfig,
      colors: newColors,
      clearStatus: true,
    );
  }

  /// Toggle audio specs badge visibility
  void toggleAudioSpecs(bool value) {
    final newConfig = state.config.copyWith(showAudioSpecsBadge: value);
    state = state.copyWith(config: newConfig, clearStatus: true);
  }

  /// Toggle branding visibility
  void toggleBranding(bool value) {
    final newConfig = state.config.copyWith(showBranding: value);
    state = state.copyWith(config: newConfig, clearStatus: true);
  }

  /// Toggle phonetic/romanized lyric lines
  void toggleRomanized(bool value) {
    final newConfig = state.config.copyWith(showRomanized: value);
    state = state.copyWith(config: newConfig, clearStatus: true);
  }

  /// Set typography font family (Sans, Serif, Monospace, Cursive)
  void setFontFamily(LyricCardFontFamily fontFamily) {
    final newConfig = state.config.copyWith(fontFamily: fontFamily);
    state = state.copyWith(config: newConfig, clearStatus: true);
  }

  /// Set font size scale multiplier (0.7x - 1.5x)
  void setFontSizeMultiplier(double multiplier) {
    final newConfig = state.config.copyWith(fontSizeMultiplier: multiplier.clamp(0.65, 1.6));
    state = state.copyWith(config: newConfig, clearStatus: true);
  }

  /// Set text styling and highlight effect (None, Stroke/Border, Instagram Pill, Spotify Glow)
  void setHighlightStyle(LyricCardHighlightStyle style) {
    final newConfig = state.config.copyWith(highlightStyle: style);
    state = state.copyWith(config: newConfig, clearStatus: true);
  }

  /// Set text border / outline stroke width (1.0px to 6.0px)
  void setStrokeWidth(double width) {
    final newConfig = state.config.copyWith(strokeWidth: width.clamp(1.0, 6.0));
    state = state.copyWith(config: newConfig, clearStatus: true);
  }

  /// Set background blur sigma for blurred artwork mode (0.0 to 60.0)
  void setBackgroundBlurSigma(double sigma) {
    final newConfig = state.config.copyWith(backgroundBlurSigma: sigma.clamp(0.0, 60.0));
    state = state.copyWith(config: newConfig, clearStatus: true);
  }

  /// Set background dim opacity (0.10 to 0.95)
  void setBackgroundDimOpacity(double opacity) {
    final newConfig = state.config.copyWith(backgroundDimOpacity: opacity.clamp(0.10, 0.95));
    state = state.copyWith(config: newConfig, clearStatus: true);
  }

  /// Set line spacing multiplier (0.6x to 2.0x)
  void setLineSpacingMultiplier(double multiplier) {
    final newConfig = state.config.copyWith(lineSpacingMultiplier: multiplier.clamp(0.6, 2.0));
    state = state.copyWith(config: newConfig, clearStatus: true);
  }

  /// Set letter spacing (-1.0 to 3.0)
  void setLetterSpacing(double spacing) {
    final newConfig = state.config.copyWith(letterSpacing: spacing.clamp(-1.0, 3.0));
    state = state.copyWith(config: newConfig, clearStatus: true);
  }

  /// Set font weight
  void setFontWeight(FontWeight weight) {
    final newConfig = state.config.copyWith(fontWeight: weight);
    state = state.copyWith(config: newConfig, clearStatus: true);
  }

  /// Toggle bold font weight
  void toggleBold() {
    final isCurrentlyBold = state.config.fontWeight == FontWeight.w700 ||
        state.config.fontWeight == FontWeight.w800 ||
        state.config.fontWeight == FontWeight.w900;
    final newWeight = isCurrentlyBold ? FontWeight.w400 : FontWeight.w700;
    final newConfig = state.config.copyWith(fontWeight: newWeight);
    state = state.copyWith(config: newConfig, clearStatus: true);
  }

  /// Toggle italic font style
  void toggleItalic(bool isItalic) {
    final newConfig = state.config.copyWith(isItalic: isItalic);
    state = state.copyWith(config: newConfig, clearStatus: true);
  }

  /// Set text alignment (left, center, right)
  void setTextAlign(TextAlign align) {
    final newConfig = state.config.copyWith(textAlign: align);
    state = state.copyWith(config: newConfig, clearStatus: true);
  }

  /// Set or reset custom audio spec badge text
  void setCustomAudioSpec(String? text) {
    final clean = (text != null && text.trim().isNotEmpty) ? text.trim() : null;
    final newConfig = state.config.copyWith(
      customAudioSpec: clean,
      clearCustomAudioSpec: clean == null,
    );
    state = state.copyWith(config: newConfig, clearStatus: true);
  }

  /// Set layout style template
  void setLayoutStyle(LyricCardLayoutStyle style) {
    final newConfig = state.config.copyWith(layoutStyle: style);
    state = state.copyWith(config: newConfig, clearStatus: true);
  }

  /// Toggle or set dual-line East Asian Romanization subtitles
  void toggleDualLineRomanized(bool value) {
    final newConfig = state.config.copyWith(showDualLineRomanized: value);
    state = state.copyWith(config: newConfig, clearStatus: true);
  }

  /// Set optional personal note / quote caption
  void setPersonalNote(String? note) {
    final clean = (note != null && note.trim().isNotEmpty) ? note.trim() : null;
    final newConfig = state.config.copyWith(
      personalNote: clean,
      clearPersonalNote: clean == null,
    );
    state = state.copyWith(config: newConfig, clearStatus: true);
  }

  /// Toggle sticker selection (max 3 stickers)
  void toggleSticker(LyricStickerType sticker) {
    final current = List<LyricStickerType>.from(state.config.selectedStickers);
    if (current.contains(sticker)) {
      current.remove(sticker);
    } else {
      if (current.length >= 3) {
        current.removeAt(0); // Cycle oldest sticker if exceeding limit
      }
      current.add(sticker);
    }
    final newConfig = state.config.copyWith(selectedStickers: current);
    state = state.copyWith(config: newConfig, clearStatus: true);
  }

  /// Set selected stickers directly
  void setStickers(List<LyricStickerType> stickers) {
    final newConfig = state.config.copyWith(selectedStickers: stickers);
    state = state.copyWith(config: newConfig, clearStatus: true);
  }

  /// Set complete audiophile telemetry stamp configuration
  void setAudiophileStamp(AudiophileStampConfig stampConfig) {
    final newConfig = state.config.copyWith(audiophileStamp: stampConfig);
    state = state.copyWith(config: newConfig, clearStatus: true);
  }

  /// Update partial audiophile telemetry stamp fields
  void updateAudiophileStamp({
    bool? enabled,
    bool? showFormatRate,
    bool? showAutoEqProfile,
    bool? showVirtualDspChain,
    bool? showHardwareDac,
    bool? showTimestamp,
    String? customDacName,
    String? customAutoEqName,
    String? customDspChainName,
  }) {
    final updatedStamp = state.config.audiophileStamp.copyWith(
      enabled: enabled,
      showFormatRate: showFormatRate,
      showAutoEqProfile: showAutoEqProfile,
      showVirtualDspChain: showVirtualDspChain,
      showHardwareDac: showHardwareDac,
      showTimestamp: showTimestamp,
      customDacName: customDacName,
      customAutoEqName: customAutoEqName,
      customDspChainName: customDspChainName,
    );
    final newConfig = state.config.copyWith(audiophileStamp: updatedStamp);
    state = state.copyWith(config: newConfig, clearStatus: true);
  }

  /// Toggle QR code badge deep link
  void toggleQrCode(bool value) {
    final newConfig = state.config.copyWith(showQrCode: value);
    state = state.copyWith(config: newConfig, clearStatus: true);
  }

  /// Capture and share the lyric card to social media via native OS sheet
  Future<ShareActionResult> shareLyricCard(GlobalKey boundaryKey) async {
    if (state.config.selectedLines.isEmpty) {
      state = state.copyWith(errorMessage: 'Please select at least 1 line to share.');
      return const ShareActionResult(
        success: false,
        errorMessage: 'Please select at least 1 line to share.',
      );
    }

    state = state.copyWith(isRendering: true, clearStatus: true);

    try {
      final result = await LyricImageGenerator.captureAndShare(
        boundaryKey,
        pixelRatio: 3.0,
        trackTitle: state.config.track.title,
        artistName: state.config.track.artist,
      );

      state = state.copyWith(
        isRendering: false,
        savedFilePath: result.savedFilePath,
        isMissingPlugin: result.isMissingPlugin,
        successMessage: result.success ? (result.errorMessage ?? 'Shared successfully!') : null,
        errorMessage: result.success ? null : result.errorMessage,
      );
      return result;
    } catch (e) {
      state = state.copyWith(
        isRendering: false,
        errorMessage: 'Failed to generate lyric image: $e',
      );
      return ShareActionResult(
        success: false,
        errorMessage: 'Failed to generate lyric image: $e',
      );
    }
  }

  /// Save image bytes directly to the device's public Pictures/Gallery directory
  Future<String?> saveImageLocally(GlobalKey boundaryKey) async {
    if (state.config.selectedLines.isEmpty) {
      state = state.copyWith(errorMessage: 'Please select at least 1 line.');
      return null;
    }

    state = state.copyWith(isRendering: true, clearStatus: true);

    try {
      final bytes = await LyricImageGenerator.capturePng(boundaryKey, pixelRatio: 3.0);
      if (bytes == null) {
        state = state.copyWith(
          isRendering: false,
          errorMessage: 'Could not rasterize lyric card.',
        );
        return null;
      }

      final file = await LyricImageGenerator.saveBytesToPublicGallery(bytes);
      state = state.copyWith(
        isRendering: false,
        savedFilePath: file?.path,
        successMessage: 'Saved to Gallery / Pictures: ${file?.path}',
      );
      return file?.path;
    } catch (e) {
      state = state.copyWith(
        isRendering: false,
        errorMessage: 'Save error: $e',
      );
      return null;
    }
  }
}
