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
              border: Border.all(
                color: isSolid
                    ? StudioSurfaceTheme.subtleOutline(context, isSolid: true)
                    : primary.withValues(alpha: 0.35),
                width: 0.8,
              ),
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
          // ─── 1. STUDIO CONFIGURATION STATUS HERO ─────────────────────────
          _buildStudioOverviewHero(context, themeState, isSolid),
          const SizedBox(height: 20),

          // ─── SECTION HEADER ──────────────────────────────────────────────
          Row(
            children: [
              HugeIcon(icon: HugeIcons.strokeRoundedGrid, size: 15, color: primary),
              const SizedBox(width: 8),
              Text(
                'SETTINGS CATEGORIES',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ─── 1. THEMING & COLOR PALETTES ─────────────────────────────────
          _buildCategoryCard(
            context,
            icon: HugeIcons.strokeRoundedLayers01,
            accentColor: primary,
            title: 'THEMING & COLOR PALETTES',
            subtitle: '7 Studio Palettes, Light/Dark/System Mode, Custom Neon Accents & Dynamic Monet Palette',
            badgeText: '${themeState.currentPalette.name} • ${themeState.themeMode.label}',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ThemingSettingsScreen()),
              );
            },
            isSolid: isSolid,
          ),
          const SizedBox(height: 12),

          // ─── 2. VISUALIZER & DISPLAY ──────────────────────────────────────
          _buildCategoryCard(
            context,
            icon: HugeIcons.strokeRoundedAudioWaveform,
            accentColor: theme.colorScheme.secondary,
            title: 'VISUALIZER & DISPLAY',
            subtitle: '120fps HiFi Profile, 3D Parallax, Gaussian Blur, Ambient Glow, Spectrum Bars & Vinyl Disc',
            badgeText: '3D Parallax • Ambient Glow',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const VisualizerSettingsScreen()),
              );
            },
            isSolid: isSolid,
          ),
          const SizedBox(height: 12),

          // ─── 3. GESTURES & TRACK TILES ────────────────────────────────────
          _buildCategoryCard(
            context,
            icon: HugeIcons.strokeRoundedActivity01,
            accentColor: const Color(0xFF00E5FF),
            title: 'GESTURES & TRACK TILES',
            subtitle: 'Artwork tap triggers (Lyrics, Fav, Inspector), swipe-to-queue/favorite & track tile layout options',
            badgeText: 'Touch Gestures • Swipe Actions',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const GesturesSettingsScreen()),
              );
            },
            isSolid: isSolid,
          ),
          const SizedBox(height: 12),

          // ─── 3. STUDIO WORKSTATION & CAR DOCK ────────────────────────────
          _buildCategoryCard(
            context,
            icon: HugeIcons.strokeRoundedCar01,
            accentColor: theme.colorScheme.tertiary,
            title: 'STUDIO WORKSTATION & CAR DOCK',
            subtitle: 'High-contrast studio clock, dual analog VU level meters & extra-large buttons for desk & car stands',
            badgeText: 'Fullscreen Stand Mode',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DockingSettingsScreen()),
              );
            },
            isSolid: isSolid,
          ),
          const SizedBox(height: 12),

          // ─── 4. AUDIO HARDWARE & DAC ENGINE ──────────────────────────────
          _buildCategoryCard(
            context,
            icon: HugeIcons.strokeRoundedCpu,
            accentColor: primary,
            title: 'AUDIO HARDWARE & DAC ENGINE',
            subtitle: 'SoLoud C++ Engine, Bit-Perfect DAC Direct Bypass, Output Audio Devices & Latency Buffer Tuning',
            badgeText: 'Bit-Perfect PCM Ready',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AudioHardwareSettingsScreen()),
              );
            },
            isSolid: isSolid,
          ),
          const SizedBox(height: 12),

          // ─── 5. ADVANCED PLAYBACK & INTERRUPTION ────────────────────────
          _buildCategoryCard(
            context,
            icon: HugeIcons.strokeRoundedDashboardSpeed01,
            accentColor: primary,
            title: 'ADVANCED PLAYBACK & INTERRUPTION',
            subtitle: 'Smooth volume fades, headphone unplug guard, speed/pitch semitones, ReplayGain & seek stepper',
            badgeText: 'Engine Transitions & Policies',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PlaybackEngineSettingsScreen()),
              );
            },
            isSolid: isSolid,
          ),
          const SizedBox(height: 12),

          // ─── 6. LIBRARY SCANNER & SLEEP TIMER ────────────────────────────
          _buildCategoryCard(
            context,
            icon: HugeIcons.strokeRoundedFolder01,
            accentColor: theme.colorScheme.secondary,
            title: 'LIBRARY SCANNER & SLEEP TIMER',
            subtitle: 'Automated 15s volume attenuation sleep timer, startup library scan & short clip duration filters',
            badgeText: 'Scanner Rules Active',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LibraryScannerSettingsScreen()),
              );
            },
            isSolid: isSolid,
          ),
          const SizedBox(height: 12),

          // ─── 7. STORAGE & CACHE QUOTA ──────────────────────────────────
          _buildCategoryCard(
            context,
            icon: HugeIcons.strokeRoundedDatabase,
            accentColor: const Color(0xFF00E5FF),
            title: 'STORAGE & CACHE QUOTA',
            subtitle: 'Disk storage gauge, artwork/lyrics cache cleaner, missing tracks relinker & duplicate resolver',
            badgeText: 'Cache & Integrity',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const StorageCacheSettingsScreen()),
              );
            },
            isSolid: isSolid,
          ),
          const SizedBox(height: 12),

          // ─── 8. BACKUP & RESTORE ARCHIVE ────────────────────────────────
          _buildCategoryCard(
            context,
            icon: HugeIcons.strokeRoundedCloudSync,
            accentColor: primary,
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
                border: Border.all(
                  color: theme.dividerColor.withValues(alpha: 0.5),
                  width: 0.8,
                ),
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
        color: StudioSurfaceTheme.surfaceContainer(context, isSolid: isSolid),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: StudioSurfaceTheme.outline(context, isSolid: isSolid),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isSolid ? 0.2 : 0.15),
            blurRadius: 12,
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
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'STUDIO SYSTEM PROFILE',
                    style: TextStyle(
                      color: primary,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isSolid
                      ? theme.colorScheme.surfaceContainerHighest
                      : StudioSurfaceTheme.tintedContainer(context, primary, isSolid: false, translucentAlpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSolid
                        ? StudioSurfaceTheme.subtleOutline(context, isSolid: true)
                        : primary.withValues(alpha: 0.4),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  '48kHz SOLOUD ONLINE',
                  style: TextStyle(
                    color: primary,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildHeroMetric(
                context,
                label: 'THEME',
                value: themeState.currentPalette.name,
                accent: primary,
                isSolid: isSolid,
              ),
              const SizedBox(width: 16),
              _buildHeroMetric(
                context,
                label: 'DAC ENGINE',
                value: isBitPerfect ? 'Bit-Perfect' : 'Standard PCM',
                accent: theme.colorScheme.primary,
                isSolid: isSolid,
              ),
              const SizedBox(width: 16),
              _buildHeroMetric(
                context,
                label: 'RTA DISPLAY',
                value: visualizerStyle,
                accent: theme.colorScheme.secondary,
                isSolid: isSolid,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroMetric(
    BuildContext context, {
    required String label,
    required String value,
    required Color accent,
    required bool isSolid,
  }) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              color: isSolid ? theme.colorScheme.onSurface : accent,
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
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
          border: Border.all(
            color: StudioSurfaceTheme.outline(context, isSolid: isSolid),
            width: 1.0,
          ),
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
                color: isSolid
                    ? theme.colorScheme.surfaceContainerHighest
                    : StudioSurfaceTheme.tintedContainer(context, accentColor, isSolid: false, translucentAlpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSolid
                      ? StudioSurfaceTheme.subtleOutline(context, isSolid: true)
                      : accentColor.withValues(alpha: 0.4),
                  width: 1.0,
                ),
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
                      color: isSolid
                          ? theme.colorScheme.surfaceContainerHighest
                          : StudioSurfaceTheme.tintedContainer(context, accentColor, isSolid: false, translucentAlpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSolid
                            ? StudioSurfaceTheme.subtleOutline(context, isSolid: true)
                            : accentColor.withValues(alpha: 0.3),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        color: isSolid ? theme.colorScheme.onSurfaceVariant : accentColor,
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
