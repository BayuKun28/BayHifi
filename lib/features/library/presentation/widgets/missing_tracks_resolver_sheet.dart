import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_haptics.dart';
import '../../../../core/database/local_persistence_service.dart';
import '../../../player/domain/track.dart';
import '../../data/library_indexer_service.dart';
import '../controllers/library_controller.dart';

/// Modal Sheet to inspect and resolve missing audio tracks in library
class MissingTracksResolverSheet extends ConsumerStatefulWidget {
  const MissingTracksResolverSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const MissingTracksResolverSheet(),
    );
  }

  @override
  ConsumerState<MissingTracksResolverSheet> createState() => _MissingTracksResolverSheetState();
}

class _MissingTracksResolverSheetState extends ConsumerState<MissingTracksResolverSheet> {
  bool _isLoading = true;
  List<Track> _missingTracks = [];
  List<MovedTrackMatch> _candidateMatches = [];

  @override
  void initState() {
    super.initState();
    _scanForMissingTracks();
  }

  Future<void> _scanForMissingTracks() async {
    setState(() => _isLoading = true);

    final libraryState = ref.read(unifiedLibraryProvider);
    final indexer = LibraryIndexerService.instance;

    final missing = await indexer.findMissingTracks(libraryState.tracks);
    final musicFolders = LocalPersistenceService.instance.getMusicFolders();

    List<MovedTrackMatch> matches = [];
    if (missing.isNotEmpty && musicFolders.isNotEmpty) {
      matches = await indexer.findMovedTrackCandidates(missing, musicFolders);
    }

    if (mounted) {
      setState(() {
        _missingTracks = missing;
        _candidateMatches = matches;
        _isLoading = false;
      });
    }
  }

  Future<void> _relinkMatchedTracks() async {
    if (_candidateMatches.isEmpty) return;
    AppHaptics.mediumImpact();

    final relinkMap = {for (final m in _candidateMatches) m.track.id: m.newFilePath};
    final libraryCtrl = ref.read(unifiedLibraryProvider.notifier);

    final currentTracks = ref.read(unifiedLibraryProvider).tracks;
    final updatedList = currentTracks.map((t) {
      final newPath = relinkMap[t.id];
      if (newPath != null) {
        return t.copyWith(filePath: newPath);
      }
      return t;
    }).toList();

    await LocalPersistenceService.instance.saveLibraryTracks(
      updatedList.map((t) => t.toMap()).toList(),
    );

    // Refresh state
    libraryCtrl.saveLibraryTracks(updatedList);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Relinked ${_candidateMatches.length} moved tracks.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _removeMissingTracks() async {
    if (_missingTracks.isEmpty) return;
    AppHaptics.mediumImpact();

    final missingIds = _missingTracks.map((t) => t.id).toSet();
    final currentTracks = ref.read(unifiedLibraryProvider).tracks;
    final remaining = currentTracks.where((t) => !missingIds.contains(t.id)).toList();

    await LocalPersistenceService.instance.saveLibraryTracks(
      remaining.map((t) => t.toMap()).toList(),
    );

    ref.read(unifiedLibraryProvider.notifier).saveLibraryTracks(remaining);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed ${_missingTracks.length} missing tracks from library.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                Icon(
                  LucideIcons.folderSync,
                  size: 20,
                  color: primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MISSING TRACKS RESOLVER',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Scan and repair references to moved or deleted files',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _scanForMissingTracks,
                  icon: Icon(
                    LucideIcons.refreshCw,
                    size: 18,
                    color: primary,
                  ),
                  tooltip: 'Rescan',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Content
            if (_isLoading) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: CircularProgressIndicator(),
                ),
              ),
            ] else if (_missingTracks.isEmpty) ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.circleCheck,
                        size: 44,
                        color: const Color(0xFF00E676),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Library Integrity 100% Intact',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'All audio tracks resolve to existing local physical files.',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // Summary Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.outlineVariant, width: 1.0),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.alertTriangle,
                      size: 16,
                      color: const Color(0xFFFF9F0A),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_missingTracks.length} missing file${_missingTracks.length > 1 ? 's' : ''} detected (${_candidateMatches.length} match${_candidateMatches.length == 1 ? '' : 'es'} found in source folders).',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Missing Tracks List
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _missingTracks.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final track = _missingTracks[index];
                    final match = _candidateMatches.cast<MovedTrackMatch?>().firstWhere(
                          (m) => m?.track.id == track.id,
                          orElse: () => null,
                        );

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: (match != null ? primary : theme.colorScheme.error)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              match != null
                                  ? LucideIcons.folderSync
                                  : LucideIcons.fileX,
                              size: 16,
                              color: match != null ? primary : theme.colorScheme.error,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  track.title,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  track.artist,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                if (match != null)
                                  Text(
                                    'Candidate: ${match.newFilePath.split('/').last} (${(match.confidence * 100).toInt()}% match)',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: primary,
                                    ),
                                  )
                                else
                                  Text(
                                    'Path: ${track.filePath ?? 'Unknown'}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _removeMissingTracks,
                      icon: Icon(
                        LucideIcons.trash2,
                        size: 14,
                        color: theme.colorScheme.error,
                      ),
                      label: Text(
                        'Remove Missing',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.error,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  if (_candidateMatches.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _relinkMatchedTracks,
                        icon: Icon(
                          LucideIcons.link,
                          size: 14,
                          color: theme.colorScheme.onPrimary,
                        ),
                        label: Text(
                          'Relink ${_candidateMatches.length} Found',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
