import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_haptics.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/studio_surface_theme.dart';
import '../../../pro_q_studio/domain/biquad_math.dart';
import '../../../pro_q_studio/domain/eq_band.dart';
import '../../../pro_q_studio/presentation/controllers/eq_controller.dart';
import '../../../pro_q_studio/presentation/pro_q_studio_screen.dart';

class ProQMiniLauncherBentoCard extends ConsumerWidget {
  const ProQMiniLauncherBentoCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isSolid = ref.isSolidStyle;
    final eqState = ref.watch(eqControllerProvider);

    String decodeClean(String? s) {
      if (s == null || s.trim().isEmpty) return '';
      try {
        return Uri.decodeComponent(s).replaceAll('_', ' ');
      } catch (_) {
        return s.replaceAll('%20', ' ').replaceAll('_', ' ');
      }
    }

    final driverName = decodeClean(eqState.driverFr?.name).isNotEmpty
        ? decodeClean(eqState.driverFr?.name)
        : 'Flat Reference';
    final targetName = decodeClean(eqState.targetFr?.name).isNotEmpty
        ? decodeClean(eqState.targetFr?.name)
        : 'Harman In-Ear 2019';

    return InkWell(
      onTap: () {
        AppHaptics.lightImpact();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const ProQStudioScreen(),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: StudioSurfaceTheme.cardDecoration(
          context: context,
          isSolid: isSolid,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header: Title + Launcher Icon
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: StudioCategoryColors.proQEqualizer.withValues(alpha: isSolid ? 0.18 : 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    LucideIcons.slidersVertical,
                    size: 15,
                    color: StudioCategoryColors.proQEqualizer,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'PRO-Q STUDIO',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: StudioCategoryColors.proQEqualizer.withValues(alpha: isSolid ? 0.18 : 0.14),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    LucideIcons.maximize2,
                    size: 13,
                    color: StudioCategoryColors.proQEqualizer,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Live Mini Interactive EQ Curve Canvas
            Container(
              height: 54,
              width: double.infinity,
              decoration: BoxDecoration(
                color: StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _MiniEqCurvePainter(
                      bands: eqState.bands,
                      isEnabled: eqState.isEnabled,
                      primaryColor: StudioCategoryColors.proQEqualizer,
                      gridColor: StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Driver & Target Curve Badges
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      driverName.length > 13 ? '${driverName.substring(0, 11)}…' : driverName,
                      style: TextStyle(
                        fontFeatures: AppTypography.audioFigures,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: StudioCategoryColors.autoEq.withValues(alpha: isSolid ? 0.18 : 0.14),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      targetName.length > 13 ? '${targetName.substring(0, 11)}…' : targetName,
                      style: const TextStyle(
                        fontFeatures: AppTypography.audioFigures,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: StudioCategoryColors.autoEq,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniEqCurvePainter extends CustomPainter {
  final List<EqBand> bands;
  final bool isEnabled;
  final Color primaryColor;
  final Color gridColor;

  _MiniEqCurvePainter({
    required this.bands,
    required this.isEnabled,
    required this.primaryColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.8;

    final curvePaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Draw center 0dB line
    final midY = size.height * 0.5;
    canvas.drawLine(Offset(0, midY), Offset(size.width, midY), gridPaint);

    if (bands.isEmpty || !isEnabled) {
      canvas.drawLine(
        Offset(0, midY),
        Offset(size.width, midY),
        curvePaint..color = primaryColor.withValues(alpha: 0.3),
      );
      return;
    }

    final path = Path();
    final fillPath = Path();
    const int points = 60;

    fillPath.moveTo(0, size.height);

    for (int i = 0; i < points; i++) {
      final double normX = i / (points - 1);
      final double freq = 20.0 * math.pow(1000.0, normX);
      double totalGainDb = 0.0;

      for (final band in bands) {
        if (band.isEnabled) {
          final coeffs = BiquadMath.calculateCoefficients(band, sampleRate: 48000.0);
          totalGainDb += coeffs.evaluateGainDb(freq, 48000.0);
        }
      }

      // Map +18dB to -18dB
      final double clampedGain = totalGainDb.clamp(-18.0, 18.0);
      final double normY = (18.0 - clampedGain) / 36.0;
      final double x = normX * size.width;
      final double y = normY * size.height;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    // Fill Gradient using active theme primary color
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        primaryColor.withValues(alpha: 0.25),
        primaryColor.withValues(alpha: 0.0),
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    fillPaint.shader = gradient;
    canvas.drawPath(fillPath, fillPaint);

    // Stroke line
    canvas.drawPath(path, curvePaint);
  }

  @override
  bool shouldRepaint(covariant _MiniEqCurvePainter oldDelegate) {
    return oldDelegate.bands != bands ||
        oldDelegate.isEnabled != isEnabled ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.gridColor != gridColor;
  }
}
