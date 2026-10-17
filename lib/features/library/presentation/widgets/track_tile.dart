import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_haptics.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/simple_as_f_theme.dart';
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
        AppHaptics.lightImpact();
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
        AppHaptics.lightImpact();
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
        AppHaptics.selectionClick();
        ref.read(unifiedLibraryProvider.notifier).toggleFavorite(track.id);
        break;
      case TrackTileSwipeAction.addToPlaylist:
        AppHaptics.selectionClick();
        onAddToPlaylist?.call();
        break;
      case TrackTileSwipeAction.none:
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
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
      margin: EdgeInsets.symmetric(
        horizontal: isTileActive ? 4 : 2,
        vertical: isTileActive ? 4 : 2,
      ),
      decoration: BoxDecoration(
        color: isSelected
            ? SimpleAsFTheme.surfaceActive(context)
            : (isTileActive
                ? SimpleAsFTheme.surfaceActive(context)
                : Colors.transparent),
        borderRadius: BorderRadius.circular(16),
        border: isSelected
            ? Border.all(color: SimpleAsFTheme.accent(context), width: 1.2)
            : (isTileActive
                ? Border.all(
                    color: SimpleAsFTheme.accent(context).withValues(alpha: 0.35),
                    width: 1.0,
                  )
                : null),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isTileActive ? 12 : 8,
              vertical: isTileActive ? 10 : 8,
            ),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    StudioArtworkWidget(
                      track: track,
                      width: 46,
                      height: 46,
                      borderRadius: BorderRadius.circular(12),
                      fallbackIcon: LucideIcons.music,
                      fallbackIconSize: 22,
                    ),
                    if (isMultiSelecting)
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? SimpleAsFTheme.accent(context).withValues(alpha: 0.85)
                              : Colors.black.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Icon(
                            isSelected
                                ? LucideIcons.checkSquare
                                : LucideIcons.square,
                            color: isSelected ? const Color(0xFF0B110E) : Colors.white,
                            size: 20,
                          ),
                        ),
                      )
                    else if (isTileActive)
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: isBuffering
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.0,
                                    valueColor: AlwaysStoppedAnimation<Color>(SimpleAsFTheme.accent(context)),
                                  ),
                                )
                              : Icon(
                                  LucideIcons.audioLines,
                                  color: SimpleAsFTheme.accent(context),
                                  size: 22,
                                ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        titleText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: isTileActive ? FontWeight.w800 : FontWeight.w600,
                          color: isTileActive ? SimpleAsFTheme.accent(context) : theme.colorScheme.onSurface,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitleText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 5),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            if (settings.trackShowFormatBadge) ...[
                              Builder(
                                builder: (context) {
                                  final Color badgeColor = track.isHiRes
                                      ? SimpleAsFTheme.accent(context)
                                      : theme.colorScheme.onSurfaceVariant;

                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: badgeColor.withValues(alpha: 0.16),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      track.format.name.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        color: badgeColor,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 6),
                            ],
                            if ((track.streamUrl != null || track.remoteUrl != null) &&
                                AudioCacheService.instance.isCached(track.id)) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: StudioCategoryColors.bitPerfect.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      LucideIcons.checkCircle2,
                                      size: 10,
                                      color: StudioCategoryColors.bitPerfect,
                                    ),
                                    SizedBox(width: 2),
                                    Text(
                                      'CACHED',
                                      style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w800,
                                        color: StudioCategoryColors.bitPerfect,
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
                                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
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
                                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (settings.trackShowDirectFav)
                      IconButton(
                        icon: Icon(
                          LucideIcons.heart,
                          color: isFav ? SimpleAsFTheme.accent(context) : theme.colorScheme.onSurfaceVariant,
                          size: 19,
                        ),
                        tooltip: isFav ? 'Remove Favorite' : 'Favorite Track',
                        onPressed: () {
                          AppHaptics.selectionClick();
                          ref.read(unifiedLibraryProvider.notifier).toggleFavorite(track.id);
                        },
                      ),
                    IconButton(
                      icon: Icon(
                        LucideIcons.moreVertical,
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 19,
                      ),
                      tooltip: 'Track Options',
                      onPressed: () => StudioTrackActionSheet.show(context, track),
                    ),
                  ],
                ),
              ],
            ),
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
          Icon(icon, color: color, size: 18),
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

  IconData _getActionIcon(TrackTileSwipeAction action) {
    switch (action) {
      case TrackTileSwipeAction.addToQueue:
        return LucideIcons.listPlus;
      case TrackTileSwipeAction.playNext:
        return LucideIcons.stepForward;
      case TrackTileSwipeAction.toggleFavorite:
        return LucideIcons.heart;
      case TrackTileSwipeAction.addToPlaylist:
        return LucideIcons.plusCircle;
      case TrackTileSwipeAction.none:
        return LucideIcons.x;
    }
  }
}
