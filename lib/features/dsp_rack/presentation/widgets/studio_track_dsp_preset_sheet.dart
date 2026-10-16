import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import '../../../../app/theme/app_haptics.dart';
import '../../../../app/theme/studio_surface_theme.dart';
import '../../../../core/widgets/studio_artwork_widget.dart';
import '../../../player/domain/track.dart';
import '../../domain/dsp_models.dart';
import '../controllers/dsp_rack_controller.dart';
import 'genre_rules_config_modal.dart';

/// Modal Bottom Sheet for assigning and pinning DSP Mastering Presets per Track
class StudioTrackDspPresetSheet extends ConsumerWidget {
  final Track track;

  const StudioTrackDspPresetSheet({
    super.key,
    required this.track,
  });

  /// Displays the Track DSP Preset sheet
  static Future<void> show(BuildContext context, Track track) {
    AppHaptics.lightImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StudioTrackDspPresetSheet(track: track),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isSolid = ref.isSolidStyle;
    final primary = theme.colorScheme.primary;
    final controller = ref.read(dspRackControllerProvider.notifier);

    // Watch DSP rack state so sheet rebuilds when preset changes
    ref.watch(dspRackControllerProvider);

    final resolution = controller.resolvePresetForTrack(track);
    final isPinned = controller.isTrackPinned(track.id);
    final customPresets = controller.customPresets;

    final genrePresets = DspPreset.studioPresets
        .where((p) => p.id.startsWith('genre_'))
        .toList();
    final studioPresets = DspPreset.studioPresets
        .where((p) => !p.id.startsWith('genre_'))
        .toList();

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── DRAG HANDLE ──────────────────────────────────────────────────
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // ─── HEADER: TRACK INFO ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid),
                        width: 0.8,
                      ),
                    ),
                    child: StudioArtworkWidget(
                      track: track,
                      borderRadius: BorderRadius.circular(9),
                      fallbackIconSize: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          track.title,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${track.artist} • ${track.album}',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (track.genre != null && track.genre!.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: StudioSurfaceTheme.tintedContainer(
                                context,
                                theme.colorScheme.tertiary,
                                isSolid: isSolid,
                                translucentAlpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: isSolid
                                    ? theme.colorScheme.outline
                                    : theme.colorScheme.tertiary.withValues(alpha: 0.3),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              'GENRE: ${track.genre!.toUpperCase()}',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: theme.colorScheme.tertiary,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  M3EIconButton(
                    icon: const Icon(
                      LucideIcons.slidersHorizontal,
                      size: 20,
                      color: Colors.grey,
                    ),
                    tooltip: 'Configure Genre Rules',
                    onPressed: () {
                      GenreRulesConfigModal.show(context);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ─── ACTIVE RESOLUTION STATUS CARD ────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: StudioSurfaceTheme.surfaceContainerHigh(
                    context,
                    isSolid: isSolid,
                    translucentAlpha: 0.4,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isPinned
                        ? primary.withValues(alpha: 0.5)
                        : StudioSurfaceTheme.outline(context, isSolid: isSolid),
                    width: isPinned ? 1.2 : 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isPinned
                          ? LucideIcons.pin
                          : (resolution.source == DspResolutionSource.genreAuto
                              ? LucideIcons.sparkles
                              : LucideIcons.sliders),
                      size: 20,
                      color: isPinned ? primary : theme.colorScheme.secondary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isPinned
                                ? 'PINNED TRACK OVERRIDE'
                                : (resolution.source == DspResolutionSource.genreAuto
                                    ? 'AUTO-APPLIED BY GENRE (${resolution.matchedGenre?.toUpperCase() ?? "DETECTED"})'
                                    : 'GLOBAL ACTIVE PRESET'),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: isPinned
                                  ? primary
                                  : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            resolution.preset.name,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isPinned)
                      M3EButton.outlined(
                        label: const Text('UNPIN', style: TextStyle(fontSize: 11)),
                        icon: const Icon(
                          LucideIcons.x,
                          size: 14,
                          color: Colors.redAccent,
                        ),
                        onPressed: () {
                          AppHaptics.lightImpact();
                          controller.unpinPresetForTrack(track.id, activeTrack: track);
                        },
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),

            // ─── PRESETS SELECTION LIST ───────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  // 1. Curated Genre Presets
                  _buildSectionHeader(
                    context,
                    title: 'GENRE-OPTIMIZED PRESETS',
                    icon: LucideIcons.sparkles,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 6),
                  ...genrePresets.map((preset) => _buildPresetTile(
                        context,
                        preset: preset,
                        isSelected: resolution.preset.id == preset.id,
                        isPinned: isPinned && controller.getTrackOverride(track.id)?.presetId == preset.id,
                        onTap: () {
                          AppHaptics.selectionClick();
                          controller.pinPresetForTrack(track.id, preset, trackTitle: track.title);
                        },
                      )),

                  const SizedBox(height: 14),

                  // 2. Studio Reference Presets
                  _buildSectionHeader(
                    context,
                    title: 'STUDIO REFERENCE PRESETS',
                    icon: LucideIcons.slidersHorizontal,
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(height: 6),
                  ...studioPresets.map((preset) => _buildPresetTile(
                        context,
                        preset: preset,
                        isSelected: resolution.preset.id == preset.id,
                        isPinned: isPinned && controller.getTrackOverride(track.id)?.presetId == preset.id,
                        onTap: () {
                          AppHaptics.selectionClick();
                          controller.pinPresetForTrack(track.id, preset, trackTitle: track.title);
                        },
                      )),

                  // 3. Custom User Profiles
                  if (customPresets.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _buildSectionHeader(
                      context,
                      title: 'CUSTOM USER PROFILES',
                      icon: LucideIcons.user,
                      color: theme.colorScheme.tertiary,
                    ),
                    const SizedBox(height: 6),
                    ...customPresets.map((preset) => _buildPresetTile(
                          context,
                          preset: preset,
                          isSelected: resolution.preset.id == preset.id,
                          isPinned: isPinned && controller.getTrackOverride(track.id)?.presetId == preset.id,
                          onTap: () {
                            AppHaptics.selectionClick();
                            controller.pinPresetForTrack(track.id, preset, trackTitle: track.title);
                          },
                        )),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: color,
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPresetTile(
    BuildContext context, {
    required DspPreset preset,
    required bool isSelected,
    required bool isPinned,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: isSelected
            ? primary.withValues(alpha: 0.12)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? primary.withValues(alpha: 0.6)
                    : theme.colorScheme.outline.withValues(alpha: 0.2),
                width: isSelected ? 1.2 : 0.8,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isPinned
                      ? LucideIcons.pin
                      : (isSelected
                          ? LucideIcons.circleCheck
                          : LucideIcons.circle),
                  size: 18,
                  color: isSelected ? primary : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        preset.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected ? primary : theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        preset.description,
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (isPinned) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'PINNED',
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                        color: primary,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
