import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../app/theme/app_typography.dart';
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
    with TickerProviderStateMixin {
  late final AnimationController _rotationController;
  late final AnimationController _armController;
  late final Animation<double> _armAnimation;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    );

    _armController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _armAnimation = CurvedAnimation(
      parent: _armController,
      curve: Curves.easeInOutCubic,
    );

    if (widget.isPlaying) {
      _rotationController.repeat();
      _armController.forward();
    }
  }

  @override
  void didUpdateWidget(covariant CustomAlbumArtView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _rotationController.repeat();
        _armController.forward();
      } else {
        _rotationController.stop();
        _armController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _armController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = widget.size;

    switch (widget.style) {
      case AlbumArtStyle.squircle:
        return _buildSquircle(context, size, theme);
      case AlbumArtStyle.square:
        return _buildSquare(context, size, theme);
      case AlbumArtStyle.disc:
        return _buildDisc(context, size, theme);
      case AlbumArtStyle.vinyl:
        return _buildVinyl(context, size, theme);
      case AlbumArtStyle.turntable:
        return _buildTurntable(context, size, theme);
      case AlbumArtStyle.cassette:
        return _buildCassette(context, size, theme);
      case AlbumArtStyle.cdJewel:
        return _buildCdJewel(context, size, theme);
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
      child: _buildVinylDisc(size, theme),
    );
  }

  Widget _buildVinylDisc(double size, ThemeData theme) {
    return Container(
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
          Positioned.fill(
            child: CustomPaint(
              painter: _VinylGroovesPainter(),
            ),
          ),
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
    );
  }

  Widget _buildTurntable(BuildContext context, double size, ThemeData theme) {
    final vinylSize = size * 0.78;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF13161C),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF262D3B),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
          if (widget.ambientGlow && widget.isPlaying)
            BoxShadow(
              color: widget.primaryColor.withValues(alpha: 0.2),
              blurRadius: 32,
              spreadRadius: 2,
            ),
        ],
      ),
      child: Stack(
        children: [
          // Platter & Vinyl Disc on left-center
          Positioned(
            left: 10,
            top: (size - vinylSize) / 2,
            child: AnimatedBuilder(
              animation: _rotationController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotationController.value * 2 * math.pi,
                  child: child,
                );
              },
              child: _buildVinylDisc(vinylSize, theme),
            ),
          ),

          // Turntable Tonearm Base & Animated Needle
          Positioned(
            right: 14,
            top: 14,
            width: size * 0.32,
            height: size * 0.75,
            child: AnimatedBuilder(
              animation: _armAnimation,
              builder: (context, child) {
                // Angle interpolates between resting post (-24 deg) and record groove (18 deg)
                final double angle = (-24.0 + (_armAnimation.value * 42.0)) * math.pi / 180.0;
                return Transform.rotate(
                  angle: angle,
                  alignment: const Alignment(0.5, -0.8),
                  child: CustomPaint(
                    painter: _TonearmPainter(
                      accentColor: widget.primaryColor,
                      isPlaying: widget.isPlaying,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCassette(BuildContext context, double size, ThemeData theme) {
    return Container(
      width: size,
      height: size * 0.78,
      decoration: BoxDecoration(
        color: const Color(0xFF14171E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF2A3242),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
          if (widget.ambientGlow && widget.isPlaying)
            BoxShadow(
              color: widget.primaryColor.withValues(alpha: 0.22),
              blurRadius: 30,
              spreadRadius: 1,
            ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Cassette Body Corner Screws
          ..._buildCassetteScrews(size),

          // Top Track Label Sticker
          Positioned(
            top: 12,
            left: 18,
            right: 18,
            height: 28,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1E232E),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF323B4E), width: 0.8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.track?.title ?? 'STUDIO CASSETTE MASTER',
                      style: TextStyle(
                        fontFeatures: AppTypography.audioFigures,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: widget.primaryColor,
                        letterSpacing: 0.4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: widget.primaryColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Text(
                      'SIDE A',
                      style: TextStyle(
                        fontSize: 7.5,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Center Viewport & Tape Spools
          Positioned(
            top: 48,
            left: 24,
            right: 24,
            bottom: 22,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0C0E14),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF262D3D), width: 1.0),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Tape Bridge Path
                  Positioned(
                    left: 20,
                    right: 20,
                    height: 18,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF332014),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),

                  // Dual Rotating Spools
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildRotatingSpool(),
                      _buildRotatingSpool(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRotatingSpool() {
    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationController.value * 2 * math.pi,
          child: child,
        );
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFF1F5F9),
          border: Border.all(color: const Color(0xFF94A3B8), width: 1.5),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            for (int i = 0; i < 6; i++)
              Transform.rotate(
                angle: (i * 60) * math.pi / 180,
                child: Container(
                  width: 3,
                  height: 38,
                  color: const Color(0xFF0F172A),
                ),
              ),
            Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF0C0E14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCassetteScrews(double size) {
    const screwColor = Color(0xFF475569);
    Widget screw() => Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: screwColor,
            border: Border.all(color: const Color(0xFF1E293B), width: 0.5),
          ),
        );

    return [
      Positioned(top: 6, left: 6, child: screw()),
      Positioned(top: 6, right: 6, child: screw()),
      Positioned(bottom: 6, left: 6, child: screw()),
      Positioned(bottom: 6, right: 6, child: screw()),
    ];
  }

  Widget _buildCdJewel(BuildContext context, double size, ThemeData theme) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF12151C),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.22),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
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
        children: [
          // Left Spine Tray
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 16,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0A0C10),
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                border: Border(
                  right: BorderSide(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 1.0,
                  ),
                ),
              ),
              child: Center(
                child: RotatedBox(
                  quarterTurns: 3,
                  child: Text(
                    'COMPACT DISC DIGITAL AUDIO',
                    style: TextStyle(
                      fontSize: 6,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Center CD Disc
          Positioned(
            left: 20,
            right: 8,
            top: 8,
            bottom: 8,
            child: Center(
              child: AnimatedBuilder(
                animation: _rotationController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotationController.value * 2 * math.pi,
                    child: child,
                  );
                },
                child: _buildDisc(context, size * 0.82, theme),
              ),
            ),
          ),

          // Glossy Acrylic Glass Highlight Sheen
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.12),
                      Colors.transparent,
                      Colors.white.withValues(alpha: 0.04),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),
          ),
        ],
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

class _TonearmPainter extends CustomPainter {
  final Color accentColor;
  final bool isPlaying;

  _TonearmPainter({
    required this.accentColor,
    required this.isPlaying,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final pivot = Offset(size.width * 0.5, size.height * 0.1);

    // 1. Pivot Base Turntable Gimbal
    final basePaint = Paint()
      ..color = const Color(0xFF334155)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pivot, 10, basePaint);

    final innerBasePaint = Paint()
      ..color = const Color(0xFF64748B)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pivot, 5, innerBasePaint);

    // 2. Metallic Tonearm Tube
    final armPath = Path()
      ..moveTo(pivot.dx, pivot.dy)
      ..lineTo(pivot.dx - 8, size.height * 0.6)
      ..lineTo(pivot.dx - 22, size.height * 0.9);

    final armPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(armPath, armPaint);

    // 3. Cartridge & Stylus Head
    final cartridgeCenter = Offset(pivot.dx - 22, size.height * 0.9);
    final cartridgeRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: cartridgeCenter, width: 14, height: 20),
      const Radius.circular(3),
    );

    final cartridgePaint = Paint()
      ..color = isPlaying ? accentColor : const Color(0xFF1E293B)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(cartridgeRect, cartridgePaint);

    final needlePaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cartridgeCenter.dx - 3, cartridgeCenter.dy + 8),
      Offset(cartridgeCenter.dx - 7, cartridgeCenter.dy + 14),
      needlePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _TonearmPainter oldDelegate) =>
      oldDelegate.isPlaying != isPlaying || oldDelegate.accentColor != accentColor;
}
