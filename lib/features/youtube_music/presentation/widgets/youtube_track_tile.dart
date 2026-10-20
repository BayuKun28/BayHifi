import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../../../app/theme/app_haptics.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/simple_as_f_theme.dart';
import '../../../../app/theme/studio_surface_theme.dart';
import '../../../../core/widgets/studio_artwork_widget.dart';
import '../../../library/presentation/widgets/studio_track_action_sheet.dart';
import '../../../player/domain/track.dart';
import '../../../player/presentation/controllers/player_controller.dart';

/// Material 3 Expressive Studio YouTube Music Track Tile
class YouTubeTrackTile extends ConsumerWidget {
  final Track track;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback onStartRadio;
  final bool isSolid;

  const YouTubeTrackTile({
    super.key,
    required this.track,
    required this.isPlaying,
    required this.onTap,
    required this.onStartRadio,
    this.isSolid = true,
  });

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    final playback = ref.watch(playerControllerProvider);
    final isCurrent = playback.currentTrack?.id == track.id;
    final isBuffering = isCurrent && playback.isLoading;
    final isTileActive = isPlaying || isBuffering;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: isTileActive
            ? SimpleAsFTheme.surfaceActive(context)
            : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: isTileActive
              ? BorderSide(
                  color: primary.withValues(alpha: 0.35),
                  width: 1.0,
                )
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(
            horizontal: isTileActive ? 12 : 8,
            vertical: 2,
          ),
          leading: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: StudioArtworkWidget(
                  track: track,
                  borderRadius: BorderRadius.circular(11),
                  fallbackIconSize: 20,
                ),
              ),
              if (isTileActive)
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: isBuffering
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: M3EProgressIndicator.circular(
                              strokeWidth: 2.0,
                              color: primary,
                            ),
                          )
                        : Icon(
                            LucideIcons.audioLines,
                            size: 20,
                            color: primary,
                          ),
                  ),
                ),
            ],
          ),
          title: Text(
            track.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isTileActive ? FontWeight.w900 : FontWeight.w700,
              color: isTileActive ? primary : theme.colorScheme.onSurface,
            ),
          ),
          subtitle: Row(
            children: [
              // Format tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: StudioSurfaceTheme.tintedContainer(context, primary, isSolid: isSolid, translucentAlpha: 0.12, solidBlendAlpha: 0.16),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'OPUS',
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    color: primary,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  track.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
              Text(
                _formatDuration(track.duration),
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  fontFeatures: AppTypography.audioFigures,
                ),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Start Radio Button
              M3EIconButton(
                variant: M3EIconButtonVariant.standard,
                icon: Icon(
                  LucideIcons.radio,
                  size: 22,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                tooltip: 'Start Smart Track Radio',
                onPressed: () {
                  AppHaptics.selectionClick();
                  onStartRadio();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Starting smart radio based on "${track.title}"...'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
              // Unified Track Action Sheet
              M3EIconButton(
                variant: M3EIconButtonVariant.standard,
                icon: Icon(
                  LucideIcons.moreVertical,
                  size: 22,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                tooltip: 'Track Options',
                onPressed: () {
                  StudioTrackActionSheet.show(context, track);
                },
              ),
            ],
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
