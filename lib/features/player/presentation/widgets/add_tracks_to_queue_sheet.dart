import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../../../app/theme/app_haptics.dart';
import '../../../../app/theme/studio_surface_theme.dart';
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

/// Pure Material 3 Expressive Bottom Sheet for adding dynamic batches of tracks to active queue (Namida style).
class AddTracksToQueueSheet extends ConsumerStatefulWidget {
  const AddTracksToQueueSheet({super.key});

  static Future<void> show(BuildContext context) {
    AppHaptics.lightImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddTracksToQueueSheet(),
    );
  }

  @override
  ConsumerState<AddTracksToQueueSheet> createState() => _AddTracksToQueueSheetState();
}

class _AddTracksToQueueSheetState extends ConsumerState<AddTracksToQueueSheet> {
  QueueAddSourceMode _selectedMode = QueueAddSourceMode.smartRandom;
  StudioMusicMood _selectedMood = StudioMusicMood.chillAcoustic;
  int _selectedCount = 10; // Default 10 tracks autofill as mandated
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
        final favTracks = allTracks.where((t) => library.favoriteTrackIds.contains(t.id)).toList();
        if (favTracks.isNotEmpty) {
          favTracks.shuffle();
          newTracks = favTracks.take(_selectedCount).toList();
        } else {
          newTracks = engine.generateQueueAdditions(
            currentTrack: currentTrack,
            pool: allTracks,
            criteria: InstantMixCriteria.smartRandom,
            count: _selectedCount,
          );
        }
        break;
    }

    if (newTracks.isEmpty) {
      newTracks = allTracks.take(_selectedCount).toList();
    }

    final isPlayNext = _placement == QueueAddPlacement.playNext;
    ref.read(playerControllerProvider.notifier).addTracksToQueue(newTracks, playNext: isPlayNext);

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isPlayNext
              ? 'Inserted ${newTracks.length} tracks up next in queue.'
              : 'Added ${newTracks.length} tracks to end of queue.',
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSolid = ref.isSolidStyle;
    final primary = colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: StudioSurfaceTheme.surfaceContainer(context, isSolid: isSolid),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.35 : 0.08,
            ),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Drag Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 2. Title & Icon
              Row(
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedPlayList,
                    size: 22,
                    color: primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Add Tracks to Queue',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: isSolid ? 0.18 : 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSolid ? colorScheme.outline : primary.withValues(alpha: 0.3),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      'SMART MIX',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        color: primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 3. Mode Selection Grid
              Text(
                'SELECT SOURCE & CRITERIA',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  _buildModeTile(
                    label: 'Random',
                    icon: HugeIcons.strokeRoundedShuffle,
                    mode: QueueAddSourceMode.smartRandom,
                  ),
                  const SizedBox(width: 8),
                  _buildModeTile(
                    label: 'Mood & Vibe',
                    icon: HugeIcons.strokeRoundedSparkles,
                    mode: QueueAddSourceMode.mood,
                  ),
                  const SizedBox(width: 8),
                  _buildModeTile(
                    label: 'Similar',
                    icon: HugeIcons.strokeRoundedAudioWaveform,
                    mode: QueueAddSourceMode.similarToCurrent,
                  ),
                  const SizedBox(width: 8),
                  _buildModeTile(
                    label: 'Favorites',
                    icon: HugeIcons.strokeRoundedFavourite,
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
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: StudioMusicMood.values.map((mood) {
                    final isSelected = _selectedMood == mood;
                    return InkWell(
                      borderRadius: BorderRadius.circular(10),
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
                              ? primary.withValues(alpha: isSolid ? 0.22 : 0.16)
                              : colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? primary
                                : colorScheme.outlineVariant.withValues(alpha: 0.5),
                            width: isSelected ? 1.4 : 0.8,
                          ),
                        ),
                        child: Text(
                          mood.displayName,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? primary : colorScheme.onSurface,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 18),

              // 4. Number of Tracks Selector (Default: 10)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'NUMBER OF TRACKS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '$_selectedCount tracks',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: primary,
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
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          AppHaptics.selectionClick();
                          setState(() {
                            _selectedCount = count;
                          });
                        },
                        child: Container(
                          height: 38,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? primary.withValues(alpha: isSolid ? 0.22 : 0.16)
                                : colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? primary
                                  : colorScheme.outlineVariant.withValues(alpha: 0.5),
                              width: isSelected ? 1.4 : 0.8,
                            ),
                          ),
                          child: Text(
                            '$count',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                              color: isSelected ? primary : colorScheme.onSurface,
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
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: colorScheme.onSurfaceVariant,
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
                      icon: HugeIcons.strokeRoundedPlaylist01,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildPlacementOption(
                      title: 'Play Next',
                      subtitle: 'Insert right after playing',
                      placement: QueueAddPlacement.playNext,
                      icon: HugeIcons.strokeRoundedNext,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 6. Action Button
              M3EButton.filled(
                label: Text(
                  _placement == QueueAddPlacement.playNext
                      ? 'INSERT $_selectedCount TRACKS NEXT'
                      : 'ADD $_selectedCount TRACKS TO END',
                ),
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedPlusSign,
                  size: 18,
                ),
                onPressed: _executeAdd,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeTile({
    required String label,
    required dynamic icon,
    required QueueAddSourceMode mode,
  }) {
    final theme = Theme.of(context);
    final isSolid = ref.isSolidStyle;
    final primary = theme.colorScheme.primary;
    final isSelected = _selectedMode == mode;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
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
                ? primary.withValues(alpha: isSolid ? 0.22 : 0.16)
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? primary : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: isSelected ? 1.4 : 0.8,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              HugeIcon(
                icon: icon,
                size: 18,
                color: isSelected ? primary : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? primary : theme.colorScheme.onSurface,
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
    required dynamic icon,
  }) {
    final theme = Theme.of(context);
    final isSolid = ref.isSolidStyle;
    final primary = theme.colorScheme.primary;
    final isSelected = _placement == placement;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
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
              ? primary.withValues(alpha: isSolid ? 0.18 : 0.12)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primary : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: isSelected ? 1.4 : 0.8,
          ),
        ),
        child: Row(
          children: [
            HugeIcon(
              icon: icon,
              size: 18,
              color: isSelected ? primary : theme.colorScheme.onSurfaceVariant,
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
                      color: isSelected ? primary : theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 9.5,
                      color: theme.colorScheme.onSurfaceVariant,
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
