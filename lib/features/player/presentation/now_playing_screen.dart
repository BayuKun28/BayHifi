import 'dart:io';
import 'dart:math' as math;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../app/theme/app_haptics.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/simple_as_f_theme.dart';
import '../../../core/widgets/meta_tracking_label.dart';
import '../../../core/widgets/studio_artwork_lightbox.dart';
import '../../../core/desktop/desktop_layout_controller.dart';
import '../../pro_q_studio/presentation/widgets/auto_eq_modal_dialog.dart';
import '../../dsp_rack/presentation/dsp_rack_screen.dart';
import '../../dsp_rack/presentation/controllers/dsp_rack_controller.dart';
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
import 'widgets/now_playing_options_sheet.dart';
import 'widgets/now_playing_queue_sheet.dart';
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
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'flac', 'wav', 'ogg', 'opus', 'aac', 'm4a', 'dsd', 'dsf', 'dff'],
    );

    if (files.isNotEmpty && files.first.path != null) {
      final file = files.first;
      final ext = file.extension?.toLowerCase() ?? '';

      AudioFormat format = AudioFormat.unknown;
      if (ext == 'flac') {
        format = AudioFormat.flac;
      } else if (ext == 'mp3') {
        format = AudioFormat.mp3;
      } else if (ext == 'wav') {
        format = AudioFormat.wav;
      } else if (ext == 'opus') {
        format = AudioFormat.opus;
      } else if (ext == 'ogg') {
        format = AudioFormat.ogg;
      } else if (ext == 'dsd' || ext == 'dsf' || ext == 'dff') {
        format = AudioFormat.dsd;
      }

      final track = Track(
        id: file.path!,
        title: file.name.replaceAll('.$ext', ''),
        artist: 'Local Audio',
        album: 'Offline Storage',
        duration: Duration.zero,
        filePath: file.path,
        format: format,
        sampleRate: format == AudioFormat.flac ? 96000 : (format == AudioFormat.dsd ? 2822400 : 44100),
        bitDepth: format == AudioFormat.flac ? 24 : 16,
      );

      await ref.read(playerControllerProvider.notifier).playTrack(track);
    }
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

  // ─── TOP HEADER BAR (Collapse, Meta Tracking Label, Sleep Timer, Options) ─
  Widget _buildMinimalistTopBar(
    BuildContext context,
    ThemeData theme,
    Color primary,
    Track? track,
    bool isFav,
    UnifiedLibraryController libraryController,
    SleepTimerState sleepTimer,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left: Back / Collapse Chevron Button
        if (widget.onCollapse != null)
          IconButton(
            onPressed: widget.onCollapse,
            icon: Icon(
              LucideIcons.chevronDown,
              size: 22,
              color: theme.colorScheme.onSurface,
            ),
            tooltip: 'Collapse to MiniPlayer',
          )
        else if (Navigator.canPop(context))
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              LucideIcons.arrowLeft,
              size: 22,
              color: theme.colorScheme.onSurface,
            ),
            tooltip: 'Back',
          )
        else
          const SizedBox(width: 48),

        // Center: Bespoke Tracking Header (Album Name & SoLoud Engine Badge)
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: MetaTrackingLabel(
                  (track != null && track.album.isNotEmpty)
                      ? track.album.toUpperCase()
                      : 'NOW PLAYING',
                  fontSize: 11,
                  letterSpacing: 1.4,
                  textAlign: TextAlign.center,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '• SOLOUD',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: primary.withValues(alpha: 0.85),
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),

        // Right Actions: Sleep Timer Pill (if active) + More Options Menu
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (sleepTimer.isActive)
              GestureDetector(
                onTap: () {
                  AppHaptics.lightImpact();
                  SleepTimerSheet.show(context);
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: SimpleAsFTheme.emeraldMint.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: SimpleAsFTheme.emeraldMint.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        LucideIcons.timer,
                        size: 14,
                        color: SimpleAsFTheme.emeraldMint,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        sleepTimer.formattedRemaining,
                        style: TextStyle(
                          fontFeatures: AppTypography.audioFigures,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: SimpleAsFTheme.emeraldMint,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // More Options Button
            IconButton(
              onPressed: () {
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
              },
              icon: Icon(
                LucideIcons.moreVertical,
                size: 22,
                color: theme.colorScheme.onSurface,
              ),
              tooltip: 'Playback Options',
            ),
          ],
        ),
      ],
    );
  }

  // ─── LANDSCAPE / TABLET TOP BAR ───────────────────────────────────────────
  Widget _buildLandscapeTopBar(
    BuildContext context,
    ThemeData theme,
    Color primary,
    Track? track,
    bool isFav,
    UnifiedLibraryController libraryController,
    SleepTimerState sleepTimer,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left: Back / Collapse Chevron Button
        if (widget.onCollapse != null)
          IconButton(
            onPressed: widget.onCollapse,
            icon: Icon(
              LucideIcons.chevronDown,
              size: 22,
              color: theme.colorScheme.onSurface,
            ),
            tooltip: 'Collapse to MiniPlayer',
          )
        else if (Navigator.canPop(context))
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              LucideIcons.arrowLeft,
              size: 22,
              color: theme.colorScheme.onSurface,
            ),
            tooltip: 'Back',
          )
        else
          const SizedBox(width: 48),

        // Center: Bespoke Tracking Header (Album Name & SoLoud Engine Badge)
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: MetaTrackingLabel(
                  (track != null && track.album.isNotEmpty)
                      ? track.album.toUpperCase()
                      : 'NOW PLAYING',
                  fontSize: 11,
                  letterSpacing: 1.4,
                  textAlign: TextAlign.center,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '• SOLOUD',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: primary.withValues(alpha: 0.85),
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),

        // Right Actions: Sleep Timer Pill (if active) + Favorite + More Options Menu
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (sleepTimer.isActive)
              GestureDetector(
                onTap: () {
                  AppHaptics.lightImpact();
                  SleepTimerSheet.show(context);
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: SimpleAsFTheme.emeraldMint.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: SimpleAsFTheme.emeraldMint.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        LucideIcons.timer,
                        size: 14,
                        color: SimpleAsFTheme.emeraldMint,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        sleepTimer.formattedRemaining,
                        style: TextStyle(
                          fontFeatures: AppTypography.audioFigures,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: SimpleAsFTheme.emeraldMint,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Favorite Button
            if (track != null)
              IconButton(
                onPressed: () {
                  AppHaptics.selectionClick();
                  libraryController.toggleFavorite(track.id);
                },
                icon: Icon(
                  LucideIcons.heart,
                  size: 20,
                  color: isFav ? const Color(0xFFFF2D55) : theme.colorScheme.onSurfaceVariant,
                ),
                tooltip: isFav ? 'Remove from Favorites' : 'Add to Favorites',
              ),

            // More Options Button
            IconButton(
              onPressed: () {
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
              },
              icon: Icon(
                LucideIcons.moreVertical,
                size: 22,
                color: theme.colorScheme.onSurface,
              ),
              tooltip: 'Playback Options',
            ),
          ],
        ),
      ],
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
          _buildMinimalistTopBar(
            context,
            theme,
            primary,
            track,
            isFav,
            libraryController,
            sleepTimer,
          ),

          const SizedBox(height: 12),

          // 2. Main Center: Lyrics View (if toggled) OR Hero Squircle Album Art
          Expanded(
            child: _showLyrics
                ? SynchronizedLyricsView(
                    key: const ValueKey('lyrics_view'),
                    lyricsResult: _lyricsResult,
                    isLoading: _isLoadingLyrics,
                    onRefresh: track != null ? () => _fetchLyrics(track, forceOnline: true) : null,
                    trackId: track?.id,
                  )
                : Center(
                    child: ParallaxArtworkCard(
                      track: track,
                      isPlaying: playback.isPlaying,
                      primaryColor: primary,
                      size: albumArtSize,
                      onSingleTap: () => _handleArtworkGesture(displaySettings.singleTapAction, track),
                      onDoubleTap: () => _handleArtworkGesture(displaySettings.doubleTapAction, track),
                      onLongPress: () => _handleArtworkGesture(displaySettings.longPressAction, track),
                    ),
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
          _buildPlaybackControlsDeck(context, playback, primary, theme),

          const SizedBox(height: 12),

          // 6. Minimalist Studio Auxiliary Bottom Row
          _buildSimpleStudioAuxiliaryBar(context, track, eqState),
        ],
      ),
    );
  }

  // ─── MAIN PLAYBACK CONTROLS DECK ──────────────────────────────────────────
  Widget _buildPlaybackControlsDeck(
    BuildContext context,
    PlaybackState playback,
    Color primary,
    ThemeData theme,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 320;
        final playSize = isCompact ? 54.0 : 64.0;
        final iconPadding = isCompact ? EdgeInsets.zero : const EdgeInsets.all(8.0);
        final iconBoxConstraints = isCompact ? const BoxConstraints(minWidth: 34, minHeight: 34) : null;
        final iconVisualDensity = isCompact ? VisualDensity.compact : null;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Shuffle
            IconButton(
              padding: iconPadding,
              constraints: iconBoxConstraints,
              visualDensity: iconVisualDensity,
              onPressed: () {
                AppHaptics.selectionClick();
                ref.read(playerControllerProvider.notifier).toggleShuffle();
              },
              icon: Icon(
                LucideIcons.shuffle,
                color: playback.isShuffle ? primary : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                size: 20,
              ),
              tooltip: 'Shuffle Playback',
            ),

            // Previous
            GestureDetector(
              onLongPress: () {
                AppHaptics.mediumImpact();
                ref.read(playerControllerProvider.notifier).seekBackward();
              },
              child: IconButton(
                padding: iconPadding,
                constraints: iconBoxConstraints,
                visualDensity: iconVisualDensity,
                onPressed: () {
                  AppHaptics.lightImpact();
                  ref.read(playerControllerProvider.notifier).skipPrevious();
                },
                icon: Icon(
                  LucideIcons.stepBack,
                  size: isCompact ? 22 : 26,
                  color: theme.colorScheme.onSurface,
                ),
                tooltip: 'Previous Track',
              ),
            ),

            // Play/Pause Centerpiece (Solid color, zero neon glow)
            GestureDetector(
              onTap: () {
                AppHaptics.mediumImpact();
                ref.read(playerControllerProvider.notifier).togglePlayPause();
              },
              child: Container(
                width: playSize,
                height: playSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primary,
                ),
                child: Center(
                  child: playback.isLoading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: theme.colorScheme.onPrimary,
                          ),
                        )
                      : Icon(
                          playback.isPlaying
                              ? LucideIcons.pause
                              : LucideIcons.play,
                          color: theme.colorScheme.onPrimary,
                          size: isCompact ? 22 : 26,
                        ),
                ),
              ),
            ),

            // Next
            GestureDetector(
              onLongPress: () {
                AppHaptics.mediumImpact();
                ref.read(playerControllerProvider.notifier).seekForward();
              },
              child: IconButton(
                padding: iconPadding,
                constraints: iconBoxConstraints,
                visualDensity: iconVisualDensity,
                onPressed: () {
                  AppHaptics.lightImpact();
                  ref.read(playerControllerProvider.notifier).skipNext();
                },
                icon: Icon(
                  LucideIcons.stepForward,
                  size: isCompact ? 22 : 26,
                  color: theme.colorScheme.onSurface,
                ),
                tooltip: 'Next Track',
              ),
            ),

            // Repeat
            IconButton(
              padding: iconPadding,
              constraints: iconBoxConstraints,
              visualDensity: iconVisualDensity,
              onPressed: () {
                AppHaptics.selectionClick();
                ref.read(playerControllerProvider.notifier).toggleRepeatMode();
              },
              icon: Icon(
                playback.repeatMode == PlaybackRepeatMode.one
                    ? LucideIcons.repeat1
                    : LucideIcons.repeat,
                color: playback.repeatMode != PlaybackRepeatMode.off
                    ? primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                size: 20,
              ),
              tooltip: 'Repeat Mode (${playback.repeatMode.name.toUpperCase()})',
            ),
          ],
        );
      },
    );
  }

  // ─── SIMPLE STUDIO AUXILIARY BAR ──────────────────────────────────────────
  Widget _buildSimpleStudioAuxiliaryBar(
    BuildContext context,
    Track? track,
    EqState eqState,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final elevatedContainer = isDark ? const Color(0xFF1E212B) : theme.colorScheme.surfaceContainerHigh;
    final outlineBorder = isDark ? const Color(0xFF2E3242) : theme.colorScheme.outlineVariant;

    final hasDriver = eqState.driverFr != null;
    final hasTarget = eqState.targetFr != null;
    final isAutoActive = eqState.isAutoEqActive || hasDriver;
    final autoEqTooltip = hasDriver
        ? 'AutoEQ: ${eqState.driverFr!.name}${hasTarget ? ' → ${eqState.targetFr!.name}' : ''}'
        : 'AutoEQ Studio & Target Matching';

    final dspState = ref.watch(dspRackControllerProvider);
    int activeDspCount = 0;
    if (!dspState.isBypassed) {
      if (dspState.tubeExciterEnabled) activeDspCount++;
      if (dspState.bassBoostEnabled) activeDspCount++;
      if (dspState.compressorEnabled) activeDspCount++;
      if (dspState.stereoWidthEnabled) activeDspCount++;
      if (dspState.crossfeedEnabled) activeDspCount++;
      if (dspState.reverbEnabled) activeDspCount++;
      if (dspState.pitchShiftEnabled) activeDspCount++;
      if (dspState.limiterEnabled) activeDspCount++;
    }
    final isDspActive = !dspState.isBypassed && activeDspCount > 0;
    final dspTooltip = isDspActive
        ? 'Mastering DSP Rack ($activeDspCount Active)'
        : (dspState.isBypassed ? 'Mastering DSP Rack (Bypassed)' : 'Mastering DSP Rack (Flat)');

    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
          // 1. Audio Specs Tag
          if (track != null) ...[
            InkWell(
              onTap: () {
                AppHaptics.lightImpact();
                AudioFileInspectorSheet.show(context, track);
              },
              borderRadius: BorderRadius.circular(9),
              child: Container(
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: elevatedContainer,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: outlineBorder, width: 1.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      track.format.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: primary,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${track.sampleRate != null ? (track.sampleRate! / 1000).toStringAsFixed(1) : '44.1'}kHz',
                      style: TextStyle(
                        fontFeatures: AppTypography.audioFigures,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // 2. Pro-Q Studio EQ (Spectrum / Frequency Curve) Icon Button
          Tooltip(
            message: eqState.isEnabled ? 'Pro-Q Studio Spectrum (Active)' : 'Pro-Q Studio Spectrum (Off)',
            child: InkWell(
              onTap: () {
                AppHaptics.selectionClick();
                widget.onOpenProQStudio();
              },
              borderRadius: BorderRadius.circular(9),
              child: Container(
                width: 38,
                height: 34,
                decoration: BoxDecoration(
                  color: eqState.isEnabled
                      ? primary.withValues(alpha: 0.16)
                      : elevatedContainer,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: eqState.isEnabled ? primary : outlineBorder,
                    width: 1.0,
                  ),
                ),
                child: Center(
                  child: Icon(
                    LucideIcons.audioLines,
                    size: 16,
                    color: eqState.isEnabled ? primary : theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 3. AutoEQ (Driver & Target Matching) Shortcut Icon Button
          Tooltip(
            message: autoEqTooltip,
            child: InkWell(
              onTap: () {
                AppHaptics.selectionClick();
                AutoEqModalDialog.show(context);
              },
              borderRadius: BorderRadius.circular(9),
              child: Container(
                width: 38,
                height: 34,
                decoration: BoxDecoration(
                  color: isAutoActive
                      ? primary.withValues(alpha: 0.16)
                      : elevatedContainer,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: isAutoActive ? primary : outlineBorder,
                    width: 1.0,
                  ),
                ),
                child: Center(
                  child: Icon(
                    LucideIcons.sparkles,
                    size: 16,
                    color: isAutoActive ? primary : theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 4. Mastering DSP Rack Shortcut Icon Button
          Tooltip(
            message: dspTooltip,
            child: InkWell(
              onTap: () {
                AppHaptics.selectionClick();
                if (widget.onOpenDspRack != null) {
                  widget.onOpenDspRack!();
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const DspRackScreen(),
                    ),
                  );
                }
              },
              borderRadius: BorderRadius.circular(9),
              child: Container(
                width: 38,
                height: 34,
                decoration: BoxDecoration(
                  color: isDspActive
                      ? primary.withValues(alpha: 0.16)
                      : elevatedContainer,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: isDspActive ? primary : outlineBorder,
                    width: 1.0,
                  ),
                ),
                child: Center(
                  child: Icon(
                    LucideIcons.slidersHorizontal,
                    size: 16,
                    color: isDspActive ? primary : theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 5. Lyrics Toggle Button with Label for Symmetry with Audio Specs Tag
          Tooltip(
            message: _showLyrics ? 'Hide Synchronized Lyrics' : 'Show Synchronized Lyrics',
            child: InkWell(
              onTap: () {
                AppHaptics.lightImpact();
                setState(() => _showLyrics = !_showLyrics);
              },
              borderRadius: BorderRadius.circular(9),
              child: Container(
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: _showLyrics
                      ? primary.withValues(alpha: 0.16)
                      : elevatedContainer,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: _showLyrics ? primary : outlineBorder,
                    width: 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.quote,
                      size: 14,
                      color: _showLyrics ? primary : theme.colorScheme.onSurface,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'LYRICS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: _showLyrics ? primary : theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),);
  }

  // ─── TABLET STUDIO AUXILIARY ACTION BAR ──────────────────────────────────
  Widget _buildTabletStudioAuxiliaryBar(
    BuildContext context,
    Track? track,
    EqState eqState,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final elevatedContainer = isDark ? const Color(0xFF1E212B) : theme.colorScheme.surfaceContainerHigh;
    final outlineBorder = isDark ? const Color(0xFF2E3242) : theme.colorScheme.outlineVariant;
    final subtleColor = theme.colorScheme.onSurfaceVariant;

    final hasDriver = eqState.driverFr != null;
    final hasTarget = eqState.targetFr != null;
    final isAutoActive = eqState.isAutoEqActive || hasDriver;
    final autoEqTooltip = hasDriver
        ? 'AutoEQ: ${eqState.driverFr!.name}${hasTarget ? ' → ${eqState.targetFr!.name}' : ''}'
        : 'AutoEQ Studio & Target Matching';

    // Format bitDepth or bitrate string
    String extraSpecs = '';
    if (track != null) {
      if (track.bitDepth != null && track.bitDepth! > 0) {
        extraSpecs = ' • ${track.bitDepth}bit';
      } else if (track.bitrate != null && track.bitrate! > 0) {
        extraSpecs = ' • ${(track.bitrate! / 1000).round()}kbps';
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ─── ROW 1: Audio Specs & Action Pills ─────────────────────────────
        Row(
          children: [
            // 1. Audio Specs Chip (Clickable for Inspector)
            if (track != null)
              InkWell(
                onTap: () {
                  AppHaptics.lightImpact();
                  AudioFileInspectorSheet.show(context, track);
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 30,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: elevatedContainer,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: outlineBorder, width: 1.0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        track.format.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: primary,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${track.sampleRate != null ? (track.sampleRate! / 1000).toStringAsFixed(1) : '44.1'}kHz$extraSpecs',
                        style: TextStyle(
                          fontFeatures: AppTypography.audioFigures,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(
                        LucideIcons.chevronRight,
                        size: 11,
                        color: subtleColor,
                      ),
                    ],
                  ),
                ),
              ),

            const Spacer(),

            // 2. Pro-Q Action Pill
            Tooltip(
              message: eqState.isEnabled ? 'Pro-Q Studio Spectrum (Active)' : 'Pro-Q Studio Spectrum (Off)',
              child: InkWell(
                onTap: () {
                  AppHaptics.selectionClick();
                  widget.onOpenProQStudio();
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 30,
                  padding: const EdgeInsets.symmetric(horizontal: 9),
                  decoration: BoxDecoration(
                    color: eqState.isEnabled
                        ? primary.withValues(alpha: 0.16)
                        : elevatedContainer,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: eqState.isEnabled ? primary : outlineBorder,
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.audioLines,
                        size: 13,
                        color: eqState.isEnabled ? primary : theme.colorScheme.onSurface,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'PRO-Q',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                          color: eqState.isEnabled ? primary : theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(width: 6),

            // 3. AutoEQ Action Pill
            Tooltip(
              message: autoEqTooltip,
              child: InkWell(
                onTap: () {
                  AppHaptics.selectionClick();
                  AutoEqModalDialog.show(context);
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 30,
                  padding: const EdgeInsets.symmetric(horizontal: 9),
                  decoration: BoxDecoration(
                    color: isAutoActive
                        ? primary.withValues(alpha: 0.16)
                        : elevatedContainer,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isAutoActive ? primary : outlineBorder,
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.sparkles,
                        size: 13,
                        color: isAutoActive ? primary : theme.colorScheme.onSurface,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'AUTO-EQ',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                          color: isAutoActive ? primary : theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 5),

        // ─── ROW 2: Subtle SoLoud Engine Branding ──────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: Image.asset(
                'assets/images/baydev_logo.png',
                width: 9,
                height: 9,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'POWERED BY SOLOUD ENGINE',
              style: TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: primary.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      ],
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
                _buildLandscapeTopBar(
                  context,
                  theme,
                  primary,
                  track,
                  isFav,
                  libraryController,
                  sleepTimer,
                ),

                const SizedBox(height: 4),

                // 2. Main Center Hero Artwork & Info (Dynamically Scaled & Uncluttered)
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final maxArtwork = math.min(constraints.maxHeight - 56.0, constraints.maxWidth - 32.0);
                      final minArtwork = math.min(120.0, maxArtwork);
                      final artworkSize = (maxArtwork > minArtwork ? maxArtwork : minArtwork).clamp(minArtwork, 275.0);

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
                          const SizedBox(height: 10),
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
                _buildPlaybackControlsDeck(context, playback, primary, theme),

                const SizedBox(height: 6),

                // 5. Tablet Studio Auxiliary Action Bar (Interactive Workstation Trigger)
                _buildTabletStudioAuxiliaryBar(context, track, eqState),
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

