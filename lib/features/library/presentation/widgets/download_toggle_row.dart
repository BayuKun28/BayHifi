import 'package:flutter/material.dart';
import '../../../../app/theme/app_haptics.dart';
import '../../../../app/theme/simple_as_f_theme.dart';
import '../../../../core/widgets/meta_tracking_label.dart';

/// Minimalist download toggle row matching Screen 1 of Dribbble 27089924.
/// Displays an uppercase tracking label "DOWNLOAD" alongside an emerald mint pill switch.
class DownloadToggleRow extends StatelessWidget {
  final bool isDownloaded;
  final ValueChanged<bool> onToggle;
  final String label;

  const DownloadToggleRow({
    super.key,
    required this.isDownloaded,
    required this.onToggle,
    this.label = 'DOWNLOAD',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          MetaTrackingLabel(
            label,
            fontSize: 11.5,
            letterSpacing: 1.6,
            color: SimpleAsFTheme.sageSlate,
          ),
          GestureDetector(
            onTap: () {
              AppHaptics.selectionClick();
              onToggle(!isDownloaded);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: 44,
              height: 24,
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: isDownloaded
                    ? SimpleAsFTheme.emeraldMint
                    : const Color(0xFF1B2B22),
                border: Border.all(
                  color: isDownloaded
                      ? SimpleAsFTheme.emeraldMint
                      : Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                alignment: isDownloaded ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDownloaded ? const Color(0xFF0B110E) : Colors.white.withValues(alpha: 0.8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
