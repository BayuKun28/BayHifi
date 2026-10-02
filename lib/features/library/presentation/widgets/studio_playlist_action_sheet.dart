import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../app/theme/app_haptics.dart';
import '../../../../app/theme/studio_surface_theme.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../player/domain/track.dart';
import '../../../player/presentation/controllers/player_controller.dart';
import '../../domain/library_collection_models.dart';
import '../../domain/m3u8_playlist_service.dart';
import '../../domain/smart_playlist_models.dart';
import '../controllers/library_controller.dart';
import 'create_smart_playlist_dialog.dart';
import 'create_custom_playlist_modal.dart';

/// Unified Material 3 Expressive Studio Playlist Action Bottom Sheet
class StudioPlaylistActionSheet extends ConsumerWidget {
  final PlaylistModel? playlist;
  final SmartPlaylist? smartPlaylist;
  final List<Track> tracks;
  final VoidCallback? onDeleted;

  const StudioPlaylistActionSheet({
    super.key,
    this.playlist,
    this.smartPlaylist,
    required this.tracks,
    this.onDeleted,
  }) : assert(playlist != null || smartPlaylist != null, 'Must provide either playlist or smartPlaylist');

  static Future<void> showForPlaylist(
    BuildContext context, {
    required PlaylistModel playlist,
    VoidCallback? onDeleted,
  }) {
    AppHaptics.lightImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StudioPlaylistActionSheet(
        playlist: playlist,
        tracks: playlist.tracks,
        onDeleted: onDeleted,
      ),
    );
  }

  static Future<void> showForSmartPlaylist(
    BuildContext context, {
    required SmartPlaylist smartPlaylist,
    required List<Track> tracks,
    VoidCallback? onDeleted,
  }) {
    AppHaptics.lightImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StudioPlaylistActionSheet(
        smartPlaylist: smartPlaylist,
        tracks: tracks,
        onDeleted: onDeleted,
      ),
    );
  }

  String get _name => playlist?.name ?? smartPlaylist?.name ?? 'Playlist';
  bool get _isPreset => smartPlaylist?.isPreset ?? false;
  bool get _isCurated => playlist != null && !playlist!.isCustom;

  void _exportM3u8(BuildContext context) async {
    final m3u8 = M3u8PlaylistService.generateM3u8(playlistName: _name, tracks: tracks);
    await Clipboard.setData(ClipboardData(text: m3u8));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Playlist "$_name" exported as M3U8 (${tracks.length} tracks copied to clipboard).',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => Consumer(
        builder: (ctx, ref, _) {
          final theme = Theme.of(ctx);
          final isSolid = ref.isSolidStyle;

          return AlertDialog(
            backgroundColor: StudioSurfaceTheme.surface(ctx, isSolid: isSolid),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: StudioSurfaceTheme.outline(ctx, isSolid: isSolid),
                width: 1.0,
              ),
            ),
            title: Text(
              smartPlaylist != null ? 'DELETE SMART PLAYLIST?' : 'DELETE PLAYLIST?',
              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, letterSpacing: 0.6),
            ),
            content: Text(
              'Are you sure you want to delete "$_name"?',
              style: TextStyle(
                fontSize: 12.5,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFF453A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  if (smartPlaylist != null) {
                    ref.read(unifiedLibraryProvider.notifier).deleteSmartPlaylist(smartPlaylist!.id);
                  } else if (playlist != null) {
                    ref.read(unifiedLibraryProvider.notifier).deletePlaylist(playlist!.id);
                  }
                  Navigator.of(ctx).pop();
                  onDeleted?.call();
                },
                child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isSolid = ref.isSolidStyle;

    final totalDuration = tracks.fold(Duration.zero, (sum, t) => sum + t.duration);
    final durationText = totalDuration.inHours > 0
        ? '${totalDuration.inHours}h ${totalDuration.inMinutes.remainder(60)}m'
        : '${totalDuration.inMinutes} mins';

    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: theme.dividerColor.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header Container
            Container(
              padding: const EdgeInsets.all(12),
              decoration: StudioSurfaceTheme.cardDecoration(
                context: context,
                isSolid: isSolid,
                radius: 16,
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: StudioSurfaceTheme.tintedContainer(
                        context,
                        smartPlaylist != null
                            ? primary
                            : (playlist?.id == 'favorites'
                                ? theme.colorScheme.tertiary
                                : (playlist?.id == 'hires_master'
                                    ? theme.colorScheme.secondary
                                    : primary)),
                        isSolid: isSolid,
                        translucentAlpha: 0.15,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid),
                        width: 0.8,
                      ),
                    ),
                    child: Center(
                      child: HugeIcon(
                        icon: smartPlaylist != null
                            ? HugeIcons.strokeRoundedFilterHorizontal
                            : (playlist?.id == 'favorites'
                                ? HugeIcons.strokeRoundedFavourite
                                : (playlist?.id == 'hires_master'
                                    ? HugeIcons.strokeRoundedSparkles
                                    : HugeIcons.strokeRoundedPlaylist01)),
                        size: 22,
                        color: smartPlaylist != null
                            ? primary
                            : (playlist?.id == 'favorites'
                                ? theme.colorScheme.tertiary
                                : (playlist?.id == 'hires_master'
                                    ? theme.colorScheme.secondary
                                    : primary)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _name,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (_isPreset)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: StudioSurfaceTheme.tintedContainer(
                                    context,
                                    theme.colorScheme.tertiary,
                                    isSolid: isSolid,
                                    translucentAlpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'PRESET',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: theme.colorScheme.tertiary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          smartPlaylist != null
                              ? '${tracks.length} Tracks • ${smartPlaylist!.rules.length} Rules • $durationText'
                              : '${tracks.length} Tracks • $durationText',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                            fontFeatures: AppTypography.audioFigures,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Action Items
            _buildActionTile(
              context,
              icon: HugeIcons.strokeRoundedPlay,
              title: 'Play Now',
              subtitle: 'Replace active queue and start playback',
              color: primary,
              onTap: () {
                if (tracks.isNotEmpty) {
                  ref.read(playerControllerProvider.notifier).setQueue(tracks, initialIndex: 0);
                }
                Navigator.of(context).pop();
              },
            ),
            _buildActionTile(
              context,
              icon: HugeIcons.strokeRoundedShuffle,
              title: 'Shuffle Play',
              subtitle: 'Play all tracks in randomized studio order',
              onTap: () {
                if (tracks.isNotEmpty) {
                  final list = List<Track>.from(tracks)..shuffle();
                  ref.read(playerControllerProvider.notifier).setQueue(list, initialIndex: 0);
                }
                Navigator.of(context).pop();
              },
            ),
            _buildActionTile(
              context,
              icon: HugeIcons.strokeRoundedPlayList,
              title: 'Add to Queue',
              subtitle: 'Append tracks to end of active queue',
              onTap: () {
                for (final track in tracks) {
                  ref.read(playerControllerProvider.notifier).addToQueue(track);
                }
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Added ${tracks.length} tracks to queue.')),
                );
              },
            ),

            if (smartPlaylist != null)
              _buildActionTile(
                context,
                icon: HugeIcons.strokeRoundedEdit02,
                title: 'Edit Smart Rules',
                subtitle: 'Modify matching conditions, logic, and limits',
                onTap: () {
                  Navigator.of(context).pop();
                  CreateSmartPlaylistDialog.show(context, initialPlaylist: smartPlaylist);
                },
              )
            else if (playlist != null && playlist!.isCustom)
              _buildActionTile(
                context,
                icon: HugeIcons.strokeRoundedEdit02,
                title: 'Rename / Edit Details',
                subtitle: 'Update playlist title and description',
                onTap: () {
                  Navigator.of(context).pop();
                  CreateCustomPlaylistModal.show(context, initialPlaylist: playlist);
                },
              ),

            if (smartPlaylist != null)
              _buildActionTile(
                context,
                icon: HugeIcons.strokeRoundedCopy01,
                title: 'Duplicate Smart Playlist',
                subtitle: 'Create a cloned smart playlist rule set',
                onTap: () {
                  ref.read(unifiedLibraryProvider.notifier).duplicateSmartPlaylist(smartPlaylist!.id);
                  Navigator.of(context).pop();
                },
              ),

            _buildActionTile(
              context,
              icon: HugeIcons.strokeRoundedShare01,
              title: 'Export M3U8 Archive',
              subtitle: 'Export tracks as standard M3U8 playlist',
              onTap: () {
                Navigator.of(context).pop();
                _exportM3u8(context);
              },
            ),

            if (!_isCurated && !_isPreset) ...[
              const SizedBox(height: 6),
              _buildActionTile(
                context,
                icon: HugeIcons.strokeRoundedDelete02,
                title: 'Delete Playlist',
                subtitle: 'Permanently remove from library',
                color: const Color(0xFFFF453A),
                onTap: () {
                  Navigator.of(context).pop();
                  _confirmDelete(context);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required dynamic icon,
    required String title,
    required String subtitle,
    Color? color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final iconColor = color ?? theme.colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2.0),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: (color ?? theme.colorScheme.surfaceContainerHighest).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: HugeIcon(
            icon: icon,
            size: 18,
            color: iconColor,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color ?? theme.colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 10.5,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
        onTap: () {
          AppHaptics.selectionClick();
          onTap();
        },
      ),
    );
  }
}
