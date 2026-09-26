import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/widgets/studio_artwork_widget.dart';
import '../../../settings/domain/player_customization_settings.dart';
import '../../domain/track.dart';

class CustomAlbumArtView extends StatefulWidget {
  final Track? track;
  final bool isPlaying;
  final AlbumArtStyle style;
  final bool ambientGlow;
  final Color primaryColor;
  final double size;

  const CustomAlbumArtView({
    super.key,
    required this.track,
    required this.isPlaying,
    required this.style,
    required this.ambientGlow,
    required this.primaryColor,
    this.size = 220,
  });

  @override
  State<CustomAlbumArtView> createState() => _CustomAlbumArtViewState();
}

class _CustomAlbumArtViewState extends State<CustomAlbumArtView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    );

    if (widget.isPlaying) {
      _rotationController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant CustomAlbumArtView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _rotationController.repeat();
      } else {
        _rotationController.stop();
      }
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = widget.size;

    switch (widget.style) {
      case AlbumArtStyle.squircle:
        return _buildSquircle(context, size, theme);
      case AlbumArtStyle.vinyl:
        return _buildVinyl(context, size, theme);
      case AlbumArtStyle.square:
        return _buildSquare(context, size, theme);
      case AlbumArtStyle.disc:
        return _buildDisc(context, size, theme);
    }
  }

  Widget _buildSquircle(BuildContext context, double size, ThemeData theme) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: widget.isPlaying
              ? widget.primaryColor.withValues(alpha: 0.5)
              : theme.dividerColor,
          width: 1.5,
        ),
        boxShadow: widget.ambientGlow
            ? [
                BoxShadow(
                  color: (widget.isPlaying ? widget.primaryColor : Colors.black)
                      .withValues(alpha: 0.28),
                  blurRadius: 36,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: _buildImage(theme, size * 0.35),
      ),
    );
  }

  Widget _buildSquare(BuildContext context, double size, ThemeData theme) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: widget.isPlaying
              ? widget.primaryColor.withValues(alpha: 0.6)
              : theme.dividerColor,
          width: 1.2,
        ),
        boxShadow: widget.ambientGlow
            ? [
                BoxShadow(
                  color: (widget.isPlaying ? widget.primaryColor : Colors.black)
                      .withValues(alpha: 0.25),
                  blurRadius: 28,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: _buildImage(theme, size * 0.35),
      ),
    );
  }

  Widget _buildDisc(BuildContext context, double size, ThemeData theme) {
    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationController.value * 2 * math.pi,
          child: child,
        );
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.colorScheme.surfaceContainer,
          border: Border.all(
            color: widget.primaryColor.withValues(alpha: 0.6),
            width: 2.0,
          ),
          boxShadow: widget.ambientGlow
              ? [
                  BoxShadow(
                    color: widget.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 32,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: ClipOval(
          child: Stack(
            alignment: Alignment.center,
            children: [
              _buildImage(theme, size * 0.35),
              // Center hole
              Container(
                width: size * 0.18,
                height: size * 0.18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0B0E14),
                  border: Border.all(
                    color: widget.primaryColor.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVinyl(BuildContext context, double size, ThemeData theme) {
    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationController.value * 2 * math.pi,
          child: child,
        );
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF11141A),
          border: Border.all(
            color: const Color(0xFF2A3140),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 28,
              offset: const Offset(0, 8),
            ),
            if (widget.ambientGlow && widget.isPlaying)
              BoxShadow(
                color: widget.primaryColor.withValues(alpha: 0.25),
                blurRadius: 36,
                spreadRadius: 2,
              ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Concentric Vinyl Grooves
            Positioned.fill(
              child: CustomPaint(
                painter: _VinylGroovesPainter(),
              ),
            ),

            // Center Label / Album Artwork
            Container(
              width: size * 0.44,
              height: size * 0.44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF3B465A),
                  width: 2.0,
                ),
              ),
              child: ClipOval(
                child: _buildImage(theme, size * 0.18),
              ),
            ),

            // Center Spindle Hole
            Container(
              width: size * 0.09,
              height: size * 0.09,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0A0C10),
                border: Border.all(
                  color: const Color(0xFF6B7C93),
                  width: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(ThemeData theme, double fallbackSize) {
    return StudioArtworkWidget(
      track: widget.track,
      fallbackIconSize: fallbackSize,
      fallbackColor: widget.isPlaying
          ? widget.primaryColor
          : theme.colorScheme.onSurface.withValues(alpha: 0.4),
      backgroundColor: Colors.transparent,
    );
  }
}

class _VinylGroovesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2 - 4;
    final minRadius = size.width * 0.23;

    final paint = Paint()
      ..color = const Color(0xFF1E2533).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    const int grooveCount = 12;
    final step = (maxRadius - minRadius) / grooveCount;

    for (int i = 0; i < grooveCount; i++) {
      final r = minRadius + (i * step);
      canvas.drawCircle(center, r, paint);
    }

    // High-light sheen on vinyl
    final sheenPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          Colors.transparent,
          Colors.white.withValues(alpha: 0.05),
          Colors.transparent,
          Colors.white.withValues(alpha: 0.05),
          Colors.transparent,
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawCircle(center, maxRadius, sheenPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
