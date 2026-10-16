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
    final isConnected = device != null && status != DacBridgeStatus.disconnected;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF16181F),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasUnsavedChanges
              ? const Color(0xFFF59E0B)
              : const Color(0xFF262936),
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
                        ? const Color(0xFF222532)
                        : const Color(0xFF1E212B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isConnected ? const Color(0xFF383D50) : const Color(0xFF262936),
                      width: 0.8,
                    ),
                  ),
                  child: Icon(
                    LucideIcons.usb,
                    color: isConnected ? Colors.white : const Color(0xFF8A9A90),
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
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
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
                                  : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isConnected ? 'Active USB HID Connection' : 'Ready to Connect',
                            style: const TextStyle(
                              color: Color(0xFF8A9A90),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
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
                        color: const Color(0xFF1E212B),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF262936), width: 0.8),
                      ),
                      child: const Icon(
                        LucideIcons.refreshCw,
                        size: 15,
                        color: Color(0xFFA1B2A7),
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
                    backgroundColor: const Color(0xFF252834),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: Color(0xFF2E3242), width: 1),
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
            const Divider(height: 1, color: Color(0xFF262936)),
            const SizedBox(height: 14),

            // Row 3: Hardware EQ Switch & Preamp info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hardware DSP Processing',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isEqEnabled ? '5-Band PEQ Active on Hardware' : 'Hardware EQ Bypassed',
                      style: const TextStyle(
                        color: Color(0xFF8A9A90),
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
    required IconData icon,
    bool isHighlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: isHighlight
            ? const Color(0xFF2A2416)
            : const Color(0xFF1E212B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isHighlight
              ? const Color(0xFFF59E0B)
              : const Color(0xFF262936),
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
                ? const Color(0xFFFBBF24)
                : const Color(0xFFA1B2A7),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: isHighlight
                  ? const Color(0xFFFBBF24)
                  : const Color(0xFFA1B2A7),
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
