import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import '../../../../app/theme/app_haptics.dart';
import '../../../../app/theme/studio_surface_theme.dart';
import '../../../../core/widgets/studio_artwork_widget.dart';
import '../../../player/domain/track.dart';
import '../../../player/presentation/controllers/player_controller.dart';
import '../../data/playback_analytics_service.dart';
import '../../domain/audiophile_persona.dart';
import '../../domain/studio_wrapped_data.dart';
import '../story/studio_wrapped_story_screen.dart';
import '../templates/studio_wrapped_export_hub.dart';

/// Comprehensive Studio Listening Insights & Playback Telemetry Screen
/// Displays deep audiophile analytics: Top Tracks (#01-#10), Top Artists, Top Albums,
/// Audiophile Persona Radar, Signal Chain Purity, Hardware DAC & DSP Tuning Telemetry.
class StudioListeningStatsDetailScreen extends ConsumerWidget {
  const StudioListeningStatsDetailScreen({super.key});

  String _formatMinutes(int minutes) {
    if (minutes <= 0) return '0 min';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) {
      return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
    }
    return '${mins}m';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isSolid = ref.isSolidStyle;
    final activeFilter = ref.watch(studioWrappedFilterProvider);
    final data = ref.watch(studioWrappedDataProvider);
    final persona = data.persona;
    final purity = data.purityReport;

    final primary = theme.colorScheme.primary;
    final secondary = theme.colorScheme.secondary;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ─── 1. STUDIO APP BAR ──────────────────────────────────────────
            SliverAppBar(
              pinned: true,
              elevation: 0,
              backgroundColor: theme.colorScheme.surface,
              surfaceTintColor: Colors.transparent,
              leading: IconButton(
                onPressed: () {
                  AppHaptics.lightImpact();
                  Navigator.of(context).pop();
                },
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowLeft01,
                  size: 20,
                  color: theme.colorScheme.onSurface,
                ),
                tooltip: 'Back to Dashboard',
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Listening Insights',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    'Deep playback telemetry & signal metrics',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  onPressed: () {
                    AppHaptics.selectionClick();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const StudioWrappedStoryScreen()),
                    );
                  },
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedSparkles,
                    size: 20,
                    color: primary,
                  ),
                  tooltip: 'Story Recap',
                ),
                IconButton(
                  onPressed: () {
                    AppHaptics.selectionClick();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => StudioWrappedExportHub()),
                    );
                  },
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedShare01,
                    size: 20,
                    color: secondary,
                  ),
                  tooltip: 'Export Cards',
                ),
                const SizedBox(width: 4),
              ],
            ),

            // ─── 2. MAIN SCROLLABLE CONTENT ──────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ─── TIME RANGE SWITCHER ─────────────────────────────────
                    _buildTimeFilterSwitcher(context, ref, activeFilter, isSolid),
                    const SizedBox(height: 16),

                    // ─── PERSONA HERO SHOWCASE ───────────────────────────────
                    _buildPersonaHeroCard(context, data, persona, isSolid),
                    const SizedBox(height: 16),

                    // ─── CORE TELEMETRY 4-GRID ───────────────────────────────
                    _buildCoreTelemetryGrid(context, data, isSolid),
                    const SizedBox(height: 20),

                    // ─── TOP 10 TRACKS SPOTLIGHT ─────────────────────────────
                    _buildTopTracksSection(context, ref, data, isSolid),
                    const SizedBox(height: 24),

                    // ─── TOP ARTISTS HALL OF FAME ────────────────────────────
                    _buildTopArtistsSection(context, data, isSolid),
                    const SizedBox(height: 24),

                    // ─── TOP ALBUMS HALL OF FAME ─────────────────────────────
                    _buildTopAlbumsSection(context, data, isSolid),
                    const SizedBox(height: 24),

                    // ─── GENRE SPECTRUM & ACOUSTIC ENERGY ────────────────────
                    _buildGenreSpectrumSection(context, data, isSolid),
                    const SizedBox(height: 24),

                    // ─── AUDIO PURITY & SIGNAL CHAIN ─────────────────────────
                    _buildAudioPuritySection(context, purity, isSolid),
                    const SizedBox(height: 24),

                    // ─── HARDWARE DAC & DSP TUNING ───────────────────────────
                    _buildHardwareAndDspSection(context, data, isSolid),
                    const SizedBox(height: 28),

                    // ─── BOTTOM ACTION LAUNCHERS ─────────────────────────────
                    _buildBottomActionLaunchers(context, isSolid),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 1. TIME FILTER SWITCHER
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildTimeFilterSwitcher(
    BuildContext context,
    WidgetRef ref,
    RecapTimeFilter activeFilter,
    bool isSolid,
  ) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: StudioSurfaceTheme.surfaceContainer(context, isSolid: isSolid),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: RecapTimeFilter.values.map((filter) {
          final isSelected = filter == activeFilter;
          return Expanded(
            child: InkWell(
              onTap: () {
                AppHaptics.selectionClick();
                ref.read(studioWrappedFilterProvider.notifier).state = filter;
              },
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? StudioSurfaceTheme.tintedContainer(context, primary, isSolid: isSolid)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    filter.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? primary : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 2. PERSONA HERO SHOWCASE CARD
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildPersonaHeroCard(
    BuildContext context,
    StudioWrappedData data,
    AudiophilePersona persona,
    bool isSolid,
  ) {
    final theme = Theme.of(context);
    final accentColor = persona.primaryColor;
    final profile = data.resonanceProfile;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: StudioSurfaceTheme.surfaceContainer(context, isSolid: isSolid),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Persona Badge & Tag
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: StudioSurfaceTheme.tintedContainer(context, accentColor, isSolid: isSolid),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedAward01,
                      size: 13,
                      color: accentColor,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'AUDIOPHILE ARCHETYPE',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'ENERGY SCORE ${profile.energyScore}/100',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Persona Name & Subtitle
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      persona.title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.onSurface,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      persona.subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      persona.description,
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.4,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              // Radar Visualizer
              SizedBox(
                width: 100,
                height: 100,
                child: CustomPaint(
                  painter: _StudioRadarPainter(
                    color: accentColor,
                    gridColor: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                    values: [
                      (data.purityReport.flacPercentage / 100.0).clamp(0.2, 1.0),
                      (data.dspHours > 0 ? (data.dspHours / 100.0) : 0.4).clamp(0.2, 1.0),
                      (data.autoEqHours > 0 ? (data.autoEqHours / 80.0) : 0.5).clamp(0.2, 1.0),
                      (profile.dynamicRangeDb / 20.0).clamp(0.2, 1.0),
                      (profile.energyScore / 100.0).clamp(0.2, 1.0),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Acoustic Attributes Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildAttributeCell(
                    context: context,
                    label: 'TIMBRAL TONE',
                    value: profile.timbralSignature,
                    icon: HugeIcons.strokeRoundedAudioWaveform,
                    color: accentColor,
                  ),
                ),
                Container(
                  width: 1,
                  height: 28,
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
                Expanded(
                  child: _buildAttributeCell(
                    context: context,
                    label: 'PEAK WINDOW',
                    value: profile.peakTimeWindow,
                    icon: HugeIcons.strokeRoundedClock01,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttributeCell({
    required BuildContext context,
    required String label,
    required String value,
    required dynamic icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HugeIcon(icon: icon, size: 11, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 3. CORE TELEMETRY 4-GRID
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildCoreTelemetryGrid(BuildContext context, StudioWrappedData data, bool isSolid) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTelemetryTile(
                context: context,
                isSolid: isSolid,
                icon: HugeIcons.strokeRoundedClock01,
                label: 'TOTAL TIME',
                value: _formatMinutes(data.totalMinutes),
                accentColor: StudioCategoryColors.statistics,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildTelemetryTile(
                context: context,
                isSolid: isSolid,
                icon: HugeIcons.strokeRoundedMusicNote01,
                label: 'TRACKS PLAYED',
                value: '${data.totalTracksPlayed}',
                accentColor: StudioCategoryColors.themingPalettes,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildTelemetryTile(
                context: context,
                isSolid: isSolid,
                icon: HugeIcons.strokeRoundedUserSquare,
                label: 'UNIQUE ARTISTS',
                value: '${data.uniqueArtistsCount}',
                accentColor: StudioCategoryColors.hiResGold,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildTelemetryTile(
                context: context,
                isSolid: isSolid,
                icon: HugeIcons.strokeRoundedAlbum02,
                label: 'UNIQUE ALBUMS',
                value: '${data.uniqueAlbumsCount}',
                accentColor: StudioCategoryColors.proQEqualizer,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTelemetryTile({
    required BuildContext context,
    required bool isSolid,
    required dynamic icon,
    required String label,
    required String value,
    required Color accentColor,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: StudioSurfaceTheme.surfaceContainer(context, isSolid: isSolid),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HugeIcon(icon: icon, size: 14, color: accentColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.onSurface,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 4. TOP 10 TRACKS SPOTLIGHT
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildTopTracksSection(
    BuildContext context,
    WidgetRef ref,
    StudioWrappedData data,
    bool isSolid,
  ) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final topTracks = data.topTracks;

    if (topTracks.isEmpty) {
      return const SizedBox.shrink();
    }

    final champion = topTracks.first;
    final others = topTracks.skip(1).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context: context,
          icon: HugeIcons.strokeRoundedMusicNote03,
          title: 'TOP 10 TRACKS',
          badge: '${topTracks.length} TRACKS RECORDED',
          badgeColor: primary,
        ),
        const SizedBox(height: 12),

        // #01 CHAMPION HERO CARD
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: StudioSurfaceTheme.surfaceContainer(context, isSolid: isSolid),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: StudioCategoryColors.hiResGold.withValues(alpha: 0.4), width: 1.2),
          ),
          child: Row(
            children: [
              // Artwork with Crown/Badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  StudioArtworkWidget(
                    url: champion.albumArtUri,
                    width: 64,
                    height: 64,
                    borderRadius: BorderRadius.circular(12),
                    fallbackIcon: HugeIcons.strokeRoundedMusicNote01,
                    fallbackIconSize: 24,
                  ),
                  Positioned(
                    top: -6,
                    left: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: StudioCategoryColors.hiResGold,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Text(
                        '#01',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              // Track Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      champion.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${champion.artist} • ${champion.album}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: StudioSurfaceTheme.tintedContainer(context, primary, isSolid: isSolid),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            champion.formatBadge,
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              color: primary,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${champion.playCount} plays • ${_formatMinutes(champion.totalMinutes)}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Instant Play Button
              InkWell(
                onTap: () {
                  AppHaptics.selectionClick();
                  final track = Track(
                    id: champion.trackId.isNotEmpty ? champion.trackId : 'rec_1',
                    title: champion.title,
                    artist: champion.artist,
                    album: champion.album,
                    duration: Duration(minutes: champion.totalMinutes),
                    albumArtUrl: champion.albumArtUri,
                    format: AudioFormat.flac,
                    sampleRate: champion.sampleRate,
                    bitDepth: champion.bitDepth,
                  );
                  ref.read(playerControllerProvider.notifier).playTrack(track);
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: StudioSurfaceTheme.tintedContainer(context, primary, isSolid: isSolid),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedPlay,
                      size: 16,
                      color: primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // #02 - #10 LIST TILES
        if (others.isNotEmpty) ...[
          const SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: others.length,
            separatorBuilder: (_, _) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final track = others[index];
              final rank = track.rank;
              final rankColor = rank <= 3
                  ? (rank == 2 ? theme.colorScheme.secondary : theme.colorScheme.tertiary)
                  : theme.colorScheme.onSurfaceVariant;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: StudioSurfaceTheme.surfaceContainer(context, isSolid: isSolid),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    // Rank badge
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: StudioSurfaceTheme.tintedContainer(context, rankColor, isSolid: isSolid),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          '#$rank',
                          style: TextStyle(
                            color: rankColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Artwork
                    StudioArtworkWidget(
                      url: track.albumArtUri,
                      width: 38,
                      height: 38,
                      borderRadius: BorderRadius.circular(8),
                      fallbackIcon: HugeIcons.strokeRoundedMusicNote01,
                      fallbackIconSize: 16,
                    ),
                    const SizedBox(width: 10),
                    // Track Title & Artist
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            track.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            '${track.artist} • ${track.format.toUpperCase()}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Play Stats
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${track.playCount} plays',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        Text(
                          _formatMinutes(track.totalMinutes),
                          style: TextStyle(
                            fontSize: 9.5,
                            color: theme.colorScheme.onSurfaceVariant,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 5. TOP ARTISTS HALL OF FAME
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildTopArtistsSection(BuildContext context, StudioWrappedData data, bool isSolid) {
    final theme = Theme.of(context);
    final secondary = theme.colorScheme.secondary;
    final topArtists = data.topArtists;

    if (topArtists.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context: context,
          icon: HugeIcons.strokeRoundedUserSquare,
          title: 'TOP ARTISTS',
          badge: '${data.uniqueArtistsCount} TOTAL EXPLORED',
          badgeColor: secondary,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 132,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: topArtists.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final artist = topArtists[index];
              return Container(
                width: 110,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: StudioSurfaceTheme.surfaceContainer(context, isSolid: isSolid),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: index == 0
                        ? secondary.withValues(alpha: 0.4)
                        : theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        StudioArtworkWidget(
                          url: artist.artworkUrl,
                          width: 46,
                          height: 46,
                          borderRadius: BorderRadius.circular(23),
                          fallbackIcon: HugeIcons.strokeRoundedMic01,
                          fallbackIconSize: 20,
                        ),
                        Positioned(
                          top: -4,
                          right: -4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: index == 0 ? secondary : theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '#${artist.rank}',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                color: index == 0 ? theme.colorScheme.onSecondary : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      artist.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${artist.percentage.toStringAsFixed(0)}% • ${_formatMinutes(artist.totalMinutes)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 6. TOP ALBUMS HALL OF FAME
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildTopAlbumsSection(BuildContext context, StudioWrappedData data, bool isSolid) {
    final theme = Theme.of(context);
    final tertiary = theme.colorScheme.tertiary;
    final topAlbums = data.topAlbums;

    if (topAlbums.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context: context,
          icon: HugeIcons.strokeRoundedAlbum02,
          title: 'TOP ALBUMS',
          badge: '${data.uniqueAlbumsCount} IN ROTATION',
          badgeColor: tertiary,
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: topAlbums.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final album = topAlbums[index];
            return Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: StudioSurfaceTheme.surfaceContainer(context, isSolid: isSolid),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  StudioArtworkWidget(
                    url: album.artworkUrl,
                    width: 44,
                    height: 44,
                    borderRadius: BorderRadius.circular(8),
                    fallbackIcon: HugeIcons.strokeRoundedAlbum01,
                    fallbackIconSize: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          album.album,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          album.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.5,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: StudioSurfaceTheme.tintedContainer(context, tertiary, isSolid: isSolid),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${album.trackCount} ${album.trackCount == 1 ? "track" : "tracks"}',
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                            color: tertiary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatMinutes(album.totalMinutes),
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 7. GENRE SPECTRUM & ACOUSTIC ENERGY
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildGenreSpectrumSection(BuildContext context, StudioWrappedData data, bool isSolid) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final topGenres = data.topGenres;

    if (topGenres.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context: context,
          icon: HugeIcons.strokeRoundedSlidersVertical,
          title: 'GENRE SPECTRUM',
          badge: '${topGenres.length} SIGNATURE GENRES',
          badgeColor: StudioCategoryColors.proQEqualizer,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: StudioSurfaceTheme.surfaceContainer(context, isSolid: isSolid),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: topGenres.map((genre) {
              final pct = genre.percentage;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          genre.genre,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          '${pct.toStringAsFixed(1)}% (${genre.playCount} plays)',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: M3EProgressIndicator.linear(
                        value: (pct / 100.0).clamp(0.05, 1.0),
                        trackColor: theme.colorScheme.surfaceContainerHighest,
                        color: primary,
                        strokeWidth: 5,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 8. AUDIO PURITY & SIGNAL CHAIN
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildAudioPuritySection(BuildContext context, AudioPurityReport purity, bool isSolid) {
    final theme = Theme.of(context);
    final gold = StudioCategoryColors.hiResGold;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context: context,
          icon: HugeIcons.strokeRoundedShieldEnergy,
          title: 'SIGNAL CHAIN PURITY',
          badge: purity.purityBadge,
          badgeColor: gold,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: StudioSurfaceTheme.surfaceContainer(context, isSolid: isSolid),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: gold.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              // 3 Ratio Columns
              Row(
                children: [
                  Expanded(
                    child: _buildPurityMetric(
                      context: context,
                      label: 'LOSSLESS FLAC',
                      percentage: purity.flacPercentage,
                      count: purity.flacCount,
                      color: gold,
                    ),
                  ),
                  Expanded(
                    child: _buildPurityMetric(
                      context: context,
                      label: 'HI-RES MASTER',
                      percentage: purity.hiResPercentage,
                      count: purity.hiResCount,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Expanded(
                    child: _buildPurityMetric(
                      context: context,
                      label: 'LOSSY / STREAM',
                      percentage: purity.totalTracks > 0
                          ? ((purity.lossyCount / purity.totalTracks) * 100)
                          : 0.0,
                      count: purity.lossyCount,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Segmented Signal Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Row(
                  children: [
                    if (purity.hiResPercentage > 0)
                      Expanded(
                        flex: (purity.hiResPercentage * 10).round().clamp(1, 1000),
                        child: Container(height: 6, color: theme.colorScheme.primary),
                      ),
                    if (purity.flacPercentage - purity.hiResPercentage > 0)
                      Expanded(
                        flex: ((purity.flacPercentage - purity.hiResPercentage) * 10).round().clamp(1, 1000),
                        child: Container(height: 6, color: gold),
                      ),
                    if (100.0 - purity.flacPercentage > 0)
                      Expanded(
                        flex: ((100.0 - purity.flacPercentage) * 10).round().clamp(1, 1000),
                        child: Container(height: 6, color: theme.colorScheme.surfaceContainerHighest),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Purity Key Specs
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Bit-Perfect Studio Time: ${purity.bitPerfectHours}h',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: gold,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    'Peak Sample Rate: ${purity.highestSampleRate}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPurityMetric({
    required BuildContext context,
    required String label,
    required double percentage,
    required int count,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 8.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${percentage.toStringAsFixed(1)}%',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        Text(
          '$count tracks',
          style: TextStyle(
            fontSize: 9.5,
            color: theme.colorScheme.onSurfaceVariant,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 9. HARDWARE DAC & DSP TUNING
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildHardwareAndDspSection(BuildContext context, StudioWrappedData data, bool isSolid) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context: context,
          icon: HugeIcons.strokeRoundedCpu,
          title: 'HARDWARE & DSP TELEMETRY',
          badge: 'STUDIO CHAIN ACTIVE',
          badgeColor: primary,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: StudioSurfaceTheme.surfaceContainer(context, isSolid: isSolid),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: [
              _buildHardwareRow(
                context: context,
                icon: HugeIcons.strokeRoundedHeadphones,
                title: 'AutoEQ Tuning Target',
                subtitle: '${data.favoriteHeadphoneProfile} • ${data.topAutoEqTarget}',
                trailing: '${data.autoEqHours}h active',
                accentColor: primary,
              ),
              const Divider(height: 18),
              _buildHardwareRow(
                context: context,
                icon: HugeIcons.strokeRoundedRadio,
                title: 'DSP Saturation Engine',
                subtitle: data.favoriteDspModule,
                trailing: '${data.dspHours}h tuned',
                accentColor: theme.colorScheme.secondary,
              ),
              const Divider(height: 18),
              _buildHardwareRow(
                context: context,
                icon: HugeIcons.strokeRoundedUsb,
                title: 'Hardware DAC Bridge',
                subtitle: data.favoriteDacDevice,
                trailing: '${data.totalDacBridgeHours}h bridged',
                accentColor: StudioCategoryColors.hiResGold,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHardwareRow({
    required BuildContext context,
    required dynamic icon,
    required String title,
    required String subtitle,
    required String trailing,
    required Color accentColor,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        HugeIcon(icon: icon, size: 18, color: accentColor),
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
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          trailing,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: accentColor,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 10. BOTTOM ACTION LAUNCHERS
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildBottomActionLaunchers(BuildContext context, bool isSolid) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () {
              AppHaptics.mediumImpact();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StudioWrappedStoryScreen()),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: StudioSurfaceTheme.tintedContainer(context, primary, isSolid: isSolid),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primary.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  HugeIcon(icon: HugeIcons.strokeRoundedSparkles, size: 16, color: primary),
                  const SizedBox(width: 8),
                  Text(
                    'Interactive Story',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: InkWell(
            onTap: () {
              AppHaptics.mediumImpact();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => StudioWrappedExportHub()),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.secondary.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedShare01,
                    size: 16,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Export Hub',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // HELPER: SECTION HEADER
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildSectionHeader({
    required BuildContext context,
    required dynamic icon,
    required String title,
    required String badge,
    required Color badgeColor,
  }) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            HugeIcon(icon: icon, size: 16, color: badgeColor),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            badge,
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: badgeColor,
            ),
          ),
        ),
      ],
    );
  }
}

/// Dynamic pentagon radar painter for audiophile archetype acoustic profile
class _StudioRadarPainter extends CustomPainter {
  final Color color;
  final Color gridColor;
  final List<double> values;

  _StudioRadarPainter({
    required this.color,
    required this.gridColor,
    required this.values,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 6;

    final gridPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw concentric polygons (3 rings)
    for (int ring = 1; ring <= 3; ring++) {
      final r = radius * (ring / 3.0);
      final ringPath = Path();
      for (int i = 0; i < 5; i++) {
        final angle = -math.pi / 2 + (i * 2 * math.pi / 5);
        final x = center.dx + r * math.cos(angle);
        final y = center.dy + r * math.sin(angle);
        if (i == 0) {
          ringPath.moveTo(x, y);
        } else {
          ringPath.lineTo(x, y);
        }
      }
      ringPath.close();
      canvas.drawPath(ringPath, gridPaint);
    }

    // Draw axes
    for (int i = 0; i < 5; i++) {
      final angle = -math.pi / 2 + (i * 2 * math.pi / 5);
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      canvas.drawLine(center, Offset(x, y), gridPaint);
    }

    // Draw value polygon
    if (values.length >= 5) {
      final fillPath = Path();
      for (int i = 0; i < 5; i++) {
        final val = values[i].clamp(0.1, 1.0);
        final r = radius * val;
        final angle = -math.pi / 2 + (i * 2 * math.pi / 5);
        final x = center.dx + r * math.cos(angle);
        final y = center.dy + r * math.sin(angle);
        if (i == 0) {
          fillPath.moveTo(x, y);
        } else {
          fillPath.lineTo(x, y);
        }
      }
      fillPath.close();

      final fillPaint = Paint()
        ..color = color.withValues(alpha: 0.35)
        ..style = PaintingStyle.fill;
      canvas.drawPath(fillPath, fillPaint);

      final strokePaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawPath(fillPath, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _StudioRadarPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.values != values;
  }
}
