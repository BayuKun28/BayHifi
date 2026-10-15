import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../app/theme/app_haptics.dart';
import '../../../../app/theme/simple_as_f_theme.dart';
import '../../../../core/widgets/meta_tracking_label.dart';
import '../../domain/track.dart';

/// Minimalist playback options bottom sheet adhering to the Simple-As-F design language.
class NowPlayingOptionsSheet extends StatelessWidget {
  final Track? track;
  final VoidCallback onOpenProQStudio;
  final VoidCallback onOpenSpeedPitch;
  final VoidCallback onOpenDeskMode;
  final VoidCallback onOpenSleepTimer;
  final VoidCallback onOpenInspector;
  final VoidCallback onToggleLyrics;
  final VoidCallback onOpenFile;
  final VoidCallback onOpenLightbox;
  final bool isLyricsActive;

  const NowPlayingOptionsSheet({
    super.key,
    required this.track,
    required this.onOpenProQStudio,
    required this.onOpenSpeedPitch,
    required this.onOpenDeskMode,
    required this.onOpenSleepTimer,
    required this.onOpenInspector,
    required this.onToggleLyrics,
    required this.onOpenFile,
    required this.onOpenLightbox,
    required this.isLyricsActive,
  });

  static Future<void> show({
    required BuildContext context,
    required Track? track,
    required VoidCallback onOpenProQStudio,
    required VoidCallback onOpenSpeedPitch,
    required VoidCallback onOpenDeskMode,
    required VoidCallback onOpenSleepTimer,
    required VoidCallback onOpenInspector,
    required VoidCallback onToggleLyrics,
    required VoidCallback onOpenFile,
    required VoidCallback onOpenLightbox,
    required bool isLyricsActive,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => NowPlayingOptionsSheet(
        track: track,
        onOpenProQStudio: onOpenProQStudio,
        onOpenSpeedPitch: onOpenSpeedPitch,
        onOpenDeskMode: onOpenDeskMode,
        onOpenSleepTimer: onOpenSleepTimer,
        onOpenInspector: onOpenInspector,
        onToggleLyrics: onToggleLyrics,
        onOpenFile: onOpenFile,
        onOpenLightbox: onOpenLightbox,
        isLyricsActive: isLyricsActive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SimpleAsFTheme.forestCanvas,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top drag pill
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const MetaTrackingLabel(
                    'PLAYBACK OPTIONS',
                    fontSize: 11,
                  ),
                  if (track != null)
                    Text(
                      track!.format.name.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: SimpleAsFTheme.emeraldMint,
                        letterSpacing: 0.5,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Options list
              _buildOptionTile(
                icon: HugeIcons.strokeRoundedSlidersVertical,
                title: 'Pro-Q Studio Equalizer',
                subtitle: 'Parametric EQ, target matching & biquad filters',
                iconColor: SimpleAsFTheme.emeraldMint,
                onTap: () {
                  Navigator.pop(context);
                  onOpenProQStudio();
                },
              ),
              _buildOptionTile(
                icon: HugeIcons.strokeRoundedTextFont,
                title: 'Synchronized Lyrics',
                subtitle: isLyricsActive ? 'Currently active — tap to hide' : 'View time-synced LRC lyrics',
                iconColor: isLyricsActive ? SimpleAsFTheme.emeraldMint : Colors.white,
                onTap: () {
                  Navigator.pop(context);
                  onToggleLyrics();
                },
              ),
              _buildOptionTile(
                icon: HugeIcons.strokeRoundedHourglass,
                title: 'Sleep Timer',
                subtitle: 'Auto pause after timeout or current song',
                iconColor: Colors.white,
                onTap: () {
                  Navigator.pop(context);
                  onOpenSleepTimer();
                },
              ),
              _buildOptionTile(
                icon: HugeIcons.strokeRoundedDashboardSpeed01,
                title: 'Speed & Pitch Semitone Engine',
                subtitle: 'Tempo scaling and pitch adjustment',
                iconColor: Colors.white,
                onTap: () {
                  Navigator.pop(context);
                  onOpenSpeedPitch();
                },
              ),
              _buildOptionTile(
                icon: HugeIcons.strokeRoundedCar01,
                title: 'Studio Desk & Car Docking Mode',
                subtitle: 'Distraction-free high contrast full screen deck',
                iconColor: Colors.white,
                onTap: () {
                  Navigator.pop(context);
                  onOpenDeskMode();
                },
              ),
              if (track != null)
                _buildOptionTile(
                  icon: HugeIcons.strokeRoundedInformationCircle,
                  title: 'Technical Specs Inspector',
                  subtitle: 'Detailed sample rate, bit depth, codec & file tags',
                  iconColor: Colors.white,
                  onTap: () {
                    Navigator.pop(context);
                    onOpenInspector();
                  },
                ),
              _buildOptionTile(
                icon: HugeIcons.strokeRoundedFolder01,
                title: 'Open Audio File',
                subtitle: 'Play FLAC, DSD, WAV, MP3 from local storage',
                iconColor: Colors.white,
                onTap: () {
                  Navigator.pop(context);
                  onOpenFile();
                },
              ),
              if (track != null)
                _buildOptionTile(
                  icon: HugeIcons.strokeRoundedMaximize02,
                  title: 'View Artwork Lightbox',
                  subtitle: 'Full resolution cover preview',
                  iconColor: Colors.white,
                  onTap: () {
                    Navigator.pop(context);
                    onOpenLightbox();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required dynamic icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        AppHaptics.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: HugeIcon(
                  icon: icon,
                  size: 20,
                  color: iconColor,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: SimpleAsFTheme.sageSlate,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const HugeIcon(
              icon: HugeIcons.strokeRoundedArrowRight01,
              size: 16,
              color: SimpleAsFTheme.sageSlate,
            ),
          ],
        ),
      ),
    );
  }
}
