import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../app/theme/studio_surface_theme.dart';
import '../../../player/presentation/studio_desk_docking_screen.dart';

class DockingSettingsScreen extends ConsumerWidget {
  const DockingSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isSolid = ref.isSolidStyle;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('STUDIO WORKSTATION & CAR DOCK'),
        leading: IconButton(
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            size: 20,
            color: theme.colorScheme.onSurface,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          _buildSectionHeader(context, 'DOCKING MODE OVERVIEW', HugeIcons.strokeRoundedCar01),
          const SizedBox(height: 8),
          _buildDeskDockingCard(context, isSolid),
          const SizedBox(height: 20),

          _buildSectionHeader(context, 'DISPLAY BEHAVIOR & FEATURES', HugeIcons.strokeRoundedTv01),
          const SizedBox(height: 8),
          _buildFeaturesCard(context, isSolid),
        ],
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
        radius: 12,
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
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFF9F0A).withValues(alpha: 0.4)),
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
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'High-contrast glanceable studio clock, dual analog VU level meters & extra-large buttons.',
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
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedMaximize01,
                size: 18,
                color: Colors.black,
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
        radius: 12,
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
        HugeIcon(icon: icon, size: 18, color: primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
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
