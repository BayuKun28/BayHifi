import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:baydev_hifi/app/theme/app_haptics.dart';
import 'package:baydev_hifi/features/lyrics_share/domain/models/lyric_sticker_model.dart';
import 'package:baydev_hifi/features/lyrics_share/presentation/controllers/lyric_share_controller.dart';
import '../lyric_share_sheet_components.dart';

/// Tab 2: Audiophile Telemetry stamps, stickers, and personal note/caption
class LyricShareTelemetryTab extends StatelessWidget {
  final LyricShareState state;
  final LyricShareController controller;
  final TextEditingController noteTextController;

  const LyricShareTelemetryTab({
    super.key,
    required this.state,
    required this.controller,
    required this.noteTextController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stamp = state.config.audiophileStamp;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Audiophile Signal Chain Stamp Bento
          LyricShareBentoSection(
            theme: theme,
            title: 'SIGNAL CHAIN TELEMETRY STAMP',
            icon: LucideIcons.slidersHorizontal,
            child: Column(
              children: [
                LyricShareToggleRow(
                  title: 'Master Telemetry Stamp',
                  subtitle: 'Audiophile signal chain badge on footer',
                  value: stamp.enabled,
                  theme: theme,
                  onChanged: (val) {
                    AppHaptics.selectionClick();
                    controller.updateAudiophileStamp(enabled: val);
                  },
                ),
                if (stamp.enabled) ...[
                  const Divider(height: 12, thickness: 0.6),
                  LyricShareToggleRow(
                    title: 'Format & Sampling Rate',
                    subtitle: 'e.g. FLAC 96kHz / 24-bit',
                    value: stamp.showFormatRate,
                    theme: theme,
                    onChanged: (val) {
                      AppHaptics.selectionClick();
                      controller.updateAudiophileStamp(showFormatRate: val);
                    },
                  ),
                  const Divider(height: 12, thickness: 0.6),
                  LyricShareToggleRow(
                    title: 'AutoEQ Profile Tag',
                    subtitle: stamp.effectiveAutoEqName,
                    value: stamp.showAutoEqProfile,
                    theme: theme,
                    onChanged: (val) {
                      AppHaptics.selectionClick();
                      controller.updateAudiophileStamp(showAutoEqProfile: val);
                    },
                  ),
                  const Divider(height: 12, thickness: 0.6),
                  LyricShareToggleRow(
                    title: 'Virtual DSP Chain',
                    subtitle: stamp.effectiveDspChainName,
                    value: stamp.showVirtualDspChain,
                    theme: theme,
                    onChanged: (val) {
                      AppHaptics.selectionClick();
                      controller.updateAudiophileStamp(showVirtualDspChain: val);
                    },
                  ),
                  const Divider(height: 12, thickness: 0.6),
                  LyricShareToggleRow(
                    title: 'Hardware DAC / USB Bridge',
                    subtitle: stamp.effectiveDacName,
                    value: stamp.showHardwareDac,
                    theme: theme,
                    onChanged: (val) {
                      AppHaptics.selectionClick();
                      controller.updateAudiophileStamp(showHardwareDac: val);
                    },
                  ),
                  const Divider(height: 12, thickness: 0.6),
                  LyricShareToggleRow(
                    title: 'Timestamp & Signature',
                    subtitle: 'Render timestamp verification tag',
                    value: stamp.showTimestamp,
                    theme: theme,
                    onChanged: (val) {
                      AppHaptics.selectionClick();
                      controller.updateAudiophileStamp(showTimestamp: val);
                    },
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 2. Studio Stickers Bento
          LyricShareBentoSection(
            theme: theme,
            title: 'STUDIO STICKERS & STAMPS (MAX 3)',
            icon: LucideIcons.award,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: LyricStickerType.values.map((type) {
                final isSelected = state.config.selectedStickers.contains(type);
                return GestureDetector(
                  onTap: () {
                    AppHaptics.selectionClick();
                    controller.toggleSticker(type);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary.withValues(alpha: 0.15)
                          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          type.icon,
                          size: 14,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          type.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 12),

          // 3. Personal Note / Caption Bento
          LyricShareBentoSection(
            theme: theme,
            title: 'PERSONAL NOTE / CAPTION',
            icon: LucideIcons.filePen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: noteTextController,
                  maxLines: 2,
                  style: const TextStyle(fontSize: 12.5),
                  decoration: InputDecoration(
                    hintText: 'e.g. Listening to this late at night on HD600...',
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: theme.colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onChanged: (text) {
                    controller.setPersonalNote(text);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
