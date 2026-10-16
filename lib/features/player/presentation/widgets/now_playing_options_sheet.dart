import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_haptics.dart';
import '../../../../core/widgets/meta_tracking_label.dart';
import '../../domain/track.dart';

/// Minimalist playback options bottom sheet or dialog adhering to the Simple-As-F design language.
///
/// Responsive across mobile (bottom sheet) and tablet/desktop (centered modal dialog).
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
  final bool isDialog;

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
    this.isDialog = false,
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
    final isDesktopOrTablet = MediaQuery.of(context).size.width >= 650;
    if (isDesktopOrTablet) {
      return showDialog(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.65),
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: NowPlayingOptionsSheet(
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
            isDialog: true,
          ),
        ),
      );
    }
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
        isDialog: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const emeraldMint = Color(0xFF4ADE80);

    return Container(
      constraints: BoxConstraints(
        maxWidth: isDialog ? 440 : double.infinity,
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF16181F),
        borderRadius: isDialog
            ? BorderRadius.circular(20)
            : const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: const Color(0xFF262936),
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
              // Top drag pill (Mobile only)
              if (!isDialog)
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E3344),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const MetaTrackingLabel(
                    'PLAYBACK OPTIONS',
                    fontSize: 11,
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (track != null)
                        Text(
                          track!.format.name.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: emeraldMint,
                            letterSpacing: 0.5,
                          ),
                        ),
                      if (isDialog) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(LucideIcons.x, size: 16, color: Color(0xFF8A9A90)),
                          onPressed: () => Navigator.pop(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Options list
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildOptionTile(
                        icon: LucideIcons.sliders,
                        title: 'Pro-Q Studio Equalizer',
                        subtitle: 'Parametric EQ, target matching & biquad filters',
                        iconColor: emeraldMint,
                        onTap: () {
                          Navigator.pop(context);
                          onOpenProQStudio();
                        },
                      ),
                      _buildOptionTile(
                        icon: LucideIcons.quote,
                        title: 'Synchronized Lyrics',
                        subtitle: isLyricsActive ? 'Currently active — tap to hide' : 'View time-synced LRC lyrics',
                        iconColor: isLyricsActive ? emeraldMint : Colors.white,
                        onTap: () {
                          Navigator.pop(context);
                          onToggleLyrics();
                        },
                      ),
                      _buildOptionTile(
                        icon: LucideIcons.timer,
                        title: 'Sleep Timer',
                        subtitle: 'Auto pause after timeout or current song',
                        iconColor: Colors.white,
                        onTap: () {
                          Navigator.pop(context);
                          onOpenSleepTimer();
                        },
                      ),
                      _buildOptionTile(
                        icon: LucideIcons.gauge,
                        title: 'Speed & Pitch Semitone Engine',
                        subtitle: 'Tempo scaling and pitch adjustment',
                        iconColor: Colors.white,
                        onTap: () {
                          Navigator.pop(context);
                          onOpenSpeedPitch();
                        },
                      ),
                      _buildOptionTile(
                        icon: LucideIcons.car,
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
                          icon: LucideIcons.info,
                          title: 'Technical Specs Inspector',
                          subtitle: 'Detailed sample rate, bit depth, codec & file tags',
                          iconColor: Colors.white,
                          onTap: () {
                            Navigator.pop(context);
                            onOpenInspector();
                          },
                        ),
                      _buildOptionTile(
                        icon: LucideIcons.folder,
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
                          icon: LucideIcons.maximize2,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
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
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF1E212B),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF262936)),
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 17,
                  color: iconColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF8A9A90),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              LucideIcons.chevronRight,
              size: 15,
              color: Color(0xFF555D6E),
            ),
          ],
        ),
      ),
    );
  }
}
