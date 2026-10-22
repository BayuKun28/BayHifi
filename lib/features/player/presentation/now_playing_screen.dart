import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../app/theme/app_haptics.dart';
import '../../../core/widgets/studio_artwork_lightbox.dart';
import '../../../core/desktop/desktop_layout_controller.dart';
import '../../dsp_rack/presentation/dsp_rack_screen.dart';
import '../../library/domain/library_collection_models.dart';
import '../../library/presentation/controllers/library_controller.dart';
import '../../library/presentation/screens/album_detail_screen.dart';
import '../../library/presentation/screens/artist_detail_screen.dart';
import '../../pro_q_studio/presentation/controllers/eq_controller.dart';
import '../../pro_q_studio/presentation/controllers/eq_state.dart';
import '../../settings/domain/player_customization_settings.dart';
import '../../settings/presentation/controllers/player_customization_controller.dart';
import '../data/lyrics_service.dart';
import '../domain/playback_state.dart';
import '../domain/track.dart';
import 'controllers/player_controller.dart';
import 'controllers/sleep_timer_controller.dart';
import 'studio_desk_docking_screen.dart';
import 'widgets/audio_file_inspector_sheet.dart';
import 'widgets/custom_time_bar.dart';
import 'widgets/dual_pane_workstation_pane.dart';
import 'widgets/now_playing_auxiliary_bar.dart';
import 'widgets/now_playing_controls_deck.dart';
import 'widgets/now_playing_engine_badge.dart';
import 'widgets/now_playing_options_sheet.dart';
import 'widgets/now_playing_queue_sheet.dart';
import 'widgets/now_playing_top_bar.dart';
import 'widgets/parallax_artwork_card.dart';
import 'widgets/playback_speed_pitch_sheet.dart';
import 'widgets/sleep_timer_sheet.dart';
import 'widgets/synchronized_lyrics_view.dart';

class NowPlayingScreen extends ConsumerStatefulWidget {
  final VoidCallback onOpenProQStudio;
  final VoidCallback? onOpenDspRack;
  final VoidCallback? onCollapse;

  const NowPlayingScreen({
    super.key,
    required this.onOpenProQStudio,
    this.onOpenDspRack,
    this.onCollapse,
  });

  @override
  ConsumerState<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends ConsumerState<NowPlayingScreen> {
  bool _showLyrics = false;
  LyricsResult _lyricsResult = const LyricsResult.empty();
  bool _isLoadingLyrics = false;
  String? _loadedTrackId;
  WorkstationTab _workstationTab = WorkstationTab.queue;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentTrack = ref.read(playerControllerProvider).currentTrack;
      if (currentTrack != null) {
        _fetchLyrics(currentTrack);
      }
    });
  }

  Future<void> _fetchLyrics(Track track, {bool forceOnline = false}) async {
    if (_loadedTrackId == track.id && _lyricsResult.isNotEmpty && !forceOnline) {
      return;
    }

    if (forceOnline) {
      LyricsService.instance.clearCacheForTrack(track.id);
    }

    setState(() {
      _isLoadingLyrics = true;
      _loadedTrackId = track.id;
    });

    try {
      final result = await LyricsService.instance.getLyricsForTrack(track);
      if (mounted) {
        setState(() {
          _lyricsResult = result;
          _isLoadingLyrics = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingLyrics = false;
        });
      }
    }
  }

  Future<void> _pickAndPlayFile() async {
    await ref.read(playerControllerProvider.notifier).pickAndPlayAudioFile();
  }

  void _navigateToAlbum(BuildContext context, Track track) {
    if (track.album.isEmpty || track.album == 'Unknown Album') return;
    final libraryState = ref.read(unifiedLibraryProvider);
    final album = libraryState.albums.firstWhere(
      (a) => a.name.toLowerCase() == track.album.toLowerCase(),
      orElse: () => AlbumModel(
        name: track.album,
        artist: track.artist,
        tracks: [track],
      ),
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AlbumDetailScreen(album: album),
      ),
    );
  }

  void _navigateToArtist(BuildContext context, Track track) {
    if (track.artist.isEmpty || track.artist == 'Unknown Artist') return;
    final libraryState = ref.read(unifiedLibraryProvider);
    final artist = libraryState.artists.firstWhere(
      (a) => a.name.toLowerCase() == track.artist.toLowerCase(),
      orElse: () => ArtistModel(
        name: track.artist,
        tracks: [track],
        coverBytes: track.albumArtBytes,
        coverUrl: track.albumArtUrl,
      ),
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ArtistDetailScreen(artist: artist),
      ),
    );
  }

  void _handleArtworkGesture(ArtworkGestureAction action, Track? track) {
    switch (action) {
      case ArtworkGestureAction.toggleLyrics:
        setState(() {
          _showLyrics = !_showLyrics;
        });
        break;
      case ArtworkGestureAction.togglePlayPause:
        ref.read(playerControllerProvider.notifier).togglePlayPause();
        break;
      case ArtworkGestureAction.toggleFavorite:
        if (track != null) {
          ref.read(unifiedLibraryProvider.notifier).toggleFavorite(track.id);
        }
        break;
      case ArtworkGestureAction.openInspector:
        if (track != null) {
          AudioFileInspectorSheet.show(context, track);
        }
        break;
      case ArtworkGestureAction.openProQStudio:
        widget.onOpenProQStudio();
        break;
      case ArtworkGestureAction.openDspRack:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const DspRackScreen()),
        );
        break;
      case ArtworkGestureAction.openQueue:
        NowPlayingQueueSheet.show(context);
        break;
      case ArtworkGestureAction.viewFullArtwork:
        if (track != null) {
          StudioArtworkLightbox.show(
            context,
            track: track,
            bytes: track.albumArtBytes,
            url: track.albumArtUrl,
            title: track.title,
            subtitle: track.artist,
            formatTag: track.format.name.toUpperCase(),
          );
        }
        break;
      case ArtworkGestureAction.none:
        break;
    }
  }

  void _showOptionsSheet(Track? track) {
    AppHaptics.lightImpact();
    NowPlayingOptionsSheet.show(
      context: context,
      track: track,
      onOpenProQStudio: widget.onOpenProQStudio,
      onOpenSpeedPitch: () => PlaybackSpeedPitchSheet.show(context),
      onOpenDeskMode: () => StudioDeskDockingScreen.show(context),
      onOpenSleepTimer: () => SleepTimerSheet.show(context),
      onOpenInspector: () {
        if (track != null) AudioFileInspectorSheet.show(context, track);
      },
      onToggleLyrics: () => setState(() => _showLyrics = !_showLyrics),
      onOpenFile: _pickAndPlayFile,
      onOpenLightbox: () {
        if (track != null) {
          StudioArtworkLightbox.show(
            context,
            track: track,
            bytes: track.albumArtBytes,
            url: track.albumArtUrl,
            title: track.title,
            subtitle: track.artist,
            formatTag: track.format.name.toUpperCase(),
          );
        }
      },
      isLyricsActive: _showLyrics,
    );
  }

  @override
  Widget build(BuildContext context) {
    final track = ref.watch(playerControllerProvider.select((s) => s.currentTrack));
    final status = ref.watch(playerControllerProvider.select((s) => s.status));
    final isShuffle = ref.watch(playerControllerProvider.select((s) => s.isShuffle));
    final repeatMode = ref.watch(playerControllerProvider.select((s) => s.repeatMode));
    final playbackSpeed = ref.watch(playerControllerProvider.select((s) => s.playbackSpeed));
    final pitchSemitones = ref.watch(playerControllerProvider.select((s) => s.pitchSemitones));
    final queue = ref.watch(playerControllerProvider.select((s) => s.queue));
    final queueIndex = ref.watch(playerControllerProvider.select((s) => s.queueIndex));

    final playback = PlaybackState(
      status: status,
      currentTrack: track,
      isShuffle: isShuffle,
      repeatMode: repeatMode,
      playbackSpeed: playbackSpeed,
      pitchSemitones: pitchSemitones,
      queue: queue,
      queueIndex: queueIndex,
    );

    final sleepTimer = ref.watch(sleepTimerControllerProvider);
    final isFav = ref.watch(unifiedLibraryProvider.select((s) => track != null && s.favoriteTrackIds.contains(track.id)));
    final libraryController = ref.read(unifiedLibraryProvider.notifier);
    final displaySettings = ref.watch(playerCustomizationProvider);
    final eqState = ref.watch(eqControllerProvider);

    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    // Auto-fetch lyrics when track changes
    if (track != null && track.id != _loadedTrackId && !_isLoadingLyrics) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchLyrics(track);
      });
    }

    final isOled = displaySettings.backdropMode == NowPlayingBackdropMode.pureBlackOled;
    final isGlow = displaySettings.backdropMode == NowPlayingBackdropMode.albumArtGlow;
    final scaffoldBg = isOled ? const Color(0xFF000000) : theme.scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: Stack(
        children: [
          if (isGlow && track != null)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.35),
                      radius: 0.85,
                      colors: [
                        primary.withValues(alpha: 0.15 * displaySettings.ambientGlowIntensity),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final desktopMode = ref.watch(desktopLayoutModeProvider);
                final isForcedMobile = desktopMode == DesktopLayoutMode.mobile;
                final isLandscape = !isForcedMobile &&
                    (constraints.maxWidth >= 720 || constraints.maxWidth > constraints.maxHeight);

                if (isLandscape) {
                  return _buildLandscapeDualPaneLayout(
                    context,
                    playback,
                    sleepTimer,
                    track,
                    theme,
                    primary,
                    isFav,
                    libraryController,
                    displaySettings,
                    eqState,
                  );
                }

                return _buildPortraitLayout(
                  context,
                  playback,
                  sleepTimer,
                  track,
                  theme,
                  primary,
                  isFav,
                  libraryController,
                  displaySettings,
                  eqState,
                  constraints,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── PORTRAIT LAYOUT ──────────────────────────────────────────────────────
  Widget _buildPortraitLayout(
    BuildContext context,
    PlaybackState playback,
    SleepTimerState sleepTimer,
    Track? track,
    ThemeData theme,
    Color primary,
    bool isFav,
    UnifiedLibraryController libraryController,
    PlayerCustomizationSettings displaySettings,
    EqState eqState,
    BoxConstraints constraints,
  ) {
    final availableHeight = constraints.maxHeight;
    final availableWidth = constraints.maxWidth;
    final isDesktopPlatform = !kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS);

    // Generous squircle artwork prominence (approx 40% height) with responsive safeguards
    final maxArtWidth = (availableWidth - 44.0).clamp(100.0, 480.0);
    final minArtWidth = math.min(140.0, maxArtWidth);
    final albumArtSize = (availableHeight * 0.40).clamp(minArtWidth, maxArtWidth);

    final horizontalPadding = availableWidth < 340 ? 12.0 : 20.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, isDesktopPlatform ? 14.0 : 6.0, horizontalPadding, 20.0),
      child: Column(
        children: [
          // 1. Top Bar with Tracking Label & More Menu
          NowPlayingTopBar(
            track: track,
            onCollapse: widget.onCollapse,
            isLandscape: false,
            isFavorite: isFav,
            sleepTimer: sleepTimer,
            onOptionsPressed: () => _showOptionsSheet(track),
          ),

          const SizedBox(height: 12),

          // 2. Main Center: Lyrics View (if toggled) OR Hero Squircle Album Art with Studio Engine Badge
          Expanded(
            child: _showLyrics
                ? SynchronizedLyricsView(
                    key: const ValueKey('lyrics_view'),
                    lyricsResult: _lyricsResult,
                    isLoading: _isLoadingLyrics,
                    onRefresh: track != null ? () => _fetchLyrics(track, forceOnline: true) : null,
                    trackId: track?.id,
                  )
                : LayoutBuilder(
                    builder: (context, box) {
                      final badgeHeight = 25.0;
                      final spacing = 10.0;
                      final maxArtAllowed = box.maxHeight - badgeHeight - spacing;
                      final effectiveArtSize = math.min(albumArtSize, math.max(120.0, maxArtAllowed));

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ParallaxArtworkCard(
                            track: track,
                            isPlaying: playback.isPlaying,
                            primaryColor: primary,
                            size: effectiveArtSize,
                            onSingleTap: () => _handleArtworkGesture(displaySettings.singleTapAction, track),
                            onDoubleTap: () => _handleArtworkGesture(displaySettings.doubleTapAction, track),
                            onLongPress: () => _handleArtworkGesture(displaySettings.longPressAction, track),
                          ),
                          const SizedBox(height: 10),
                          NowPlayingEngineBadge(
                            track: track,
                            primaryColor: primary,
                          ),
                        ],
                      );
                    },
                  ),
          ),

          const SizedBox(height: 16),

          // 3. Track Details Row (Heart Favorite on Left, Bold Title & Muted Artist Centered, Queue on Right)
          Row(
            children: [
              // Left: Favorite Button
              IconButton(
                onPressed: () {
                  if (track != null) {
                    AppHaptics.selectionClick();
                    libraryController.toggleFavorite(track.id);
                  }
                },
                icon: Icon(
                  LucideIcons.heart,
                  color: isFav ? primary : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  size: 22,
                ),
                tooltip: isFav ? 'Remove from Favorites' : 'Add to Favorites',
              ),

              // Center: Track Title & Artist / Album
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      track?.title ?? 'No Track Playing',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: theme.colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    if (track != null)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: InkWell(
                              onTap: () => _navigateToArtist(context, track),
                              borderRadius: BorderRadius.circular(4),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                child: Text(
                                  track.artist,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w500,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                          if (track.album.isNotEmpty) ...[
                            Text(
                              ' • ',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                              ),
                            ),
                            Flexible(
                              child: InkWell(
                                onTap: () => _navigateToAlbum(context, track),
                                borderRadius: BorderRadius.circular(4),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  child: Text(
                                    track.album,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w400,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      )
                    else
                      Text(
                        'Select music from library',
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),

              // Right: Up Next Queue Button
              IconButton(
                onPressed: () {
                  AppHaptics.lightImpact();
                  NowPlayingQueueSheet.show(context);
                },
                icon: Badge(
                  isLabelVisible: playback.queue.isNotEmpty,
                  label: Text('${playback.queue.length}'),
                  backgroundColor: primary,
                  textColor: theme.colorScheme.onPrimary,
                  smallSize: 8,
                  child: Icon(
                    LucideIcons.listMusic,
                    size: 22,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                tooltip: 'Up Next Queue',
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 4. Waveform / Time Bar
          const _NowPlayingIsolatedProgressBar(),

          const SizedBox(height: 12),

          // 5. Main Playback Controls Deck
          NowPlayingControlsDeck(
            isPlaying: playback.isPlaying,
            isLoading: playback.isLoading,
            isShuffle: playback.isShuffle,
            repeatMode: playback.repeatMode,
            primaryColor: primary,
            onPlayPause: () =>
                ref.read(playerControllerProvider.notifier).togglePlayPause(),
            onSkipNext: () =>
                ref.read(playerControllerProvider.notifier).skipNext(),
            onSkipPrevious: () =>
                ref.read(playerControllerProvider.notifier).skipPrevious(),
            onSeekForward: () =>
                ref.read(playerControllerProvider.notifier).seekForward(),
            onSeekBackward: () =>
                ref.read(playerControllerProvider.notifier).seekBackward(),
            onToggleShuffle: () =>
                ref.read(playerControllerProvider.notifier).toggleShuffle(),
            onToggleRepeat: () =>
                ref.read(playerControllerProvider.notifier).toggleRepeatMode(),
          ),

          const SizedBox(height: 12),

          // 6. Minimalist Studio Auxiliary Bottom Row
          NowPlayingAuxiliaryBar(
            track: track,
            eqState: eqState,
            onOpenProQStudio: widget.onOpenProQStudio,
            onOpenDspRack: widget.onOpenDspRack,
            isTablet: false,
            showLyrics: _showLyrics,
            onToggleLyrics: () => setState(() => _showLyrics = !_showLyrics),
          ),
        ],
      ),
    );
  }

  // ─── LANDSCAPE / TABLET DUAL-PANE WORKSTATION LAYOUT ───────────────────────
  Widget _buildLandscapeDualPaneLayout(
    BuildContext context,
    PlaybackState playback,
    SleepTimerState sleepTimer,
    Track? track,
    ThemeData theme,
    Color primary,
    bool isFav,
    UnifiedLibraryController libraryController,
    PlayerCustomizationSettings displaySettings,
    EqState eqState,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 4.0, bottom: 12.0),
      child: Row(
        children: [
          // LEFT PANE (45%): Playback Deck, Hero Squircle Artwork, Track Info, Sliders
          Expanded(
            flex: 5,
            child: Column(
              children: [
                // 1. Top Bar with Bespoke Tracking Header & Actions
                NowPlayingTopBar(
                  track: track,
                  onCollapse: widget.onCollapse,
                  isLandscape: true,
                  isFavorite: isFav,
                  onToggleFavorite: track != null ? () => libraryController.toggleFavorite(track.id) : null,
                  sleepTimer: sleepTimer,
                  onOptionsPressed: () => _showOptionsSheet(track),
                ),

                const SizedBox(height: 4),

                // 2. Main Center Hero Artwork & Info (Dynamically Scaled & Uncluttered)
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final maxArtwork = math.min(constraints.maxHeight - 88.0, constraints.maxWidth - 32.0);
                      final minArtwork = math.min(100.0, maxArtwork);
                      final artworkSize = (maxArtwork > minArtwork ? maxArtwork : minArtwork).clamp(minArtwork, 260.0);

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ParallaxArtworkCard(
                            track: track,
                            isPlaying: playback.isPlaying,
                            primaryColor: primary,
                            size: artworkSize,
                            onSingleTap: () => _handleArtworkGesture(displaySettings.singleTapAction, track),
                            onDoubleTap: () => _handleArtworkGesture(displaySettings.doubleTapAction, track),
                            onLongPress: () => _handleArtworkGesture(displaySettings.longPressAction, track),
                          ),
                          const SizedBox(height: 8),
                          NowPlayingEngineBadge(
                            track: track,
                            primaryColor: primary,
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              track?.title ?? 'No Track Playing',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.2,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 3),
                          if (track != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: InkWell(
                                onTap: () => _navigateToAlbum(context, track),
                                borderRadius: BorderRadius.circular(4),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  child: Text(
                                    '${track.artist}${track.album.isNotEmpty ? ' • ${track.album}' : ''}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.onSurfaceVariant,
                                      letterSpacing: 0.3,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(height: 4),

                // 3. Customizable Time Bar (Isolated Progress Bar)
                const _NowPlayingIsolatedProgressBar(),

                const SizedBox(height: 4),

                // 4. Main Playback Controls Deck
                NowPlayingControlsDeck(
                  isPlaying: playback.isPlaying,
                  isLoading: playback.isLoading,
                  isShuffle: playback.isShuffle,
                  repeatMode: playback.repeatMode,
                  primaryColor: primary,
                  onPlayPause: () =>
                      ref.read(playerControllerProvider.notifier).togglePlayPause(),
                  onSkipNext: () =>
                      ref.read(playerControllerProvider.notifier).skipNext(),
                  onSkipPrevious: () =>
                      ref.read(playerControllerProvider.notifier).skipPrevious(),
                  onSeekForward: () =>
                      ref.read(playerControllerProvider.notifier).seekForward(),
                  onSeekBackward: () =>
                      ref.read(playerControllerProvider.notifier).seekBackward(),
                  onToggleShuffle: () =>
                      ref.read(playerControllerProvider.notifier).toggleShuffle(),
                  onToggleRepeat: () =>
                      ref.read(playerControllerProvider.notifier).toggleRepeatMode(),
                ),

                const SizedBox(height: 6),

                // 5. Tablet Studio Auxiliary Action Bar (Interactive Workstation Trigger)
                NowPlayingAuxiliaryBar(
                  track: track,
                  eqState: eqState,
                  onOpenProQStudio: widget.onOpenProQStudio,
                  onOpenDspRack: widget.onOpenDspRack,
                  isTablet: true,
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // RIGHT PANE (55%): Multi-Tab Workstation (Up Next Queue / Lyrics / DSP Rack)
          Expanded(
            flex: 6,
            child: DualPaneWorkstationPane(
              lyricsResult: _lyricsResult,
              isLoadingLyrics: _isLoadingLyrics,
              onRefreshLyrics: track != null ? () => _fetchLyrics(track, forceOnline: true) : null,
              activeTab: _workstationTab,
              onTabChanged: (tab) => setState(() => _workstationTab = tab),
            ),
          ),
        ],
      ),
    );
  }
}

/// Isolated progress bar that exclusively listens to position & duration updates,
/// eliminating root screen rebuild cascades on high-frequency playback ticks.
class _NowPlayingIsolatedProgressBar extends ConsumerWidget {
  const _NowPlayingIsolatedProgressBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position = ref.watch(playerControllerProvider.select((s) => s.position));
    final duration = ref.watch(playerControllerProvider.select((s) => s.duration));
    final timeDisplayMode = ref.watch(playerControllerProvider.select((s) => s.timeDisplayMode));
    final timeBarStyle = ref.watch(playerCustomizationProvider.select((s) => s.timeBarStyle));
    final primary = Theme.of(context).colorScheme.primary;

    return RepaintBoundary(
      child: CustomTimeBar(
        position: position,
        duration: duration,
        style: timeBarStyle,
        primaryColor: primary,
        timeDisplayMode: timeDisplayMode,
        onToggleTimeDisplayMode: () =>
            ref.read(playerControllerProvider.notifier).toggleTimeDisplayMode(),
        onSeek: (newPos) => ref.read(playerControllerProvider.notifier).seek(newPos),
      ),
    );
  }
}

