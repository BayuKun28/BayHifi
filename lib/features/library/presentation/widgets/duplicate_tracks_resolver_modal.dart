import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../app/theme/app_haptics.dart';
import '../../../../core/database/local_persistence_service.dart';
import '../../data/library_indexer_service.dart';
import '../controllers/library_controller.dart';

/// Modal dialog to inspect and purge duplicate audio tracks based on audiophile fidelity
class DuplicateTracksResolverModal extends ConsumerStatefulWidget {
  const DuplicateTracksResolverModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const DuplicateTracksResolverModal(),
    );
  }

  @override
  ConsumerState<DuplicateTracksResolverModal> createState() => _DuplicateTracksResolverModalState();
}

class _DuplicateTracksResolverModalState extends ConsumerState<DuplicateTracksResolverModal> {
  List<DuplicateTrackGroup> _duplicateGroups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _scanDuplicates();
  }

  void _scanDuplicates() {
    final libraryState = ref.read(unifiedLibraryProvider);
    final groups = LibraryIndexerService.instance.findDuplicates(libraryState.tracks);
    setState(() {
      _duplicateGroups = groups;
      _isLoading = false;
    });
  }

  Future<void> _purgeAllRedundantDuplicates() async {
    if (_duplicateGroups.isEmpty) return;
    AppHaptics.mediumImpact();

    final allRedundantIds = <String>{};
    for (final g in _duplicateGroups) {
      for (final red in g.redundantTracks) {
        allRedundantIds.add(red.id);
      }
    }

    final currentTracks = ref.read(unifiedLibraryProvider).tracks;
    final filtered = currentTracks.where((t) => !allRedundantIds.contains(t.id)).toList();

    await LocalPersistenceService.instance.saveLibraryTracks(
      filtered.map((t) => t.toMap()).toList(),
    );

    ref.read(unifiedLibraryProvider.notifier).saveLibraryTracks(filtered);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Purged ${allRedundantIds.length} duplicate lower-quality tracks.'),
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

    final totalRedundantCount = _duplicateGroups.fold<int>(
      0,
      (prev, g) => prev + g.redundantTracks.length,
    );

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
                HugeIcon(
                  icon: HugeIcons.strokeRoundedLayers01,
                  size: 20,
                  color: primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DUPLICATE TRACKS RESOLVER',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Identify duplicate audio files and preserve highest fidelity master',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
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
            ] else if (_duplicateGroups.isEmpty) ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                        size: 44,
                        color: const Color(0xFF00E676),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Zero Duplicate Tracks Found',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your library is perfectly deduplicated with unique audio entries.',
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
              // Summary Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.outlineVariant, width: 1.0),
                ),
                child: Row(
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedSparkles,
                      size: 16,
                      color: primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Found ${_duplicateGroups.length} duplicate groups ($totalRedundantCount redundant files can be purged).',
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

              // Duplicate Groups List
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _duplicateGroups.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final group = _duplicateGroups[index];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.colorScheme.outlineVariant, width: 0.8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  group.bestTrack.title,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              Text(
                                '${group.tracks.length} copies',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            group.bestTrack.artist,
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Best Track
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: primary.withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              children: [
                                HugeIcon(
                                  icon: HugeIcons.strokeRoundedCheckmarkBadge01,
                                  size: 14,
                                  color: primary,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Keep: ${group.bestTrack.format.name.toUpperCase()} (${group.bestTrack.bitDepth != null ? '${group.bestTrack.bitDepth}bit/' : ''}${((group.bestTrack.sampleRate ?? 44100) / 1000).toStringAsFixed(1)}kHz)',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Redundant Tracks
                          ...group.redundantTracks.map((red) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                              child: Row(
                                children: [
                                  HugeIcon(
                                    icon: HugeIcons.strokeRoundedDelete02,
                                    size: 12,
                                    color: theme.colorScheme.error,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Remove: ${red.format.name.toUpperCase()} (${red.bitrate != null ? '${red.bitrate}kbps' : 'Standard Quality'})',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Action Buttons
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _purgeAllRedundantDuplicates,
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedSparkles,
                    size: 16,
                    color: theme.colorScheme.onPrimary,
                  ),
                  label: Text(
                    'Purge $totalRedundantCount Redundant Files',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
