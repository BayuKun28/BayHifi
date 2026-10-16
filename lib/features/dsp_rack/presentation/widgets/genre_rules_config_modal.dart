import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import '../../../../app/theme/app_haptics.dart';
import '../../../../app/theme/studio_surface_theme.dart';
import '../../domain/dsp_models.dart';
import '../controllers/dsp_rack_controller.dart';

/// Modal dialog/sheet to configure genre-to-preset auto-apply mappings
class GenreRulesConfigModal extends ConsumerWidget {
  const GenreRulesConfigModal({super.key});

  /// Opens the Genre Rules Configuration bottom sheet
  static Future<void> show(BuildContext context) {
    AppHaptics.lightImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const GenreRulesConfigModal(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isSolid = ref.isSolidStyle;
    final primary = theme.colorScheme.primary;
    final controller = ref.read(dspRackControllerProvider.notifier);

    // Watch DSP rack state
    ref.watch(dspRackControllerProvider);

    final isAutoEnabled = controller.isAutoApplyGenreEnabled;
    final customMappings = controller.customGenreMappings;
    final availablePresets = [
      ...DspPreset.studioPresets,
      ...controller.customPresets,
    ];

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

            // ─── HEADER ───────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.sparkles,
                    size: 20,
                    color: primary,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'GENRE AUTO-PRESET RULES',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  M3EIconButton(
                    variant: M3EIconButtonVariant.standard,
                    icon: Icon(
                      LucideIcons.x,
                      size: 22,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ─── GLOBAL TOGGLE CARD ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: StudioSurfaceTheme.surfaceContainerHigh(
                    context,
                    isSolid: isSolid,
                    translucentAlpha: 0.4,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: StudioSurfaceTheme.outline(context, isSolid: isSolid),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Auto-Apply by Track Genre',
                            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Automatically adapt DSP rack when genre metadata is detected',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    M3ESwitch(
                      value: isAutoEnabled,
                      onChanged: (val) {
                        AppHaptics.selectionClick();
                        controller.setAutoApplyGenreEnabled(val);
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),

            // ─── GENRE CATEGORIES MAPPING LIST ────────────────────────────────
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                itemCount: GenrePresetMatcher.defaultGenreMappings.length,
                itemBuilder: (context, index) {
                  final mapping = GenrePresetMatcher.defaultGenreMappings[index];
                  final currentTargetId =
                      customMappings[mapping.genreKey] ?? mapping.targetPresetId;
                  final currentPreset = controller.findPresetById(currentTargetId) ??
                      DspPreset.studioPresets.firstWhere(
                        (p) => p.id == mapping.targetPresetId,
                        orElse: () => DspPreset.studioPresets.first,
                      );

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.outline.withValues(alpha: 0.2),
                          width: 0.8,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: StudioSurfaceTheme.tintedContainer(
                                    context,
                                    primary,
                                    isSolid: isSolid,
                                    translucentAlpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  mapping.displayName.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w900,
                                    color: primary,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              PopupMenuButton<DspPreset>(
                                tooltip: 'Select preset for ${mapping.displayName}',
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: StudioSurfaceTheme.outline(context, isSolid: isSolid),
                                  ),
                                ),
                                onSelected: (selectedPreset) {
                                  AppHaptics.selectionClick();
                                  controller.updateGenreMapping(
                                    mapping.genreKey,
                                    selectedPreset.id,
                                  );
                                },
                                itemBuilder: (context) {
                                  return availablePresets.map((preset) {
                                    final isSelected = preset.id == currentPreset.id;
                                    return PopupMenuItem<DspPreset>(
                                      value: preset,
                                      child: Row(
                                        children: [
                                          Icon(
                                            isSelected
                                                ? LucideIcons.circleCheck
                                                : LucideIcons.circle,
                                            size: 16,
                                            color: isSelected ? primary : Colors.grey,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              preset.name,
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: isSelected
                                                    ? FontWeight.w800
                                                    : FontWeight.w500,
                                                color: isSelected ? primary : null,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList();
                                },
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceContainerHigh,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: theme.colorScheme.outline.withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        currentPreset.name,
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: primary,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        LucideIcons.chevronDown,
                                        size: 12,
                                        color: primary,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Keywords: ${mapping.keywords.take(6).join(', ')}${mapping.keywords.length > 6 ? '...' : ''}',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
