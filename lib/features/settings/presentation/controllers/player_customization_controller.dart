import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/local_persistence_service.dart';
import '../../domain/player_customization_settings.dart';

final playerCustomizationProvider =
    StateNotifierProvider<PlayerCustomizationNotifier, PlayerCustomizationSettings>((ref) {
  return PlayerCustomizationNotifier();
});

class PlayerCustomizationNotifier extends StateNotifier<PlayerCustomizationSettings> {
  PlayerCustomizationNotifier() : super(const PlayerCustomizationSettings()) {
    _loadSettings();
  }

  void _loadSettings() {
    final storage = LocalPersistenceService.instance;
    final artStyleStr = storage.getSetting<String>('player_album_art_style');
    final specStyleStr = storage.getSetting<String>('player_spectrum_style');
    final timeStyleStr = storage.getSetting<String>('player_timebar_style');
    final glow = storage.getSetting<bool>('player_ambient_glow', true) ?? true;
    final glowIntensity = storage.getSetting<double>('player_ambient_glow_intensity', 0.35) ?? 0.35;
    final bins = storage.getSetting<int>('player_fft_bins', 512) ?? 512;

    final perfModeStr = storage.getSetting<String>('player_perf_mode');
    final parallax = storage.getSetting<bool>('player_enable_parallax', true) ?? true;
    final parallaxInt = storage.getSetting<double>('player_parallax_intensity', 1.0) ?? 1.0;
    final backdropBlur = storage.getSetting<bool>('player_backdrop_blur', true) ?? true;
    final blurSigma = storage.getSetting<double>('player_blur_sigma', 18.0) ?? 18.0;
    final pulse = storage.getSetting<bool>('player_breathing_pulse', true) ?? true;

    final singleTapStr = storage.getSetting<String>('player_art_single_tap');
    final doubleTapStr = storage.getSetting<String>('player_art_double_tap');
    final longPressStr = storage.getSetting<String>('player_art_long_press');

    final titleFirst = storage.getSetting<bool>('track_tile_title_first', true) ?? true;
    final showBadge = storage.getSetting<bool>('track_tile_show_badge', true) ?? true;
    final showBitrate = storage.getSetting<bool>('track_tile_show_bitrate', true) ?? true;
    final showDuration = storage.getSetting<bool>('track_tile_show_duration', true) ?? true;
    final showDirectFav = storage.getSetting<bool>('track_tile_show_direct_fav', true) ?? true;
    final swipeLeftStr = storage.getSetting<String>('track_tile_swipe_left');
    final swipeRightStr = storage.getSetting<String>('track_tile_swipe_right');

    state = PlayerCustomizationSettings(
      albumArtStyle: AlbumArtStyle.fromString(artStyleStr),
      spectrumStyle: SpectrumStyle.fromString(specStyleStr),
      timeBarStyle: TimeBarStyle.fromString(timeStyleStr),
      ambientGlow: glow,
      ambientGlowIntensity: glowIntensity,
      fftBins: bins,
      performanceMode: PerformanceMode.fromString(perfModeStr),
      enableParallax: parallax,
      parallaxIntensity: parallaxInt,
      enableBackdropBlur: backdropBlur,
      blurSigma: blurSigma,
      enableBreathingPulse: pulse,
      singleTapAction: ArtworkGestureAction.fromString(singleTapStr, ArtworkGestureAction.toggleLyrics),
      doubleTapAction: ArtworkGestureAction.fromString(doubleTapStr, ArtworkGestureAction.toggleFavorite),
      longPressAction: ArtworkGestureAction.fromString(longPressStr, ArtworkGestureAction.openInspector),
      trackTitleFirst: titleFirst,
      trackShowFormatBadge: showBadge,
      trackShowBitrate: showBitrate,
      trackShowDuration: showDuration,
      trackShowDirectFav: showDirectFav,
      trackSwipeLeft: TrackTileSwipeAction.fromString(swipeLeftStr, TrackTileSwipeAction.addToQueue),
      trackSwipeRight: TrackTileSwipeAction.fromString(swipeRightStr, TrackTileSwipeAction.toggleFavorite),
    );
  }

  Future<void> setAlbumArtStyle(AlbumArtStyle style) async {
    state = state.copyWith(albumArtStyle: style);
    await LocalPersistenceService.instance.saveSetting('player_album_art_style', style.name);
  }

  Future<void> setSpectrumStyle(SpectrumStyle style) async {
    state = state.copyWith(spectrumStyle: style);
    await LocalPersistenceService.instance.saveSetting('player_spectrum_style', style.name);
  }

  Future<void> setTimeBarStyle(TimeBarStyle style) async {
    state = state.copyWith(timeBarStyle: style);
    await LocalPersistenceService.instance.saveSetting('player_timebar_style', style.name);
  }

  Future<void> setAmbientGlow(bool glow) async {
    state = state.copyWith(ambientGlow: glow);
    await LocalPersistenceService.instance.saveSetting('player_ambient_glow', glow);
  }

  Future<void> setAmbientGlowIntensity(double intensity) async {
    state = state.copyWith(ambientGlowIntensity: intensity);
    await LocalPersistenceService.instance.saveSetting('player_ambient_glow_intensity', intensity);
  }

  Future<void> setFftBins(int bins) async {
    state = state.copyWith(fftBins: bins);
    await LocalPersistenceService.instance.saveSetting('player_fft_bins', bins);
  }

  Future<void> setPerformanceMode(PerformanceMode mode) async {
    switch (mode) {
      case PerformanceMode.studioHiFi:
        state = state.copyWith(
          performanceMode: mode,
          enableParallax: true,
          parallaxIntensity: 1.0,
          ambientGlow: true,
          ambientGlowIntensity: 0.35,
          enableBackdropBlur: true,
          blurSigma: 18.0,
          enableBreathingPulse: true,
          fftBins: 512,
        );
        break;
      case PerformanceMode.balanced:
        state = state.copyWith(
          performanceMode: mode,
          enableParallax: true,
          parallaxIntensity: 0.6,
          ambientGlow: true,
          ambientGlowIntensity: 0.25,
          enableBackdropBlur: true,
          blurSigma: 12.0,
          enableBreathingPulse: false,
          fftBins: 256,
        );
        break;
      case PerformanceMode.batterySaver:
        state = state.copyWith(
          performanceMode: mode,
          enableParallax: false,
          parallaxIntensity: 0.0,
          ambientGlow: false,
          ambientGlowIntensity: 0.0,
          enableBackdropBlur: false,
          blurSigma: 0.0,
          enableBreathingPulse: false,
          fftBins: 256,
        );
        break;
      case PerformanceMode.custom:
        state = state.copyWith(performanceMode: mode);
        break;
    }

    final storage = LocalPersistenceService.instance;
    await storage.saveSetting('player_perf_mode', mode.name);
    await storage.saveSetting('player_enable_parallax', state.enableParallax);
    await storage.saveSetting('player_parallax_intensity', state.parallaxIntensity);
    await storage.saveSetting('player_ambient_glow', state.ambientGlow);
    await storage.saveSetting('player_ambient_glow_intensity', state.ambientGlowIntensity);
    await storage.saveSetting('player_backdrop_blur', state.enableBackdropBlur);
    await storage.saveSetting('player_blur_sigma', state.blurSigma);
    await storage.saveSetting('player_breathing_pulse', state.enableBreathingPulse);
    await storage.saveSetting('player_fft_bins', state.fftBins);
  }

  Future<void> setEnableParallax(bool enable) async {
    state = state.copyWith(enableParallax: enable, performanceMode: PerformanceMode.custom);
    await LocalPersistenceService.instance.saveSetting('player_enable_parallax', enable);
    await LocalPersistenceService.instance.saveSetting('player_perf_mode', PerformanceMode.custom.name);
  }

  Future<void> setParallaxIntensity(double intensity) async {
    state = state.copyWith(parallaxIntensity: intensity, performanceMode: PerformanceMode.custom);
    await LocalPersistenceService.instance.saveSetting('player_parallax_intensity', intensity);
    await LocalPersistenceService.instance.saveSetting('player_perf_mode', PerformanceMode.custom.name);
  }

  Future<void> setEnableBackdropBlur(bool enable) async {
    state = state.copyWith(enableBackdropBlur: enable, performanceMode: PerformanceMode.custom);
    await LocalPersistenceService.instance.saveSetting('player_backdrop_blur', enable);
    await LocalPersistenceService.instance.saveSetting('player_perf_mode', PerformanceMode.custom.name);
  }

  Future<void> setBlurSigma(double sigma) async {
    state = state.copyWith(blurSigma: sigma, performanceMode: PerformanceMode.custom);
    await LocalPersistenceService.instance.saveSetting('player_blur_sigma', sigma);
    await LocalPersistenceService.instance.saveSetting('player_perf_mode', PerformanceMode.custom.name);
  }

  Future<void> setEnableBreathingPulse(bool enable) async {
    state = state.copyWith(enableBreathingPulse: enable, performanceMode: PerformanceMode.custom);
    await LocalPersistenceService.instance.saveSetting('player_breathing_pulse', enable);
    await LocalPersistenceService.instance.saveSetting('player_perf_mode', PerformanceMode.custom.name);
  }

  Future<void> setSingleTapAction(ArtworkGestureAction action) async {
    state = state.copyWith(singleTapAction: action);
    await LocalPersistenceService.instance.saveSetting('player_art_single_tap', action.name);
  }

  Future<void> setDoubleTapAction(ArtworkGestureAction action) async {
    state = state.copyWith(doubleTapAction: action);
    await LocalPersistenceService.instance.saveSetting('player_art_double_tap', action.name);
  }

  Future<void> setLongPressAction(ArtworkGestureAction action) async {
    state = state.copyWith(longPressAction: action);
    await LocalPersistenceService.instance.saveSetting('player_art_long_press', action.name);
  }

  Future<void> setTrackTitleFirst(bool val) async {
    state = state.copyWith(trackTitleFirst: val);
    await LocalPersistenceService.instance.saveSetting('track_tile_title_first', val);
  }

  Future<void> setTrackShowFormatBadge(bool val) async {
    state = state.copyWith(trackShowFormatBadge: val);
    await LocalPersistenceService.instance.saveSetting('track_tile_show_badge', val);
  }

  Future<void> setTrackShowBitrate(bool val) async {
    state = state.copyWith(trackShowBitrate: val);
    await LocalPersistenceService.instance.saveSetting('track_tile_show_bitrate', val);
  }

  Future<void> setTrackShowDuration(bool val) async {
    state = state.copyWith(trackShowDuration: val);
    await LocalPersistenceService.instance.saveSetting('track_tile_show_duration', val);
  }

  Future<void> setTrackShowDirectFav(bool val) async {
    state = state.copyWith(trackShowDirectFav: val);
    await LocalPersistenceService.instance.saveSetting('track_tile_show_direct_fav', val);
  }

  Future<void> setTrackSwipeLeft(TrackTileSwipeAction action) async {
    state = state.copyWith(trackSwipeLeft: action);
    await LocalPersistenceService.instance.saveSetting('track_tile_swipe_left', action.name);
  }

  Future<void> setTrackSwipeRight(TrackTileSwipeAction action) async {
    state = state.copyWith(trackSwipeRight: action);
    await LocalPersistenceService.instance.saveSetting('track_tile_swipe_right', action.name);
  }
}
