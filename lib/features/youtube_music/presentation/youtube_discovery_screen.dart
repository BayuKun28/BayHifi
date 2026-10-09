import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../../app/theme/app_haptics.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/studio_surface_theme.dart';
import '../../../core/widgets/studio_artwork_widget.dart';
import '../../dsp_rack/presentation/dsp_rack_screen.dart';
import '../../library/presentation/widgets/studio_track_action_sheet.dart';
import '../../player/domain/track.dart';
import '../../player/presentation/controllers/player_controller.dart';
import 'controllers/youtube_music_controller.dart';
import '../../spotify_importer/presentation/widgets/universal_import_dialog.dart';

/// Material 3 Expressive Studio YouTube Music Discovery & Search Screen
/// Provides high-bitrate Opus/AAC streaming directly processed through C++ SoLoud DSP master chain.
class YouTubeDiscoveryScreen extends ConsumerStatefulWidget {
  final bool showAppBar;
  final double? bottomPadding;

  const YouTubeDiscoveryScreen({
    super.key,
    this.showAppBar = true,
    this.bottomPadding,
  });

  @override
  ConsumerState<YouTubeDiscoveryScreen> createState() =>
      _YouTubeDiscoveryScreenState();
}

class _YouTubeDiscoveryScreenState extends ConsumerState<YouTubeDiscoveryScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  String _selectedFilter = 'All';

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  static final List<({String label, dynamic icon})> _quickFilters = [
    (label: 'All', icon: HugeIcons.strokeRoundedSparkles),
    (label: 'Top 100 Charts', icon: HugeIcons.strokeRoundedChartHistogram),
    (label: 'Audiophile Masters', icon: HugeIcons.strokeRoundedDisc),
    (label: 'Acoustic Live', icon: HugeIcons.strokeRoundedMic01),
    (label: 'Hi-Res Mixes', icon: HugeIcons.strokeRoundedSlidersVertical),
    (label: 'Lofi & Chill', icon: HugeIcons.strokeRoundedCoffee01),
    (label: 'Bass & EDM', icon: HugeIcons.strokeRoundedVolumeHigh),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onFilterSelected(String filter) {
    AppHaptics.selectionClick();
    setState(() {
      _selectedFilter = filter;
    });

    if (filter == 'All') {
      _searchController.clear();
      ref.read(youtubeMusicControllerProvider.notifier).onQueryChanged('');
    } else {
      _searchController.text = filter;
      ref.read(youtubeMusicControllerProvider.notifier).onQueryChanged(filter);
    }
  }

  void _openImportPlaylistDialog() {
    AppHaptics.lightImpact();
    UniversalImportDialog.show(context);
  }

  void _openDspRack() {
    AppHaptics.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DspRackScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isSolid = ref.isSolidStyle;
    final ytState = ref.watch(youtubeMusicControllerProvider);
    final ytController = ref.read(youtubeMusicControllerProvider.notifier);
    final currentPlayingId =
        ref.watch(playerControllerProvider.select((s) => s.currentTrack?.id));

    final isSearching = ytState.isSearching;
    final hasQuery = ytState.query.trim().isNotEmpty;
    final searchResults = ytState.searchResults;
    final trendingTracks = ytState.trendingTracks;
    final effectiveBottomPadding = widget.bottomPadding ?? 96.0;

    final content = Column(
      children: [
        // ─── 1. SEARCH BAR & ACTION ROW ─────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: StudioSurfaceTheme.surfaceContainerLow(context, isSolid: isSolid),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedSearch01,
                        size: 18,
                        color: _searchFocusNode.hasFocus
                            ? primary
                            : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          style: const TextStyle(fontSize: 13.5),
                          decoration: InputDecoration(
                            hintText: 'Search songs, artists, or paste Spotify/YouTube link...',
                            hintStyle: TextStyle(
                              fontSize: 12.5,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (val) {
                            final clean = val.trim();
                            if (clean.contains('spotify.com') || clean.startsWith('spotify:') || clean.contains('youtube.com/playlist')) {
                              UniversalImportDialog.show(context, initialUrl: clean);
                              _searchController.clear();
                              return;
                            }
                            ytController.onQueryChanged(val);
                          },
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        M3EIconButton(
                          variant: M3EIconButtonVariant.standard,
                          icon: HugeIcon(
                            icon: HugeIcons.strokeRoundedCancel01,
                            size: 20,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () {
                            AppHaptics.selectionClick();
                            _searchController.clear();
                            ytController.onQueryChanged('');
                          },
                        ),
                      const SizedBox(width: 4),
                    ],
                  ),
                ),
              ),
              if (!widget.showAppBar) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: _openImportPlaylistDialog,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: StudioSurfaceTheme.tintedContainer(
                        context,
                        StudioCategoryColors.youtubeMusic,
                        isSolid: isSolid,
                        translucentAlpha: 0.16,
                        solidBlendAlpha: 0.2,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedPlayList,
                        size: 20,
                        color: StudioCategoryColors.youtubeMusic,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // ─── 2. HORIZONTAL QUICK FILTER PILLS ──────────────────────────────
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _quickFilters.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (ctx, idx) {
              final filter = _quickFilters[idx];
              final isSelected = _selectedFilter == filter.label;
              final ytColor = StudioCategoryColors.youtubeMusic;
              return ChoiceChip(
                showCheckmark: false,
                avatar: HugeIcon(
                  icon: filter.icon,
                  size: 14,
                  color: isSelected ? ytColor : theme.colorScheme.onSurfaceVariant,
                ),
                label: Text(
                  filter.label,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? ytColor : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                selected: isSelected,
                selectedColor: StudioSurfaceTheme.tintedContainer(
                  context,
                  ytColor,
                  isSolid: isSolid,
                  translucentAlpha: 0.16,
                  solidBlendAlpha: 0.20,
                ),
                backgroundColor: StudioSurfaceTheme.surfaceContainerLow(context, isSolid: isSolid),
                side: BorderSide(
                  color: isSelected
                      ? ytColor.withValues(alpha: 0.6)
                      : StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid),
                  width: 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                onSelected: (_) => _onFilterSelected(filter.label),
              );
            },
          ),
        ),

        const SizedBox(height: 8),

        // ─── 3. CONTENT AREA ────────────────────────────────────────────────
        Expanded(
          child: _buildContent(
            context: context,
            isSearching: isSearching,
            isLoadingTrending: ytState.isLoadingTrending,
            hasQuery: hasQuery,
            searchResults: searchResults,
            trendingTracks: trendingTracks,
            currentPlayingId: currentPlayingId,
            ytController: ytController,
            theme: theme,
            bottomPadding: effectiveBottomPadding,
            isSolid: isSolid,
          ),
        ),
      ],
    );

    if (!widget.showAppBar) {
      return content;
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Navigator.of(context).canPop()
            ? M3EIconButton(
                variant: M3EIconButtonVariant.standard,
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowLeft01,
                  size: 22,
                  color: theme.colorScheme.onSurface,
                ),
                onPressed: () {
                  AppHaptics.selectionClick();
                  Navigator.of(context).pop();
                },
              )
            : Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: StudioCategoryColors.youtubeMusic.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedPlayList,
                    size: 18,
                    color: StudioCategoryColors.youtubeMusic,
                  ),
                ),
              ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'YOUTUBE MUSIC HIFI',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF00E676),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    'OPUS 160KBPS • SOLOUD C++ DSP',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontFeatures: AppTypography.audioFigures,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          M3EIconButton(
            variant: M3EIconButtonVariant.standard,
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedSlidersHorizontal,
              size: 22,
              color: StudioCategoryColors.dspMastering,
            ),
            tooltip: 'Open DSP Mastering Rack',
            onPressed: _openDspRack,
          ),
          M3EIconButton(
            variant: M3EIconButtonVariant.standard,
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedPlayList,
              size: 22,
              color: StudioCategoryColors.youtubeMusic,
            ),
            tooltip: 'Import Playlist URL',
            onPressed: _openImportPlaylistDialog,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: content,
    );
  }

  Widget _buildContent({
    required BuildContext context,
    required bool isSearching,
    required bool isLoadingTrending,
    required bool hasQuery,
    required List<Track> searchResults,
    required List<Track> trendingTracks,
    required String? currentPlayingId,
    required YouTubeMusicController ytController,
    required ThemeData theme,
    required double bottomPadding,
    required bool isSolid,
  }) {
    final primary = theme.colorScheme.primary;

    if (isSearching) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: M3EProgressIndicator.circular(
                strokeWidth: 2.5,
                color: primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Searching YouTube Music HiFi...',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    // ─── SEARCH RESULTS VIEW ────────────────────────────────────────────────
    if (hasQuery) {
      if (searchResults.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedSearch01,
                size: 40,
                color: theme.dividerColor,
              ),
              const SizedBox(height: 12),
              Text(
                'No music results found for "${_searchController.text.trim()}".',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }

      return Column(
        children: [
          // Header Bar with Quick Play All / Shuffle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    '${searchResults.length} RESULTS FOUND',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontFeatures: AppTypography.audioFigures,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () {
                        AppHaptics.selectionClick();
                        ref.read(playerControllerProvider.notifier).setQueue(
                              searchResults,
                              initialIndex: 0,
                            );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: StudioSurfaceTheme.tintedContainer(context, primary, isSolid: isSolid, translucentAlpha: 0.12, solidBlendAlpha: 0.16),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            HugeIcon(
                              icon: HugeIcons.strokeRoundedPlay,
                              size: 12,
                              color: primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Play All',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        AppHaptics.selectionClick();
                        final shuffled = List<Track>.from(searchResults)..shuffle();
                        ref.read(playerControllerProvider.notifier).setQueue(
                              shuffled,
                              initialIndex: 0,
                            );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: StudioSurfaceTheme.surfaceContainerLow(context, isSolid: isSolid),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            HugeIcon(
                              icon: HugeIcons.strokeRoundedShuffle,
                              size: 12,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Shuffle',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.fromLTRB(16, 4, 16, bottomPadding),
              itemCount: searchResults.length,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              itemBuilder: (ctx, index) {
                final track = searchResults[index];
                final isPlaying = currentPlayingId == track.id;
                return _buildYouTubeTrackTile(
                  context: context,
                  track: track,
                  isPlaying: isPlaying,
                  onTap: () {
                    AppHaptics.selectionClick();
                    _searchFocusNode.unfocus();
                    ref.read(playerControllerProvider.notifier).setQueue(
                          searchResults,
                          initialIndex: index,
                        );
                  },
                  onStartRadio: () => ytController.startRadio(track),
                  theme: theme,
                  isSolid: isSolid,
                );
              },
            ),
          ),
        ],
      );
    }

    // ─── DISCOVERY HOME VIEW (BENTO OVERVIEW + TRENDING CHARTS) ──────────────
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 6, 16, bottomPadding),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        // ─── BENTO HERO OVERVIEW ─────────────────────────────────────────────
        InkWell(
          onTap: _openDspRack,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: StudioSurfaceTheme.cardDecoration(
              context: context,
              isSolid: isSolid,
              radius: 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: StudioSurfaceTheme.tintedContainer(context, primary, isSolid: isSolid, translucentAlpha: 0.12, solidBlendAlpha: 0.16),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedAudioWave01,
                          size: 20,
                          color: primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Flexible(
                                child: Text(
                                  'C++ SOLOUD AUDIO PIPELINE',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.6,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00E676).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'ACTIVE',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF00E676),
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'All YouTube streams route through mastering DSP chain',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildBentoFeatureTag(
                      context,
                      HugeIcons.strokeRoundedSlidersHorizontal,
                      'Pro-Q 10-Band EQ',
                      isSolid,
                    ),
                    _buildBentoFeatureTag(
                      context,
                      HugeIcons.strokeRoundedHeadphones,
                      'AutoEQ IEM Calibration',
                      isSolid,
                    ),
                    _buildBentoFeatureTag(
                      context,
                      HugeIcons.strokeRoundedFlame,
                      'Analog Tube Warmth',
                      isSolid,
                    ),
                    _buildBentoFeatureTag(
                      context,
                      HugeIcons.strokeRoundedShield01,
                      'Inter-Sample Peak Limiter',
                      isSolid,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ─── 2X2 CURATED DISCOVERY BENTO GRID ──────────────────────────────
        Row(
          children: [
            Expanded(
              child: _buildDiscoveryBentoTile(
                context: context,
                theme: theme,
                primary: primary,
                title: 'Global Top 50',
                subtitle: 'Billboard & Global Hits',
                icon: HugeIcons.strokeRoundedChartHistogram,
                badge: 'TRENDING',
                onTap: () => _onFilterSelected('Top 100 Charts'),
                isSolid: isSolid,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildDiscoveryBentoTile(
                context: context,
                theme: theme,
                primary: primary,
                title: 'Audiophile Mix',
                subtitle: 'Studio Master Quality',
                icon: HugeIcons.strokeRoundedDisc,
                badge: 'LOSSLESS',
                onTap: () => _onFilterSelected('Audiophile Masters'),
                isSolid: isSolid,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildDiscoveryBentoTile(
                context: context,
                theme: theme,
                primary: primary,
                title: 'Acoustic Sessions',
                subtitle: 'Unplugged Sessions',
                icon: HugeIcons.strokeRoundedMic01,
                badge: 'STUDIO',
                onTap: () => _onFilterSelected('Acoustic Live'),
                isSolid: isSolid,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildDiscoveryBentoTile(
                context: context,
                theme: theme,
                primary: primary,
                title: 'Import Playlist',
                subtitle: 'Paste YouTube URL',
                icon: HugeIcons.strokeRoundedPlayList,
                badge: 'IMPORT',
                onTap: _openImportPlaylistDialog,
                isSolid: isSolid,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // ─── TRENDING CHARTS HEADER ──────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedChartHistogram,
                    size: 18,
                    color: primary,
                  ),
                  const SizedBox(width: 8),
                  const Flexible(
                    child: Text(
                      'GLOBAL TOP MUSIC CHARTS',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                if (trendingTracks.isNotEmpty)
                  InkWell(
                    onTap: () {
                      AppHaptics.selectionClick();
                      ref.read(playerControllerProvider.notifier).setQueue(
                            trendingTracks,
                            initialIndex: 0,
                          );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: StudioSurfaceTheme.tintedContainer(context, primary, isSolid: isSolid, translucentAlpha: 0.12, solidBlendAlpha: 0.16),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedPlay,
                            size: 12,
                            color: primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Play All',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(width: 6),
                M3EIconButton(
                  variant: M3EIconButtonVariant.standard,
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedRefresh,
                    size: 22,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  tooltip: 'Refresh Charts',
                  onPressed: () {
                    AppHaptics.selectionClick();
                    ytController.fetchTrending(force: true);
                  },
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Trending Tracks List
        if (isLoadingTrending)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: M3EProgressIndicator.circular(
                  strokeWidth: 2,
                  color: primary,
                ),
              ),
            ),
          )
        else if (trendingTracks.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Search for songs or tap refresh to load global music charts.',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  M3EButton.outlined(
                    onPressed: () {
                      AppHaptics.selectionClick();
                      ytController.fetchTrending(force: true);
                    },
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedRefresh,
                      size: 14,
                      color: primary,
                    ),
                    label: const Text(
                      'Load Global Charts',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...trendingTracks.map((track) {
            final isPlaying = currentPlayingId == track.id;
            return _buildYouTubeTrackTile(
              context: context,
              track: track,
              isPlaying: isPlaying,
              onTap: () {
                AppHaptics.selectionClick();
                ref.read(playerControllerProvider.notifier).setQueue(
                      trendingTracks,
                      initialIndex: trendingTracks.indexOf(track),
                    );
              },
              onStartRadio: () => ytController.startRadio(track),
              theme: theme,
              isSolid: isSolid,
            );
          }),
      ],
    );
  }

  Widget _buildDiscoveryBentoTile({
    required BuildContext context,
    required ThemeData theme,
    required Color primary,
    required String title,
    required String subtitle,
    required dynamic icon,
    required String badge,
    required VoidCallback onTap,
    required bool isSolid,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
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
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: StudioSurfaceTheme.tintedContainer(context, primary, isSolid: isSolid, translucentAlpha: 0.12, solidBlendAlpha: 0.16),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: HugeIcon(
                      icon: icon,
                      size: 16,
                      color: primary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.4,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBentoFeatureTag(BuildContext context, dynamic icon, String label, bool isSolid) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: StudioSurfaceTheme.surfaceContainerLow(context, isSolid: isSolid),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(
            icon: icon,
            size: 12,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYouTubeTrackTile({
    required BuildContext context,
    required Track track,
    required bool isPlaying,
    required VoidCallback onTap,
    required VoidCallback onStartRadio,
    required ThemeData theme,
    required bool isSolid,
  }) {
    final primary = theme.colorScheme.primary;

    final playback = ref.watch(playerControllerProvider);
    final isCurrent = playback.currentTrack?.id == track.id;
    final isBuffering = isCurrent && playback.isLoading;
    final isTileActive = isPlaying || isBuffering;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: isTileActive
            ? StudioSurfaceTheme.tintedContainer(context, primary, isSolid: isSolid, translucentAlpha: 0.08, solidBlendAlpha: 0.16)
            : StudioSurfaceTheme.surfaceContainerLow(context, isSolid: isSolid),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          leading: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: StudioArtworkWidget(
                  track: track,
                  borderRadius: BorderRadius.circular(11),
                  fallbackIconSize: 20,
                ),
              ),
              if (isTileActive)
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: isBuffering
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: M3EProgressIndicator.circular(
                              strokeWidth: 2.0,
                              color: primary,
                            ),
                          )
                        : HugeIcon(
                            icon: HugeIcons.strokeRoundedAudioWave01,
                            size: 20,
                            color: primary,
                          ),
                  ),
                ),
            ],
          ),
          title: Text(
            track.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isTileActive ? FontWeight.w900 : FontWeight.w700,
              color: isTileActive ? primary : theme.colorScheme.onSurface,
            ),
          ),
          subtitle: Row(
            children: [
              // Format tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: StudioSurfaceTheme.tintedContainer(context, primary, isSolid: isSolid, translucentAlpha: 0.12, solidBlendAlpha: 0.16),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'OPUS',
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    color: primary,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  track.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
              Text(
                _formatDuration(track.duration),
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  fontFeatures: AppTypography.audioFigures,
                ),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Start Radio Button
              M3EIconButton(
                variant: M3EIconButtonVariant.standard,
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedRadio,
                  size: 22,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                tooltip: 'Start Smart Track Radio',
                onPressed: () {
                  AppHaptics.selectionClick();
                  onStartRadio();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Starting smart radio based on "${track.title}"...'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
              // Unified Track Action Sheet
              M3EIconButton(
                variant: M3EIconButtonVariant.standard,
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedMoreVertical,
                  size: 22,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                tooltip: 'Track Options',
                onPressed: () {
                  StudioTrackActionSheet.show(context, track);
                },
              ),
            ],
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
