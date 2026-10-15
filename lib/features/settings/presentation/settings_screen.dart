import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import '../../../app/theme/studio_surface_theme.dart';
import '../../../app/theme/theme_mode_controller.dart';
import '../../../core/widgets/two_tone_header.dart';
import '../../cloud_sync/presentation/widgets/settings_account_card.dart';
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
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeControllerProvider);
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isSolid = ref.isSolidStyle;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const TwoToneHeader(
          primaryText: 'STUDIO',
          accentText: 'SETTINGS',
          fontSize: 18,
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isSolid
                  ? theme.colorScheme.surfaceContainerHighest
                  : StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: false),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: primary.withValues(alpha: 0.35),
                width: 1.0,
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
                    color: theme.colorScheme.onSurface,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── PINNED TOP INSTANT SETTINGS SEARCH BAR ─────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: _buildSearchBar(context, theme, primary, isSolid),
          ),

          // ─── SCROLLABLE SETTINGS CONTENT & HERO ─────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 120), // Extra bottom padding for floating dock & miniplayer
              children: [
                // ─── 0. CLOUD ACCOUNT & PROFILE CARD ────────────────────────
                if (_searchQuery.isEmpty) ...[
                  const SettingsAccountCard(),
                  const SizedBox(height: 16),
                ],

                if (_searchQuery.isNotEmpty)
                  ..._buildSearchResults(context, theme, isSolid)
                else ...[
            // ─── 1. SECTION 1: AESTHETICS & ATMOSPHERE ──────────────────────
            _buildSectionHeader(
              context,
              title: 'AESTHETICS & DISPLAY',
              icon: HugeIcons.strokeRoundedLayers01,
              color: primary,
            ),
            const SizedBox(height: 10),

          _buildCategoryCard(
            context,
            icon: HugeIcons.strokeRoundedColorPicker,
            accentColor: primary,
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
            accentColor: primary,
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
            accentColor: primary,
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

          // ─── 2. SECTION 2: AUDIO ARCHITECTURE & HARDWARE ─────────────────
          _buildSectionHeader(
            context,
            title: 'AUDIO ARCHITECTURE & ENGINE',
            icon: HugeIcons.strokeRoundedCpu,
            color: primary,
          ),
          const SizedBox(height: 10),

          _buildCategoryCard(
            context,
            icon: HugeIcons.strokeRoundedCpu,
            accentColor: primary,
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
            accentColor: primary,
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

          // ─── 3. SECTION 3: MEDIA, STORAGE & ARCHIVE ──────────────────────
          _buildSectionHeader(
            context,
            title: 'MEDIA, STORAGE & VAULT',
            icon: HugeIcons.strokeRoundedFolder01,
            color: primary,
          ),
          const SizedBox(height: 10),

          _buildCategoryCard(
            context,
            icon: HugeIcons.strokeRoundedFolder01,
            accentColor: primary,
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
            accentColor: primary,
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
          const SizedBox(height: 10),

          _buildCategoryCard(
            context,
            icon: HugeIcons.strokeRoundedSettings01,
            accentColor: primary,
            title: 'GESTURES, HOTKEYS & CONTROLS',
            subtitle: 'MiniPlayer swipe gestures, track tile actions, double-tap seek intervals & keyboard shortcuts',
            badgeText: 'Custom Interaction Matrix',
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
            icon: HugeIcons.strokeRoundedCloudCheck,
            accentColor: primary,
            title: 'CLOUD VAULT & BACKUP',
            subtitle: 'Export/import library playlists, equalizer curves, hardware DAC profiles & backup archives',
            badgeText: 'Encrypted JSON Vault',
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
        ],
      ),
    ),
    ],
    ),
    );
  }

  Widget _buildSearchBar(BuildContext context, ThemeData theme, Color primary, bool isSolid) {
    return Container(
      key: const ValueKey('settings_search_bar_container'),
      decoration: BoxDecoration(
        color: isSolid
            ? theme.colorScheme.surfaceContainerHighest
            : StudioSurfaceTheme.surfaceContainer(context, isSolid: false),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1.0,
        ),
      ),
      child: TextField(
        key: const ValueKey('settings_search_field'),
        controller: _searchController,
        focusNode: _searchFocusNode,
        onChanged: (val) => setState(() => _searchQuery = val.trim()),
        style: TextStyle(
          fontSize: 13.5,
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: 'Search settings, DSP, hardware, theming...',
          hintStyle: TextStyle(
            fontSize: 13,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedSearch01,
              color: primary,
              size: 18,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 42, minHeight: 42),
          suffixIcon: _searchQuery.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: M3EIconButton(
                    variant: M3EIconButtonVariant.standard,
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedCancel01,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      size: 16,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                      _searchFocusNode.requestFocus();
                    },
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  List<Widget> _buildSearchResults(BuildContext context, ThemeData theme, bool isSolid) {
    final query = _searchQuery.toLowerCase();
    final primary = theme.colorScheme.primary;
    final allItems = [
      (
        icon: HugeIcons.strokeRoundedColorPicker,
        accentColor: primary,
        title: 'THEMING & COLOR PALETTES',
        subtitle: '19 Studio Palettes, Light/Dark/System Mode, Pure Solid M3 Surface Fills & Monet Dynamic Art',
        badgeText: 'Studio Wallpapers • Palettes',
        keywords: 'theming palette wallpaper color dynamic monet dark light accent background',
        builder: (BuildContext ctx) => const ThemingSettingsScreen(),
      ),
      (
        icon: HugeIcons.strokeRoundedAudioWaveform,
        accentColor: primary,
        title: 'VISUALIZER & DISPLAY',
        subtitle: 'Turntable Tonearm, Cassette, CD Jewel, Dual VU Meters, Mirror Wave & Precision Studio Ruler',
        badgeText: 'Live RTA • 20 Expressive Styles',
        keywords: 'visualizer rta spectrum cassette vinyl cd meter display ruler waveform beam',
        builder: (BuildContext ctx) => const VisualizerSettingsScreen(),
      ),
      (
        icon: HugeIcons.strokeRoundedCar01,
        accentColor: primary,
        title: 'STUDIO WORKSTATION & CAR DOCK',
        subtitle: 'High-contrast studio timecode clock, dual analog VU level dials & large controls for desk stands',
        badgeText: 'Fullscreen Stand Mode',
        keywords: 'dock workstation desk car stand clock vu meter timecode landscape',
        builder: (BuildContext ctx) => const DockingSettingsScreen(),
      ),
      (
        icon: HugeIcons.strokeRoundedCpu,
        accentColor: primary,
        title: 'AUDIO HARDWARE & DAC ENGINE',
        subtitle: 'SoLoud C++ Engine, Bit-Perfect Direct Stream Bypass, Output Devices & Latency Buffer Tuning',
        badgeText: 'Bit-Perfect PCM Ready',
        keywords: 'hardware dac soloud bit-perfect buffer latency output driver direct autoeq dsp mastering',
        builder: (BuildContext ctx) => const AudioHardwareSettingsScreen(),
      ),
      (
        icon: HugeIcons.strokeRoundedDashboardSpeed01,
        accentColor: primary,
        title: 'ADVANCED PLAYBACK ENGINE & FADES',
        subtitle: 'Smooth volume fades, headphone unplug guard, speed/pitch semitones, ReplayGain & seek stepper',
        badgeText: 'Engine Transitions & Policies',
        keywords: 'playback engine fade replaygain speed pitch semitones volume stepper unplug dsp equalizer',
        builder: (BuildContext ctx) => const PlaybackEngineSettingsScreen(),
      ),
      (
        icon: HugeIcons.strokeRoundedFolder01,
        accentColor: primary,
        title: 'LIBRARY SCANNER & SLEEP TIMER',
        subtitle: 'Automated 15s/30s volume attenuation sleep timer, startup library scan & audio clip filters',
        badgeText: 'Scanner Rules Active',
        keywords: 'library scanner sleep timer duration filter clip startup rescan folder',
        builder: (BuildContext ctx) => const LibraryScannerSettingsScreen(),
      ),
      (
        icon: HugeIcons.strokeRoundedDatabase,
        accentColor: primary,
        title: 'STORAGE & CACHE QUOTA',
        subtitle: 'Disk storage gauge, artwork/lyrics cache cleaner, missing tracks relinker & database vacuum',
        badgeText: 'Cache & Integrity',
        keywords: 'storage cache artwork lyrics clean missing relinker vacuum disk quota',
        builder: (BuildContext ctx) => const StorageCacheSettingsScreen(),
      ),
      (
        icon: HugeIcons.strokeRoundedActivity01,
        accentColor: primary,
        title: 'GESTURES & TRACK TILES',
        subtitle: 'Artwork tap triggers (Lyrics, Fav, Inspector), swipe-to-queue/favorite & track tile layouts',
        badgeText: 'Touch Gestures • Swipe Actions',
        keywords: 'gestures track tile tap swipe queue favorite artwork double single longpress',
        builder: (BuildContext ctx) => const GesturesSettingsScreen(),
      ),
      (
        icon: HugeIcons.strokeRoundedCloudSync,
        accentColor: primary,
        title: 'BACKUP & RESTORE ARCHIVE',
        subtitle: 'Export and import portable .bayhifi JSON snapshots containing playlists, smart rules & presets',
        badgeText: '.bayhifi Snapshot Engine',
        keywords: 'backup restore archive export import snapshot json presets playlists',
        builder: (BuildContext ctx) => const BackupRestoreSettingsScreen(),
      ),
    ];

    final matches = allItems.where((item) {
      final t = item.title.toLowerCase();
      final s = item.subtitle.toLowerCase();
      final k = item.keywords.toLowerCase();
      return t.contains(query) || s.contains(query) || k.contains(query);
    }).toList();

    if (matches.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
          alignment: Alignment.center,
          child: Column(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedSearch01,
                size: 36,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
              ),
              const SizedBox(height: 12),
              Text(
                'No settings found for "$_searchQuery"',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Try searching for "AutoEQ", "DSP", "DAC", "Theming", or "Buffer"',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
        ),
      ];
    }

    return [
      _buildSectionHeader(
        context,
        title: 'MATCHING SETTINGS (${matches.length})',
        icon: HugeIcons.strokeRoundedSearch01,
        color: theme.colorScheme.primary,
      ),
      const SizedBox(height: 10),
      ...matches.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildCategoryCard(
              context,
              icon: item.icon,
              accentColor: theme.colorScheme.primary,
              title: item.title,
              subtitle: item.subtitle,
              badgeText: item.badgeText,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: item.builder),
                );
              },
              isSolid: isSolid,
            ),
          )),
    ];
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
            // Solid Icon Container with high-contrast framing
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSolid
                    ? StudioSurfaceTheme.tintedContainer(
                        context,
                        accentColor,
                        isSolid: true,
                        solidBlendAlpha: 0.22,
                      )
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.40),
                  width: 1.2,
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
                  // Solid Badge Container with high-contrast text
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: isSolid
                          ? theme.colorScheme.surfaceContainerHighest
                          : StudioSurfaceTheme.tintedContainer(
                              context,
                              accentColor,
                              isSolid: false,
                              translucentAlpha: 0.14,
                            ),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.35),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: accentColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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
