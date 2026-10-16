import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_haptics.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/studio_surface_theme.dart';
import '../../../../core/widgets/studio_artwork_widget.dart';
import '../../../library/presentation/widgets/studio_track_action_sheet.dart';
import '../../../player/presentation/controllers/player_controller.dart';
import '../../../spotify_importer/presentation/widgets/universal_import_dialog.dart';
import '../controllers/download_controller.dart';
import '../../domain/download_task.dart';

/// Material 3 Expressive Studio Download Manager Tab embedded in Unified Library
class LibraryDownloadsTab extends ConsumerWidget {
  const LibraryDownloadsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadState = ref.watch(downloadControllerProvider);
    final downloadController = ref.read(downloadControllerProvider.notifier);
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isSolid = ref.isSolidStyle;

    final activeTasks = [...downloadState.active, ...downloadState.queue];
    final completedTasks = downloadState.completed;
    final failedTasks = downloadState.failed;

    if (activeTasks.isEmpty && completedTasks.isEmpty && failedTasks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: StudioSurfaceTheme.tintedContainer(
                    context,
                    primary,
                    isSolid: isSolid,
                    translucentAlpha: 0.12,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.download,
                  size: 36,
                  color: primary,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'NO DOWNLOADS IN QUEUE',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Download high-bitrate tracks from Spotify & YouTube for lossless offline listening with full studio DSP processing.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
                icon: const Icon(LucideIcons.link, size: 16, color: Colors.white),
                label: const Text('Import from Link', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
                onPressed: () {
                  AppHaptics.lightImpact();
                  UniversalImportDialog.show(context);
                },
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        // ─── ACTIVE QUEUE SECTION ───────────────────────────────────────────
        if (activeTasks.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'DOWNLOADING (${activeTasks.length})',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: primary,
                      ),
                    ),
                  ],
                ),
                if (downloadState.active.isNotEmpty)
                  Text(
                    downloadState.active.first.progress.speedFormatted,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      fontFeatures: AppTypography.audioFigures,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          ...activeTasks.map(
            (task) => _buildActiveTaskTile(
              context: context,
              task: task,
              theme: theme,
              primary: primary,
              isSolid: isSolid,
              onCancel: () => downloadController.cancelTask(task.id),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // ─── FAILED DOWNLOADS SECTION ───────────────────────────────────────
        if (failedTasks.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'FAILED DOWNLOADS (${failedTasks.length})',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          ...failedTasks.map(
            (task) => _buildFailedTaskTile(
              context: context,
              task: task,
              theme: theme,
              isSolid: isSolid,
              onRetry: () => downloadController.retryTask(task.id),
              onDismiss: () => downloadController.cancelTask(task.id),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // ─── COMPLETED DOWNLOADS SECTION ────────────────────────────────────
        if (completedTasks.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981), // Precision Mint
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'COMPLETED (${completedTasks.length})',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () => downloadController.clearCompleted(),
                  child: const Text('Clear History', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          ...completedTasks.map(
            (task) => _buildCompletedTaskTile(
              context: context,
              task: task,
              ref: ref,
              theme: theme,
              isSolid: isSolid,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActiveTaskTile({
    required BuildContext context,
    required DownloadTask task,
    required ThemeData theme,
    required Color primary,
    required bool isSolid,
    required VoidCallback onCancel,
  }) {
    final track = task.track;
    final progress = task.progress;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: StudioSurfaceTheme.surfaceContainer(context, isSolid: isSolid),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: StudioArtworkWidget(
                    track: track,
                    width: 44,
                    height: 44,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      track.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  LucideIcons.x,
                  size: 16,
                  color: Colors.grey,
                ),
                onPressed: onCancel,
                tooltip: 'Cancel Download',
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.fraction > 0 ? progress.fraction : null,
              minHeight: 4,
              backgroundColor: StudioSurfaceTheme.surfaceContainerLow(context, isSolid: isSolid),
              valueColor: AlwaysStoppedAnimation<Color>(primary),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                progress.statusText.isNotEmpty ? progress.statusText : task.status.label,
                style: TextStyle(
                  fontSize: 10.5,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              if (progress.sizeFormatted.isNotEmpty)
                Text(
                  progress.sizeFormatted,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                    fontFeatures: AppTypography.audioFigures,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFailedTaskTile({
    required BuildContext context,
    required DownloadTask task,
    required ThemeData theme,
    required bool isSolid,
    required VoidCallback onRetry,
    required VoidCallback onDismiss,
  }) {
    final track = task.track;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: StudioSurfaceTheme.surfaceContainer(context, isSolid: isSolid),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 44,
              height: 44,
              child: StudioArtworkWidget(
                track: track,
                width: 44,
                height: 44,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  task.errorMessage ?? 'Download failed',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              LucideIcons.rotateCw,
              size: 16,
              color: theme.colorScheme.primary,
            ),
            onPressed: onRetry,
            tooltip: 'Retry Download',
          ),
          IconButton(
            icon: const Icon(
              LucideIcons.x,
              size: 16,
              color: Colors.grey,
            ),
            onPressed: onDismiss,
            tooltip: 'Dismiss',
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedTaskTile({
    required BuildContext context,
    required DownloadTask task,
    required WidgetRef ref,
    required ThemeData theme,
    required bool isSolid,
  }) {
    final track = task.track;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: StudioSurfaceTheme.surfaceContainer(context, isSolid: isSolid),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 44,
              height: 44,
              child: StudioArtworkWidget(
                track: track,
                width: 44,
                height: 44,
              ),
            ),
          ),
          title: Text(
            track.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          ),
          subtitle: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'OFFLINE',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${track.artist} • ${track.album}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  LucideIcons.play,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                onPressed: () {
                  AppHaptics.selectionClick();
                  final playableTrack = (task.destinationPath != null && task.destinationPath!.isNotEmpty)
                      ? track.copyWith(filePath: task.destinationPath)
                      : track;
                  ref.read(playerControllerProvider.notifier).playTrack(playableTrack);
                },
                tooltip: 'Play Now',
              ),
              IconButton(
                icon: Icon(
                  LucideIcons.moreVertical,
                  size: 18,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                onPressed: () {
                  final playableTrack = (task.destinationPath != null && task.destinationPath!.isNotEmpty)
                      ? track.copyWith(filePath: task.destinationPath)
                      : track;
                  StudioTrackActionSheet.show(context, playableTrack);
                },
                tooltip: 'Actions',
              ),
            ],
          ),
          onTap: () {
            AppHaptics.selectionClick();
            final playableTrack = (task.destinationPath != null && task.destinationPath!.isNotEmpty)
                ? track.copyWith(filePath: task.destinationPath)
                : track;
            ref.read(playerControllerProvider.notifier).playTrack(playableTrack);
          },
        ),
      ),
    );
  }
}
