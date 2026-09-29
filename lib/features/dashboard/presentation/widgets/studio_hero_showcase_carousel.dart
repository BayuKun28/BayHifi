import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../app/theme/studio_surface_theme.dart';
import '../../../../core/database/local_persistence_service.dart';
import '../../../../core/widgets/studio_artwork_widget.dart';
import '../../../library/presentation/controllers/library_controller.dart';
import '../../../player/domain/track.dart';
import '../../../player/presentation/controllers/player_controller.dart';
import '../../../youtube_music/presentation/youtube_discovery_screen.dart';

/// Data model representing an auto-generated audiophile smart mix
class StudioMixItem {
  final String id;
  final String categoryBadge;
  final String title;
  final String subtitle;
  final dynamic icon;
  final List<Track> tracks;

  const StudioMixItem({
    required this.id,
    required this.categoryBadge,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tracks,
  });

  int get trackCount => tracks.length;

  Duration get totalDuration =>
      tracks.fold(Duration.zero, (prev, t) => prev + t.duration);

  String get formattedDuration {
    final dur = totalDuration;
    final h = dur.inHours;
    final m = dur.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    return '${dur.inMinutes}m';
  }
}

/// Horizontal Studio Mixes Showcase Banner Carousel (Material 3 Expressive)
/// Placed in the Dashboard with dynamic auto-generated smart mixes and instant 1-tap playback.
class StudioHeroShowcaseCarousel extends ConsumerStatefulWidget {
  const StudioHeroShowcaseCarousel({super.key});

  @override
  ConsumerState<StudioHeroShowcaseCarousel> createState() =>
      _StudioHeroShowcaseCarouselState();
}

class _StudioHeroShowcaseCarouselState
    extends ConsumerState<StudioHeroShowcaseCarousel> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<StudioMixItem> _generateMixes(List<Track> allTracks) {
    const ytShowcase = StudioMixItem(
      id: 'youtube_hifi_showcase',
      categoryBadge: 'OPUS 160K • DSP MASTER',
      title: 'YouTube Music HiFi',
      subtitle: 'Stream global music charts & route Opus audio directly through SoLoud DSP chain',
      icon: HugeIcons.strokeRoundedPlayList,
      tracks: [],
    );

    if (allTracks.isEmpty) {
      return [
        const StudioMixItem(
          id: 'empty_library',
          categoryBadge: 'STUDIO MIXES',
          title: 'Add Music to Generate Mixes',
          subtitle: 'Scan your local folders or connect Navidrome to unlock smart dynamic mixes',
          icon: HugeIcons.strokeRoundedMusicNote01,
          tracks: [],
        ),
        ytShowcase,
      ];
    }

    final rng = Random(DateTime.now().day);

    // 1. Recommended Studio Mix (50 Auto-Generated randomized tracks)
    final shuffledAll = List<Track>.from(allTracks)..shuffle(rng);
    final recommendedTracks = shuffledAll.take(50).toList();

    // 2. Top Heavy Rotation & Recents
    final history = LocalPersistenceService.instance.getPlaybackHistory();
    final historyTrackIds = history.map((e) => e['id'] as String?).whereType<String>().toSet();
    final topRecents = allTracks.where((t) => historyTrackIds.contains(t.id)).toList();
    final heavyRotationTracks = topRecents.isNotEmpty
        ? topRecents.take(40).toList()
        : shuffledAll.take(30).toList();

    // 3. Underrated Hi-Res Gems
    final hiResTracks = allTracks.where((t) => t.isHiRes).toList();
    final underratedTracks = hiResTracks.isNotEmpty
        ? (List<Track>.from(hiResTracks)..shuffle(Random(42))).take(35).toList()
        : (List<Track>.from(allTracks)..shuffle(Random(42))).take(25).toList();

    // 4. Late-Night Analog & Acoustic
    final acousticKeywords = ['acoustic', 'unplugged', 'jazz', 'ambient', 'chill', 'live', 'piano', 'vocal', 'ballad', 'relax', 'night'];
    final acousticTracks = allTracks.where((t) {
      final name = '${t.title} ${t.album} ${t.artist}'.toLowerCase();
      return acousticKeywords.any((k) => name.contains(k));
    }).toList();
    final lateNightTracks = acousticTracks.length >= 5
        ? (List<Track>.from(acousticTracks)..shuffle(Random(77))).take(40).toList()
        : (List<Track>.from(shuffledAll)..shuffle(Random(77))).take(30).toList();

    // 5. Studio Master Quality Mix (24-bit / 96kHz / Lossless)
    final studioMasterTracks = allTracks.where((t) => (t.bitDepth ?? 16) >= 24 || (t.sampleRate ?? 44100) >= 88200 || t.isHiRes).toList();
    final masterTracks = studioMasterTracks.isNotEmpty
        ? studioMasterTracks.take(45).toList()
        : allTracks.take(30).toList();

    return [
      StudioMixItem(
        id: 'recommended_50',
        categoryBadge: '50 TRACKS • DYNAMIC MIX',
        title: 'Recommended Studio Mix',
        subtitle: 'Auto-generated randomized selection from your lossless collection',
        icon: HugeIcons.strokeRoundedSparkles,
        tracks: recommendedTracks,
      ),
      ytShowcase,
      StudioMixItem(
        id: 'heavy_rotation',
        categoryBadge: 'HEAVY ROTATION • TOP RECENTS',
        title: 'Top Heavy Rotation',
        subtitle: 'Your most played and recently enjoyed audiophile tracks',
        icon: HugeIcons.strokeRoundedFavourite,
        tracks: heavyRotationTracks,
      ),
      StudioMixItem(
        id: 'underrated_gems',
        categoryBadge: 'DISCOVERY • HI-RES GEMS',
        title: 'Underrated Hi-Res Gems',
        subtitle: 'Hidden studio master tracks waiting to be rediscovered',
        icon: HugeIcons.strokeRoundedDiamond,
        tracks: underratedTracks,
      ),
      StudioMixItem(
        id: 'late_night_acoustic',
        categoryBadge: 'STUDIO SESSION • ANALOG CHILL',
        title: 'Late-Night Acoustic Session',
        subtitle: 'Warm, acoustic, ambient & relaxing vocal recordings for late-night listening',
        icon: HugeIcons.strokeRoundedMoon02,
        tracks: lateNightTracks,
      ),
      StudioMixItem(
        id: 'studio_master',
        categoryBadge: '24-BIT / 96KHZ • STUDIO MASTER',
        title: 'Studio Master Quality Mix',
        subtitle: 'Pure bit-perfect lossless high dynamic range tracks',
        icon: HugeIcons.strokeRoundedAudioWaveform,
        tracks: masterTracks,
      ),
    ];
  }

  void _playMix(StudioMixItem mix, {bool shuffle = false, int initialIndex = 0}) {
    if (mix.id == 'youtube_hifi_showcase') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const YouTubeDiscoveryScreen()),
      );
      return;
    }

    if (mix.tracks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No tracks available in library for this mix'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    final tracksToPlay = shuffle
        ? (List<Track>.from(mix.tracks)..shuffle())
        : mix.tracks;

    ref.read(playerControllerProvider.notifier).setQueue(
      tracksToPlay,
      initialIndex: shuffle ? 0 : initialIndex.clamp(0, tracksToPlay.length - 1),
    );

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Playing ${mix.title} (${mix.trackCount} tracks)'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openMixDetailSheet(BuildContext context, StudioMixItem mix) {
    HapticFeedback.lightImpact();
    if (mix.id == 'youtube_hifi_showcase') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const YouTubeDiscoveryScreen()),
      );
      return;
    }

    final isSolid = ref.isSolidStyle;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StudioMixDetailSheet(
        mix: mix,
        isSolid: isSolid,
        onPlayAll: () {
          Navigator.of(context).pop();
          _playMix(mix, shuffle: false);
        },
        onShuffle: () {
          Navigator.of(context).pop();
          _playMix(mix, shuffle: true);
        },
        onSelectTrack: (index) {
          Navigator.of(context).pop();
          _playMix(mix, shuffle: false, initialIndex: index);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isSolid = ref.isSolidStyle;
    final libraryState = ref.watch(unifiedLibraryProvider);
    final mixes = _generateMixes(libraryState.tracks);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedSparkles,
                  size: 15,
                  color: primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'DYNAMIC STUDIO MIXES',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
            Text(
              '${_currentPage + 1}/${mixes.length}',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: primary,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Carousel Slider
        SizedBox(
          height: 168,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemCount: mixes.length,
            itemBuilder: (context, index) {
              final mix = mixes[index];
              return _buildMixCard(context, mix, theme, primary, isSolid);
            },
          ),
        ),

        const SizedBox(height: 8),

        // Page Indicator Dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(mixes.length, (index) {
            final isSelected = _currentPage == index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isSelected ? 18 : 6,
              height: 5,
              decoration: BoxDecoration(
                color: isSelected ? primary : StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildMixCard(
    BuildContext context,
    StudioMixItem mix,
    ThemeData theme,
    Color primary,
    bool isSolid,
  ) {
    final firstTrack = mix.tracks.isNotEmpty ? mix.tracks.first : null;

    return InkWell(
      onTap: () => _openMixDetailSheet(context, mix),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: StudioSurfaceTheme.cardDecoration(
          context: context,
          isSolid: isSolid,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(19),
          child: Stack(
            children: [
              // Background Ambient Icon
              Positioned(
                right: -15,
                bottom: -15,
                child: Opacity(
                  opacity: 0.05,
                  child: HugeIcon(
                    icon: mix.icon,
                    size: 140,
                    color: primary,
                  ),
                ),
              ),

              // Content Layout
              Padding(
                padding: const EdgeInsets.all(13.0),
                child: Row(
                  children: [
                    // Left Side: Artwork Thumbnail / Grid Preview
                    if (mix.id == 'youtube_hifi_showcase')
                      Container(
                        width: 78,
                        height: 78,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: primary.withValues(alpha: 0.35),
                            width: 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedPlayList,
                            size: 34,
                            color: primary,
                          ),
                        ),
                      )
                    else if (firstTrack != null)
                      Container(
                        width: 78,
                        height: 78,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: primary.withValues(alpha: 0.3),
                            width: 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          child: StudioArtworkWidget(
                            track: firstTrack,
                            width: 78,
                            height: 78,
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),
                      ),

                    // Right Side: Title, Subtitle, and Action Buttons
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Top Row: Category Badge & Studio Icon
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: primary.withValues(alpha: 0.3),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  mix.categoryBadge,
                                  style: TextStyle(
                                    color: primary,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainer.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: HugeIcon(
                                  icon: mix.icon,
                                  size: 14,
                                  color: primary,
                                ),
                              ),
                            ],
                          ),

                          // Middle: Title and Subtitle
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                mix.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.2,
                                  color: theme.colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                mix.subtitle,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),

                          // Bottom Row: Stats & Action Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Track Count and Duration
                              if (mix.trackCount > 0)
                                Expanded(
                                  child: Text(
                                    '${mix.trackCount} trk • ${mix.formattedDuration}',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )
                              else if (mix.id == 'youtube_hifi_showcase')
                                Expanded(
                                  child: Text(
                                    'Global Charts • Live',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )
                              else
                                const Spacer(),
                              const SizedBox(width: 8),

                              // Action Buttons (Play & Shuffle or Discover)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (mix.id == 'youtube_hifi_showcase') ...[
                                    InkWell(
                                      onTap: () {
                                        HapticFeedback.selectionClick();
                                        Navigator.of(context).push(
                                          MaterialPageRoute(builder: (_) => const YouTubeDiscoveryScreen()),
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: primary,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            HugeIcon(
                                              icon: HugeIcons.strokeRoundedPlayList,
                                              size: 12,
                                              color: Colors.black,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              'DISCOVER',
                                              style: TextStyle(
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 0.4,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ] else ...[
                                    if (mix.trackCount > 0) ...[
                                      InkWell(
                                        onTap: () => _playMix(mix, shuffle: true),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.surfaceContainerHighest,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: theme.dividerColor.withValues(alpha: 0.6),
                                              width: 0.8,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              HugeIcon(
                                                icon: HugeIcons.strokeRoundedShuffle,
                                                size: 12,
                                                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                                              ),
                                              const SizedBox(width: 3),
                                              Text(
                                                'Shuffle',
                                                style: TextStyle(
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                    ],
                                    InkWell(
                                      onTap: () => _playMix(mix),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: primary,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            HugeIcon(
                                              icon: HugeIcons.strokeRoundedPlay,
                                              size: 12,
                                              color: Colors.black,
                                            ),
                                            SizedBox(width: 3),
                                            Text(
                                              'Play',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Modal Bottom Sheet displaying the full tracklist of a Studio Mix
class _StudioMixDetailSheet extends StatelessWidget {
  final StudioMixItem mix;
  final bool isSolid;
  final VoidCallback onPlayAll;
  final VoidCallback onShuffle;
  final ValueChanged<int> onSelectTrack;

  const _StudioMixDetailSheet({
    required this.mix,
    this.isSolid = false,
    required this.onPlayAll,
    required this.onShuffle,
    required this.onSelectTrack,
  });

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: BoxDecoration(
        color: StudioSurfaceTheme.surface(context, isSolid: isSolid),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: StudioSurfaceTheme.outline(context, isSolid: isSolid),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 32,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 38,
              height: 4.5,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header Info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                if (mix.tracks.isNotEmpty)
                  Container(
                    width: 52,
                    height: 52,
                    margin: const EdgeInsets.only(right: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSolid ? theme.colorScheme.outline : primary.withValues(alpha: 0.4),
                        width: 1.0,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: StudioArtworkWidget(
                        track: mix.tracks.first,
                        width: 52,
                        height: 52,
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: StudioSurfaceTheme.tintedContainer(context, primary, isSolid: isSolid),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          mix.categoryBadge,
                          style: TextStyle(
                            color: primary,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        mix.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${mix.trackCount} tracks • ${mix.formattedDuration}',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Action Buttons Bar (Play All & Shuffle)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onPlayAll,
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedPlay,
                      size: 16,
                      color: Colors.black,
                    ),
                    label: const Text(
                      'Play All',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12.5,
                        color: Colors.black,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onShuffle,
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedShuffle,
                      size: 16,
                      color: theme.colorScheme.onSurface,
                    ),
                    label: Text(
                      'Shuffle Play',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid)),
                      backgroundColor: StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          Divider(color: StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid), height: 1),

          // Scrollable Tracklist
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              itemCount: mix.tracks.length,
              itemBuilder: (context, index) {
                final track = mix.tracks[index];
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 3),
                  decoration: BoxDecoration(
                    color: StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid),
                      width: 0.8,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      onTap: () => onSelectTrack(index),
                      leading: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: StudioSurfaceTheme.surfaceContainer(context, isSolid: isSolid),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid),
                            width: 0.8,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            (index + 1).toString().padLeft(2, '0'),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurfaceVariant,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              track.title,
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (track.isHiRes) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: StudioSurfaceTheme.tintedContainer(context, primary, isSolid: isSolid),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: isSolid ? theme.colorScheme.outline : primary.withValues(alpha: 0.6),
                                  width: 0.6,
                                ),
                              ),
                              child: Text(
                                'Hi-Res',
                                style: TextStyle(
                                  color: primary,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      subtitle: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${track.artist} • ${track.album}',
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (track.duration > Duration.zero)
                            Text(
                              _formatDuration(track.duration),
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                        ],
                      ),
                      trailing: HugeIcon(
                        icon: HugeIcons.strokeRoundedPlay,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

