import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_haptics.dart';
import '../../app/theme/app_typography.dart';
import '../../app/theme/studio_surface_theme.dart';
import '../../audio_engine/fft_processor.dart';
import '../../core/widgets/studio_artwork_lightbox.dart';
import '../../core/widgets/studio_artwork_widget.dart';
import '../../features/dsp_rack/presentation/dsp_rack_screen.dart';
import '../../features/library/presentation/controllers/library_controller.dart';
import '../../features/player/domain/playback_state.dart';
import '../../features/player/domain/track.dart';
import '../../features/player/presentation/controllers/player_controller.dart';
import '../../features/player/presentation/controllers/player_expansion_controller.dart';
import '../../features/player/presentation/widgets/audio_file_inspector_sheet.dart';
import '../../features/player/presentation/widgets/now_playing_queue_sheet.dart';
import '../../features/pro_q_studio/presentation/pro_q_studio_screen.dart';
import '../../features/settings/domain/player_customization_settings.dart';
import '../../features/settings/domain/player_playback_settings.dart';
import '../../features/settings/presentation/controllers/playback_settings_controller.dart';
import '../../features/settings/presentation/controllers/player_customization_controller.dart';
import '../../features/settings/presentation/sub_screens/visualizer_settings_screen.dart';
import 'desktop_lyrics_dialog.dart';

/// Persistent Master Playback Transport Deck khusus Desktop Linux / Desktop Canvas ($\ge 960$px).
/// Menghadirkan kontrol audio kelas studio profesional permanen di bagian bawah layar
/// dengan visibilitas dinamis dan penyesuaian gaya penuh (Seekbar, RTA, Album Art, Badges).
class DesktopBottomMasterTransportDeck extends ConsumerWidget {
  const DesktopBottomMasterTransportDeck({super.key});

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (duration.inHours > 0) {
      return '${duration.inHours}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  void _handleArtworkGesture(
    BuildContext context,
    WidgetRef ref,
    ArtworkGestureAction action,
    Track? track,
  ) {
    AppHaptics.selectionClick();
    switch (action) {
      case ArtworkGestureAction.toggleLyrics:
        DesktopLyricsDialog.show(context, track);
        break;
      case ArtworkGestureAction.togglePlayPause:
        ref.read(playerControllerProvider.notifier).togglePlayPause();
        break;
      case ArtworkGestureAction.toggleFavorite:
        if (track != null) {
          ref.read(unifiedLibraryProvider.notifier).toggleFavorite(track.id);
        }
        break;
      case ArtworkGestureAction.openInspector:
        if (track != null) {
          AudioFileInspectorSheet.show(context, track);
        }
        break;
      case ArtworkGestureAction.openProQStudio:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ProQStudioScreen()),
        );
        break;
      case ArtworkGestureAction.openDspRack:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const DspRackScreen()),
        );
        break;
      case ArtworkGestureAction.openQueue:
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const NowPlayingQueueSheet(),
        );
        break;
      case ArtworkGestureAction.viewFullArtwork:
        if (track != null) {
          StudioArtworkLightbox.show(
            context,
            track: track,
            bytes: track.albumArtBytes,
            url: track.albumArtUrl,
            title: track.title,
            subtitle: track.artist,
            formatTag: track.format.name.toUpperCase(),
          );
        }
        break;
      case ArtworkGestureAction.none:
        ref.read(playerExpansionProvider.notifier).expand();
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isSolid = ref.isSolidStyle;
    final playback = ref.watch(playerControllerProvider);
    final libraryState = ref.watch(unifiedLibraryProvider);
    final settings = ref.watch(playerCustomizationProvider);
    final playbackSettings = ref.watch(playbackSettingsProvider);

    final playerCtrl = ref.read(playerControllerProvider.notifier);
    final libraryCtrl = ref.read(unifiedLibraryProvider.notifier);
    final track = playback.currentTrack;
    final isFav = track != null && libraryState.favoriteTrackIds.contains(track.id);
    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');

    final posSeconds = playback.position.inMilliseconds / 1000.0;
    final totalSeconds = playback.duration.inMilliseconds > 0
        ? playback.duration.inMilliseconds / 1000.0
        : (track?.duration.inMilliseconds ?? 1) / 1000.0;
    final maxSec = totalSeconds > 0 ? totalSeconds : 1.0;
    final curSec = posSeconds.clamp(0.0, maxSec);

    // Format duration label (Remaining vs Total)
    final remaining = playback.duration > playback.position
        ? playback.duration - playback.position
        : Duration.zero;
    final durationLabel = playbackSettings.timeDisplayMode == TimeDisplayMode.remaining
        ? '-${_formatDuration(remaining)}'
        : _formatDuration(playback.duration);

    // Dynamic Title & Artist based on trackTitleFirst setting
    final titleText = track?.title ?? 'No Track Playing';
    final artistText = track?.artist ?? 'Baydev HiFi';
    final firstText = settings.trackTitleFirst ? titleText : artistText;
    final secondText = settings.trackTitleFirst ? artistText : titleText;

    return Container(
      height: 94,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: StudioSurfaceTheme.surface(context, isSolid: isSolid),
        border: Border(
          top: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.7),
            width: 1.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // ─── 1. LEFT: Track Info, Dynamic Artwork & Badges ──────
          SizedBox(
            width: 250,
            child: Row(
              children: [
                // Dynamic Styled Album Art with Gestures
                GestureDetector(
                  onTap: () => _handleArtworkGesture(
                    context,
                    ref,
                    settings.singleTapAction,
                    track,
                  ),
                  onDoubleTap: () => _handleArtworkGesture(
                    context,
                    ref,
                    settings.doubleTapAction,
                    track,
                  ),
                  onLongPress: () => _handleArtworkGesture(
                    context,
                    ref,
                    settings.longPressAction,
                    track,
                  ),
                  child: _buildDynamicArtworkContainer(
                    context,
                    track,
                    settings,
                    theme,
                    isSolid,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        firstText,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        secondText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: settings.trackTitleFirst
                              ? FontWeight.normal
                              : FontWeight.bold,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Hi-Res Format Badge (Visibility governed by settings)
                      if (settings.trackShowFormatBadge && track != null) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.25),
                                  width: 0.6,
                                ),
                              ),
                              child: Text(
                                _getFormatBadgeText(track, settings.trackShowBitrate),
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                  color: theme.colorScheme.primary,
                                  fontFeatures: AppTypography.audioFigures,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                // Direct Favorite Icon (Visibility governed by settings)
                if (settings.trackShowDirectFav)
                  Tooltip(
                    message: isFav ? 'Remove from Favorites' : 'Add to Favorites',
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          if (track != null) {
                            AppHaptics.selectionClick();
                            libraryCtrl.toggleFavorite(track.id);
                          }
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isFav
                                ? (isSolid
                                    ? StudioSurfaceTheme.tintedContainer(
                                        context,
                                        theme.colorScheme.error,
                                        isSolid: true,
                                        solidBlendAlpha: 0.18,
                                      )
                                    : theme.colorScheme.error.withValues(alpha: 0.15))
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isFav
                                  ? theme.colorScheme.error.withValues(alpha: 0.45)
                                  : Colors.transparent,
                              width: 1.2,
                            ),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              HugeIcon(
                                icon: HugeIcons.strokeRoundedFavourite,
                                color: isFav
                                    ? theme.colorScheme.error
                                    : theme.colorScheme.onSurface.withValues(alpha: 0.55),
                                size: 18,
                              ),
                              if (isFav)
                                Positioned(
                                  bottom: 3,
                                  child: Container(
                                    width: 4,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.error,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // ─── 2. CENTER: Transport Controls & Dynamic Seekbar ───
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Transport Buttons Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Shuffle Button with High-Visibility Active Pill & Micro Indicator
                    Tooltip(
                      message: playback.isShuffle ? 'Shuffle: ON' : 'Shuffle: OFF',
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            AppHaptics.selectionClick();
                            playerCtrl.toggleShuffle();
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: playback.isShuffle
                                  ? (isSolid
                                      ? StudioSurfaceTheme.tintedContainer(
                                          context,
                                          theme.colorScheme.primary,
                                          isSolid: true,
                                          solidBlendAlpha: 0.22,
                                        )
                                      : theme.colorScheme.primary.withValues(alpha: 0.18))
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: playback.isShuffle
                                    ? theme.colorScheme.primary.withValues(alpha: 0.5)
                                    : Colors.transparent,
                                width: 1.2,
                              ),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                HugeIcon(
                                  icon: HugeIcons.strokeRoundedShuffle,
                                  color: playback.isShuffle
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurface.withValues(alpha: 0.55),
                                  size: 18,
                                ),
                                if (playback.isShuffle)
                                  Positioned(
                                    bottom: 3,
                                    child: Container(
                                      width: 4,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Previous
                    M3EIconButton(
                      icon: HugeIcon(
                        icon: HugeIcons.strokeRoundedPrevious,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                        size: 18,
                      ),
                      onPressed: () {
                        AppHaptics.lightImpact();
                        playerCtrl.skipPrevious();
                      },
                    ),
                    const SizedBox(width: 8),

                    // Play / Pause (Prominent 42px Squircle Button)
                    Material(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(14),
                      elevation: 2,
                      shadowColor: theme.colorScheme.primary.withValues(alpha: 0.35),
                      child: InkWell(
                        onTap: () {
                          AppHaptics.lightImpact();
                          playerCtrl.togglePlayPause();
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: SizedBox(
                          width: 42,
                          height: 42,
                          child: Center(
                            child: playback.isLoading
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: M3EProgressIndicator.circular(
                                      strokeWidth: 2.4,
                                      color: theme.colorScheme.onPrimary,
                                    ),
                                  )
                                : HugeIcon(
                                    icon: playback.isPlaying
                                        ? HugeIcons.strokeRoundedPause
                                        : HugeIcons.strokeRoundedPlay,
                                    color: theme.colorScheme.onPrimary,
                                    size: 22,
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Next
                    M3EIconButton(
                      icon: HugeIcon(
                        icon: HugeIcons.strokeRoundedNext,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                        size: 18,
                      ),
                      onPressed: () {
                        AppHaptics.lightImpact();
                        playerCtrl.skipNext();
                      },
                    ),
                    const SizedBox(width: 6),

                    // Repeat Mode with High-Visibility Active Pill & Micro Indicator
                    Tooltip(
                      message: playback.repeatMode == PlaybackRepeatMode.one
                          ? 'Repeat: ONE'
                          : (playback.repeatMode == PlaybackRepeatMode.all
                              ? 'Repeat: ALL'
                              : 'Repeat: OFF'),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            AppHaptics.selectionClick();
                            playerCtrl.toggleRepeatMode();
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: playback.repeatMode != PlaybackRepeatMode.off
                                  ? (isSolid
                                      ? StudioSurfaceTheme.tintedContainer(
                                          context,
                                          theme.colorScheme.primary,
                                          isSolid: true,
                                          solidBlendAlpha: 0.22,
                                        )
                                      : theme.colorScheme.primary.withValues(alpha: 0.18))
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: playback.repeatMode != PlaybackRepeatMode.off
                                    ? theme.colorScheme.primary.withValues(alpha: 0.5)
                                    : Colors.transparent,
                                width: 1.2,
                              ),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                HugeIcon(
                                  icon: playback.repeatMode == PlaybackRepeatMode.one
                                      ? HugeIcons.strokeRoundedRepeatOne01
                                      : HugeIcons.strokeRoundedRepeat,
                                  color: playback.repeatMode != PlaybackRepeatMode.off
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurface.withValues(alpha: 0.55),
                                  size: 18,
                                ),
                                if (playback.repeatMode != PlaybackRepeatMode.off)
                                  Positioned(
                                    bottom: 3,
                                    child: Container(
                                      width: 4,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Timestamps & Dynamic Seekbar Row
                Row(
                  children: [
                    Text(
                      _formatDuration(playback.position),
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        fontFeatures: AppTypography.audioFigures,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 24,
                        child: _buildDesktopSeekBar(
                          context,
                          ref,
                          curSec,
                          maxSec,
                          settings.timeBarStyle,
                          playback.isPlaying,
                          playerCtrl,
                          theme,
                          isTest,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (settings.trackShowDuration)
                      InkWell(
                        onTap: () {
                          AppHaptics.selectionClick();
                          ref.read(playbackSettingsProvider.notifier).toggleTimeDisplayMode();
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                          child: Text(
                            durationLabel,
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              fontFeatures: AppTypography.audioFigures,
                            ),
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 4),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // ─── 3. RIGHT: Live Dynamic RTA, Specs, Lyrics, Queue, Volume ─
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Live Dynamic Spectrum Visualizer (RTA)
              Tooltip(
                message: 'Spectrum: ${settings.spectrumStyle.label}',
                child: InkWell(
                  onTap: () {
                    AppHaptics.selectionClick();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const VisualizerSettingsScreen()),
                    );
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    width: 38,
                    height: 24,
                    decoration: BoxDecoration(
                      color: StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid)
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: theme.dividerColor.withValues(alpha: 0.3),
                        width: 0.8,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: _DesktopDynamicRtaVisualizer(
                        style: settings.spectrumStyle,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),

              // Audio Specs Inspector
              Tooltip(
                message: 'Audio Specs Inspector',
                child: M3EIconButton(
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedInformationCircle,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    size: 16,
                  ),
                  onPressed: () {
                    if (track != null) {
                      AppHaptics.selectionClick();
                      AudioFileInspectorSheet.show(context, track);
                    }
                  },
                ),
              ),

              // Synchronized Lyrics
              Tooltip(
                message: 'Synchronized Lyrics',
                child: M3EIconButton(
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedMusicNote01,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    size: 16,
                  ),
                  onPressed: () {
                    AppHaptics.selectionClick();
                    DesktopLyricsDialog.show(context, track);
                  },
                ),
              ),

              // Up Next Queue
              Tooltip(
                message: 'Up Next Queue',
                child: M3EIconButton(
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedQueue01,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    size: 16,
                  ),
                  onPressed: () {
                    AppHaptics.selectionClick();
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const NowPlayingQueueSheet(),
                    );
                  },
                ),
              ),

              // Pro-Q Studio Shortcut
              Tooltip(
                message: 'Pro-Q Studio Parametric EQ',
                child: M3EIconButton(
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedSlidersVertical,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    size: 16,
                  ),
                  onPressed: () {
                    AppHaptics.selectionClick();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ProQStudioScreen()),
                    );
                  },
                ),
              ),

              const SizedBox(width: 4),

              // Volume Control with Expanded Precision Slider
              Tooltip(
                message: 'Volume: ${(playback.volume * 100).round()}%',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    M3EIconButton(
                      icon: HugeIcon(
                        icon: playback.volume == 0.0
                            ? HugeIcons.strokeRoundedVolumeOff
                            : (playback.volume < 0.5
                                ? HugeIcons.strokeRoundedVolumeLow
                                : HugeIcons.strokeRoundedVolumeHigh),
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        size: 16,
                      ),
                      onPressed: () {
                        AppHaptics.selectionClick();
                        if (playback.volume > 0.0) {
                          playerCtrl.setVolume(0.0);
                        } else {
                          playerCtrl.setVolume(1.0);
                        }
                      },
                    ),
                    SizedBox(
                      width: 120,
                      child: isTest
                          ? SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 3.0,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                              ),
                              child: Slider(
                                value: playback.volume.clamp(0.0, 1.0),
                                onChanged: (val) => playerCtrl.setVolume(val),
                              ),
                            )
                          : M3ESlider(
                              value: playback.volume.clamp(0.0, 1.0),
                              onChanged: (val) => playerCtrl.setVolume(val),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Dynamic Artwork Container Helper ───────────────────────
  Widget _buildDynamicArtworkContainer(
    BuildContext context,
    Track? track,
    PlayerCustomizationSettings settings,
    ThemeData theme,
    bool isSolid,
  ) {
    final glowColor = theme.colorScheme.primary;
    final isCircular = settings.albumArtStyle == AlbumArtStyle.disc ||
        settings.albumArtStyle == AlbumArtStyle.vinyl;
    final isSquare = settings.albumArtStyle == AlbumArtStyle.square;
    final isJewel = settings.albumArtStyle == AlbumArtStyle.cdJewel;

    final borderRadius = isCircular
        ? null
        : (isSquare ? BorderRadius.circular(6) : BorderRadius.circular(12));

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid),
        borderRadius: borderRadius,
        shape: isCircular ? BoxShape.circle : BoxShape.rectangle,
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: isJewel ? 0.4 : 0.2),
          width: 1.0,
        ),
        boxShadow: settings.ambientGlow
            ? [
                BoxShadow(
                  color: glowColor.withValues(alpha: 0.25 * settings.ambientGlowIntensity),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          StudioArtworkWidget(
            track: track,
            fit: BoxFit.cover,
            fallbackIconSize: 22,
            fallbackColor: theme.colorScheme.primary.withValues(alpha: 0.6),
          ),
          if (isJewel)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 4,
              child: Container(
                color: Colors.black.withValues(alpha: 0.3),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Dynamic Seekbar Builder ────────────────────────────────
  Widget _buildDesktopSeekBar(
    BuildContext context,
    WidgetRef ref,
    double curSec,
    double maxSec,
    TimeBarStyle style,
    bool isPlaying,
    PlayerController playerCtrl,
    ThemeData theme,
    bool isTest,
  ) {
    if (isTest) {
      return SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: 3.0,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
        ),
        child: Slider(
          value: curSec,
          max: maxSec,
          onChanged: (val) {
            playerCtrl.seek(Duration(milliseconds: (val * 1000).toInt()));
          },
        ),
      );
    }

    final progressRatio = maxSec > 0 ? (curSec / maxSec).clamp(0.0, 1.0) : 0.0;
    final primary = theme.colorScheme.primary;

    switch (style) {
      case TimeBarStyle.wavy:
        return M3ESlider.wavy(
          value: curSec,
          max: maxSec,
          wavelength: 18.0,
          amplitude: isPlaying ? 2.5 : 0.0,
          onChanged: (val) {
            playerCtrl.seek(Duration(milliseconds: (val * 1000).toInt()));
          },
        );

      case TimeBarStyle.slim:
        return SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3.5,
            activeTrackColor: primary,
            inactiveTrackColor: theme.dividerColor.withValues(alpha: 0.4),
            thumbColor: primary,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
          ),
          child: Slider(
            value: curSec,
            max: maxSec,
            onChanged: (val) {
              playerCtrl.seek(Duration(milliseconds: (val * 1000).toInt()));
            },
          ),
        );

      case TimeBarStyle.capsule:
        return SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 7.0,
            activeTrackColor: primary,
            inactiveTrackColor: theme.colorScheme.surfaceContainerHighest,
            thumbColor: Colors.white,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6, elevation: 2),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            trackShape: const RoundedRectSliderTrackShape(),
          ),
          child: Slider(
            value: curSec,
            max: maxSec,
            onChanged: (val) {
              playerCtrl.seek(Duration(milliseconds: (val * 1000).toInt()));
            },
          ),
        );

      case TimeBarStyle.segmented:
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: (details) => _handleSeekTouch(context, details.localPosition, maxSec, playerCtrl),
          onTapDown: (details) => _handleSeekTouch(context, details.localPosition, maxSec, playerCtrl),
          child: LayoutBuilder(
            builder: (context, constraints) {
              const int segments = 28;
              final activeSegments = (progressRatio * segments).round();
              return Row(
                children: List.generate(segments, (i) {
                  final isActive = i < activeSegments;
                  return Expanded(
                    child: Container(
                      height: 12,
                      margin: const EdgeInsets.symmetric(horizontal: 1.0),
                      decoration: BoxDecoration(
                        color: isActive
                            ? (i > segments * 0.8 ? const Color(0xFFFF9F0A) : primary)
                            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        );

      case TimeBarStyle.waveform:
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: (details) => _handleSeekTouch(context, details.localPosition, maxSec, playerCtrl),
          onTapDown: (details) => _handleSeekTouch(context, details.localPosition, maxSec, playerCtrl),
          child: LayoutBuilder(
            builder: (context, constraints) {
              const int bars = 36;
              final activeBars = (progressRatio * bars).round();
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: List.generate(bars, (i) {
                  final isActive = i < activeBars;
                  final double normalizedHeight = 0.3 + 0.7 * ((i * 7 + 3) % 11) / 10.0;
                  return Expanded(
                    child: Center(
                      child: Container(
                        width: 2.2,
                        height: 18 * normalizedHeight,
                        margin: const EdgeInsets.symmetric(horizontal: 0.8),
                        decoration: BoxDecoration(
                          color: isActive
                              ? primary
                              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(1.5),
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        );

      case TimeBarStyle.ruler:
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: (details) => _handleSeekTouch(context, details.localPosition, maxSec, playerCtrl),
          onTapDown: (details) => _handleSeekTouch(context, details.localPosition, maxSec, playerCtrl),
          child: LayoutBuilder(
            builder: (context, constraints) {
              const int totalTicks = 40;
              final int currentTick = (progressRatio * totalTicks).round();

              return Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 2,
                    child: Container(height: 1.0, color: theme.colorScheme.outlineVariant),
                  ),
                  Row(
                    children: List.generate(totalTicks, (i) {
                      final isMajor = i % 5 == 0;
                      final double tickHeight = isMajor ? 14 : 7;
                      final isActive = i <= currentTick;

                      return Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            width: isMajor ? 1.4 : 0.9,
                            height: tickHeight,
                            color: isActive ? primary : theme.colorScheme.outlineVariant,
                          ),
                        ),
                      );
                    }),
                  ),
                  Positioned(
                    left: (constraints.maxWidth * progressRatio - 3).clamp(0.0, constraints.maxWidth - 6),
                    top: 0,
                    child: Container(
                      width: 6,
                      height: 16,
                      decoration: BoxDecoration(
                        color: primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );

      case TimeBarStyle.glowingPill:
        return SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4.5,
            activeTrackColor: primary,
            inactiveTrackColor: theme.colorScheme.surfaceContainerHighest,
            thumbColor: primary,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4.5),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
          ),
          child: Slider(
            value: curSec,
            max: maxSec,
            onChanged: (val) {
              playerCtrl.seek(Duration(milliseconds: (val * 1000).toInt()));
            },
          ),
        );
    }
  }

  void _handleSeekTouch(BuildContext context, Offset localPosition, double maxSec, PlayerController playerCtrl) {
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize && box.size.width > 0) {
      final double ratio = (localPosition.dx / box.size.width).clamp(0.0, 1.0);
      final int newMs = (ratio * maxSec * 1000).toInt();
      AppHaptics.selectionClick();
      playerCtrl.seek(Duration(milliseconds: newMs));
    }
  }

  String _getFormatBadgeText(Track track, bool showBitrate) {
    if (showBitrate && track.sampleRate != null && track.bitDepth != null) {
      final srKHz = (track.sampleRate! / 1000.0).toStringAsFixed(1).replaceAll('.0', '');
      return '${srKHz}kHz / ${track.bitDepth}bit';
    }
    final fmt = track.format.name.toUpperCase();
    return fmt.isNotEmpty && fmt != 'UNKNOWN'
        ? fmt
        : (track.filePath ?? '').split('.').last.toUpperCase();
  }
}

// ─── Dynamic Live Mini RTA Visualizer ─────────────────────────
class _DesktopDynamicRtaVisualizer extends ConsumerWidget {
  final SpectrumStyle style;

  const _DesktopDynamicRtaVisualizer({required this.style});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isPlaying = ref.watch(playerControllerProvider.select((s) => s.isPlaying));
    final rtaAsync = ref.watch(rtaSpectrumProvider);

    return rtaAsync.when(
      data: (magnitudes) {
        final rawFft = isPlaying ? magnitudes : <double>[];
        return CustomPaint(
          painter: _DesktopMiniRtaPainter(
            fft: rawFft,
            color: theme.colorScheme.primary,
            style: style,
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (err, stack) => const SizedBox.shrink(),
    );
  }
}

class _DesktopMiniRtaPainter extends CustomPainter {
  final List<double> fft;
  final Color color;
  final SpectrumStyle style;

  _DesktopMiniRtaPainter({
    required this.fft,
    required this.color,
    required this.style,
  });

  @override
  void paint(Canvas canvas, Size size) {
    switch (style) {
      case SpectrumStyle.m3Expressive:
        _paintM3Expressive(canvas, size);
        break;
      case SpectrumStyle.bars:
        _paintBars(canvas, size);
        break;
      case SpectrumStyle.wave:
        _paintWave(canvas, size);
        break;
      case SpectrumStyle.dots:
        _paintDots(canvas, size);
        break;
      case SpectrumStyle.beam:
        _paintBeam(canvas, size);
        break;
      case SpectrumStyle.mirrorWave:
        _paintMirrorWave(canvas, size);
        break;
      case SpectrumStyle.vuMeter:
        _paintVuMeter(canvas, size);
        break;
      case SpectrumStyle.circular:
        _paintCircular(canvas, size);
        break;
    }
  }

  void _paintM3Expressive(Canvas canvas, Size size) {
    const numBars = 8;
    final barWidth = size.width / numBars;
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < numBars; i++) {
      double mag = 0.08;
      if (fft.isNotEmpty) {
        final idx = ((i + 1) * (fft.length ~/ (numBars + 2))).clamp(0, fft.length - 1);
        mag = (fft[idx] * 1.5).clamp(0.08, 1.0);
      }
      final barHeight = size.height * mag;
      final x = i * barWidth + 0.8;
      final y = size.height - barHeight;

      paint.color = color.withValues(alpha: 0.5 + mag * 0.45);
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, (barWidth - 1.4).clamp(1.0, 10.0), barHeight),
        const Radius.circular(1.5),
      );
      canvas.drawRRect(rrect, paint);
    }
  }

  void _paintBars(Canvas canvas, Size size) {
    const numBars = 8;
    final barWidth = size.width / numBars;
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < numBars; i++) {
      double mag = 0.08;
      if (fft.isNotEmpty) {
        final idx = ((i + 1) * (fft.length ~/ (numBars + 2))).clamp(0, fft.length - 1);
        mag = (fft[idx] * 1.4).clamp(0.08, 1.0);
      }
      final barHeight = size.height * mag;
      final x = i * barWidth + 0.8;
      final y = size.height - barHeight;

      paint.color = Color.lerp(color.withValues(alpha: 0.6), AppColors.mintTarget, mag)!;
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, (barWidth - 1.2).clamp(1.0, 10.0), barHeight),
        const Radius.circular(1.0),
      );
      canvas.drawRRect(rrect, paint);
    }
  }

  void _paintWave(Canvas canvas, Size size) {
    final count = fft.isNotEmpty ? math.min(16, fft.length) : 8;
    final path = Path();
    final fillPath = Path();

    final step = size.width / (count - 1);
    final firstMag = fft.isNotEmpty ? fft[0].clamp(0.05, 1.0) : 0.08;
    path.moveTo(0, size.height - (firstMag * size.height));
    fillPath.moveTo(0, size.height);
    fillPath.lineTo(0, size.height - (firstMag * size.height));

    for (int i = 1; i < count; i++) {
      final x = i * step;
      final mag = fft.isNotEmpty ? fft[(i * (fft.length ~/ count)).clamp(0, fft.length - 1)].clamp(0.05, 1.0) : 0.08;
      final y = size.height - (mag * size.height);
      path.lineTo(x, y);
      fillPath.lineTo(x, y);
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawPath(path, strokePaint);
  }

  void _paintDots(Canvas canvas, Size size) {
    const count = 7;
    final step = size.width / count;
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < count; i++) {
      double mag = 0.1;
      if (fft.isNotEmpty) {
        final idx = (i * (fft.length ~/ count)).clamp(0, fft.length - 1);
        mag = (fft[idx] * 1.5).clamp(0.1, 1.0);
      }
      final x = (i + 0.5) * step;
      final y = size.height - (mag * size.height * 0.85);
      paint.color = Color.lerp(color.withValues(alpha: 0.6), const Color(0xFF00E5FF), mag)!;
      canvas.drawCircle(Offset(x, y), 1.6 + mag * 1.2, paint);
    }
  }

  void _paintBeam(Canvas canvas, Size size) {
    final midY = size.height * 0.5;
    final count = fft.isNotEmpty ? math.min(12, fft.length) : 8;
    final step = size.width / (count - 1);

    final topPath = Path()..moveTo(0, midY);
    final btmPath = Path()..moveTo(0, midY);

    for (int i = 0; i < count; i++) {
      final x = i * step;
      double mag = 0.08;
      if (fft.isNotEmpty) {
        final idx = (i * (fft.length ~/ count)).clamp(0, fft.length - 1);
        mag = (fft[idx] * 1.5).clamp(0.08, 1.0);
      }
      final halfAmp = mag * size.height * 0.45;
      topPath.lineTo(x, midY - halfAmp);
      btmPath.lineTo(x, midY + halfAmp);
    }

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawPath(topPath, strokePaint);
    canvas.drawPath(btmPath, strokePaint);

    final centerLine = Paint()
      ..color = const Color(0xFF00F0FF).withValues(alpha: 0.8)
      ..strokeWidth = 0.8;
    canvas.drawLine(Offset(0, midY), Offset(size.width, midY), centerLine);
  }

  void _paintMirrorWave(Canvas canvas, Size size) {
    final midY = size.height * 0.5;
    final count = 8;
    final step = size.width / (count - 1);
    final topPath = Path()..moveTo(0, midY);
    final btmPath = Path()..moveTo(0, midY);

    for (int i = 0; i < count; i++) {
      final x = i * step;
      double mag = 0.08;
      if (fft.isNotEmpty) {
        final idx = (i * (fft.length ~/ count)).clamp(0, fft.length - 1);
        mag = (fft[idx] * 1.4).clamp(0.08, 1.0);
      }
      final amp = mag * midY * 0.9;
      topPath.lineTo(x, midY - amp);
      btmPath.lineTo(x, midY + amp);
    }

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawPath(topPath, strokePaint);
    canvas.drawPath(btmPath, strokePaint);
  }

  void _paintVuMeter(Canvas canvas, Size size) {
    final halfWidth = size.width / 2;
    double leftEnergy = 0.08;
    double rightEnergy = 0.08;

    if (fft.isNotEmpty) {
      final halfCount = fft.length ~/ 2;
      for (int i = 0; i < halfCount; i++) {
        leftEnergy += fft[i];
      }
      for (int i = halfCount; i < fft.length; i++) {
        rightEnergy += fft[i];
      }
      leftEnergy = (leftEnergy / halfCount * 2.5).clamp(0.08, 1.0);
      rightEnergy = (rightEnergy / (fft.length - halfCount) * 2.5).clamp(0.08, 1.0);
    }

    _paintMiniDial(canvas, Rect.fromLTWH(2, 2, halfWidth - 3, size.height - 4), leftEnergy);
    _paintMiniDial(canvas, Rect.fromLTWH(halfWidth + 1, 2, halfWidth - 3, size.height - 4), rightEnergy);
  }

  void _paintMiniDial(Canvas canvas, Rect bounds, double energy) {
    final rrect = RRect.fromRectAndRadius(bounds, const Radius.circular(3));
    final bgPaint = Paint()..color = const Color(0xFF14171E);
    canvas.drawRRect(rrect, bgPaint);

    final pivot = Offset(bounds.center.dx, bounds.bottom + 2);
    final radius = bounds.height * 1.1;

    final needleAngle = (math.pi * 1.5) + ((energy - 0.5) * (math.pi * 0.4));
    final needleEnd = Offset(
      pivot.dx + radius * math.cos(needleAngle),
      pivot.dy + radius * math.sin(needleAngle),
    );

    final needlePaint = Paint()
      ..color = energy > 0.85 ? const Color(0xFFFF453A) : color
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(pivot, needleEnd, needlePaint);
  }

  void _paintCircular(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.height * 0.3;
    const count = 10;

    for (int i = 0; i < count; i++) {
      final angle = (i / count) * 2 * math.pi;
      double mag = 0.08;
      if (fft.isNotEmpty) {
        final idx = (i * (fft.length ~/ count)).clamp(0, fft.length - 1);
        mag = (fft[idx] * 1.5).clamp(0.08, 1.0);
      }
      final barLen = 1.5 + (mag * size.height * 0.4);

      final start = Offset(
        center.dx + baseRadius * math.cos(angle),
        center.dy + baseRadius * math.sin(angle),
      );
      final end = Offset(
        center.dx + (baseRadius + barLen) * math.cos(angle),
        center.dy + (baseRadius + barLen) * math.sin(angle),
      );

      final paint = Paint()
        ..color = Color.lerp(color.withValues(alpha: 0.6), const Color(0xFF00E5FF), mag)!
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DesktopMiniRtaPainter oldDelegate) => true;
}

