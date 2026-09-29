import 'package:flutter/foundation.dart';

enum AlbumArtStyle {
  squircle('Default Squircle', 'Modern 28px squircle with dynamic ambient glow'),
  square('Square Studio', 'Sharp 8px studio monitor card with crisp 1px borders'),
  disc('Minimalist Disc', 'Circular CD audio disc with orbital rim'),
  vinyl('Vinyl Record', 'Classic spinning vinyl with groove ridges and center label'),
  turntable('Turntable & Tonearm', 'Spinning vinyl record with animated metallic tonearm needle'),
  cassette('Retro Cassette Tape', 'Analog cassette tape with dual rotating spools and tape window'),
  cdJewel('CD Jewel Case', 'Acrylic jewel case with spine tray and hologram optical sheen');

  final String label;
  final String description;
  const AlbumArtStyle(this.label, this.description);

  static AlbumArtStyle fromString(String? val) {
    for (final s in AlbumArtStyle.values) {
      if (s.name == val) return s;
    }
    return AlbumArtStyle.squircle;
  }
}

enum SpectrumStyle {
  bars('Multi-Band Bars', 'High-density multi-frequency FFT studio bars'),
  wave('Liquid Wave', 'Smooth anti-aliased gradient Bezier sound wave'),
  dots('Peak Dots', 'Pulsing audiophile matrix peak dots'),
  beam('Laser Beam', 'Minimalist glowing laser beam line'),
  mirrorWave('Mirror Symmetrical Wave', 'Center-aligned dual vertical mirror wave'),
  vuMeter('Dual Analog VU Dials', 'Classic stereo L/R analog needle VU meters'),
  circular('Circular Orbit Ring', '360-degree radial frequency orbit ring');

  final String label;
  final String description;
  const SpectrumStyle(this.label, this.description);

  static SpectrumStyle fromString(String? val) {
    for (final s in SpectrumStyle.values) {
      if (s.name == val) return s;
    }
    return SpectrumStyle.bars;
  }
}

enum TimeBarStyle {
  slim('Slim Studio', 'Precision 3.5px studio track with tabular figures'),
  capsule('Hi-Fi Capsule', 'Thick 8px solid capsule seekbar'),
  segmented('Segmented LED', 'Multi-segment audiophile VU meter time bar'),
  waveform('Waveform Bar', 'Acoustic waveform profile seekbar'),
  ruler('Timecode Precision Ruler', 'Studio ruler grid with sub-second tick marks'),
  glowingPill('Floating Pill Indicator', 'Clean continuous floating pill seekbar');

  final String label;
  final String description;
  const TimeBarStyle(this.label, this.description);

  static TimeBarStyle fromString(String? val) {
    for (final s in TimeBarStyle.values) {
      if (s.name == val) return s;
    }
    return TimeBarStyle.slim;
  }
}

enum PerformanceMode {
  studioHiFi('Studio HiFi (120 FPS)', 'Maximum visual dynamics, high-frequency FFT, 3D parallax & ambient glow'),
  balanced('Balanced (60 FPS)', 'Optimized smooth 60fps refresh rate with gentle effects'),
  batterySaver('Battery Saver (30 FPS)', 'Minimalist lightweight rendering, no heavy shaders to preserve battery'),
  custom('Custom Profile', 'User-defined granular visual parameters');

  final String label;
  final String description;
  const PerformanceMode(this.label, this.description);

  static PerformanceMode fromString(String? val) {
    for (final m in PerformanceMode.values) {
      if (m.name == val) return m;
    }
    return PerformanceMode.studioHiFi;
  }
}

enum ArtworkGestureAction {
  toggleLyrics('Toggle Lyrics', 'Switch between Album Art and Synchronized Lyrics'),
  togglePlayPause('Play / Pause', 'Toggle playback state immediately'),
  toggleFavorite('Toggle Favorite', 'Add or remove track from library favorites'),
  openInspector('File Inspector', 'Inspect codec, bitrate, sample rate & audio container metadata'),
  openProQStudio('Pro-Q Studio EQ', 'Open interactive 32-band Parametric Equalizer'),
  openDspRack('Mastering DSP Rack', 'Open 10-module hardware mastering DSP rack'),
  openQueue('Up Next Queue', 'Open active playback queue bottom sheet'),
  none('No Action', 'Do nothing on gesture trigger');

  final String label;
  final String description;
  const ArtworkGestureAction(this.label, this.description);

  static ArtworkGestureAction fromString(String? val, [ArtworkGestureAction fallback = ArtworkGestureAction.none]) {
    for (final a in ArtworkGestureAction.values) {
      if (a.name == val) return a;
    }
    return fallback;
  }
}

enum TrackTileSwipeAction {
  addToQueue('Add to Queue', 'Append track to the end of current playing queue'),
  playNext('Play Next', 'Insert track directly after the active playing track'),
  toggleFavorite('Toggle Favorite', 'Toggle favorite status in music library'),
  addToPlaylist('Add to Playlist', 'Open dialog to add track into custom playlists'),
  none('No Action', 'Disable swipe action');

  final String label;
  final String description;
  const TrackTileSwipeAction(this.label, this.description);

  static TrackTileSwipeAction fromString(String? val, [TrackTileSwipeAction fallback = TrackTileSwipeAction.none]) {
    for (final a in TrackTileSwipeAction.values) {
      if (a.name == val) return a;
    }
    return fallback;
  }
}

@immutable
class PlayerCustomizationSettings {
  final AlbumArtStyle albumArtStyle;
  final SpectrumStyle spectrumStyle;
  final TimeBarStyle timeBarStyle;
  final bool ambientGlow;
  final double ambientGlowIntensity;
  final int fftBins;

  // Visual dynamics & Parallax
  final PerformanceMode performanceMode;
  final bool enableParallax;
  final double parallaxIntensity;
  final bool enableBackdropBlur;
  final double blurSigma;
  final bool enableBreathingPulse;

  // Artwork Gestures
  final ArtworkGestureAction singleTapAction;
  final ArtworkGestureAction doubleTapAction;
  final ArtworkGestureAction longPressAction;

  // Track Tile Layout & Gestures
  final bool trackTitleFirst;
  final bool trackShowFormatBadge;
  final bool trackShowBitrate;
  final bool trackShowDuration;
  final bool trackShowDirectFav;
  final TrackTileSwipeAction trackSwipeLeft;
  final TrackTileSwipeAction trackSwipeRight;

  const PlayerCustomizationSettings({
    this.albumArtStyle = AlbumArtStyle.squircle,
    this.spectrumStyle = SpectrumStyle.bars,
    this.timeBarStyle = TimeBarStyle.slim,
    this.ambientGlow = true,
    this.ambientGlowIntensity = 0.35,
    this.fftBins = 512,
    this.performanceMode = PerformanceMode.studioHiFi,
    this.enableParallax = true,
    this.parallaxIntensity = 1.0,
    this.enableBackdropBlur = true,
    this.blurSigma = 18.0,
    this.enableBreathingPulse = true,
    this.singleTapAction = ArtworkGestureAction.toggleLyrics,
    this.doubleTapAction = ArtworkGestureAction.toggleFavorite,
    this.longPressAction = ArtworkGestureAction.openInspector,
    this.trackTitleFirst = true,
    this.trackShowFormatBadge = true,
    this.trackShowBitrate = true,
    this.trackShowDuration = true,
    this.trackShowDirectFav = true,
    this.trackSwipeLeft = TrackTileSwipeAction.addToQueue,
    this.trackSwipeRight = TrackTileSwipeAction.toggleFavorite,
  });

  PlayerCustomizationSettings copyWith({
    AlbumArtStyle? albumArtStyle,
    SpectrumStyle? spectrumStyle,
    TimeBarStyle? timeBarStyle,
    bool? ambientGlow,
    double? ambientGlowIntensity,
    int? fftBins,
    PerformanceMode? performanceMode,
    bool? enableParallax,
    double? parallaxIntensity,
    bool? enableBackdropBlur,
    double? blurSigma,
    bool? enableBreathingPulse,
    ArtworkGestureAction? singleTapAction,
    ArtworkGestureAction? doubleTapAction,
    ArtworkGestureAction? longPressAction,
    bool? trackTitleFirst,
    bool? trackShowFormatBadge,
    bool? trackShowBitrate,
    bool? trackShowDuration,
    bool? trackShowDirectFav,
    TrackTileSwipeAction? trackSwipeLeft,
    TrackTileSwipeAction? trackSwipeRight,
  }) {
    return PlayerCustomizationSettings(
      albumArtStyle: albumArtStyle ?? this.albumArtStyle,
      spectrumStyle: spectrumStyle ?? this.spectrumStyle,
      timeBarStyle: timeBarStyle ?? this.timeBarStyle,
      ambientGlow: ambientGlow ?? this.ambientGlow,
      ambientGlowIntensity: ambientGlowIntensity ?? this.ambientGlowIntensity,
      fftBins: fftBins ?? this.fftBins,
      performanceMode: performanceMode ?? this.performanceMode,
      enableParallax: enableParallax ?? this.enableParallax,
      parallaxIntensity: parallaxIntensity ?? this.parallaxIntensity,
      enableBackdropBlur: enableBackdropBlur ?? this.enableBackdropBlur,
      blurSigma: blurSigma ?? this.blurSigma,
      enableBreathingPulse: enableBreathingPulse ?? this.enableBreathingPulse,
      singleTapAction: singleTapAction ?? this.singleTapAction,
      doubleTapAction: doubleTapAction ?? this.doubleTapAction,
      longPressAction: longPressAction ?? this.longPressAction,
      trackTitleFirst: trackTitleFirst ?? this.trackTitleFirst,
      trackShowFormatBadge: trackShowFormatBadge ?? this.trackShowFormatBadge,
      trackShowBitrate: trackShowBitrate ?? this.trackShowBitrate,
      trackShowDuration: trackShowDuration ?? this.trackShowDuration,
      trackShowDirectFav: trackShowDirectFav ?? this.trackShowDirectFav,
      trackSwipeLeft: trackSwipeLeft ?? this.trackSwipeLeft,
      trackSwipeRight: trackSwipeRight ?? this.trackSwipeRight,
    );
  }
}
