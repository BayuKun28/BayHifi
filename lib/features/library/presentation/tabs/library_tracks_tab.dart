import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/theme/studio_surface_theme.dart';
import '../../../../core/widgets/studio_alphabetical_scroller.dart';
import '../../../player/domain/track.dart';
import '../../../player/presentation/controllers/player_controller.dart';
import '../../domain/library_collection_models.dart';
import '../controllers/library_controller.dart';
import '../controllers/library_selection_controller.dart';
import '../widgets/batch_track_tag_editor_modal.dart';
import '../widgets/online_batch_auto_tagger_modal.dart';
import '../widgets/track_tile.dart';

/// Modular Presentation Tab for Library Tracks View (Alphabetical Scroller & List)
class LibraryTracksTab extends ConsumerWidget {
  final ScrollController scrollController;
  final double bottomPadding;
  final Widget? emptyView;
  final VoidCallback? onDismissKeyboard;
  final void Function(Track track)? onAddToPlaylist;

  const LibraryTracksTab({
    super.key,
    required this.scrollController,
    required this.bottomPadding,
    this.emptyView,
    this.onDismissKeyboard,
    this.onAddToPlaylist,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryState = ref.watch(unifiedLibraryProvider);
    final tracks = libraryState.tracks;
    final currentPlayingId = ref.watch(playerControllerProvider.select((s) => s.currentTrack?.id));
    final selectionState = ref.watch(librarySelectionProvider);
    final theme = Theme.of(context);
    final isSolid = ref.isSolidStyle;

    if (tracks.isEmpty) {
      return emptyView ?? const Center(child: Text('No audio tracks found.'));
    }

    final isUntaggedFilter = libraryState.selectedFilter == LibrarySourceFilter.untagged;

    final isAlphabetical = !isUntaggedFilter &&
        (libraryState.sortField == SortField.title ||
            libraryState.sortField == SortField.artist ||
            libraryState.sortField == SortField.album);

    final trackListContent = ListView.builder(
      controller: scrollController,
      itemExtent: null,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(14, 4, isAlphabetical ? 28 : 14, bottomPadding),
      itemCount: tracks.length + (isUntaggedFilter ? 1 : 0),
      itemBuilder: (ctx, index) {
        if (isUntaggedFilter && index == 0) {
          return _buildUntaggedQuickBanner(context, tracks, theme, isSolid);
        }

        final trackIndex = isUntaggedFilter ? index - 1 : index;
        final track = tracks[trackIndex];
        final isPlayingThis = currentPlayingId == track.id;
        final isSelected = selectionState.isSelected(track.id);

        return TrackTile(
          track: track,
          isPlaying: isPlayingThis,
          isMultiSelecting: selectionState.isSelecting,
          isSelected: isSelected,
          onTap: () {
            onDismissKeyboard?.call();
            FocusManager.instance.primaryFocus?.unfocus();
            if (selectionState.isSelecting) {
              ref.read(librarySelectionProvider.notifier).toggle(track.id);
            } else {
              ref.read(playerControllerProvider.notifier).setQueue(tracks, initialIndex: trackIndex);
            }
          },
          onLongPress: () => ref.read(librarySelectionProvider.notifier).toggle(track.id),
          onPlayNext: () => ref.read(playerControllerProvider.notifier).playNext(track),
          onAddToQueue: () => ref.read(playerControllerProvider.notifier).addToQueue(track),
          onAddToPlaylist: () => onAddToPlaylist?.call(track),
        );
      },
    );

    return StudioAlphabeticalScroller(
      scrollController: scrollController,
      itemCount: tracks.length,
      itemHeight: 84.0,
      isAlphabetical: isAlphabetical,
      letterSelector: (index) {
        if (index < 0 || index >= tracks.length) return '';
        final track = tracks[index];
        return switch (libraryState.sortField) {
          SortField.artist => track.artist,
          SortField.album => track.album,
          _ => track.title,
        };
      },
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: trackListContent,
    );
  }

  Widget _buildUntaggedQuickBanner(
    BuildContext context,
    List<Track> tracks,
    ThemeData theme,
    bool isSolid,
  ) {
    final cs = theme.colorScheme;
    final primary = cs.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12, top: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: StudioSurfaceTheme.tintedContainer(
          context,
          primary,
          isSolid: isSolid,
          solidBlendAlpha: 0.16,
          translucentAlpha: 0.12,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primary.withValues(alpha: 0.35),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  LucideIcons.alertCircle,
                  size: 18,
                  color: primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${tracks.length} Untagged Tracks Found',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                    ),
                    Text(
                      'These tracks lack proper artist, album tags, or cover art.',
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 1,
                  ),
                  icon: const Icon(
                    LucideIcons.sparkles,
                    size: 16,
                    color: Colors.black,
                  ),
                  label: const Text(
                    'Auto-Tag All from Internet',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                  onPressed: () {
                    OnlineBatchAutoTaggerModal.show(context, tracks);
                  },
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: cs.onSurface,
                  side: BorderSide(
                    color: StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(
                  LucideIcons.pencil,
                  size: 15,
                ),
                label: const Text(
                  'Batch Edit',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                onPressed: () {
                  BatchTrackTagEditorModal.show(context, tracks);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
