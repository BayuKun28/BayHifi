import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import '../../../../app/theme/app_haptics.dart';
import '../../../../core/widgets/studio_artwork_widget.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/studio_surface_theme.dart';
import '../../domain/track.dart';
import '../controllers/player_controller.dart';
import '../controllers/player_expansion_controller.dart';
import '../now_playing_screen.dart';
import '../../../pro_q_studio/presentation/pro_q_studio_screen.dart';
import '../../../library/domain/library_collection_models.dart';
import '../../../library/presentation/controllers/library_controller.dart';
import '../../../library/presentation/controllers/library_selection_controller.dart';
import '../../../library/presentation/playlists_screen.dart';

/// Namida-inspired Expandable MiniPlayer
/// Melayang tepat di atas Bottom Navigation Bar dan dapat di-expand secara mulus ke full NowPlayingScreen.
class NamidaExpandableMiniPlayer extends ConsumerStatefulWidget {
  final double collapsedBottomOffset;
  final bool isLibraryTab;

  const NamidaExpandableMiniPlayer({
    super.key,
    this.collapsedBottomOffset = 86.0,
    this.isLibraryTab = false,
  });

  @override
  ConsumerState<NamidaExpandableMiniPlayer> createState() =>
      _NamidaExpandableMiniPlayerState();
}

class _NamidaExpandableMiniPlayerState
    extends ConsumerState<NamidaExpandableMiniPlayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _expandAnimation;
  bool _isSourceDockExpanded = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.fastOutSlowIn,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void didUpdateWidget(covariant NamidaExpandableMiniPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLibraryTab && !widget.isLibraryTab && _isSourceDockExpanded) {
      _isSourceDockExpanded = false;
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onExpand() {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _isSourceDockExpanded = false);
    ref.read(playerExpansionProvider.notifier).expand();
  }

  void _onCollapse() {
    FocusManager.instance.primaryFocus?.unfocus();
    ref.read(playerExpansionProvider.notifier).collapse();
  }

  IconData _getSourceFilterIcon(LibrarySourceFilter filter) {
    return switch (filter) {
      LibrarySourceFilter.all => LucideIcons.music,
      LibrarySourceFilter.offline => LucideIcons.folder,
      LibrarySourceFilter.cloud => LucideIcons.cloud,
      LibrarySourceFilter.hiRes => LucideIcons.disc,
      LibrarySourceFilter.untagged => LucideIcons.alertCircle,
    };
  }

  String _getSourceFilterLabel(LibrarySourceFilter filter) {
    return switch (filter) {
      LibrarySourceFilter.all => 'All Sources',
      LibrarySourceFilter.offline => 'Offline Local',
      LibrarySourceFilter.cloud => 'Cloud Library',
      LibrarySourceFilter.hiRes => 'Hi-Res Lossless',
      LibrarySourceFilter.untagged => 'Untagged Audio',
    };
  }

  String _getSourceFilterShortLabel(LibrarySourceFilter filter) {
    return switch (filter) {
      LibrarySourceFilter.all => 'ALL',
      LibrarySourceFilter.offline => 'OFFLINE',
      LibrarySourceFilter.cloud => 'CLOUD',
      LibrarySourceFilter.hiRes => 'HI-RES',
      LibrarySourceFilter.untagged => 'UNTAGGED',
    };
  }

  int _getSourceFilterCount(UnifiedLibraryState state, LibrarySourceFilter filter) {
    return switch (filter) {
      LibrarySourceFilter.all => state.totalTracksCount,
      LibrarySourceFilter.offline => state.offlineTracksCount,
      LibrarySourceFilter.cloud => state.cloudTracksCount,
      LibrarySourceFilter.hiRes => state.hiResTracksCount,
      LibrarySourceFilter.untagged => state.untaggedTracksCount,
    };
  }



  @override
  Widget build(BuildContext context) {
    final isExpanded = ref.watch(playerExpansionProvider);
    final playback = ref.watch(playerControllerProvider);
    final libraryState = ref.watch(unifiedLibraryProvider);
    final track = playback.currentTrack;
    final theme = Theme.of(context);
    final isSolid = ref.isSolidStyle;
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final bool isDesktopPlatform = !kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS);
    final double desktopTitleBarHeight = isDesktopPlatform ? 38.0 : 0.0;
    final double maxAvailableHeight = screenHeight - desktopTitleBarHeight;

    // Sinkronkan controller animasi dengan state
    if (isExpanded && _animController.status != AnimationStatus.completed) {
      _animController.forward();
    } else if (!isExpanded && _animController.status != AnimationStatus.dismissed) {
      _animController.reverse();
    }

    // Track aktif atau fallback demo
    final currentTrack = track ??
        const Track(
          id: 'demo_track',
          title: 'Tap to Play Audio',
          artist: 'Baydev HiFi Audiophile Player',
          album: 'Studio Engine Ready',
          duration: Duration(minutes: 3, seconds: 45),
          format: AudioFormat.flac,
          sampleRate: 96000,
          bitDepth: 24,
        );

    return PopScope(
      canPop: !isExpanded && !_isSourceDockExpanded,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_isSourceDockExpanded) {
          setState(() => _isSourceDockExpanded = false);
          return;
        }
        if (isExpanded) {
          _onCollapse();
        }
      },
      child: AnimatedBuilder(
        animation: _expandAnimation,
        builder: (context, child) {
        final progress = _expandAnimation.value;

        // Animasikan bottom offset: dari collapsedBottomOffset + safe area bottom ke 0px
        final double baseBottomOffset =
            widget.collapsedBottomOffset + mediaQuery.padding.bottom;
        final double currentBottom = (1.0 - progress) * baseBottomOffset;

        // Animasikan tinggi: dari 66px ke maxAvailableHeight (menghindari tumpang tindih dengan Desktop TitleBar)
        const double miniPlayerHeight = 66.0;
        final double currentHeight =
            miniPlayerHeight + progress * (maxAvailableHeight - miniPlayerHeight);

        // Animasikan margin samping: dari 10px ke 0px
        final double horizontalMargin = (1.0 - progress) * 10.0;
        final double borderRadius = (1.0 - progress) * 16.0;

        // Jika di Library tab, miniplayer menyisakan ruang 66px di kanan untuk tombol Category FAB
        final double miniPlayerRight =
            (1.0 - progress) * (widget.isLibraryTab ? 76.0 : 10.0);

        return Stack(
          children: [
            // ─── 0. DISMISS BACKDROP SAAT SOURCE DOCK EXPANDED ──────────────
            if (_isSourceDockExpanded && widget.isLibraryTab && progress < 0.1)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _isSourceDockExpanded = false),
                  child: const ColoredBox(color: Colors.transparent),
                ),
              ),

            // ─── 1. FLOATING AUDIO SOURCE FILTER DOCK POPUP ──────────────────
            if (_isSourceDockExpanded && widget.isLibraryTab && progress < 0.1)
              Positioned(
                right: 10,
                bottom: currentBottom + miniPlayerHeight + 8.0,
                child: _buildFloatingSourceFilterDock(context, theme, isSolid),
              ),

            // ─── 2. MAIN EXPANDABLE MINIPLAYER ──────────────────────────────
            Positioned(
              left: horizontalMargin,
              right: miniPlayerRight,
              bottom: currentBottom,
              height: currentHeight,
              child: GestureDetector(
                onVerticalDragUpdate: (details) {
                  if (details.primaryDelta != null) {
                    if (details.primaryDelta! < -6 && !isExpanded) {
                      _onExpand();
                    } else if (details.primaryDelta! > 6 && isExpanded) {
                      _onCollapse();
                    }
                  }
                },
                child: Material(
                  color: Colors.transparent,
                  elevation: progress > 0.05 ? 24 : 10,
                  borderRadius: BorderRadius.circular(borderRadius),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(borderRadius),
                    child: Container(
                      decoration: BoxDecoration(
                        color: StudioSurfaceTheme.surfaceContainer(context, isSolid: isSolid),
                        borderRadius: BorderRadius.circular(borderRadius),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Layer 1: Full NowPlayingScreen (Fade in saat di-expand)
                          if (progress > 0.01)
                            Positioned(
                              top: 0,
                              left: 0,
                              width: mediaQuery.size.width,
                              height: maxAvailableHeight,
                              child: Opacity(
                                opacity: progress.clamp(0.0, 1.0),
                                child: NowPlayingScreen(
                                  onCollapse: _onCollapse,
                                  onOpenProQStudio: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const ProQStudioScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),

                          // Layer 2: Collapsed MiniPlayer Bar (Fade out saat di-expand)
                          if (progress < 0.99)
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              height: miniPlayerHeight,
                              child: Opacity(
                                opacity: (1.0 - progress * 2.0).clamp(0.0, 1.0),
                                child: _buildMiniPlayerContent(
                                  context,
                                  currentTrack,
                                  playback,
                                  theme,
                                  isSolid,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ─── 3. AUDIO SOURCE FILTER FAB (SEJAJAR DI KANAN MINIPLAYER) ──
            if (widget.isLibraryTab && progress < 0.95)
              Positioned(
                right: 10,
                bottom: currentBottom,
                width: 58,
                height: miniPlayerHeight,
                child: Opacity(
                  opacity: (1.0 - progress * 3.0).clamp(0.0, 1.0),
                  child: _buildSourceFilterFab(context, theme, isSolid),
                ),
              ),

            // ─── 4. SHUFFLE SHORTCUT FAB (DI ATAS SOURCE FILTER FAB PADA TRACKS TAB) ───
            if (widget.isLibraryTab &&
                libraryState.currentTab == CollectionTab.tracks &&
                !_isSourceDockExpanded &&
                progress < 0.95)
              Positioned(
                right: 10,
                bottom: currentBottom + miniPlayerHeight + 8.0,
                width: 58,
                height: 54,
                child: Opacity(
                  opacity: (1.0 - progress * 3.0).clamp(0.0, 1.0),
                  child: _buildShuffleFab(context, theme, isSolid),
                ),
              ),
          ],
        );
      },
    ),
  );
}

  Widget _buildShuffleFab(BuildContext context, ThemeData theme, bool isSolid) {
    final libraryState = ref.watch(unifiedLibraryProvider);
    final primary = theme.colorScheme.primary;
    final tracks = libraryState.filteredTracks.isNotEmpty
        ? libraryState.filteredTracks
        : libraryState.tracks;

    return Tooltip(
      message: 'Shuffle All Tracks',
      child: Material(
        color: Colors.transparent,
        elevation: 10,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            if (tracks.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No tracks to shuffle.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              return;
            }
            AppHaptics.lightImpact();
            final shuffled = List<Track>.from(tracks)..shuffle();
            ref.read(playerControllerProvider.notifier).setQueue(
                  shuffled,
                  initialIndex: 0,
                );
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Shuffled ${shuffled.length} tracks into queue'),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 58,
            height: 54,
            decoration: BoxDecoration(
              color: StudioSurfaceTheme.surfaceContainer(context, isSolid: isSolid),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.shuffle,
                  size: 20,
                  color: primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSourceFilterFab(BuildContext context, ThemeData theme, bool isSolid) {
    final libraryState = ref.watch(unifiedLibraryProvider);
    final primary = theme.colorScheme.primary;
    final isFiltered = libraryState.selectedFilter != LibrarySourceFilter.all;

    return Tooltip(
      message: 'Filter Audio Source',
      child: Material(
        color: Colors.transparent,
        elevation: 10,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            AppHaptics.selectionClick();
            setState(() => _isSourceDockExpanded = !_isSourceDockExpanded);
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 58,
            height: 66,
            decoration: BoxDecoration(
              color: StudioSurfaceTheme.surfaceContainer(context, isSolid: isSolid),
              borderRadius: BorderRadius.circular(16),
              border: isFiltered
                  ? Border.all(
                      color: primary.withValues(alpha: 0.6),
                      width: 1.2,
                    )
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getSourceFilterIcon(libraryState.selectedFilter),
                  size: 20,
                  color: primary,
                ),
                const SizedBox(height: 3),
                Text(
                  _getSourceFilterShortLabel(libraryState.selectedFilter),
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                    color: isFiltered ? primary : theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingSourceFilterDock(BuildContext context, ThemeData theme, bool isSolid) {
    final libraryState = ref.watch(unifiedLibraryProvider);
    final primary = theme.colorScheme.primary;

    return Material(
      color: Colors.transparent,
      elevation: 16,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 220,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: StudioSurfaceTheme.cardDecoration(
          context: context,
          isSolid: isSolid,
          radius: 18,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Text(
                'AUDIO SOURCE',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
            const SizedBox(height: 2),
            ...LibrarySourceFilter.values.map((filter) {
              final isSelected = libraryState.selectedFilter == filter;
              final count = _getSourceFilterCount(libraryState, filter);
              return InkWell(
                onTap: () {
                  AppHaptics.selectionClick();
                  ref.read(librarySelectionProvider.notifier).clear();
                  ref.read(unifiedLibraryProvider.notifier).setFilter(filter);
                  setState(() => _isSourceDockExpanded = false);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isSolid
                            ? StudioSurfaceTheme.tintedContainer(
                                context,
                                primary,
                                isSolid: true,
                                solidBlendAlpha: 0.18,
                              )
                            : StudioSurfaceTheme.tintedContainer(
                                context,
                                primary,
                                isSolid: false,
                                translucentAlpha: 0.15,
                              ))
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getSourceFilterIcon(filter),
                        size: 16,
                        color: isSelected ? primary : primary.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _getSourceFilterLabel(filter),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? primary : theme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? primary.withValues(alpha: 0.2)
                              : theme.colorScheme.onSurface.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            fontFeatures: const [FontFeature.tabularFigures()],
                            color: isSelected ? primary : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 6),
            Divider(height: 1, color: StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid)),
            const SizedBox(height: 4),
            InkWell(
              onTap: () {
                AppHaptics.selectionClick();
                setState(() => _isSourceDockExpanded = false);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PlaylistsScreen()),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.listMusic,
                      size: 16,
                      color: theme.colorScheme.secondary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Playlists',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniPlayerContent(
    BuildContext context,
    Track track,
    dynamic playback,
    ThemeData theme,
    bool isSolid,
  ) {
    final isPlaying = playback.isPlaying as bool;
    final position = playback.position as Duration;
    final duration = playback.duration as Duration;
    final progressRatio = duration.inMilliseconds > 0
        ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return GestureDetector(
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! < -200) {
          _onExpand();
        }
      },
      child: InkWell(
        onTap: _onExpand,
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Bar Content Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
              child: Row(
              children: [
                // Squircle Album Art Thumbnail
                Hero(
                  tag: 'miniplayer_album_art',
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: (isPlaying ? theme.colorScheme.primary : Colors.black)
                              .withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: StudioArtworkWidget(
                        track: track,
                        fallbackIconSize: 22,
                        fallbackColor: isPlaying
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Title, Artist, & Hi-Res Badge
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              track.title,
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: isSolid
                                  ? theme.colorScheme.surfaceContainerHighest
                                  : StudioSurfaceTheme.tintedContainer(context, theme.colorScheme.primary, isSolid: false, translucentAlpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${track.format.name.toUpperCase()} 24/96',
                              style: TextStyle(
                                color: isSolid ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.primary,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w900,
                                fontFeatures: AppTypography.audioFigures,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${track.artist} • ${track.album}',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Play / Pause Circle Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      ref.read(playerControllerProvider.notifier).togglePlayPause();
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: isSolid
                                ? Colors.black.withValues(alpha: 0.25)
                                : theme.colorScheme.primary.withValues(alpha: 0.35),
                            blurRadius: isSolid ? 6 : 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: playback.isLoading
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: M3EProgressIndicator.circular(
                                  strokeWidth: 2.2,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              )
                            : Icon(
                                isPlaying ? LucideIcons.pause : LucideIcons.play,
                                color: theme.colorScheme.onPrimary,
                                size: 20,
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),

                // Next Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      ref.read(playerControllerProvider.notifier).skipNext();
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        LucideIcons.stepForward,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        size: 20,
                      ),
                    ),
                  ),
                ),

                // Expand Chevron Icon
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _onExpand,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        LucideIcons.chevronUp,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Micro Progress Bar at the bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SizedBox(
              height: 2.5,
              child: M3EProgressIndicator.linear(
                value: progressRatio,
                trackColor: StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid),
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}
