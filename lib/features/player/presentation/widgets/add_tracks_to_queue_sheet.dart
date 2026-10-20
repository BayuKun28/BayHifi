import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/theme/app_haptics.dart';
import '../../../../app/theme/simple_as_f_theme.dart';
import '../../../library/domain/instant_mix_engine.dart';
import '../../../library/presentation/controllers/library_controller.dart';
import '../../domain/track.dart';
import '../controllers/player_controller.dart';

enum QueueAddSourceMode {
  smartRandom,
  mood,
  similarToCurrent,
  favorites,
}

/// Solid Matte Dialog & Bottom Sheet for adding dynamic batches of tracks to active queue.
class AddTracksToQueueSheet extends ConsumerStatefulWidget {
  final bool isDialog;

  const AddTracksToQueueSheet({
    super.key,
    this.isDialog = false,
  });

  static Future<void> show(BuildContext context) {
    AppHaptics.lightImpact();
    final width = MediaQuery.of(context).size.width;
    if (width >= 650) {
      return showDialog(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.65),
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: const AddTracksToQueueSheet(isDialog: true),
            ),
          ),
        ),
      );
    }

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddTracksToQueueSheet(isDialog: false),
    );
  }

  @override
  ConsumerState<AddTracksToQueueSheet> createState() => _AddTracksToQueueSheetState();
}

class _AddTracksToQueueSheetState extends ConsumerState<AddTracksToQueueSheet> {
  QueueAddSourceMode _selectedMode = QueueAddSourceMode.smartRandom;
  StudioMusicMood _selectedMood = StudioMusicMood.chillAcoustic;
  int _selectedCount = 10;
  QueueAddPlacement _placement = QueueAddPlacement.appendToEnd;

  static const List<int> _countOptions = [5, 10, 20, 50];

  void _executeAdd() {
    AppHaptics.heavyImpact();
    final library = ref.read(unifiedLibraryProvider);
    final allTracks = library.tracks;
    if (allTracks.isEmpty) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Library is empty.')),
      );
      return;
    }

    final currentTrack = ref.read(playerControllerProvider).currentTrack;
    const engine = InstantMixEngine();
    List<Track> newTracks = [];

    switch (_selectedMode) {
      case QueueAddSourceMode.smartRandom:
        newTracks = engine.generateQueueAdditions(
          currentTrack: currentTrack,
          pool: allTracks,
          criteria: InstantMixCriteria.smartRandom,
          count: _selectedCount,
          favoriteIds: library.favoriteTrackIds,
        );
        break;

      case QueueAddSourceMode.mood:
        newTracks = engine.generateQueueAdditions(
          currentTrack: currentTrack,
          pool: allTracks,
          criteria: InstantMixCriteria.mood,
          targetMood: _selectedMood,
          count: _selectedCount,
          favoriteIds: library.favoriteTrackIds,
        );
        break;

      case QueueAddSourceMode.similarToCurrent:
        if (currentTrack != null) {
          newTracks = engine.generateInstantMix(
            seedTrack: currentTrack,
            pool: allTracks,
            criteria: InstantMixCriteria.genre,
            count: _selectedCount,
            favoriteIds: library.favoriteTrackIds,
          );
        } else {
          newTracks = engine.generateQueueAdditions(
            pool: allTracks,
            criteria: InstantMixCriteria.smartRandom,
            count: _selectedCount,
            favoriteIds: library.favoriteTrackIds,
          );
        }
        break;

      case QueueAddSourceMode.favorites:
        final favorites = allTracks
            .where((t) => library.favoriteTrackIds.contains(t.id))
            .toList();
        if (favorites.isNotEmpty) {
          newTracks = engine.generateQueueAdditions(
            pool: favorites,
            criteria: InstantMixCriteria.smartRandom,
            count: _selectedCount,
          );
        } else {
          newTracks = engine.generateQueueAdditions(
            pool: allTracks,
            criteria: InstantMixCriteria.smartRandom,
            count: _selectedCount,
          );
        }
        break;
    }

    if (newTracks.isNotEmpty) {
      ref.read(playerControllerProvider.notifier).addTracksToQueue(
            newTracks,
            playNext: _placement == QueueAddPlacement.playNext,
          );
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Added ${newTracks.length} tracks to ${_placement == QueueAddPlacement.playNext ? 'play next' : 'queue end'}.',
          ),
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1E212B)
              : Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
      );
    } else {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No matching tracks found.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDialog = widget.isDialog;
    final metaColor = isDark ? const Color(0xFF8A9A90) : theme.colorScheme.onSurfaceVariant;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16181F) : theme.colorScheme.surfaceContainer,
        borderRadius: isDialog
            ? BorderRadius.circular(24)
            : SimpleAsFTheme.sheetTopBorderRadius,
        border: Border.all(
          color: isDark ? const Color(0xFF262936) : theme.colorScheme.outlineVariant,
          width: 1.0,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Drag Handle (mobile only)
              if (!isDialog) ...[
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2E3242) : theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // 2. Title & Icon
              Row(
                children: [
                  const Icon(
                    LucideIcons.listPlus,
                    size: 20,
                    color: Color(0xFF10B981),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Add Tracks to Queue',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : theme.colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E212B) : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isDark ? const Color(0xFF262936) : theme.colorScheme.outlineVariant, width: 0.8),
                    ),
                    child: const Text(
                      'SMART MIX',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF10B981),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  if (isDialog) ...[
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(LucideIcons.x, size: 16, color: Color(0xFF8A9A90)),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 18),

              // 3. Mode Selection Grid
              Text(
                'SELECT SOURCE & CRITERIA',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: metaColor,
                ),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  _buildModeTile( 
                    label: 'Random',
                    icon: LucideIcons.shuffle,
                    mode: QueueAddSourceMode.smartRandom,
                  ),
                  const SizedBox(width: 8),
                  _buildModeTile( 
                    label: 'Mood',
                    icon: LucideIcons.sparkles,
                    mode: QueueAddSourceMode.mood,
                  ),
                  const SizedBox(width: 8),
                  _buildModeTile( 
                    label: 'Similar',
                    icon: LucideIcons.audioLines,
                    mode: QueueAddSourceMode.similarToCurrent,
                  ),
                  const SizedBox(width: 8),
                  _buildModeTile( 
                    label: 'Favorites',
                    icon: LucideIcons.heart,
                    mode: QueueAddSourceMode.favorites,
                  ),
                ],
              ),

              // Mood Selector Sub-options
              if (_selectedMode == QueueAddSourceMode.mood) ...[
                const SizedBox(height: 14),
                Text(
                  'TARGET MOOD',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: metaColor,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: StudioMusicMood.values.map((mood) {
                    final isSelected = _selectedMood == mood;
                    return InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        AppHaptics.selectionClick();
                        setState(() {
                          _selectedMood = mood;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isDark ? const Color(0xFF252834) : theme.colorScheme.surfaceContainerHighest)
                              : (isDark ? const Color(0xFF16181F) : theme.colorScheme.surfaceContainer),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? (isDark ? const Color(0xFF383D50) : theme.colorScheme.outline)
                                : (isDark ? const Color(0xFF262936) : theme.colorScheme.outlineVariant),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          mood.displayName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected
                                ? (isDark ? Colors.white : theme.colorScheme.onSurface)
                                : (isDark ? const Color(0xFFA1B2A7) : theme.colorScheme.onSurfaceVariant),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 18),

              // 4. Number of Tracks Selector
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'NUMBER OF TRACKS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: metaColor,
                    ),
                  ),
                  Text(
                    '$_selectedCount tracks',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : theme.colorScheme.onSurface,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _countOptions.map((count) {
                  final isSelected = _selectedCount == count;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3.0),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          AppHaptics.selectionClick();
                          setState(() {
                            _selectedCount = count;
                          });
                        },
                        child: Container(
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark ? const Color(0xFF252834) : theme.colorScheme.surfaceContainerHighest)
                                : (isDark ? const Color(0xFF16181F) : theme.colorScheme.surfaceContainer),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? (isDark ? const Color(0xFF383D50) : theme.colorScheme.outline)
                                  : (isDark ? const Color(0xFF262936) : theme.colorScheme.outlineVariant),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            '$count',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                              color: isSelected
                                  ? (isDark ? Colors.white : theme.colorScheme.onSurface)
                                  : (isDark ? const Color(0xFFA1B2A7) : theme.colorScheme.onSurfaceVariant),
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 18),

              // 5. Queue Placement Selector
              Text(
                'QUEUE PLACEMENT',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: metaColor,
                ),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: _buildPlacementOption( 
                      title: 'Append to End',
                      subtitle: 'Add after current queue',
                      placement: QueueAddPlacement.appendToEnd,
                      icon: LucideIcons.listPlus,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildPlacementOption( 
                      title: 'Play Next',
                      subtitle: 'Insert right after playing',
                      placement: QueueAddPlacement.playNext,
                      icon: LucideIcons.stepForward,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 6. Action Button
              SizedBox(
                height: 42,
                child: ElevatedButton.icon(
                  onPressed: _executeAdd,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF252834) : theme.colorScheme.surfaceContainerHighest,
                    foregroundColor: isDark ? Colors.white : theme.colorScheme.onSurface,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: isDark ? const Color(0xFF2E3242) : theme.colorScheme.outlineVariant, width: 1),
                    ),
                  ),
                  icon: const Icon(LucideIcons.plus, size: 16),
                  label: Text(
                    _placement == QueueAddPlacement.playNext
                        ? 'INSERT $_selectedCount TRACKS NEXT'
                        : 'ADD $_selectedCount TRACKS TO END',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeTile({
    required String label,
    required IconData icon,
    required QueueAddSourceMode mode,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSelected = _selectedMode == mode;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          AppHaptics.selectionClick();
          setState(() {
            _selectedMode = mode;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF252834) : theme.colorScheme.surfaceContainerHighest)
                : (isDark ? const Color(0xFF16181F) : theme.colorScheme.surfaceContainer),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? (isDark ? const Color(0xFF383D50) : theme.colorScheme.outline)
                  : (isDark ? const Color(0xFF262936) : theme.colorScheme.outlineVariant),
              width: 0.8,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? (isDark ? Colors.white : theme.colorScheme.onSurface)
                    : (isDark ? const Color(0xFF8A9A90) : theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected
                      ? (isDark ? Colors.white : theme.colorScheme.onSurface)
                      : (isDark ? const Color(0xFFA1B2A7) : theme.colorScheme.onSurfaceVariant),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlacementOption({
    required String title,
    required String subtitle,
    required QueueAddPlacement placement,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSelected = _placement == placement;
    final meta = isDark ? const Color(0xFF8A9A90) : theme.colorScheme.onSurfaceVariant;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        AppHaptics.selectionClick();
        setState(() {
          _placement = placement;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF20232E) : theme.colorScheme.surfaceContainerHighest)
              : (isDark ? const Color(0xFF16181F) : theme.colorScheme.surfaceContainer),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? (isDark ? const Color(0xFF383D50) : theme.colorScheme.outline)
                : (isDark ? const Color(0xFF262936) : theme.colorScheme.outlineVariant),
            width: 0.8,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? const Color(0xFF10B981) : meta,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected
                          ? (isDark ? Colors.white : theme.colorScheme.onSurface)
                          : (isDark ? const Color(0xFFA1B2A7) : theme.colorScheme.onSurfaceVariant),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 9.5,
                      color: meta,
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
    );
  }
}
