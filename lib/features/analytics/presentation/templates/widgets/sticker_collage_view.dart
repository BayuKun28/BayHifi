import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../../core/widgets/studio_artwork_widget.dart';
import '../../../domain/audiophile_persona.dart';
import '../../../domain/studio_wrapped_data.dart';

/// 🏷️ Template 2: Studio Sticker Slap & Tape Collage (Y2K / Studio Aesthetic)
/// Features tilted 3D stickers, tactile drop shadows, holographic stamps, and gold foil badges.
class StickerCollageView extends StatelessWidget {
  final StudioWrappedData data;

  const StickerCollageView({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final topTrack = data.topTrack;
    final topArtist = data.topArtist;
    final persona = data.persona;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 420),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F12), // Deep Matte Vinyl Black
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF27272A), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── STICKER 1: Studio Header Tape ─────────────────────────
          Transform.rotate(
            angle: -2.0 * math.pi / 180,
            child: _buildStudioTapeHeader(),
          ),
          const SizedBox(height: 14),

          // ─── STICKER 2 & 3: Top Artist & Vinyl Badge ────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Top Artist Sticker
              Expanded(
                flex: 5,
                child: Transform.rotate(
                  angle: -3.5 * math.pi / 180,
                  child: _buildTopArtistSticker(topArtist),
                ),
              ),
              const SizedBox(width: 8),

              // Right: Top #1 Track Vinyl Sticker
              Expanded(
                flex: 6,
                child: Transform.rotate(
                  angle: 4.0 * math.pi / 180,
                  child: _buildTopTrackSticker(topTrack),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ─── STICKER 4: Heavy Rotation Listening Time ───────────────
          Transform.rotate(
            angle: 1.5 * math.pi / 180,
            child: _buildListeningTimeSticker(data.totalMinutes),
          ),
          const SizedBox(height: 12),

          // ─── STICKER 5 & 6: Hi-Res Purity & DSP Gear ────────────────
          Row(
            children: [
              // Left: Lossless Purity Stamp
              Expanded(
                flex: 6,
                child: Transform.rotate(
                  angle: -2.5 * math.pi / 180,
                  child: _buildPuritySticker(data.purityReport),
                ),
              ),
              const SizedBox(width: 8),

              // Right: Gear & Tuning Badge
              Expanded(
                flex: 5,
                child: Transform.rotate(
                  angle: 3.5 * math.pi / 180,
                  child: _buildGearSticker(data.favoriteAutoEqDriver, data.favoriteDspModule),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ─── STICKER 7: Audiophile Persona Archetype ────────────────
          Transform.rotate(
            angle: -1.2 * math.pi / 180,
            child: _buildPersonaSticker(persona),
          ),
          const SizedBox(height: 14),

          // ─── FOOTER BARCODE STAMP ───────────────────────────────────
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF18181B),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF3F3F46), width: 0.8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HugeIcon(icon: HugeIcons.strokeRoundedMusicNote03, size: 12, color: Color(0xFF38BDF8)),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'BAYDEV AUDIO ENGINE • BIT-PERFECT BITSTREAM',
                      style: TextStyle(
                        fontSize: 8.0,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: Color(0xFFA1A1AA),
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
    );
  }

  Widget _buildStudioTapeHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFACC15), // Studio Tape Yellow
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              'BAYDEV HIFI',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.8,
                color: Color(0xFF18181B),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: 8),
          Text(
            '2026 RECAP // LOSSLESS',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: Color(0xFF18181B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopArtistSticker(TopArtistRank? artist) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFEC4899), // Neon Pink Sticker
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white, width: 2.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(3, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              HugeIcon(icon: HugeIcons.strokeRoundedAward01, size: 12, color: Colors.white),
              SizedBox(width: 4),
              Text(
                '#1 ARTIST',
                style: TextStyle(fontSize: 8.0, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              StudioArtworkWidget(
                url: artist?.artworkUrl,
                width: 28,
                height: 28,
                borderRadius: BorderRadius.circular(14),
                fallbackIcon: HugeIcons.strokeRoundedUser,
                fallbackIconSize: 14,
                backgroundColor: Colors.white24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      artist?.artist ?? 'Pink Floyd',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${artist?.totalMinutes ?? 1420} mins',
                      style: const TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFFCE7F3),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopTrackSticker(TopTrackRank? track) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF0284C7), // Electric Ocean Blue
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white, width: 2.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(3, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              HugeIcon(icon: HugeIcons.strokeRoundedDisc, size: 12, color: Colors.white),
              SizedBox(width: 4),
              Text(
                'TOP TRACK',
                style: TextStyle(fontSize: 8.0, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              StudioArtworkWidget(
                url: track?.albumArtUri,
                width: 30,
                height: 30,
                borderRadius: BorderRadius.circular(6),
                fallbackIcon: HugeIcons.strokeRoundedMusicNote01,
                fallbackIconSize: 16,
                backgroundColor: Colors.white24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track?.title ?? 'Time (2023 Remaster)',
                      style: const TextStyle(
                        fontSize: 11.0,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${track?.playCount ?? 84} plays • ${track?.format.toUpperCase() ?? "FLAC"}',
                      style: const TextStyle(
                        fontSize: 8.0,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFE0F2FE),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListeningTimeSticker(int minutes) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF059669), // Emerald Vinyl Sticker
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white, width: 2.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(2, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'STUDIO LISTENING TIME',
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'HEAVY ROTATION',
                  style: TextStyle(
                    fontSize: 7.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFD1FAE5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$minutes MINS',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              fontFeatures: [FontFeature.tabularFigures()],
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPuritySticker(AudioPurityReport purity) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF8B5CF6), // Violet Stamp
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white, width: 2.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(2, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              HugeIcon(icon: HugeIcons.strokeRoundedSparkles, size: 12, color: Colors.white),
              SizedBox(width: 4),
              Text(
                'AUDIO PURITY',
                style: TextStyle(fontSize: 8.0, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${purity.flacPercentage.toStringAsFixed(1)}%',
            style: const TextStyle(
              fontSize: 15.0,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const Text(
            'Hi-Res FLAC',
            style: TextStyle(
              fontSize: 8.0,
              fontWeight: FontWeight.w700,
              color: Color(0xFFEDE9FE),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGearSticker(String driver, String dsp) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF97316), // Orange Gear Sticker
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white, width: 2.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(2, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              HugeIcon(icon: HugeIcons.strokeRoundedHeadphones, size: 12, color: Colors.white),
              SizedBox(width: 4),
              Text(
                'STUDIO GEAR',
                style: TextStyle(fontSize: 8.0, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            driver.toUpperCase(),
            style: const TextStyle(
              fontSize: 9.0,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            dsp.toUpperCase(),
            style: const TextStyle(
              fontSize: 8.0,
              fontWeight: FontWeight.w700,
              color: Color(0xFFFFEDD5),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPersonaSticker(AudiophilePersona persona) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [persona.primaryColor, persona.secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: persona.primaryColor.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HugeIcon(icon: persona.icon, size: 14, color: Colors.white),
              const SizedBox(width: 6),
              const Text(
                'AUDIOPHILE PERSONA',
                style: TextStyle(
                  fontSize: 8.0,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            persona.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '"${persona.quote}"',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 8.5,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.92),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
