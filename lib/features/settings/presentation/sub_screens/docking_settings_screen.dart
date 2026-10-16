import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import '../../../../app/theme/app_haptics.dart';
import '../../../../app/theme/studio_surface_theme.dart';
import '../../../../core/database/local_persistence_service.dart';
import '../../../../core/desktop/desktop_window_service.dart';
import '../../../player/presentation/studio_desk_docking_screen.dart';

class DockingSettingsScreen extends ConsumerStatefulWidget {
  const DockingSettingsScreen({super.key});

  @override
  ConsumerState<DockingSettingsScreen> createState() => _DockingSettingsScreenState();
}

class _DockingSettingsScreenState extends ConsumerState<DockingSettingsScreen> {
  bool _closeToTray = true;
  bool _trayTooltip = true;

  @override
  void initState() {
    super.initState();
    final storage = LocalPersistenceService.instance;
    _closeToTray = storage.getSetting<bool>('desktop_close_to_tray', true) ?? true;
    _trayTooltip = storage.getSetting<bool>('desktop_tray_tooltip_enabled', true) ?? true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isSolid = ref.isSolidStyle;
    final storage = LocalPersistenceService.instance;
    final isDesktop = !kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('STUDIO WORKSTATION & DOCKING'),
        leading: M3EIconButton(
          variant: M3EIconButtonVariant.standard,
          icon: Icon(
            LucideIcons.arrowLeft,
            size: 22,
            color: theme.colorScheme.onSurface,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          // ─── 1. STATUS HERO BANNER ──────────────────────────────────────────
          _buildStatusHero(context, theme, primary, isSolid, isDesktop),
          const SizedBox(height: 18),

          // ─── 2. DESKTOP SYSTEM TRAY INTEGRATION (DESKTOP ONLY) ───────────────
          if (isDesktop) ...[
            _buildSectionHeader(
              context,
              'DESKTOP & SYSTEM TRAY INTEGRATION',
              LucideIcons.slidersHorizontal,
            ),
            const SizedBox(height: 8),
            _buildDesktopTrayCard(context, theme, primary, storage, isSolid),
            const SizedBox(height: 20),
          ],

          // ─── 3. DOCKING MODE OVERVIEW ───────────────────────────────────────
          _buildSectionHeader(context, 'DOCKING MODE LAUNCHER', LucideIcons.car),
          const SizedBox(height: 8),
          _buildDeskDockingCard(context, isSolid, isDesktop),
          const SizedBox(height: 20),

          // ─── 4. DISPLAY BEHAVIOR & FEATURES ─────────────────────────────────
          _buildSectionHeader(context, 'DISPLAY BEHAVIOR & FEATURES', LucideIcons.tv),
          const SizedBox(height: 8),
          _buildFeaturesCard(context, isSolid),
        ],
      ),
    );
  }

  Widget _buildStatusHero(
    BuildContext context,
    ThemeData theme,
    Color primary,
    bool isSolid,
    bool isDesktop,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: StudioSurfaceTheme.cardDecoration(
        context: context,
        isSolid: isSolid,
        radius: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: StudioSurfaceTheme.tintedContainer(
                    context,
                    primary,
                    isSolid: isSolid,
                    translucentAlpha: 0.12,
                    solidBlendAlpha: 0.16,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  LucideIcons.monitor,
                  size: 18,
                  color: primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STUDIO WORKSTATION & DOCK',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      isDesktop
                          ? 'Linux tray quick menu, close-to-tray background playback & desk stand'
                          : 'High-contrast telemetry, analog VU needles & distraction-free car mode',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (isDesktop)
                _buildStatusPill(
                  context,
                  theme,
                  label: 'System Tray: Active',
                  isActive: true,
                  color: primary,
                  isSolid: isSolid,
                ),
              _buildStatusPill(
                context,
                theme,
                label: 'Dual VU Ballistics: Active',
                isActive: true,
                color: theme.colorScheme.secondary,
                isSolid: isSolid,
              ),
              _buildStatusPill(
                context,
                theme,
                label: 'Studio Clock: Real-Time',
                isActive: true,
                color: theme.colorScheme.tertiary,
                isSolid: isSolid,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(
    BuildContext context,
    ThemeData theme, {
    required String label,
    required bool isActive,
    required Color color,
    required bool isSolid,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
      decoration: BoxDecoration(
        color: isSolid
            ? (isActive
                ? color.withValues(alpha: 0.16)
                : theme.colorScheme.surfaceContainerHighest)
            : (isActive
                ? color.withValues(alpha: 0.14)
                : theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isActive ? color : theme.colorScheme.onSurface.withValues(alpha: 0.65),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 15, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
            fontSize: 11.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopTrayCard(
    BuildContext context,
    ThemeData theme,
    Color primary,
    LocalPersistenceService storage,
    bool isSolid,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: StudioSurfaceTheme.cardDecoration(
        context: context,
        isSolid: isSolid,
        radius: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Linux & Desktop Tray Quick Controls',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: StudioSurfaceTheme.tintedContainer(
                    context,
                    primary,
                    isSolid: isSolid,
                    translucentAlpha: 0.15,
                    solidBlendAlpha: 0.20,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'TRAY DAEMON: ONLINE',
                  style: TextStyle(
                    color: primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 9.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Control playback, AutoEQ status, mute, and DSP routing directly from the system tray quick menu.',
            style: TextStyle(
              fontSize: 10.5,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // Switch 1: Close to tray
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Minimize to Tray on Close',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Keep music playing seamlessly in background when window is closed',
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              M3ESwitch(
                value: _closeToTray,
                onChanged: (val) {
                  AppHaptics.lightImpact();
                  setState(() => _closeToTray = val);
                  storage.saveSetting('desktop_close_to_tray', val);
                },
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // Switch 2: Tray Tooltip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'System Tray Track Telemetry Tooltip',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Show track title, artist, and bitrate codec on hover',
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              M3ESwitch(
                value: _trayTooltip,
                onChanged: (val) {
                  AppHaptics.lightImpact();
                  setState(() => _trayTooltip = val);
                  storage.saveSetting('desktop_tray_tooltip_enabled', val);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeskDockingCard(BuildContext context, bool isSolid, bool isDesktop) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: StudioSurfaceTheme.cardDecoration(
        context: context,
        isSolid: isSolid,
        radius: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: StudioSurfaceTheme.tintedContainer(
                    context,
                    const Color(0xFFFF9F0A),
                    isSolid: isSolid,
                    translucentAlpha: 0.15,
                    solidBlendAlpha: 0.20,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  LucideIcons.car,
                  size: 22,
                  color: Color(0xFFFF9F0A),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Desk & Vehicle Stand Mode',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Glanceable studio clock, dual analog VU level meters & extra-large tap targets.',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                if (isDesktop) {
                  DesktopWindowService.instance.toggleFullScreen();
                }
                StudioDeskDockingScreen.show(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              icon: Icon(
                LucideIcons.maximize2,
                size: 18,
                color: theme.colorScheme.onPrimary,
              ),
              label: const Text(
                'LAUNCH STUDIO DOCKING MODE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesCard(BuildContext context, bool isSolid) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: StudioSurfaceTheme.cardDecoration(
        context: context,
        isSolid: isSolid,
        radius: 16,
      ),
      child: Column(
        children: [
          _buildFeatureRow(
            context,
            icon: LucideIcons.clock,
            title: 'High-Contrast Studio Clock',
            subtitle: 'Large digital clock with seconds precision for studio desks and vehicle docks.',
          ),
          const Divider(height: 20),
          _buildFeatureRow(
            context,
            icon: LucideIcons.audioLines,
            title: 'Dual Analog VU Meters',
            subtitle: 'Real-time ballistic needle response for Left & Right audio channels.',
          ),
          const Divider(height: 20),
          _buildFeatureRow(
            context,
            icon: LucideIcons.playCircle,
            title: 'Extra-Large Touch Targets',
            subtitle: 'Oversized playback controls optimized for quick tap interactions.',
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: StudioSurfaceTheme.tintedContainer(
              context,
              primary,
              isSolid: false,
              translucentAlpha: 0.10,
              solidBlendAlpha: 0.12,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10.5,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


