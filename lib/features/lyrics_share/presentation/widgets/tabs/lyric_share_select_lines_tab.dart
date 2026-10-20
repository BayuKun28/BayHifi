import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:baydev_hifi/app/theme/app_haptics.dart';
import 'package:baydev_hifi/core/lyrics/east_asian_romanizer.dart';
import 'package:baydev_hifi/features/lyrics_share/presentation/controllers/lyric_share_controller.dart';

/// Tab 1: Lyrics lines selection and CJK Dual-Line Romanization toggle
class LyricShareSelectLinesTab extends StatelessWidget {
  final LyricShareState state;
  final LyricShareController controller;

  const LyricShareSelectLinesTab({
    super.key,
    required this.state,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allLines = state.allLines;

    return Column(
      children: [
        // Subtitles Options Header (Dual-Line Romanization)
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
            border: Border(
              bottom: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
              child: Icon(
                LucideIcons.type,
                size: 16,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dual-Line Romanization',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Auto-transliterate CJK (Romaji, Pinyin, Hangul)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: state.config.showDualLineRomanized,
              onChanged: (val) {
                AppHaptics.selectionClick();
                controller.toggleDualLineRomanized(val);
              },
              activeTrackColor: theme.colorScheme.primary,
            ),
          ],
        ),
      ),

      // List of lines
      Expanded(
        child: allLines.isEmpty
            ? Center(
                child: Text(
                  'No synchronized lyrics available for this track.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            : ListView.separated(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: allLines.length,
                separatorBuilder: (_, _) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final line = allLines[index];
                  final isSelected = state.config.selectedLines.contains(line);

                  // Automatic Romanization preview if enabled
                  String? subtitleText;
                  if (line.hasRomanization) {
                    subtitleText = line.effectiveRomanized;
                  } else if (EastAsianRomanizer.needsRomanization(line.text)) {
                    subtitleText = EastAsianRomanizer.romanize(line.text);
                  }

                  return GestureDetector(
                    onTap: () {
                      AppHaptics.selectionClick();
                      controller.toggleLineSelection(line);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary.withValues(alpha: 0.12)
                            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary.withValues(alpha: 0.4)
                              : Colors.transparent,
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Icon(
                              isSelected
                                  ? LucideIcons.circleCheck
                                  : LucideIcons.circle,
                              size: 18,
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  line.text,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurface,
                                  ),
                                ),
                                if (subtitleText != null && subtitleText.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    subtitleText,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontStyle: FontStyle.italic,
                                      color: isSelected
                                          ? theme.colorScheme.primary.withValues(alpha: 0.8)
                                          : theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ],
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
  );
}
}
