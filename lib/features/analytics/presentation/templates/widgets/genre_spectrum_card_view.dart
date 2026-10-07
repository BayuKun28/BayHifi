import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../domain/studio_wrapped_data.dart';

/// Dedicated Focus Card 3: Genre & Sonic Spectrum Card
/// Features studio frequency distribution, ranked genre breakdown with color bars, and timbral acoustic profile.
class GenreSpectrumCardView extends StatelessWidget {
  final StudioWrappedData data;

  const GenreSpectrumCardView({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final topGenres = data.topGenres;
    final primaryGenre = topGenres.isNotEmpty ? topGenres.first : null;
    final profile = data.resonanceProfile;
    final persona = data.persona;

    const cardBg = Color(0xFF0F1118);
    const textBright = Color(0xFFF8FAFC);
    const textDim = Color(0xFF94A3B8);
    final accentColor = persona.primaryColor;

    final genreColors = [
      const Color(0xFF38BDF8), // Studio Sky
      const Color(0xFFF59E0B), // Warm Tube Amber
      const Color(0xFF10B981), // Precision Mint
      const Color(0xFFA855F7), // Holographic Violet
      const Color(0xFFEC4899), // Neon Rose
    ];

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 420),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF22283A), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.18),
            blurRadius: 36,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.75),
            blurRadius: 28,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── 1. HEADER HUD ─────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF161A26),
              border: const Border(
                bottom: BorderSide(color: Color(0xFF252C3E), width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedSlidersVertical,
                        size: 16,
                        color: Color(0xFF38BDF8),
                      ),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'SONIC SPECTRUM // 2026',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 9.5,
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
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
                  ),
                  child: const Text(
                    'RTA ANALYZED',
                    style: TextStyle(
                      fontSize: 8.0,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                      color: Color(0xFF38BDF8),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ─── 2. PRIMARY GENRE SPOTLIGHT HERO ───────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF1A2030),
                        accentColor.withValues(alpha: 0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: accentColor.withValues(alpha: 0.4), width: 1.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              'DOMINANT SOUND ECOSYSTEM',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 8.0,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                                color: Color(0xFF38BDF8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${primaryGenre?.percentage.toStringAsFixed(1) ?? '0.0'}% DOMINANCE',
                            style: TextStyle(
                              fontSize: 9.0,
                              fontWeight: FontWeight.w800,
                              color: accentColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        primaryGenre?.genre ?? 'Progressive Rock & Studio',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                          color: textBright,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Timbral Mood: ${profile.timbralSignature}',
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

                const SizedBox(height: 16),

                // ─── 3. MULTI-SEGMENT SPECTRUM BAR ─────────────────────
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ACOUSTIC SPECTRUM DISTRIBUTION',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 8.0,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: textDim,
                      ),
                    ),
                    Text(
                      '20Hz - 20kHz',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 8.0,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF38BDF8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    height: 10,
                    child: Row(
                      children: topGenres.asMap().entries.map((entry) {
                        final color = genreColors[entry.key % genreColors.length];
                        final flex = (entry.value.percentage * 10).toInt().clamp(1, 1000);
                        return Expanded(
                          flex: flex,
                          child: Container(color: color),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ─── 4. GENRES RANKED LIST ─────────────────────────────
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141722),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF222838)),
                  ),
                  child: Column(
                    children: topGenres.take(4).toList().asMap().entries.map((entry) {
                      final index = entry.key + 1;
                      final genre = entry.value;
                      final color = genreColors[entry.key % genreColors.length];

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.5),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: color,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '0$index.',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: textDim,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                genre.genre,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: textBright,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${genre.percentage.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: color,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 14),

                // ─── 5. FOOTER PERSONA HARMONY STATUS ──────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E1017),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF1E2436)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            HugeIcon(icon: persona.icon, size: 14, color: accentColor),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                persona.title.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 9.0,
                                  fontWeight: FontWeight.w900,
                                  color: accentColor,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'DR ${profile.dynamicRangeDb} dB',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 9.0,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF38BDF8),
                          fontFeatures: [FontFeature.tabularFigures()],
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
}
