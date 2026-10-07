import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../../core/widgets/studio_artwork_widget.dart';
import '../../../domain/studio_wrapped_data.dart';

/// 💻 Template 8: Cyber Tech Spec & Hardware IC HUD Edition
/// Features engineering datasheet aesthetics, hardware DSP telemetry, circuit grid reticles, and DAC signal matrix.
class CyberSpecCardView extends StatelessWidget {
  final StudioWrappedData data;

  const CyberSpecCardView({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final topTrack = data.topTrack;
    final topArtist = data.topArtist;
    final persona = data.persona;
    final profile = data.resonanceProfile;
    final purity = data.audioPurityReport;

    const cyberBg = Color(0xFF0A0C10);
    const cyberCardBg = Color(0xFF12151D);
    const cyanAccent = Color(0xFF00F0FF);
    const greenAccent = Color(0xFF00FF9D);
    const textBright = Color(0xFFF1F5F9);
    const textDim = Color(0xFF64748B);

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 420),
      decoration: BoxDecoration(
        color: cyberBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E2638), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: cyanAccent.withValues(alpha: 0.15),
            blurRadius: 36,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.8),
            blurRadius: 28,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // ─── 0. BACKGROUND CYBER GRID & RETICLES ────────────────────
          Positioned.fill(
            child: CustomPaint(
              painter: _CyberGridPainter(
                accentColor: cyanAccent,
              ),
            ),
          ),

          // ─── 1. FOREGROUND CONTENT ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header HUD
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: greenAccent,
                              boxShadow: [
                                BoxShadow(color: greenAccent.withValues(alpha: 0.8), blurRadius: 6),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Flexible(
                            child: Text(
                              'SYSTEM DIAGNOSTIC // 2026',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                                color: cyanAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161C28),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: cyanAccent.withValues(alpha: 0.4)),
                      ),
                      child: const Text(
                        '0x7F:SOLOUD-DSP',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          color: textBright,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ─── DSP CORE ARCHITECTURE CARD ────────────────────────
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cyberCardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF222B3D)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const HugeIcon(
                            icon: HugeIcons.strokeRoundedCpu,
                            size: 16,
                            color: cyanAccent,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'DSP ENGINE: ${persona.title.toUpperCase()}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 10.0,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.0,
                                color: textBright,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'SNR 124dB',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 9.0,
                              fontWeight: FontWeight.w700,
                              color: greenAccent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Telemetry Stats Row
                      Row(
                        children: [
                          _buildHardwareMetric(
                            label: 'ENERGY INDEX',
                            value: '${profile.energyScore}%',
                            accentColor: cyanAccent,
                          ),
                          const SizedBox(width: 12),
                          _buildHardwareMetric(
                            label: 'DYN RANGE',
                            value: '${profile.dynamicRangeDb.toStringAsFixed(1)} dB',
                            accentColor: greenAccent,
                          ),
                          const SizedBox(width: 12),
                          _buildHardwareMetric(
                            label: 'TIMBRE',
                            value: profile.timbralSignature.split(' ').first,
                            accentColor: persona.primaryColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ─── OPTICAL MEMORY CORE (TOP TRACK & ARTIST) ──────────
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10131B),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: cyanAccent.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      // Circular Reticle with Album Art
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: cyanAccent, width: 1.5),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: StudioArtworkWidget(
                              url: topTrack?.albumArtUri,
                              width: 60,
                              height: 60,
                              borderRadius: BorderRadius.circular(30),
                              fallbackIcon: HugeIcons.strokeRoundedMusicNote01,
                              fallbackIconSize: 26,
                              backgroundColor: const Color(0xFF0A0C10),
                            ),
                          ),
                          // Reticle Crosshairs
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: cyanAccent.withValues(alpha: 0.3), width: 1),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Text(
                                  'CORE MASTER ASSET',
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 8.0,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                    color: cyanAccent,
                                  ),
                                ),
                                Spacer(),
                                Text(
                                  '#01 ASSET',
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 8.0,
                                    fontWeight: FontWeight.w700,
                                    color: greenAccent,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              topTrack?.title ?? 'Master Telemetry Track',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13.0,
                                fontWeight: FontWeight.w900,
                                color: textBright,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              topArtist?.artist ?? 'Master Engineer',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: textDim,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ─── SIGNAL TELEMETRY MATRIX (TOP TRACKS) ──────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: cyberCardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF222B3D)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              'TELEMETRY MATRIX [TOP 4]',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 9.0,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                                color: cyanAccent,
                              ),
                            ),
                          ),
                          Text(
                            '${(data.totalMinutes / 60).round()} HRS LOGGED',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 8.5,
                              fontWeight: FontWeight.w700,
                              color: textDim,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...data.topTracks.take(4).toList().asMap().entries.map((entry) {
                        final index = entry.key + 1;
                        final track = entry.value;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Text(
                                '0x0$index',
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 9.0,
                                  fontWeight: FontWeight.w700,
                                  color: textDim,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  track.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11.0,
                                    fontWeight: FontWeight.w600,
                                    color: textBright,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E2638),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${track.playCount}x',
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 9.0,
                                    fontWeight: FontWeight.w700,
                                    color: cyanAccent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ─── FOOTER HARDWARE STATUS HUD ────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F121A),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF1E2638)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'LOSSLESS PURITY',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 7.5,
                                fontWeight: FontWeight.w800,
                                color: textDim,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${purity.flacPercentage.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 13.0,
                                fontWeight: FontWeight.w900,
                                color: greenAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F121A),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF1E2638)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'PEAK WINDOW',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 7.5,
                                fontWeight: FontWeight.w800,
                                color: textDim,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              profile.peakTimeWindow.split(' ').first,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12.0,
                                fontWeight: FontWeight.w900,
                                color: cyanAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F121A),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF1E2638)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TOTAL TRACKS',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 7.5,
                                fontWeight: FontWeight.w800,
                                color: textDim,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${data.totalTracksPlayed}',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 13.0,
                                fontWeight: FontWeight.w900,
                                color: textBright,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildHardwareMetric({
    required String label,
    required String value,
    required Color accentColor,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 7.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12.0,
              fontWeight: FontWeight.w900,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for cyber grid, corner brackets, and circuit traces
class _CyberGridPainter extends CustomPainter {
  final Color accentColor;

  _CyberGridPainter({required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final bracketPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const cornerLength = 16.0;
    const padding = 8.0;

    // Top-Left Corner Bracket
    canvas.drawLine(
      const Offset(padding, padding + cornerLength),
      const Offset(padding, padding),
      bracketPaint,
    );
    canvas.drawLine(
      const Offset(padding, padding),
      const Offset(padding + cornerLength, padding),
      bracketPaint,
    );

    // Top-Right Corner Bracket
    canvas.drawLine(
      Offset(size.width - padding - cornerLength, padding),
      Offset(size.width - padding, padding),
      bracketPaint,
    );
    canvas.drawLine(
      Offset(size.width - padding, padding),
      Offset(size.width - padding, padding + cornerLength),
      bracketPaint,
    );

    // Bottom-Left Corner Bracket
    canvas.drawLine(
      Offset(padding, size.height - padding - cornerLength),
      Offset(padding, size.height - padding),
      bracketPaint,
    );
    canvas.drawLine(
      Offset(padding, size.height - padding),
      Offset(padding + cornerLength, size.height - padding),
      bracketPaint,
    );

    // Bottom-Right Corner Bracket
    canvas.drawLine(
      Offset(size.width - padding - cornerLength, size.height - padding),
      Offset(size.width - padding, size.height - padding),
      bracketPaint,
    );
    canvas.drawLine(
      Offset(size.width - padding, size.height - padding),
      Offset(size.width - padding, size.height - padding - cornerLength),
      bracketPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CyberGridPainter oldDelegate) =>
      oldDelegate.accentColor != accentColor;
}
