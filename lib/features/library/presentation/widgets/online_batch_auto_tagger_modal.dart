import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../app/theme/app_haptics.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/studio_surface_theme.dart';
import '../../../player/domain/track.dart';
import '../../../player/presentation/controllers/player_controller.dart';
import '../../data/metadata_tagger_service.dart';
import '../../data/online_metadata_service.dart';
import '../controllers/library_controller.dart';

class BatchMatchItem {
  final Track originalTrack;
  OnlineMetadataCandidate? matchedCandidate;
  DownloadedArtwork? downloadedArtwork;
  String? lyrics;
  bool isSelected;
  bool isSearching;
  String? error;

  BatchMatchItem({
    required this.originalTrack,
    this.matchedCandidate,
    this.downloadedArtwork,
    this.lyrics,
    this.isSelected = true,
    this.isSearching = true,
    this.error,
  });
}

class OnlineBatchAutoTaggerModal extends ConsumerStatefulWidget {
  final List<Track> tracks;

  const OnlineBatchAutoTaggerModal({super.key, required this.tracks});

  static Future<void> show(BuildContext context, List<Track> tracks) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => OnlineBatchAutoTaggerModal(tracks: tracks),
    );
  }

  @override
  ConsumerState<OnlineBatchAutoTaggerModal> createState() =>
      _OnlineBatchAutoTaggerModalState();
}

class _OnlineBatchAutoTaggerModalState
    extends ConsumerState<OnlineBatchAutoTaggerModal> {
  late List<BatchMatchItem> _items;
  bool _isSearchingAll = true;
  bool _isWriting = false;
  double _searchProgress = 0.0;
  double _writeProgress = 0.0;
  String _statusText = 'Starting online metadata search...';

  @override
  void initState() {
    super.initState();
    _items = widget.tracks
        .map((t) => BatchMatchItem(originalTrack: t, isSearching: true))
        .toList();
    _startBatchSearch();
  }

  Future<void> _startBatchSearch() async {
    final service = ref.read(onlineMetadataServiceProvider);
    int completed = 0;

    for (int i = 0; i < _items.length; i++) {
      if (!mounted) return;
      final item = _items[i];

      setState(() {
        _statusText = 'Searching (${i + 1}/${_items.length}): "${item.originalTrack.title}"...';
      });

      try {
        final candidates = await service.searchCandidatesForTrack(item.originalTrack);
        if (candidates.isNotEmpty) {
          final best = candidates.first;
          item.matchedCandidate = best;

          // Download artwork if available
          if (best.artworkUrl != null && best.artworkUrl!.isNotEmpty) {
            item.downloadedArtwork = await service.downloadArtwork(best.artworkUrl!);
          }

          // Fetch lyrics
          final lyricsRes = await service.fetchLyrics(
            title: best.title,
            artist: best.artist,
            album: best.album,
            durationSeconds: best.durationSeconds ?? item.originalTrack.duration.inSeconds,
          );
          item.lyrics = lyricsRes.lyrics;
          item.isSelected = best.confidenceScore >= 0.50;
        } else {
          item.error = 'No match found';
          item.isSelected = false;
        }
      } catch (e) {
        item.error = 'Search failed';
        item.isSelected = false;
      }

      item.isSearching = false;
      completed++;
      if (mounted) {
        setState(() {
          _searchProgress = completed / _items.length;
        });
      }

      // Safe debounce for rate-limiting
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }

    if (mounted) {
      setState(() {
        _isSearchingAll = false;
        final matchedCount = _items.where((it) => it.matchedCandidate != null).length;
        _statusText = 'Found matches for $matchedCount of ${_items.length} tracks.';
      });
    }
  }

  Future<void> _applyAndSaveAll() async {
    final selectedItems = _items
        .where((it) => it.isSelected && it.matchedCandidate != null)
        .toList();

    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tracks selected to update.')),
      );
      return;
    }

    setState(() {
      _isWriting = true;
      _statusText = 'Writing metadata & cover artwork to audio files...';
    });
    AppHaptics.mediumImpact();

    final taggingItems = <BatchTaggingItem>[];
    for (final item in selectedItems) {
      final c = item.matchedCandidate!;
      final tagData = c.toAudioTagData(
        downloadedArtwork: item.downloadedArtwork?.bytes,
        artworkMime: item.downloadedArtwork?.mimeType,
      );
      taggingItems.add(
        BatchTaggingItem(
          track: item.originalTrack,
          tagData: tagData,
        ),
      );
    }

    try {
      final result = await ref
          .read(unifiedLibraryProvider.notifier)
          .updateBatchTracksTags(
            taggingItems,
            onProgress: (cur, tot, file) {
              if (mounted) {
                setState(() {
                  _writeProgress = cur / tot;
                  _statusText = 'Writing ($cur/$tot): $file';
                });
              }
            },
          );

      // Sync active player if any updated track is in queue or currently playing
      ref.read(playerControllerProvider.notifier).updateBatchTracksMetadata(result.updatedTracks);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully updated tags for ${result.successCount} files!'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isWriting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error writing batch tags: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isSolid = ref.isSolidStyle;
    final primary = cs.primary;
    final mediaQuery = MediaQuery.of(context);

    final selectedCount = _items.where((it) => it.isSelected && it.matchedCandidate != null).length;

    return Container(
      constraints: BoxConstraints(
        maxHeight: mediaQuery.size.height * 0.90,
      ),
      decoration: BoxDecoration(
        color: StudioSurfaceTheme.surfaceContainer(context, isSolid: isSolid),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        border: Border.all(
          color: StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid),
          width: 1.0,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Drag Handle
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 6),
              child: Container(
                width: 38,
                height: 4.5,
                decoration: BoxDecoration(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: StudioCategoryColors.warmTubeAmber.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const HugeIcon(
                      icon: HugeIcons.strokeRoundedSparkles,
                      size: 18,
                      color: StudioCategoryColors.warmTubeAmber,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Batch Online Auto-Tagger',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface,
                            letterSpacing: -0.2,
                          ),
                        ),
                        Text(
                          _statusText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedCancel01,
                      size: 18,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Progress Bar
            if (_isSearchingAll || _isWriting)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                child: LinearProgressIndicator(
                  value: _isWriting ? _writeProgress : _searchProgress,
                  backgroundColor: cs.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _isWriting ? StudioCategoryColors.bitPerfect : StudioCategoryColors.warmTubeAmber,
                  ),
                  borderRadius: BorderRadius.circular(4),
                  minHeight: 4,
                ),
              ),

            const Divider(height: 12),

            // Tracks Review List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  final orig = item.originalTrack;
                  final match = item.matchedCandidate;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: StudioSurfaceTheme.surfaceContainerLow(context, isSolid: isSolid),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: item.isSelected
                            ? primary.withValues(alpha: 0.5)
                            : StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid),
                        width: item.isSelected ? 1.2 : 0.8,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Checkbox
                        Checkbox(
                          value: item.isSelected,
                          activeColor: primary,
                          onChanged: match != null && !_isWriting
                              ? (val) {
                                  setState(() {
                                    item.isSelected = val ?? false;
                                  });
                                }
                              : null,
                        ),
                        const SizedBox(width: 4),

                        // Artwork Thumbnail
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: item.downloadedArtwork != null
                                ? Image.memory(
                                    item.downloadedArtwork!.bytes,
                                    fit: BoxFit.cover,
                                  )
                                : (match?.artworkUrl != null
                                    ? Image.network(
                                        match!.artworkUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => const Center(
                                          child: HugeIcon(
                                            icon: HugeIcons.strokeRoundedMusicNote01,
                                            size: 18,
                                          ),
                                        ),
                                      )
                                    : const Center(
                                        child: HugeIcon(
                                          icon: HugeIcons.strokeRoundedMusicNote01,
                                          size: 18,
                                        ),
                                      )),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Track Details & Match Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                match != null ? match.title : orig.title,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: cs.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                match != null
                                    ? '${match.artist} • ${match.album}'
                                    : (orig.artist.isNotEmpty ? orig.artist : 'Original: ${orig.title}'),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: cs.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        // Status Badge or Loader
                        if (item.isSearching)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else if (match != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: StudioCategoryColors.bitPerfect.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${(match.confidenceScore * 100).round()}%',
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: StudioCategoryColors.bitPerfect,
                                fontFeatures: AppTypography.audioFigures,
                              ),
                            ),
                          )
                        else
                          Text(
                            item.error ?? 'No Match',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: cs.error,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Footer Action Button
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: cs.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                  ),
                  icon: _isWriting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const HugeIcon(
                          icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                          size: 20,
                          color: Colors.white,
                        ),
                  label: Text(
                    _isWriting
                        ? 'Writing Metadata to Files...'
                        : 'Apply & Save $selectedCount Tracks to Files',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  onPressed: (_isSearchingAll || _isWriting || selectedCount == 0)
                      ? null
                      : _applyAndSaveAll,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
