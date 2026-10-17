import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import '../../domain/models/dac_device.dart';
import '../controllers/dac_bridge_state.dart';

/// Solid Matte Hero Card displaying the connected USB DAC status,
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
    this.onConnectWebHid,
  });

  final DacDevice? device;
  final DacBridgeStatus status;
  final bool isEqEnabled;
  final bool hasUnsavedChanges;
  final ValueChanged<bool> onToggleEq;
  final VoidCallback onRefresh;
  final VoidCallback? onDisconnect;
  final VoidCallback? onConnectWebHid;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isConnected = device != null && status != DacBridgeStatus.disconnected;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16181F) : theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasUnsavedChanges
              ? const Color(0xFFF59E0B)
              : (isDark ? const Color(0xFF262936) : theme.colorScheme.outlineVariant),
          width: hasUnsavedChanges ? 1.4 : 1.0,
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
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isConnected
                        ? (isDark ? const Color(0xFF222532) : theme.colorScheme.primaryContainer)
                        : (isDark ? const Color(0xFF1E212B) : theme.colorScheme.surfaceContainerHighest),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? (isConnected ? const Color(0xFF383D50) : const Color(0xFF262936))
                          : theme.colorScheme.outlineVariant,
                      width: 0.8,
                    ),
                  ),
                  child: Icon(
                    LucideIcons.usb,
                    color: isConnected
                        ? (isDark ? Colors.white : theme.colorScheme.onPrimaryContainer)
                        : (isDark ? const Color(0xFF8A9A90) : theme.colorScheme.onSurfaceVariant),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device?.formattedTitle ?? 'No DAC Connected',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isConnected
                                  ? const Color(0xFF10B981) // Studio Mint
                                  : (isDark ? const Color(0xFF64748B) : theme.colorScheme.outline),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              isConnected ? 'Active USB HID Connection' : 'Ready to Connect',
                              style: TextStyle(
                                color: isDark ? const Color(0xFF8A9A90) : theme.colorScheme.onSurfaceVariant,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Tooltip(
                  message: 'Sync with Hardware',
                  child: InkWell(
                    onTap: onRefresh,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E212B) : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark ? const Color(0xFF262936) : theme.colorScheme.outlineVariant,
                          width: 0.8,
                        ),
                      ),
                      child: Icon(
                        LucideIcons.refreshCw,
                        size: 15,
                        color: isDark ? const Color(0xFFA1B2A7) : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            if (kIsWeb && !isConnected) ...[
              const SizedBox(height: 14),
              SizedBox(
                height: 38,
                child: ElevatedButton.icon(
                  onPressed: onConnectWebHid,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF252834) : theme.colorScheme.primary,
                    foregroundColor: isDark ? Colors.white : theme.colorScheme.onPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: isDark ? const Color(0xFF2E3242) : Colors.transparent,
                        width: 1,
                      ),
                    ),
                  ),
                  icon: const Icon(LucideIcons.usb, size: 16),
                  label: const Text(
                    'PAIR PHYSICAL USB DAC (WEBHID)',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 14),

            // Row 2: Badges (Chipset, Resolution, Flash status)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildBadge(
                  context,
                  label: device?.chipset.displayName ?? 'Universal DSP',
                  icon: LucideIcons.cpu,
                ),
                _buildBadge(
                  context,
                  label: device?.audioCapabilityString ?? '32-bit / 384kHz',
                  icon: LucideIcons.sliders,
                ),
                if (hasUnsavedChanges)
                  _buildBadge(
                    context,
                    label: 'Unsaved Flash Changes',
                    icon: LucideIcons.alertCircle,
                    isHighlight: true,
                  ),
              ],
            ),

            const SizedBox(height: 14),
            Divider(
              height: 1,
              color: isDark ? const Color(0xFF262936) : theme.colorScheme.outlineVariant,
            ),
            const SizedBox(height: 14),

            // Row 3: Hardware EQ Switch & Preamp info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hardware DSP Processing',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isEqEnabled ? '5-Band PEQ Active on Hardware' : 'Hardware EQ Bypassed',
                        style: TextStyle(
                          color: isDark ? const Color(0xFF8A9A90) : theme.colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
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
    required IconData icon,
    bool isHighlight = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: isHighlight
            ? (isDark ? const Color(0xFF2A2416) : const Color(0xFFFEF3C7))
            : (isDark ? const Color(0xFF1E212B) : theme.colorScheme.surfaceContainerHighest),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isHighlight
              ? const Color(0xFFF59E0B)
              : (isDark ? const Color(0xFF262936) : theme.colorScheme.outlineVariant),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: isHighlight
                ? const Color(0xFFD97706)
                : (isDark ? const Color(0xFFA1B2A7) : theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: isHighlight
                  ? const Color(0xFFD97706)
                  : (isDark ? const Color(0xFFA1B2A7) : theme.colorScheme.onSurfaceVariant),
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
