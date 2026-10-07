import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import '../../../../app/theme/studio_surface_theme.dart';
import '../../../player/presentation/studio_desk_docking_screen.dart';

class DockingSettingsScreen extends ConsumerWidget {
  const DockingSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isSolid = ref.isSolidStyle;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('STUDIO WORKSTATION & CAR DOCK'),
        leading: M3EIconButton(
          variant: M3EIconButtonVariant.standard,
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
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
          _buildStatusHero(context, theme, primary, isSolid),
          const SizedBox(height: 18),

          // ─── 2. DOCKING MODE OVERVIEW ───────────────────────────────────────
          _buildSectionHeader(context, 'DOCKING MODE LAUNCHER', HugeIcons.strokeRoundedCar01),
          const SizedBox(height: 8),
          _buildDeskDockingCard(context, isSolid),
          const SizedBox(height: 20),

          // ─── 3. DISPLAY BEHAVIOR & FEATURES ─────────────────────────────────
          _buildSectionHeader(context, 'DISPLAY BEHAVIOR & FEATURES', HugeIcons.strokeRoundedTv01),
          const SizedBox(height: 8),
          _buildFeaturesCard(context, isSolid),
        ],
      ),
    );
  }

  Widget _buildStatusHero(BuildContext context, ThemeData theme, Color primary, bool isSolid) {
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
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedComputer,
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
                      'High-contrast telemetry, analog VU needles & distraction-free car mode',
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
              _buildStatusPill(
                context,
                theme,
                label: 'Landscape & Portrait Adaptive',
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

  Widget _buildSectionHeader(BuildContext context, String title, dynamic icon) {
    final theme = Theme.of(context);
    return Row(
      children: [
        HugeIcon(icon: icon, size: 15, color: theme.colorScheme.primary),
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

  Widget _buildDeskDockingCard(BuildContext context, bool isSolid) {
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
                child: const HugeIcon(
                  icon: HugeIcons.strokeRoundedCar01,
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
              onPressed: () => StudioDeskDockingScreen.show(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedMaximize01,
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
            icon: HugeIcons.strokeRoundedClock01,
            title: 'High-Contrast Studio Clock',
            subtitle: 'Large digital clock with seconds precision for studio desks and vehicle docks.',
          ),
          const Divider(height: 20),
          _buildFeatureRow(
            context,
            icon: HugeIcons.strokeRoundedAudioWaveform,
            title: 'Dual Analog VU Meters',
            subtitle: 'Real-time ballistic needle response for Left & Right audio channels.',
          ),
          const Divider(height: 20),
          _buildFeatureRow(
            context,
            icon: HugeIcons.strokeRoundedPlayCircle,
            title: 'Extra-Large Touch Targets',
            subtitle: 'Oversized playback controls optimized for quick tap interactions.',
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(
    BuildContext context, {
    required dynamic icon,
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
          child: HugeIcon(icon: icon, size: 16, color: primary),
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

