import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import '../../domain/models/dac_device.dart';
import '../controllers/dac_bridge_state.dart';

/// Pure Material 3 Expressive Hero Card displaying the connected USB DAC status,
/// hardware chipset capabilities, and real-time EQ bypass toggle.
class DacHeroStatusCard extends StatelessWidget {
  const DacHeroStatusCard({
    super.key,
    required this.device,
    required this.status,
    required this.isEqEnabled,
    required this.hasUnsavedChanges,
    required this.onToggleEq,
    required this.onRefresh,
    this.onDisconnect,
  });

  final DacDevice? device;
  final DacBridgeStatus status;
  final bool isEqEnabled;
  final bool hasUnsavedChanges;
  final ValueChanged<bool> onToggleEq;
  final VoidCallback onRefresh;
  final VoidCallback? onDisconnect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isConnected = device != null && status != DacBridgeStatus.disconnected;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasUnsavedChanges
              ? colorScheme.tertiary.withValues(alpha: 0.8)
              : colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: hasUnsavedChanges ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Icon, Title, Status & Menu
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isConnected
                        ? colorScheme.primaryContainer
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedUsb,
                    color: isConnected
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurfaceVariant,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device?.formattedTitle ?? 'No DAC Connected',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isConnected
                                  ? const Color(0xFF10B981) // Precision Mint
                                  : colorScheme.outline,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isConnected ? 'Active USB HID Connection' : 'Ready to Connect',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                M3EIconButton(
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedRefresh,
                    size: 20,
                  ),
                  tooltip: 'Sync with Hardware',
                  onPressed: onRefresh,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Row 2: Badges (Chipset, Resolution, Flash status)
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _buildBadge(
                  context,
                  label: device?.chipset.displayName ?? 'Universal DSP',
                  icon: HugeIcons.strokeRoundedCpu,
                ),
                _buildBadge(
                  context,
                  label: device?.audioCapabilityString ?? '32-bit / 384kHz',
                  icon: HugeIcons.strokeRoundedSlidersVertical,
                ),
                if (hasUnsavedChanges)
                  _buildBadge(
                    context,
                    label: 'Unsaved Flash Changes',
                    icon: HugeIcons.strokeRoundedAlertCircle,
                    isHighlight: true,
                  ),
              ],
            ),

            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),

            // Row 3: Hardware EQ Switch & Preamp info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hardware DSP Processing',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      isEqEnabled ? '5-Band PEQ Active on Hardware' : 'Hardware EQ Bypassed',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                M3ESwitch(
                  value: isEqEnabled,
                  onChanged: isConnected ? onToggleEq : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(
    BuildContext context, {
    required String label,
    required dynamic icon,
    bool isHighlight = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isHighlight
            ? colorScheme.tertiaryContainer.withValues(alpha: 0.6)
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isHighlight
              ? colorScheme.tertiary
              : colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(
            icon: icon,
            size: 14,
            color: isHighlight
                ? colorScheme.onTertiaryContainer
                : colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: isHighlight
                  ? colorScheme.onTertiaryContainer
                  : colorScheme.onSurfaceVariant,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
