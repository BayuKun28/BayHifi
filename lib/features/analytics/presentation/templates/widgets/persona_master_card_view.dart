import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../core/widgets/studio_artwork_widget.dart';
import '../../../domain/studio_wrapped_data.dart';

/// Dedicated Focus Card 1: Audiophile Persona Master Card
/// Showcases the user's audiophile archetype, dynamic acoustic radar, signature sound tags, and hardware integration.
class PersonaMasterCardView extends StatelessWidget {
  final StudioWrappedData data;

  const PersonaMasterCardView({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final persona = data.persona;
    final profile = data.resonanceProfile;
    final purity = data.audioPurityReport;
    final topTrack = data.topTrack;

    const cardBg = Color(0xFF0C0E14);
    const textBright = Color(0xFFF8FAFC);
    const textMuted = Color(0xFF94A3B8);
    final accentColor = persona.primaryColor;
    final secondaryAccent = persona.secondaryColor;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 420),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accentColor.withValues(alpha: 0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.8),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // ─── BACKGROUND ACOUSTIC GLOW ───────────────────────────────
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    accentColor.withValues(alpha: 0.25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    secondaryAccent.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ─── FOREGROUND CONTENT ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Top Header ID Badge
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
                              color: accentColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Flexible(
                            child: Text(
                              'AUDIOPHILE ARCHETYPE // 2026',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 9.0,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                                color: textBright,
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
                        color: accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: accentColor.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        'MASTER CERTIFIED',
                        style: TextStyle(
                          fontSize: 8.0,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                          color: accentColor,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // 2. Large Persona Grand Seal & Icon
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Concentric halo rings
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: accentColor.withValues(alpha: 0.3), width: 1.5),
                        ),
                      ),
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              accentColor.withValues(alpha: 0.35),
                              secondaryAccent.withValues(alpha: 0.25),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            persona.icon,
                            size: 44,
                            color: textBright,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 3. Persona Title & Philosophy Quote
                Center(
                  child: Column(
                    children: [
                      Text(
                        persona.title.toUpperCase(),
                        style: TextStyle(
                          fontSize: 17.0,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                          color: accentColor,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        persona.description,
                        style: const TextStyle(
                          fontSize: 11.0,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                          color: textMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 4. Signature Sound Tags Row
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6,
                  runSpacing: 6,
                  children: persona.soundSignatureTags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161A24),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF262E40)),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: textBright,
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 18),

                // 5. Acoustic Radar / Telemetry Grid
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF12151E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF222838)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _buildRadarStat(
                            label: 'ENERGY INDEX',
                            value: '${profile.energyScore}%',
                            accentColor: accentColor,
                          ),
                          _buildRadarStat(
                            label: 'DYN RANGE',
                            value: '${profile.dynamicRangeDb.toStringAsFixed(1)} dB',
                            accentColor: secondaryAccent,
                          ),
                          _buildRadarStat(
                            label: 'LOSSLESS PURITY',
                            value: '${purity.flacPercentage.toStringAsFixed(1)}%',
                            accentColor: accentColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Divider(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3), height: 1),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _buildRadarStat(
                            label: 'TOTAL STREAMED',
                            value: '${data.totalMinutes} MINS',
                            accentColor: textBright,
                          ),
                          _buildRadarStat(
                            label: 'PEAK WINDOW',
                            value: profile.peakTimeWindow.split(' ').first,
                            accentColor: textBright,
                          ),
                          _buildRadarStat(
                            label: 'TOP DRIVER',
                            value: data.favoriteAutoEqDriver.split(' ').first,
                            accentColor: textBright,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // 6. Footer Hardware Bridge Status
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F121A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF1E2436)),
                  ),
                  child: Row(
                    children: [
                      if (topTrack != null)
                        StudioArtworkWidget(
                          url: topTrack.albumArtUri,
                          width: 28,
                          height: 28,
                          borderRadius: BorderRadius.circular(6),
                          fallbackIcon: LucideIcons.music,
                          fallbackIconSize: 14,
                        ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'SIGNAL CHAIN HARDWARE',
                              style: TextStyle(
                                fontSize: 7.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                                color: textMuted,
                              ),
                            ),
                            Text(
                              '${data.favoriteDacDevice} • ${data.favoriteDspModule}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: textBright,
                              ),
                            ),
                          ],
                        ),
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

  static Widget _buildRadarStat({
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
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
