import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/studio_surface_theme.dart';
import '../../../../audio_engine/audio_cache_service.dart';
import '../../../../core/widgets/studio_artwork_widget.dart';
import '../../../player/domain/track.dart';
import '../../../player/presentation/controllers/player_controller.dart';
import '../../../settings/domain/player_customization_settings.dart';
import '../../../settings/presentation/controllers/player_customization_controller.dart';
import '../controllers/library_controller.dart';
import 'studio_track_action_sheet.dart';

class TrackTile extends ConsumerWidget {
  final Track track;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback? onPlayNext;
  final VoidCallback? onAddToQueue;
  final VoidCallback? onAddToPlaylist;
  final bool isMultiSelecting;
  final bool isSelected;
  final VoidCallback? onLongPress;

  const TrackTile({
    super.key,
    required this.track,
    required this.isPlaying,
    required this.onTap,
    this.onPlayNext,
    this.onAddToQueue,
    this.onAddToPlaylist,
    this.isMultiSelecting = false,
    this.isSelected = false,
    this.onLongPress,
  });

  String _formatDuration(Duration d) {
    if (d.inSeconds <= 0) return '--:--';
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _executeAction(BuildContext context, WidgetRef ref, TrackTileSwipeAction action) {
    switch (action) {
      case TrackTileSwipeAction.addToQueue:
        HapticFeedback.lightImpact();
        onAddToQueue?.call();
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added "${track.title}" to Queue'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
        break;
      case TrackTileSwipeAction.playNext:
        HapticFeedback.lightImpact();
        onPlayNext?.call();
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Playing "${track.title}" next'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
        break;
      case TrackTileSwipeAction.toggleFavorite:
        HapticFeedback.selectionClick();
        ref.read(unifiedLibraryProvider.notifier).toggleFavorite(track.id);
        break;
      case TrackTileSwipeAction.addToPlaylist:
        HapticFeedback.selectionClick();
        onAddToPlaylist?.call();
        break;
      case TrackTileSwipeAction.none:
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isSolid = ref.isSolidStyle;
    final settings = ref.watch(playerCustomizationProvider);
    final libraryState = ref.watch(unifiedLibraryProvider);
    final playback = ref.watch(playerControllerProvider);
    final isFav = libraryState.favoriteTrackIds.contains(track.id);
    final isCurrent = playback.currentTrack?.id == track.id;
    final isBuffering = isCurrent && playback.isLoading;
    final isTileActive = isPlaying || isBuffering;

    final titleText = settings.trackTitleFirst ? track.title : track.artist;
    final subtitleText = settings.trackTitleFirst
        ? '${track.artist} • ${track.album}'
        : '${track.title} • ${track.album}';

    Widget tileContent = Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isSelected
            ? StudioSurfaceTheme.tintedContainer(context, primary, isSolid: isSolid, translucentAlpha: 0.16, solidBlendAlpha: 0.22)
            : (isTileActive
                ? StudioSurfaceTheme.tintedContainer(context, primary, isSolid: isSolid, translucentAlpha: 0.1, solidBlendAlpha: 0.14)
                : StudioSurfaceTheme.surface(context, isSolid: isSolid)),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected
              ? primary
              : (isTileActive
                  ? (isSolid ? primary : primary.withValues(alpha: 0.5))
                  : StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid)),
          width: isSelected ? 1.4 : 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          onTap: onTap,
          onLongPress: onLongPress,
          leading: Stack(
            alignment: Alignment.center,
            children: [
              StudioArtworkWidget(
                track: track,
                width: 46,
                height: 46,
                borderRadius: BorderRadius.circular(10),
                fallbackIcon: HugeIcons.strokeRoundedMusicNote01,
                fallbackIconSize: 22,
              ),
              if (isMultiSelecting)
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary.withValues(alpha: 0.85)
                        : Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: HugeIcon(
                      icon: isSelected
                          ? HugeIcons.strokeRoundedCheckmarkSquare02
                          : HugeIcons.strokeRoundedSquare,
                      color: isSelected ? theme.colorScheme.onPrimary : Colors.white,
                      size: 20,
                    ),
                  ),
                )
              else if (isTileActive)
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: isBuffering
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.0,
                              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                            ),
                          )
                        : HugeIcon(
                            icon: HugeIcons.strokeRoundedAudioWaveform,
                            color: theme.colorScheme.primary,
                            size: 22,
                          ),
                  ),
                ),
            ],
          ),
          title: Text(
            titleText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: isTileActive ? FontWeight.w800 : FontWeight.w600,
              color: isTileActive ? theme.colorScheme.primary : theme.colorScheme.onSurface,
              fontSize: 13,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                subtitleText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 3),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (settings.trackShowFormatBadge) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: track.isHiRes
                              ? const Color(0xFFFF9F0A).withValues(alpha: 0.15)
                              : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: track.isHiRes
                                ? const Color(0xFFFF9F0A).withValues(alpha: 0.5)
                                : theme.dividerColor,
                            width: 0.6,
                          ),
                        ),
                        child: Text(
                          track.format.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: track.isHiRes
                                ? const Color(0xFFFF9F0A)
                                : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    if ((track.streamUrl != null || track.remoteUrl != null) &&
                        AudioCacheService.instance.isCached(track.id)) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E676).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: const Color(0xFF00E676).withValues(alpha: 0.5),
                            width: 0.6,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            HugeIcon(
                              icon: HugeIcons.strokeRoundedCheckmarkCircle01,
                              size: 9,
                              color: Color(0xFF00E676),
                            ),
                            SizedBox(width: 2),
                            Text(
                              'CACHED',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF00E676),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    if (settings.trackShowBitrate && track.sampleRate != null) ...[
                      Text(
                        '${(track.sampleRate! / 1000).toStringAsFixed(1)}kHz',
                        style: TextStyle(
                          fontFeatures: AppTypography.audioFigures,
                          fontSize: 10,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    if (settings.trackShowDuration && track.duration.inSeconds > 0)
                      Text(
                        _formatDuration(track.duration),
                        style: TextStyle(
                          fontFeatures: AppTypography.audioFigures,
                          fontSize: 10,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (settings.trackShowDirectFav)
                IconButton(
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedFavourite,
                    color: isFav ? const Color(0xFFFF2D55) : theme.colorScheme.onSurface.withValues(alpha: 0.35),
                    size: 18,
                  ),
                  tooltip: isFav ? 'Remove Favorite' : 'Favorite Track',
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    ref.read(unifiedLibraryProvider.notifier).toggleFavorite(track.id);
                  },
                ),
              IconButton(
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedMoreVertical,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  size: 18,
                ),
                tooltip: 'Track Options',
                onPressed: () => StudioTrackActionSheet.show(context, track),
              ),
            ],
          ),
        ),
      ),
    );

    // If both swipe actions are disabled, return simple tile
    if (settings.trackSwipeLeft == TrackTileSwipeAction.none &&
        settings.trackSwipeRight == TrackTileSwipeAction.none) {
      return tileContent;
    }

    return Dismissible(
      key: ValueKey('track_tile_${track.id}'),
      direction: _getDismissDirection(settings.trackSwipeLeft, settings.trackSwipeRight),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          _executeAction(context, ref, settings.trackSwipeRight);
        } else if (direction == DismissDirection.endToStart) {
          _executeAction(context, ref, settings.trackSwipeLeft);
        }
        return false; // Prevent removal from list
      },
      background: _buildSwipeBackground(
        theme,
        settings.trackSwipeRight,
        Alignment.centerLeft,
        const EdgeInsets.only(left: 18),
      ),
      secondaryBackground: _buildSwipeBackground(
        theme,
        settings.trackSwipeLeft,
        Alignment.centerRight,
        const EdgeInsets.only(right: 18),
      ),
      child: tileContent,
    );
  }

  DismissDirection _getDismissDirection(TrackTileSwipeAction left, TrackTileSwipeAction right) {
    if (left != TrackTileSwipeAction.none && right != TrackTileSwipeAction.none) {
      return DismissDirection.horizontal;
    } else if (right != TrackTileSwipeAction.none) {
      return DismissDirection.startToEnd;
    } else if (left != TrackTileSwipeAction.none) {
      return DismissDirection.endToStart;
    }
    return DismissDirection.none;
  }

  Widget _buildSwipeBackground(
    ThemeData theme,
    TrackTileSwipeAction action,
    Alignment alignment,
    EdgeInsets padding,
  ) {
    final color = _getActionColor(theme, action);
    final icon = _getActionIcon(action);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: padding,
      alignment: alignment,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(icon: icon, color: color, size: 20),
          const SizedBox(width: 6),
          Text(
            action.label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Color _getActionColor(ThemeData theme, TrackTileSwipeAction action) {
    switch (action) {
      case TrackTileSwipeAction.addToQueue:
        return theme.colorScheme.primary;
      case TrackTileSwipeAction.playNext:
        return const Color(0xFF00E676);
      case TrackTileSwipeAction.toggleFavorite:
        return const Color(0xFFFF2D55);
      case TrackTileSwipeAction.addToPlaylist:
        return const Color(0xFFFF9F0A);
      case TrackTileSwipeAction.none:
        return Colors.transparent;
    }
  }

  dynamic _getActionIcon(TrackTileSwipeAction action) {
    switch (action) {
      case TrackTileSwipeAction.addToQueue:
        return HugeIcons.strokeRoundedPlaylist01;
      case TrackTileSwipeAction.playNext:
        return HugeIcons.strokeRoundedNext;
      case TrackTileSwipeAction.toggleFavorite:
        return HugeIcons.strokeRoundedFavourite;
      case TrackTileSwipeAction.addToPlaylist:
        return HugeIcons.strokeRoundedAddCircleHalfDot;
      case TrackTileSwipeAction.none:
        return HugeIcons.strokeRoundedCancel01;
    }
  }
}
