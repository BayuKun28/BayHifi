import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../app/theme/studio_surface_theme.dart';
import '../../../app/theme/theme_mode_controller.dart';
import '../../../core/database/local_persistence_service.dart';
import 'sub_screens/audio_hardware_settings_screen.dart';
import 'sub_screens/backup_restore_settings_screen.dart';
import 'sub_screens/docking_settings_screen.dart';
import 'sub_screens/gestures_settings_screen.dart';
import 'sub_screens/library_scanner_settings_screen.dart';
import 'sub_screens/playback_engine_settings_screen.dart';
import 'sub_screens/storage_cache_settings_screen.dart';
import 'sub_screens/theming_settings_screen.dart';
import 'sub_screens/visualizer_settings_screen.dart';

/// Studio Settings & Personalization Screen (Categorized Hub)
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeControllerProvider);
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isSolid = ref.isSolidStyle;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('SETTINGS & PREFERENCES'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isSolid
                  ? theme.colorScheme.surfaceContainerHighest
                  : StudioSurfaceTheme.tintedContainer(
                      context,
                      primary,
                      isSolid: false,
                      translucentAlpha: 0.12,
                    ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                HugeIcon(icon: HugeIcons.strokeRoundedColorPicker, size: 13, color: primary),
                const SizedBox(width: 6),
                Text(
                  themeState.currentPalette.name,
                  style: TextStyle(
                    color: primary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120), // Extra bottom padding for floating dock & miniplayer
        children: [
          // ─── 1. INTERACTIVE STUDIO COCKPIT TELEMETRY HERO ────────────────
          _buildStudioOverviewHero(context, themeState, isSolid),
          const SizedBox(height: 24),

          // ─── 2. SECTION 1: AESTHETICS & ATMOSPHERE ──────────────────────
          _buildSectionHeader(
            context,
            title: 'AESTHETICS & ATMOSPHERE',
            icon: HugeIcons.strokeRoundedLayers01,
            color: StudioCategoryColors.themingPalettes,
          ),
          const SizedBox(height: 10),

          _buildCategoryCard(
            context,
            icon: HugeIcons.strokeRoundedColorPicker,
            accentColor: StudioCategoryColors.themingPalettes,
            title: 'THEMING & COLOR PALETTES',
            subtitle: '19 Studio Palettes, Light/Dark/System Mode, Pure Solid M3 Surface Fills & Monet Dynamic Art',
            badgeText: '${themeState.currentPalette.name} • ${themeState.isSolidStyle ? "Pure Solid" : "Translucent"}',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ThemingSettingsScreen()),
              );
            },
            isSolid: isSolid,
          ),
          const SizedBox(height: 10),

          _buildCategoryCard(
            context,
            icon: HugeIcons.strokeRoundedAudioWaveform,
            accentColor: StudioCategoryColors.visualizer,
            title: 'VISUALIZER & DISPLAY',
            subtitle: 'Turntable Tonearm, Cassette, CD Jewel, Dual VU Meters, Mirror Wave & Precision Studio Ruler',
            badgeText: 'Live RTA • 20 Expressive Styles',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const VisualizerSettingsScreen()),
              );
            },
            isSolid: isSolid,
          ),
          const SizedBox(height: 10),

          _buildCategoryCard(
            context,
            icon: HugeIcons.strokeRoundedCar01,
            accentColor: StudioCategoryColors.dockingDesk,
            title: 'STUDIO WORKSTATION & CAR DOCK',
            subtitle: 'High-contrast studio timecode clock, dual analog VU level dials & large controls for desk stands',
            badgeText: 'Fullscreen Stand Mode',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DockingSettingsScreen()),
              );
            },
            isSolid: isSolid,
          ),
          const SizedBox(height: 24),

          // ─── 3. SECTION 2: AUDIO ARCHITECTURE & DSP ─────────────────────
          _buildSectionHeader(
            context,
            title: 'AUDIO ARCHITECTURE & DSP WORKSTATION',
            icon: HugeIcons.strokeRoundedCpu,
            color: StudioCategoryColors.audioHardware,
          ),
          const SizedBox(height: 10),

          _buildCategoryCard(
            context,
            icon: HugeIcons.strokeRoundedCpu,
            accentColor: StudioCategoryColors.audioHardware,
            title: 'AUDIO HARDWARE & DAC ENGINE',
            subtitle: 'SoLoud C++ Engine, Bit-Perfect Direct Stream Bypass, Output Devices & Latency Buffer Tuning',
            badgeText: 'Bit-Perfect PCM Ready',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AudioHardwareSettingsScreen()),
              );
            },
            isSolid: isSolid,
          ),
          const SizedBox(height: 10),

          _buildCategoryCard(
            context,
            icon: HugeIcons.strokeRoundedDashboardSpeed01,
            accentColor: StudioCategoryColors.proQEqualizer,
            title: 'ADVANCED PLAYBACK ENGINE & FADES',
            subtitle: 'Smooth volume fades, headphone unplug guard, speed/pitch semitones, ReplayGain & seek stepper',
            badgeText: 'Engine Transitions & Policies',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PlaybackEngineSettingsScreen()),
              );
            },
            isSolid: isSolid,
          ),
          const SizedBox(height: 24),

          // ─── 4. SECTION 3: MEDIA, LIBRARY & STORAGE ──────────────────────
          _buildSectionHeader(
            context,
            title: 'MEDIA, LIBRARY & STORAGE',
            icon: HugeIcons.strokeRoundedFolder01,
            color: StudioCategoryColors.libraryScanner,
          ),
          const SizedBox(height: 10),

          _buildCategoryCard(
            context,
            icon: HugeIcons.strokeRoundedFolder01,
            accentColor: StudioCategoryColors.libraryScanner,
            title: 'LIBRARY SCANNER & SLEEP TIMER',
            subtitle: 'Automated 15s/30s volume attenuation sleep timer, startup library scan & audio clip filters',
            badgeText: 'Scanner Rules Active',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LibraryScannerSettingsScreen()),
              );
            },
            isSolid: isSolid,
          ),
          const SizedBox(height: 10),

          _buildCategoryCard(
            context,
            icon: HugeIcons.strokeRoundedDatabase,
            accentColor: StudioCategoryColors.storageCache,
            title: 'STORAGE & CACHE QUOTA',
            subtitle: 'Disk storage gauge, artwork/lyrics cache cleaner, missing tracks relinker & database vacuum',
            badgeText: 'Cache & Integrity',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const StorageCacheSettingsScreen()),
              );
            },
            isSolid: isSolid,
          ),
          const SizedBox(height: 24),

          // ─── 5. SECTION 4: SYSTEM, GESTURES & ARCHIVE ────────────────────
          _buildSectionHeader(
            context,
            title: 'SYSTEM, GESTURES & ARCHIVE',
            icon: HugeIcons.strokeRoundedSettings01,
            color: StudioCategoryColors.gestures,
          ),
          const SizedBox(height: 10),

          _buildCategoryCard(
            context,
            icon: HugeIcons.strokeRoundedActivity01,
            accentColor: StudioCategoryColors.gestures,
            title: 'GESTURES & TRACK TILES',
            subtitle: 'Artwork tap triggers (Lyrics, Fav, Inspector), swipe-to-queue/favorite & track tile layouts',
            badgeText: 'Touch Gestures • Swipe Actions',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const GesturesSettingsScreen()),
              );
            },
            isSolid: isSolid,
          ),
          const SizedBox(height: 10),

          _buildCategoryCard(
            context,
            icon: HugeIcons.strokeRoundedCloudSync,
            accentColor: StudioCategoryColors.backupVault,
            title: 'BACKUP & RESTORE ARCHIVE',
            subtitle: 'Export and import portable .bayhifi JSON snapshots containing playlists, smart rules & presets',
            badgeText: '.bayhifi Snapshot Engine',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BackupRestoreSettingsScreen()),
              );
            },
            isSolid: isSolid,
          ),
          const SizedBox(height: 28),

          // ─── 6. BAYDEV STUDIO WATERMARK ─────────────────────────────────
          _buildBaydevWatermark(context, theme, primary),
        ],
      ),
    );
  }

  Widget _buildBaydevWatermark(BuildContext context, ThemeData theme, Color primary) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Image.asset(
                'assets/images/baydev_logo.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'BAYDEV HIFI STUDIO',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Version 1.0.0 • Pure Audiophile Lossless Engine',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Crafted by Baydev Studio',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: primary.withValues(alpha: 0.8),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required dynamic icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 2.0),
      child: Row(
        children: [
          HugeIcon(icon: icon, size: 14, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudioOverviewHero(BuildContext context, ThemeSettingsState themeState, bool isSolid) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final storage = LocalPersistenceService.instance;
    final isBitPerfect = storage.getSetting<bool>('bit_perfect', true) ?? true;
    final visualizerStyle = storage.getSetting<String>('visualizer_style', 'Spectrum Bars') ?? 'Spectrum Bars';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSolid ? theme.colorScheme.surfaceContainer : StudioSurfaceTheme.surfaceContainer(context, isSolid: false),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isSolid ? 0.25 : 0.15),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primary.withValues(alpha: 0.5),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'STUDIO SYSTEM COCKPIT',
                    style: TextStyle(
                      color: primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.9,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                decoration: BoxDecoration(
                  color: isSolid
                      ? theme.colorScheme.surfaceContainerHighest
                      : StudioSurfaceTheme.tintedContainer(context, primary, isSolid: false, translucentAlpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HugeIcon(icon: HugeIcons.strokeRoundedCpu, size: 11, color: primary),
                    const SizedBox(width: 5),
                    Text(
                      '48kHz SOLOUD ENGINE',
                      style: TextStyle(
                        color: primary,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildInteractiveTelemetryChip(
                context,
                icon: HugeIcons.strokeRoundedPaintBoard,
                label: 'PALETTE',
                value: themeState.currentPalette.name,
                accent: StudioCategoryColors.themingPalettes,
                isSolid: isSolid,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ThemingSettingsScreen()),
                  );
                },
              ),
              const SizedBox(width: 8),
              _buildInteractiveTelemetryChip(
                context,
                icon: HugeIcons.strokeRoundedCpu,
                label: 'AUDIO DAC',
                value: isBitPerfect ? 'Bit-Perfect' : 'Standard',
                accent: StudioCategoryColors.bitPerfect,
                isSolid: isSolid,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AudioHardwareSettingsScreen()),
                  );
                },
              ),
              const SizedBox(width: 8),
              _buildInteractiveTelemetryChip(
                context,
                icon: HugeIcons.strokeRoundedAudioWaveform,
                label: 'RTA PROFILE',
                value: visualizerStyle,
                accent: StudioCategoryColors.visualizer,
                isSolid: isSolid,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const VisualizerSettingsScreen()),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveTelemetryChip(
    BuildContext context, {
    required dynamic icon,
    required String label,
    required String value,
    required Color accent,
    required bool isSolid,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: isSolid ? 0.14 : 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  HugeIcon(icon: icon, size: 11, color: accent),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: accent,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context, {
    required dynamic icon,
    required Color accentColor,
    required String title,
    required String subtitle,
    required String badgeText,
    required VoidCallback onTap,
    required bool isSolid,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: StudioSurfaceTheme.surfaceContainer(context, isSolid: isSolid),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isSolid ? 0.2 : 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: isSolid ? 0.16 : 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: HugeIcon(
                  icon: icon,
                  size: 22,
                  color: accentColor,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 11,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: isSolid ? 0.14 : 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            HugeIcon(
              icon: HugeIcons.strokeRoundedArrowRight01,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}
