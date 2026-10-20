import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../../../app/theme/app_haptics.dart';
import '../../../../app/theme/studio_surface_theme.dart';
import '../../../../app/theme/simple_as_f_theme.dart';
import '../../../../core/widgets/studio_artwork_widget.dart';
import '../../../player/domain/track.dart';
import '../../../player/presentation/controllers/player_controller.dart';
import '../../domain/instant_mix_engine.dart';
import '../controllers/library_controller.dart';

/// Pure Material 3 Expressive Bottom Sheet for configuring and launching an Instant Mix.
class InstantMixConfigSheet extends ConsumerStatefulWidget {
  const InstantMixConfigSheet({
    super.key,
    required this.seedTrack,
  });

  final Track seedTrack;

  static Future<void> show(BuildContext context, {required Track seedTrack}) {
    AppHaptics.lightImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => InstantMixConfigSheet(seedTrack: seedTrack),
    );
  }

  @override
  ConsumerState<InstantMixConfigSheet> createState() => _InstantMixConfigSheetState();
}

class _InstantMixConfigSheetState extends ConsumerState<InstantMixConfigSheet> {
  InstantMixCriteria _selectedCriteria = InstantMixCriteria.genre;
  StudioMusicMood _selectedMood = StudioMusicMood.energetic;
  int _selectedCount = 10; // Default 10 tracks autofill as mandated

  static const List<int> _countOptions = [5, 10, 15, 25, 50];

  @override
  void initState() {
    super.initState();
    // Default mood inferred from seed track
    if (widget.seedTrack.isHiRes) {
      _selectedMood = StudioMusicMood.audiophileMaster;
    } else {
      final g = (widget.seedTrack.genre ?? '').toLowerCase();
      if (g.contains('acoustic') || g.contains('classic') || g.contains('ambient')) {
        _selectedMood = StudioMusicMood.chillAcoustic;
      } else if (g.contains('r&b') || g.contains('soul') || g.contains('lo-fi') || g.contains('indie')) {
        _selectedMood = StudioMusicMood.melancholic;
      } else {
        _selectedMood = StudioMusicMood.energetic;
      }
    }
  }

  void _executeMix() {
    AppHaptics.heavyImpact();
    final library = ref.read(unifiedLibraryProvider);
    final allTracks = library.tracks;

    const engine = InstantMixEngine();
    final mixedTracks = engine.generateInstantMix(
      seedTrack: widget.seedTrack,
      pool: allTracks,
      criteria: _selectedCriteria,
      targetMood: _selectedCriteria == InstantMixCriteria.mood ? _selectedMood : null,
      count: _selectedCount,
      favoriteIds: library.favoriteTrackIds,
    );

    ref.read(playerControllerProvider.notifier).startInstantMix(widget.seedTrack, mixedTracks);

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Started Instant Mix with ${mixedTracks.length + 1} tracks.'),
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
        borderRadius: SimpleAsFTheme.sheetTopBorderRadius,
        border: Border.all(
          color: StudioSurfaceTheme.outline(context, isSolid: isSolid),
          width: 1.0,
        ),
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

              // 2. Title & Badge
              Row(
                children: [
                  Icon(
                    LucideIcons.sparkles,
                    size: 22,
                    color: primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Instant Mix Studio',
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
                      'AUTOPLAY',
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
              const SizedBox(height: 14),

              // 3. Seed Track Hero Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: StudioArtworkWidget(
                        track: widget.seedTrack,
                        borderRadius: BorderRadius.circular(10),
                        fallbackIconSize: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.seedTrack.title,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${widget.seedTrack.artist} • ${widget.seedTrack.album}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (widget.seedTrack.isHiRes) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: primary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'HI-RES',
                                    style: TextStyle(
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w900,
                                      color: primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              if (widget.seedTrack.genre != null && widget.seedTrack.genre!.isNotEmpty)
                                Text(
                                  widget.seedTrack.genre!.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // 4. Mix By Selector (Segmented Cards)
              Text(
                'MIX BY CRITERIA',
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
                  _buildCriteriaChip(
                    label: 'Genre',
                    icon: LucideIcons.guitar,
                    criteria: InstantMixCriteria.genre,
                  ),
                  const SizedBox(width: 8),
                  _buildCriteriaChip(
                    label: 'Mood',
                    icon: LucideIcons.sparkles,
                    criteria: InstantMixCriteria.mood,
                  ),
                  const SizedBox(width: 8),
                  _buildCriteriaChip(
                    label: 'Artist & Era',
                    icon: LucideIcons.mic,
                    criteria: InstantMixCriteria.artistAndEra,
                  ),
                  const SizedBox(width: 8),
                  _buildCriteriaChip(
                    label: 'Random',
                    icon: LucideIcons.shuffle,
                    criteria: InstantMixCriteria.smartRandom,
                  ),
                ],
              ),

              // Mood Sub-Selector (Visible when Mood is active)
              if (_selectedCriteria == InstantMixCriteria.mood) ...[
                const SizedBox(height: 14),
                Text(
                  'TARGET MOOD & VIBE',
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

              // 5. Track Count Selector (Default: 10)
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

              const SizedBox(height: 24),

              // 6. Launch Button
              M3EButton.filled(
                label: Text('START INSTANT MIX (${_selectedCount + 1} TRACKS)'),
                icon: const Icon(
                  LucideIcons.play,
                  size: 18,
                ),
                onPressed: _executeMix,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCriteriaChip({
    required String label,
    required IconData icon,
    required InstantMixCriteria criteria,
  }) {
    final theme = Theme.of(context);
    final isSolid = ref.isSolidStyle;
    final primary = theme.colorScheme.primary;
    final isSelected = _selectedCriteria == criteria;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          AppHaptics.selectionClick();
          setState(() {
            _selectedCriteria = criteria;
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
              Icon(
                icon,
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
}
