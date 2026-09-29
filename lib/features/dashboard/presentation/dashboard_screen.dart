import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/studio_surface_theme.dart';
import 'widgets/engine_telemetry_bento_card.dart';
import 'widgets/listening_statistics_card.dart';
import 'widgets/recent_sessions_bento_carousel.dart';
import 'widgets/studio_hero_showcase_carousel.dart';

class DashboardScreen extends ConsumerWidget {
  final VoidCallback? onNavigateToPlayer;
  final VoidCallback? onNavigateToLibrary;
  final VoidCallback? onNavigateToDsp;

  const DashboardScreen({
    super.key,
    this.onNavigateToPlayer,
    this.onNavigateToLibrary,
    this.onNavigateToDsp,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 160.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── 1. HERO HEADER WITH LIVE BADGE ─────────────────────────────
              _buildHeader(context, ref, primary, theme)
                  .animate()
                  .fadeIn(duration: 300.ms, curve: Curves.easeOut)
                  .slideY(begin: -0.05, end: 0.0, curve: Curves.easeOutCubic),

              const SizedBox(height: 16),

              // ─── 2. BENTO 1: C++ AUDIO ENGINE & HARDWARE TELEMETRY ──────────
              const EngineTelemetryBentoCard()
                  .animate()
                  .fadeIn(delay: 50.ms, duration: 350.ms, curve: Curves.easeOut)
                  .slideY(begin: 0.06, end: 0.0, curve: Curves.easeOutBack),

              const SizedBox(height: 16),

              // ─── 3. STUDIO HERO SHOWCASE CAROUSEL (4 STUDIO SHOWCASE CARDS) ──
              const StudioHeroShowcaseCarousel()
                  .animate()
                  .fadeIn(delay: 100.ms, duration: 350.ms, curve: Curves.easeOut)
                  .slideY(begin: 0.06, end: 0.0, curve: Curves.easeOutBack),

              const SizedBox(height: 16),

              // ─── 4. BENTO 2: AUDIOPHILE LISTENING STATS & HI-RES INSIGHTS ───
              const ListeningStatisticsCard()
                  .animate()
                  .fadeIn(delay: 150.ms, duration: 350.ms, curve: Curves.easeOut)
                  .slideY(begin: 0.06, end: 0.0, curve: Curves.easeOutBack),

              const SizedBox(height: 12),

              // ─── 5. BENTO 3: RECENT LOSSLESS SESSIONS & QUICK RESUME ────────
              RecentSessionsBentoCarousel(
                onNavigateToLibrary: onNavigateToLibrary,
              )
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 350.ms, curve: Curves.easeOut)
                  .slideY(begin: 0.06, end: 0.0, curve: Curves.easeOutBack),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    Color primary,
    ThemeData theme,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  'assets/images/baydev_logo.png',
                  width: 22,
                  height: 22,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'BAYDEV HIFI STUDIO',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),

        // Live Engine Pulse Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
          decoration: BoxDecoration(
            color: StudioSurfaceTheme.tintedContainer(context, primary, isSolid: ref.isSolidStyle),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: ref.isSolidStyle ? theme.colorScheme.outline : primary.withValues(alpha: 0.4),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedCpu,
                size: 13,
                color: primary,
              ),
              const SizedBox(width: 5),
              Text(
                'SoLoud Active',
                style: TextStyle(
                  fontFeatures: AppTypography.audioFigures,
                  color: primary,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
