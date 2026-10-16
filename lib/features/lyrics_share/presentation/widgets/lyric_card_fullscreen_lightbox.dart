import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import '../../../../app/theme/app_haptics.dart';
import '../../domain/models/lyric_card_theme.dart';
import '../../domain/models/lyric_share_config.dart';
import '../controllers/lyric_share_controller.dart';
import 'lyric_card_widget.dart';

/// Interactive Full-Screen Preview Lightbox for Studio Lyric Cards.
/// Features pinch-to-zoom, pan, spring physics dismiss, and quick save/share actions.
class LyricCardFullScreenLightbox extends StatefulWidget {
  final LyricShareConfig config;
  final LyricCardColors colors;
  final LyricShareController? controller;
  final GlobalKey? parentRepaintKey;

  const LyricCardFullScreenLightbox({
    super.key,
    required this.config,
    required this.colors,
    this.controller,
    this.parentRepaintKey,
  });

  /// Opens the full-screen interactive lightbox.
  static Future<void> show(
    BuildContext context, {
    required LyricShareConfig config,
    required LyricCardColors colors,
    LyricShareController? controller,
    GlobalKey? parentRepaintKey,
  }) {
    AppHaptics.mediumImpact();
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.88),
        pageBuilder: (ctx, anim, secAnim) {
          return LyricCardFullScreenLightbox(
            config: config,
            colors: colors,
            controller: controller,
            parentRepaintKey: parentRepaintKey,
          );
        },
        transitionsBuilder: (ctx, anim, secAnim, child) {
          final curved = CurvedAnimation(
            parent: anim,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  State<LyricCardFullScreenLightbox> createState() => _LyricCardFullScreenLightboxState();
}

class _LyricCardFullScreenLightboxState extends State<LyricCardFullScreenLightbox>
    with SingleTickerProviderStateMixin {
  final TransformationController _transformController = TransformationController();
  final GlobalKey _lightboxRepaintKey = GlobalKey();
  bool _isRendering = false;

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    AppHaptics.lightImpact();
    _transformController.value = Matrix4.identity();
  }

  void _showToast(String message) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger != null) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleSave() async {
    if (_isRendering || widget.controller == null) return;
    setState(() => _isRendering = true);
    AppHaptics.lightImpact();
    try {
      final keyToUse = widget.parentRepaintKey ?? _lightboxRepaintKey;
      final path = await widget.controller!.saveImageLocally(keyToUse);
      if (mounted && path != null) {
        _showToast('Saved to Gallery: $path');
      }
    } finally {
      if (mounted) setState(() => _isRendering = false);
    }
  }

  Future<void> _handleShare() async {
    if (_isRendering || widget.controller == null) return;
    setState(() => _isRendering = true);
    AppHaptics.mediumImpact();
    try {
      final keyToUse = widget.parentRepaintKey ?? _lightboxRepaintKey;
      final result = await widget.controller!.shareLyricCard(keyToUse);
      if (mounted) {
        if (result.isMissingPlugin) {
          _showToast('Image saved to Gallery! Restart app to enable native sharing.');
        } else if (!result.success && result.errorMessage != null) {
          _showToast(result.errorMessage!);
        }
      }
    } finally {
      if (mounted) setState(() => _isRendering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = widget.config.ratio;
    final size = MediaQuery.of(context).size;

    // Calculate optimal full-screen preview bounds based on aspect ratio
    final double maxPreviewWidth;
    final double maxPreviewHeight;

    switch (ratio) {
      case LyricCardRatio.landscape_16_9:
        maxPreviewWidth = (size.width * 0.90).clamp(320.0, 720.0);
        maxPreviewHeight = maxPreviewWidth * (9.0 / 16.0);
        break;
      case LyricCardRatio.story_9_16:
        maxPreviewHeight = (size.height * 0.72).clamp(400.0, 700.0);
        maxPreviewWidth = maxPreviewHeight * (9.0 / 16.0);
        break;
      case LyricCardRatio.portrait_4_5:
        maxPreviewHeight = (size.height * 0.68).clamp(360.0, 640.0);
        maxPreviewWidth = maxPreviewHeight * (4.0 / 5.0);
        break;
      case LyricCardRatio.square_1_1:
        final minDim = size.shortestSide * 0.82;
        maxPreviewWidth = minDim.clamp(280.0, 500.0);
        maxPreviewHeight = maxPreviewWidth;
        break;
    }

    return ScaffoldMessenger(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // 1. Interactive Pinch-to-Zoom Stage
            Positioned.fill(
              child: GestureDetector(
                onDoubleTap: _resetZoom,
                child: InteractiveViewer(
                  transformationController: _transformController,
                  minScale: 0.8,
                  maxScale: 3.5,
                  boundaryMargin: const EdgeInsets.all(48),
                  child: Center(
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: maxPreviewWidth,
                        maxHeight: maxPreviewHeight,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.65),
                            blurRadius: 36,
                            spreadRadius: 4,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: LyricCardWidget(
                          config: widget.config,
                          colors: widget.colors,
                          repaintBoundaryKey: _lightboxRepaintKey,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 2. Top Header Bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      // Close button
                      M3EIconButton(
                        variant: M3EIconButtonVariant.standard,
                        onPressed: () {
                          AppHaptics.lightImpact();
                          Navigator.of(context).pop();
                        },
                        icon: Icon(
                          LucideIcons.x,
                          size: 22,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        tooltip: 'Close Preview',
                      ),
                      const SizedBox(width: 12),
                      // Ratio & Template Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.proportions,
                              size: 13,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${widget.config.ratio.label} • ${widget.config.layoutStyle.label.toUpperCase()}',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Reset Zoom Button
                      M3EIconButton(
                        variant: M3EIconButtonVariant.standard,
                        tooltip: 'Reset Zoom (Double-Tap)',
                        onPressed: _resetZoom,
                        icon: Icon(
                          LucideIcons.eye,
                          size: 22,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 3. Bottom Action Bar (Save & Share)
            if (widget.controller != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 10, 24, 18),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Save Button
                              Expanded(
                                flex: 2,
                                child: M3EButton.outlined(
                                  onPressed: _isRendering ? null : _handleSave,
                                  icon: Icon(
                                    LucideIcons.download,
                                    size: 16,
                                    color: theme.colorScheme.primary,
                                  ),
                                  label: const Text('Save'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Share Button
                              Expanded(
                                flex: 3,
                                child: M3EButton.filled(
                                  onPressed: _isRendering || widget.config.selectedLines.isEmpty ? null : _handleShare,
                                  icon: _isRendering
                                      ? SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: M3EProgressIndicator.circular(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Icon(
                                          LucideIcons.share2,
                                          size: 16,
                                          color: theme.colorScheme.onPrimary,
                                        ),
                                  label: Text(_isRendering ? 'Rendering...' : 'Share Card'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
