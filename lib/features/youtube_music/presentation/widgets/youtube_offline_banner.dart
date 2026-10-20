import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/theme/simple_as_f_theme.dart';
import '../../../../app/theme/studio_surface_theme.dart';

/// Modular Offline Warning Capsule Banner for YouTube Music Discovery Screen
class YouTubeOfflineBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final bool isSolid;

  const YouTubeOfflineBanner({
    super.key,
    required this.message,
    required this.onRetry,
    this.isSolid = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final cleanMessage = message.contains('Failed to') || message.contains('Exception')
        ? 'Offline Mode • Tap to retry connection'
        : message;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: StudioSurfaceTheme.surfaceContainer(context, isSolid: isSolid),
        borderRadius: SimpleAsFTheme.capsuleRowRadius,
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.18),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.wifiOff,
            size: 16,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              cleanMessage,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: onRetry,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: StudioSurfaceTheme.tintedContainer(
                  context,
                  primary,
                  isSolid: isSolid,
                  translucentAlpha: 0.14,
                  solidBlendAlpha: 0.20,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.refreshCw,
                    size: 12,
                    color: primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Retry',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
