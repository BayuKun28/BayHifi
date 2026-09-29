import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/studio_surface_theme.dart';
import '../controllers/sleep_timer_controller.dart';

class SleepTimerSheet extends ConsumerStatefulWidget {
  const SleepTimerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SleepTimerSheet(),
    );
  }

  @override
  ConsumerState<SleepTimerSheet> createState() => _SleepTimerSheetState();
}

class _SleepTimerSheetState extends ConsumerState<SleepTimerSheet> {
  int _selectedMinutes = 30;
  bool _stopAtEndOfTrack = false;
  bool _enableFadeOut = true;

  final List<int> _presetOptions = [15, 30, 45, 60, 90];

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(sleepTimerControllerProvider);
    final timerController = ref.read(sleepTimerControllerProvider.notifier);
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isSolid = ref.isSolidStyle;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: StudioSurfaceTheme.surface(context, isSolid: isSolid),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: StudioSurfaceTheme.outline(context, isSolid: isSolid), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black87,
            blurRadius: 32,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── DRAG HANDLE ───────────────────────────────────────────────
            Center(
              child: Container(
                width: 38,
                height: 4.5,
                decoration: BoxDecoration(
                  color: StudioSurfaceTheme.outline(context, isSolid: isSolid),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ─── HEADER ───────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedMoon,
                      size: 20,
                      color: primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'SMART SLEEP TIMER',
                      style: AppTypography.badge(color: primary),
                    ),
                  ],
                ),
                if (timerState.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: StudioSurfaceTheme.tintedContainer(
                        context,
                        const Color(0xFF00E676),
                        isSolid: isSolid,
                        translucentAlpha: 0.15,
                        solidBlendAlpha: 0.18,
                      ),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSolid
                            ? theme.colorScheme.outline
                            : const Color(0xFF00E676).withValues(alpha: 0.5),
                      ),
                    ),
                    child: const Text(
                      'RUNNING',
                      style: TextStyle(
                        color: Color(0xFF00E676),
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // ─── ACTIVE TIMER VIEW ─────────────────────────────────────────
            if (timerState.isActive) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSolid ? theme.colorScheme.outline : primary.withValues(alpha: 0.4),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      timerState.formattedRemaining,
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        color: primary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timerState.isFadingOut
                          ? 'Gradual 15s Fade-Out in Progress...'
                          : 'Audio will gracefully pause when completed',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: timerState.isFadingOut
                            ? const Color(0xFFFF9F0A)
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Extend Pills
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildQuickExtendChip(context, '+5 Min', 5, timerController, isSolid),
                  _buildQuickExtendChip(context, '+15 Min', 15, timerController, isSolid),
                  _buildQuickExtendChip(context, '+30 Min', 30, timerController, isSolid),
                ],
              ),

              const SizedBox(height: 16),

              // Cancel Button
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    timerController.cancelTimer();
                    Navigator.of(context).pop();
                  },
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedCancel01,
                    size: 18,
                    color: AppColors.crimsonAlert,
                  ),
                  label: const Text(
                    'Cancel Sleep Timer',
                    style: TextStyle(
                      color: AppColors.crimsonAlert,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: isSolid ? theme.colorScheme.outline : AppColors.crimsonAlert.withValues(alpha: 0.6),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ] else ...[
              // ─── INACTIVE / TIMER SETUP VIEW ─────────────────────────────
              Text(
                'QUICK PRESETS',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 8),

              // Preset Buttons
              Row(
                children: _presetOptions.map((mins) {
                  final isSelected = _selectedMinutes == mins;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedMinutes = mins);
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? StudioSurfaceTheme.tintedContainer(
                                    context,
                                    primary,
                                    isSolid: isSolid,
                                    translucentAlpha: 0.18,
                                    solidBlendAlpha: 0.22,
                                  )
                                : StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? (isSolid ? theme.colorScheme.outline : primary)
                                  : StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid),
                              width: isSelected ? 1.2 : 0.8,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '${mins}m',
                              style: TextStyle(
                                color: isSelected ? primary : theme.colorScheme.onSurface,
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.w900
                                    : FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // Custom Slider Readout
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'CUSTOM DURATION',
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                  Text(
                    '$_selectedMinutes Minutes',
                    style: TextStyle(
                      color: primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              Slider(
                value: _selectedMinutes.toDouble(),
                min: 1,
                max: 120,
                divisions: 119,
                onChanged: (val) {
                  setState(() => _selectedMinutes = val.round());
                },
              ),

              const SizedBox(height: 10),

              // Options
              _buildOptionTile(
                context: context,
                isSolid: isSolid,
                title: 'Stop at End of Track',
                subtitle: 'Finishes playing active song before stopping',
                icon: HugeIcons.strokeRoundedMusicNote01,
                value: _stopAtEndOfTrack,
                primaryColor: primary,
                onChanged: (val) => setState(() => _stopAtEndOfTrack = val),
              ),

              const SizedBox(height: 8),

              _buildOptionTile(
                context: context,
                isSolid: isSolid,
                title: '15s Gentle Fade-Out',
                subtitle: 'Gradually lowers volume smoothly to avoid jarring stops',
                icon: HugeIcons.strokeRoundedVolumeLow,
                value: _enableFadeOut,
                primaryColor: primary,
                onChanged: (val) => setState(() => _enableFadeOut = val),
              ),

              const SizedBox(height: 16),

              // Start Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    timerController.startTimer(
                      _selectedMinutes,
                      stopAtEndOfTrack: _stopAtEndOfTrack,
                      enableFadeOut: _enableFadeOut,
                    );
                    Navigator.of(context).pop();
                  },
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedPlay,
                    size: 18,
                    color: Colors.black,
                  ),
                  label: Text(
                    'Start Timer ($_selectedMinutes Min)',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickExtendChip(
    BuildContext context,
    String label,
    int minutes,
    SleepTimerController controller,
    bool isSolid,
  ) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        controller.extendTimer(minutes);
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid),
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required BuildContext context,
    required bool isSolid,
    required String title,
    required String subtitle,
    required dynamic icon,
    required bool value,
    required Color primaryColor,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: StudioSurfaceTheme.surfaceContainer(context, isSolid: isSolid),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          HugeIcon(icon: icon, size: 18, color: primaryColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: primaryColor,
            onChanged: (val) {
              HapticFeedback.selectionClick();
              onChanged(val);
            },
          ),
        ],
      ),
    );
  }
}

