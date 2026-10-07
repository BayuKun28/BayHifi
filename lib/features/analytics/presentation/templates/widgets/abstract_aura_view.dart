import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../../core/widgets/studio_artwork_widget.dart';
import '../../../domain/studio_wrapped_data.dart';

/// Template 5: Abstract Generative Soundwave & Acoustic Aura Edition
/// Features mathematical bezier fluid curves, radiant acoustic halos, and harmonic resonance metrics.
class AbstractSoundwaveAuraView extends StatelessWidget {
  final StudioWrappedData data;

  const AbstractSoundwaveAuraView({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final topTrack = data.topTrack;
    final topArtist = data.topArtist;
    final persona = data.persona;
    final profile = data.resonanceProfile;

    const canvasBg = Color(0xFF0B0D13);
    const textPrimary = Color(0xFFF8FAFC);
    const textSecondary = Color(0xFF94A3B8);
    final auraColor = persona.primaryColor;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 420),
      decoration: BoxDecoration(
        color: canvasBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF1E2230), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // ─── BACKGROUND PROCEDURAL SOUNDWAVE AURA ──────────────────
          Positioned.fill(
            child: CustomPaint(
              painter: _SoundwaveAuraPainter(
                amplitudes: profile.waveSeedAmplitudes,
                primaryColor: auraColor,
                secondaryColor: persona.secondaryColor,
              ),
            ),
          ),

          // ─── FOREGROUND CONTENT ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Header Minimal Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: auraColor,
                            boxShadow: [
                              BoxShadow(color: auraColor.withValues(alpha: 0.8), blurRadius: 8),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'SONIC RESONANCE 2026',
                          style: TextStyle(
                            fontSize: 9.0,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Text(
                        'DR: ${profile.dynamicRangeDb} dB',
                        style: const TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          color: textSecondary,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 2. Center Spotlight: Glowing Halo with Album Art
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Radiant outer sound aura rings
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: auraColor.withValues(alpha: 0.25), width: 1.5),
                        ),
                      ),
                      Container(
                        width: 118,
                        height: 118,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: auraColor.withValues(alpha: 0.45), width: 1.5),
                        ),
                      ),
                      // Core Album Artwork
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: auraColor.withValues(alpha: 0.5),
                              blurRadius: 28,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: StudioArtworkWidget(
                          url: topTrack?.albumArtUri,
                          width: 96,
                          height: 96,
                          borderRadius: BorderRadius.circular(48),
                          fallbackIcon: HugeIcons.strokeRoundedDisc,
                          fallbackIconSize: 40,
                          backgroundColor: const Color(0xFF1E2230),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Track Title & Resonance Title
                Center(
                  child: Column(
                    children: [
                      Text(
                        topTrack?.title ?? 'Comfortably Numb',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: textPrimary,
                          letterSpacing: -0.3,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${topTrack?.artist ?? "Pink Floyd"} • ${topTrack?.formatBadge ?? "FLAC 24-bit"}',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: auraColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // 4. Acoustic Energy Index & Timbral Resonance Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131722).withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFF232838), width: 1),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'TIMBRAL SIGNATURE',
                                  style: TextStyle(fontSize: 8.0, fontWeight: FontWeight.w800, color: textSecondary, letterSpacing: 0.8),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  profile.timbralSignature,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: textPrimary),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: auraColor.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'ENERGY: ${profile.energyScore}/100',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                color: auraColor,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Energy Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (profile.energyScore / 100.0).clamp(0.0, 1.0),
                          backgroundColor: Colors.white12,
                          valueColor: AlwaysStoppedAnimation<Color>(auraColor),
                          minHeight: 4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 5. Top Artists & Listening Time Stream
                Row(
                  children: [
                    // Top Artist
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF131722).withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF232838)),
                        ),
                        child: Row(
                          children: [
                            StudioArtworkWidget(
                              url: topArtist?.artworkUrl,
                              width: 28,
                              height: 28,
                              borderRadius: BorderRadius.circular(14),
                              fallbackIcon: HugeIcons.strokeRoundedUser,
                              fallbackIconSize: 14,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'PRIMARY ARTIST',
                                    style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.w800, color: textSecondary),
                                  ),
                                  Text(
                                    topArtist?.artist ?? 'Pink Floyd',
                                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: textPrimary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Active Listening Hours
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF131722).withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF232838)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TOTAL STREAMED',
                              style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.w800, color: textSecondary),
                            ),
                            Text(
                              '${data.totalMinutes} MINS',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: textPrimary,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 6. Footer Persona Tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: auraColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: auraColor.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            HugeIcon(icon: persona.icon, size: 14, color: auraColor),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                persona.title.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 9.0, fontWeight: FontWeight.w900, color: auraColor, letterSpacing: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        profile.peakTimeWindow.split(' ').first,
                        style: const TextStyle(fontSize: 8.0, fontWeight: FontWeight.w700, color: textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SoundwaveAuraPainter extends CustomPainter {
  final List<double> amplitudes;
  final Color primaryColor;
  final Color secondaryColor;

  _SoundwaveAuraPainter({
    required this.amplitudes,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Draw flowing sinusoidal wave ribbon across the background
    final wavePath1 = Path();

    final amp0 = amplitudes.isNotEmpty ? amplitudes[0] : 0.5;
    final amp1 = amplitudes.length > 1 ? amplitudes[1] : 0.8;
    final amp2 = amplitudes.length > 2 ? amplitudes[2] : 0.4;

    wavePath1.moveTo(0, h * 0.35);
    wavePath1.cubicTo(
      w * 0.3,
      h * (0.35 - (0.12 * amp0)),
      w * 0.7,
      h * (0.35 + (0.15 * amp1)),
      w,
      h * 0.35,
    );
    wavePath1.lineTo(w, h * 0.75);
    wavePath1.cubicTo(
      w * 0.6,
      h * (0.75 + (0.10 * amp2)),
      w * 0.3,
      h * (0.75 - (0.14 * amp0)),
      0,
      h * 0.75,
    );
    wavePath1.close();

    final paint1 = Paint()
      ..shader = LinearGradient(
        colors: [
          primaryColor.withValues(alpha: 0.12),
          secondaryColor.withValues(alpha: 0.05),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    canvas.drawPath(wavePath1, paint1);

    // Subtle line contours
    final strokePaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final contourPath = Path();
    contourPath.moveTo(0, h * 0.52);
    contourPath.cubicTo(w * 0.25, h * 0.42, w * 0.75, h * 0.62, w, h * 0.52);
    canvas.drawPath(contourPath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _SoundwaveAuraPainter oldDelegate) => true;
}
