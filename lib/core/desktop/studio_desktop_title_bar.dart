import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:window_manager/window_manager.dart';
import '../../features/player/presentation/controllers/player_controller.dart';
import 'desktop_window_service.dart';

/// Custom Frameless Studio Desktop Title Bar (CSD - Client-Side Decoration).
/// Integrates 100% seamlessly with Material 3 Expressive theme, dark/light modes,
/// and dynamic album art palettes on Linux/macOS/Windows desktop platforms.
class StudioDesktopTitleBar extends ConsumerWidget implements PreferredSizeWidget {
  final double height;

  const StudioDesktopTitleBar({
    super.key,
    this.height = 38.0,
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (kIsWeb) return const SizedBox.shrink();
    if (!Platform.isLinux && !Platform.isWindows && !Platform.isMacOS) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final playback = ref.watch(playerControllerProvider);
    final currentTrack = playback.currentTrack;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.25),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          // ─── 1. Left: Studio Branding & Format Pill ────────────────────
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onDoubleTap: () => DesktopWindowService.instance.toggleMaximize(),
            child: DragToMoveArea(
              child: Container(
                height: height,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedAudioWave01,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'BAYDEV HiFi',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    if (currentTrack != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          currentTrack.format.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onPrimaryContainer,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // ─── 2. Center: Draggable Title Area ───────────────────────────
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onDoubleTap: () => DesktopWindowService.instance.toggleMaximize(),
              child: DragToMoveArea(
                child: Container(
                  height: height,
                  alignment: Alignment.center,
                  child: currentTrack != null
                      ? Text(
                          '${currentTrack.title} — ${currentTrack.artist}',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : Text(
                          'Studio Audiophile Workstation',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.8,
                            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                          ),
                        ),
                ),
              ),
            ),
          ),

          // ─── 3. Right: Studio Window Controls (3 Essential Buttons) ──
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Minimize Button
              _StudioTitleBarButton(
                tooltip: 'Minimize',
                icon: HugeIcons.strokeRoundedMinusSign,
                onTap: () => DesktopWindowService.instance.minimize(),
              ),

              // Maximize / Restore Button
              ValueListenableBuilder<bool>(
                valueListenable: DesktopWindowService.instance.isMaximizedNotifier,
                builder: (context, isMaximized, _) {
                  return _StudioTitleBarButton(
                    tooltip: isMaximized ? 'Restore' : 'Maximize',
                    icon: isMaximized
                        ? HugeIcons.strokeRoundedCopy01
                        : HugeIcons.strokeRoundedSquare,
                    onTap: () => DesktopWindowService.instance.toggleMaximize(),
                  );
                },
              ),

              // Close Button (Studio Red on Hover)
              _StudioTitleBarButton(
                tooltip: 'Close',
                icon: HugeIcons.strokeRoundedCancel01,
                isCloseButton: true,
                onTap: () => DesktopWindowService.instance.close(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Studio Title Bar Action Button with subtle hover micro-interactions
class _StudioTitleBarButton extends StatefulWidget {
  final String tooltip;
  final dynamic icon;
  final VoidCallback onTap;
  final bool isCloseButton;

  const _StudioTitleBarButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.isCloseButton = false,
  });

  @override
  State<_StudioTitleBarButton> createState() => _StudioTitleBarButtonState();
}

class _StudioTitleBarButtonState extends State<_StudioTitleBarButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color backgroundColor = Colors.transparent;
    Color iconColor = theme.colorScheme.onSurfaceVariant;

    if (_isHovered) {
      if (widget.isCloseButton) {
        backgroundColor = const Color(0xFFE11D48); // Studio crimson red
        iconColor = Colors.white;
      } else {
        backgroundColor = theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6);
        iconColor = theme.colorScheme.onSurface;
      }
    }

    return M3ETooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.zero,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            width: 44,
            height: 38,
            color: backgroundColor,
            alignment: Alignment.center,
            child: HugeIcon(
              icon: widget.icon,
              size: 15,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }
}
