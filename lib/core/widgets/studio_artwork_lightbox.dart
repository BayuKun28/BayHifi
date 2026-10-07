import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import '../../app/theme/app_haptics.dart';
import '../../app/theme/app_typography.dart';
import '../../app/theme/studio_surface_theme.dart';
import '../../features/player/domain/track.dart';
import 'studio_artwork_widget.dart';

/// Interactive high-resolution zoomable artwork lightbox modal with pinch-to-zoom,
/// double-tap zoom toggle, smooth spring physics, and swipe-to-dismiss.
class StudioArtworkLightbox extends StatefulWidget {
  final Track? track;
  final Uint8List? bytes;
  final String? url;
  final String? title;
  final String? subtitle;
  final String? formatTag;
  final String? heroTag;

  const StudioArtworkLightbox({
    super.key,
    this.track,
    this.bytes,
    this.url,
    this.title,
    this.subtitle,
    this.formatTag,
    this.heroTag,
  });

  /// Opens the interactive artwork lightbox in a smooth modal dialog.
  static Future<void> show(
    BuildContext context, {
    Track? track,
    Uint8List? bytes,
    String? url,
    String? title,
    String? subtitle,
    String? formatTag,
    String? heroTag,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.82),
        pageBuilder: (context, animation, secondaryAnimation) {
          return StudioArtworkLightbox(
            track: track,
            bytes: bytes,
            url: url,
            title: title,
            subtitle: subtitle,
            formatTag: formatTag,
            heroTag: heroTag,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.94, end: 1.0).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  State<StudioArtworkLightbox> createState() => _StudioArtworkLightboxState();
}

class _StudioArtworkLightboxState extends State<StudioArtworkLightbox>
    with SingleTickerProviderStateMixin {
  final TransformationController _transformController = TransformationController();
  late AnimationController _zoomAnimController;
  Animation<Matrix4>? _zoomAnimation;

  double _dragOffsetY = 0.0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _zoomAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _zoomAnimController.addListener(() {
      if (_zoomAnimation != null) {
        _transformController.value = _zoomAnimation!.value;
      }
    });
  }

  @override
  void dispose() {
    _transformController.dispose();
    _zoomAnimController.dispose();
    super.dispose();
  }

  void _handleDoubleTap(TapDownDetails details) {
    AppHaptics.lightImpact();
    final currentScale = _transformController.value.getMaxScaleOnAxis();

    final Matrix4 targetMatrix;
    if (currentScale > 1.2) {
      // Zoom out to 1.0x
      targetMatrix = Matrix4.identity();
    } else {
      // Zoom in to 2.5x centered at tap position
      final position = details.localPosition;
      targetMatrix = Matrix4.diagonal3Values(2.5, 2.5, 1.0)
        ..setTranslationRaw(-position.dx * 1.5, -position.dy * 1.5, 0.0);
    }

    _zoomAnimation = Matrix4Tween(
      begin: _transformController.value,
      end: targetMatrix,
    ).animate(CurvedAnimation(
      parent: _zoomAnimController,
      curve: Curves.easeOutCubic,
    ));

    _zoomAnimController.forward(from: 0.0);
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    final currentScale = _transformController.value.getMaxScaleOnAxis();
    if (currentScale <= 1.05) {
      setState(() {
        _isDragging = true;
        _dragOffsetY += details.delta.dy;
      });
    }
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (_dragOffsetY.abs() > 120 || (details.primaryVelocity?.abs() ?? 0) > 800) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _isDragging = false;
        _dragOffsetY = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final displayTitle = widget.title ?? widget.track?.title ?? 'Album Artwork';
    final displaySubtitle = widget.subtitle ?? widget.track?.artist ?? 'Master Reference';

    final dragOpacity = _isDragging
        ? (1.0 - (_dragOffsetY.abs() / 320.0)).clamp(0.2, 1.0)
        : 1.0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Opacity(
          opacity: dragOpacity,
          child: Transform.translate(
            offset: Offset(0, _dragOffsetY),
            child: Column(
              children: [
                // ─── TOP STUDIO APP BAR ───────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      // Close button
                      M3EIconButton(
                        variant: M3EIconButtonVariant.standard,
                        onPressed: () => Navigator.of(context).pop(),
                        icon: HugeIcon(
                          icon: HugeIcons.strokeRoundedCancel01,
                          size: 22,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Title & Subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              displayTitle,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              displaySubtitle,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Format / Hi-Res Pill
                      if (widget.formatTag != null && widget.formatTag!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: StudioSurfaceTheme.tintedContainer(
                              context,
                              primary,
                              isSolid: true,
                              translucentAlpha: 0.2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: primary.withValues(alpha: 0.4),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            widget.formatTag!,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                              color: primary,
                              fontFeatures: AppTypography.audioFigures,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // ─── MAIN ZOOMABLE ARTWORK CANVAS ─────────────────────────────
                Expanded(
                  child: GestureDetector(
                    onDoubleTapDown: _handleDoubleTap,
                    onDoubleTap: () {},
                    onVerticalDragUpdate: _onVerticalDragUpdate,
                    onVerticalDragEnd: _onVerticalDragEnd,
                    child: Center(
                      child: InteractiveViewer(
                        transformationController: _transformController,
                        minScale: 1.0,
                        maxScale: 5.0,
                        panEnabled: true,
                        scaleEnabled: true,
                        clipBehavior: Clip.none,
                        child: Hero(
                          tag: widget.heroTag ?? 'artwork_lightbox_${widget.track?.id ?? widget.title ?? "preview"}',
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.92,
                              maxHeight: MediaQuery.of(context).size.height * 0.65,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.45),
                                  blurRadius: 36,
                                  offset: const Offset(0, 16),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: AspectRatio(
                                aspectRatio: 1.0,
                                child: StudioArtworkWidget(
                                  track: widget.track,
                                  bytes: widget.bytes ?? widget.track?.albumArtBytes,
                                  url: widget.url ?? widget.track?.albumArtUrl,
                                  borderRadius: BorderRadius.zero,
                                  fallbackIconSize: 84,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ─── BOTTOM CONTROL & INTERACTION HINT STRIP ──────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainer.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedImage01,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Pinch or double-tap to zoom (1.0x - 5.0x) • Swipe down to dismiss',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
