import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import '../../../app/theme/app_haptics.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/simple_as_f_theme.dart';
import '../../../app/theme/studio_surface_theme.dart';
import '../../../core/widgets/meta_tracking_label.dart';
import '../../../core/widgets/studio_artwork_lightbox.dart';
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
import 'widgets/now_playing_options_sheet.dart';
import 'widgets/now_playing_queue_sheet.dart';
import 'widgets/parallax_artwork_card.dart';
import 'widgets/playback_speed_pitch_sheet.dart';
import 'widgets/sleep_timer_sheet.dart';
import 'widgets/studio_dsp_bento_capsule.dart';
import 'widgets/synchronized_lyrics_view.dart';

class NowPlayingScreen extends ConsumerStatefulWidget {
  final VoidCallback onOpenProQStudio;
  final VoidCallback? onCollapse;

  const NowPlayingScreen({
    super.key,
    required this.onOpenProQStudio,
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
    final libraryState = ref.watch(unifiedLibraryProvider);
    final libraryController = ref.read(unifiedLibraryProvider.notifier);
    final displaySettings = ref.watch(playerCustomizationProvider);
    final eqState = ref.watch(eqControllerProvider);

    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    final isFav = track != null && libraryState.favoriteTrackIds.contains(track.id);

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
                final isLandscape = constraints.maxWidth >= 720 || constraints.maxWidth > constraints.maxHeight;

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
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedArrowDown01,
              size: 22,
              color: Colors.white,
            ),
            tooltip: 'Collapse to MiniPlayer',
          )
        else if (Navigator.canPop(context))
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedArrowLeft01,
              size: 22,
              color: Colors.white,
            ),
            tooltip: 'Back',
          )
        else
          const SizedBox(width: 48),

        // Center: Bespoke Tracking Header
        Expanded(
          child: MetaTrackingLabel(
            (track != null && track.album.isNotEmpty)
                ? track.album.toUpperCase()
                : 'NOW PLAYING',
            fontSize: 11,
            letterSpacing: 1.4,
            textAlign: TextAlign.center,
            color: SimpleAsFTheme.sageSlate,
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
                      const HugeIcon(
                        icon: HugeIcons.strokeRoundedHourglass,
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
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedMoreHorizontal,
                size: 22,
                color: Colors.white,
              ),
              tooltip: 'Playback Options',
            ),
          ],
        ),
      ],
    );
  }

  // ─── LANDSCAPE TOP BAR (With Streamlined Studio Actions Toolbar) ───────────
  Widget _buildLandscapeTopBar(
    BuildContext context,
    ThemeData theme,
    Color primary,
    Track? track,
    bool isFav,
    UnifiedLibraryController libraryController,
    SleepTimerState sleepTimer,
    PlaybackState playback,
  ) {
    final isSolid = ref.isSolidStyle;
    return Row(
      children: [
        // Left: Collapse Chevron Button
        if (widget.onCollapse != null)
          M3EIconButton(
            variant: M3EIconButtonVariant.standard,
            onPressed: widget.onCollapse,
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedArrowDown01,
              size: 22,
              color: theme.colorScheme.onSurface,
            ),
            tooltip: 'Collapse to MiniPlayer',
          ),

        const SizedBox(width: 4),

        // NOW PLAYING Text
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: Image.asset(
                'assets/images/baydev_logo.png',
                width: 13,
                height: 13,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              'NOW PLAYING',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),

        const SizedBox(width: 8),

        // Relocated Studio Actions Toolbar
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
              // 1. Open Local File
              M3EIconButton(
                variant: M3EIconButtonVariant.standard,
                onPressed: _pickAndPlayFile,
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedFolder01,
                  size: 22,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                tooltip: 'Open Audio File',
              ),

              // 2. Playback Speed & Pitch Engine
              M3EIconButton(
                variant: M3EIconButtonVariant.standard,
                onPressed: () {
                  AppHaptics.lightImpact();
                  PlaybackSpeedPitchSheet.show(context);
                },
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedDashboardSpeed01,
                  size: 22,
                  color: (playback.playbackSpeed != 1.0 || playback.pitchSemitones != 0.0)
                      ? primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                tooltip: 'Speed & Pitch (${playback.playbackSpeed.toStringAsFixed(1)}x)',
              ),

              // 3. Studio Desk & Car Docking Mode
              M3EIconButton(
                variant: M3EIconButtonVariant.standard,
                onPressed: () {
                  AppHaptics.lightImpact();
                  StudioDeskDockingScreen.show(context);
                },
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedCar01,
                  size: 22,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                tooltip: 'Studio Desk & Car Mode',
              ),

              // 4. Full-Screen Pro-Q Studio Equalizer
              M3EIconButton(
                variant: M3EIconButtonVariant.standard,
                onPressed: () {
                  AppHaptics.selectionClick();
                  widget.onOpenProQStudio();
                },
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedSlidersVertical,
                  size: 22,
                  color: primary,
                ),
                tooltip: 'Pro-Q Studio Equalizer',
              ),

              // 5. Technical Audio Specs Inspector
              if (track != null)
                M3EIconButton(
                  variant: M3EIconButtonVariant.standard,
                  onPressed: () {
                    AppHaptics.lightImpact();
                    AudioFileInspectorSheet.show(context, track);
                  },
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedInformationCircle,
                    size: 22,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  tooltip: 'Audio Specs Inspector',
                ),

              // 6. Sleep Timer
              InkWell(
                onTap: () {
                  AppHaptics.lightImpact();
                  SleepTimerSheet.show(context);
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: sleepTimer.isActive
                        ? StudioSurfaceTheme.tintedContainer(
                            context,
                            StudioCategoryColors.sleepTimer,
                            isSolid: isSolid,
                            translucentAlpha: 0.16,
                            solidBlendAlpha: 0.2,
                          )
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedHourglass,
                        size: 18,
                        color: sleepTimer.isActive
                            ? StudioCategoryColors.sleepTimer
                            : theme.colorScheme.onSurface.withValues(alpha: 0.75),
                      ),
                      if (sleepTimer.isActive) ...[
                        const SizedBox(width: 3),
                        Text(
                          sleepTimer.formattedRemaining,
                          style: TextStyle(
                            fontFeatures: AppTypography.audioFigures,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: StudioCategoryColors.sleepTimer,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // 7. Favorite Button
              if (track != null)
                M3EIconButton(
                  variant: M3EIconButtonVariant.standard,
                  onPressed: () {
                    AppHaptics.selectionClick();
                    libraryController.toggleFavorite(track.id);
                  },
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedFavourite,
                    color: isFav ? const Color(0xFFFF2D55) : theme.colorScheme.onSurfaceVariant,
                    size: 22,
                  ),
                  tooltip: isFav ? 'Remove from Favorites' : 'Add to Favorites',
                ),
            ],
          ),
        ),
      ),
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

    // Generous squircle artwork prominence (approx 40% height)
    final albumArtSize = (availableHeight * 0.40).clamp(230.0, availableWidth - 44.0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 6.0, 20.0, 20.0),
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
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedFavourite,
                  color: isFav ? SimpleAsFTheme.emeraldMint : Colors.white.withValues(alpha: 0.7),
                  size: 24,
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
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: Colors.white,
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
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w500,
                                    color: SimpleAsFTheme.sageSlate,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                          if (track.album.isNotEmpty) ...[
                            const Text(
                              ' • ',
                              style: TextStyle(
                                fontSize: 12,
                                color: SimpleAsFTheme.sageSlate,
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
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w400,
                                      color: SimpleAsFTheme.sageSlate,
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
                      const Text(
                        'Select music from library',
                        style: TextStyle(
                          fontSize: 13,
                          color: SimpleAsFTheme.sageSlate,
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
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedPlaylist01,
                    size: 24,
                    color: Colors.white.withValues(alpha: 0.7),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Shuffle
        IconButton(
          onPressed: () {
            AppHaptics.selectionClick();
            ref.read(playerControllerProvider.notifier).toggleShuffle();
          },
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedShuffle,
            color: playback.isShuffle ? primary : Colors.white.withValues(alpha: 0.6),
            size: 22,
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
            onPressed: () {
              AppHaptics.lightImpact();
              ref.read(playerControllerProvider.notifier).skipPrevious();
            },
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedPrevious,
              size: 28,
              color: Colors.white,
            ),
            tooltip: 'Previous Track',
          ),
        ),

        // Play/Pause Centerpiece
        GestureDetector(
          onTap: () {
            AppHaptics.mediumImpact();
            ref.read(playerControllerProvider.notifier).togglePlayPause();
          },
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primary,
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
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
                  : HugeIcon(
                      icon: playback.isPlaying
                          ? HugeIcons.strokeRoundedPause
                          : HugeIcons.strokeRoundedPlay,
                      color: theme.colorScheme.onPrimary,
                      size: 28,
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
            onPressed: () {
              AppHaptics.lightImpact();
              ref.read(playerControllerProvider.notifier).skipNext();
            },
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedNext,
              size: 28,
              color: Colors.white,
            ),
            tooltip: 'Next Track',
          ),
        ),

        // Repeat
        IconButton(
          onPressed: () {
            AppHaptics.selectionClick();
            ref.read(playerControllerProvider.notifier).toggleRepeatMode();
          },
          icon: HugeIcon(
            icon: playback.repeatMode == PlaybackRepeatMode.one
                ? HugeIcons.strokeRoundedRepeatOne01
                : HugeIcons.strokeRoundedRepeat,
            color: playback.repeatMode != PlaybackRepeatMode.off
                ? primary
                : Colors.white.withValues(alpha: 0.6),
            size: 22,
          ),
          tooltip: 'Repeat Mode (${playback.repeatMode.name.toUpperCase()})',
        ),
      ],
    );
  }

  // ─── SIMPLE STUDIO AUXILIARY BAR ──────────────────────────────────────────
  Widget _buildSimpleStudioAuxiliaryBar(
    BuildContext context,
    Track? track,
    EqState eqState,
  ) {
    final primary = Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Audio Specs Tag
        if (track != null)
          InkWell(
            onTap: () {
              AppHaptics.lightImpact();
              AudioFileInspectorSheet.show(context, track);
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    track.format.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: track.isHiRes ? StudioCategoryColors.hiResGold : primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${track.sampleRate != null ? (track.sampleRate! / 1000).toStringAsFixed(1) : '44.1'}kHz',
                    style: const TextStyle(
                      fontFeatures: AppTypography.audioFigures,
                      fontSize: 10,
                      color: SimpleAsFTheme.sageSlate,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          const SizedBox(width: 48),

        // Center: Pro-Q EQ Button
        InkWell(
          onTap: () {
            AppHaptics.selectionClick();
            widget.onOpenProQStudio();
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: eqState.isEnabled
                  ? primary.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: eqState.isEnabled
                    ? primary.withValues(alpha: 0.3)
                    : Colors.transparent,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedSlidersVertical,
                  size: 14,
                  color: eqState.isEnabled ? primary : SimpleAsFTheme.sageSlate,
                ),
                const SizedBox(width: 5),
                Text(
                  eqState.isEnabled ? 'EQ ON' : 'EQ STUDIO',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: eqState.isEnabled ? primary : SimpleAsFTheme.sageSlate,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Right: Lyrics Toggle
        InkWell(
          onTap: () {
            AppHaptics.lightImpact();
            setState(() => _showLyrics = !_showLyrics);
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _showLyrics
                  ? SimpleAsFTheme.emeraldMint.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedTextFont,
                  size: 14,
                  color: _showLyrics ? SimpleAsFTheme.emeraldMint : SimpleAsFTheme.sageSlate,
                ),
                const SizedBox(width: 4),
                Text(
                  'LYRICS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: _showLyrics ? SimpleAsFTheme.emeraldMint : SimpleAsFTheme.sageSlate,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── AUDIO SPECS BANNER ───────────────────────────────────────────────────
  Widget _buildAudioSpecsBanner(
    BuildContext context,
    Track? track,
    ThemeData theme,
    Color primary,
  ) {
    if (track == null) return const SizedBox.shrink();
    final isSolid = ref.isSolidStyle;

    final formatStr = track.format.name.toUpperCase();
    final sampleRateStr = track.sampleRate != null
        ? '${(track.sampleRate! / 1000).toStringAsFixed(1)} kHz'
        : '44.1 kHz';
    final bitDepthStr = track.bitDepth != null ? '${track.bitDepth}-bit' : '16-bit';
    final isHiRes = track.isHiRes;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
      decoration: BoxDecoration(
        color: StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid, translucentAlpha: 0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: StudioSurfaceTheme.tintedContainer(
                  context,
                  isHiRes ? StudioCategoryColors.hiResGold : StudioCategoryColors.flacLossless,
                  isSolid: isSolid,
                  translucentAlpha: 0.18,
                  solidBlendAlpha: 0.22,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isHiRes ? 'HI-RES MASTER' : 'LOSSLESS AUDIO',
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w900,
                  color: isHiRes ? StudioCategoryColors.hiResGold : StudioCategoryColors.flacLossless,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$formatStr • $bitDepthStr / $sampleRateStr',
              style: TextStyle(
                fontFeatures: AppTypography.audioFigures,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                letterSpacing: 0.3,
              ),
            ),
            if (track.genre != null && track.genre!.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                '• ${track.genre}',
                style: TextStyle(
                  fontSize: 10.5,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ],
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          // LEFT PANE (42%): Playback Deck, Cover Art, Track Info, Sliders (Clean & Concise)
          Expanded(
            flex: 5,
            child: Column(
              children: [
                // 1. Top Bar with Relocated Studio Actions Toolbar
                _buildLandscapeTopBar(
                  context,
                  theme,
                  primary,
                  track,
                  isFav,
                  libraryController,
                  sleepTimer,
                  playback,
                ),

                const SizedBox(height: 6),

                // 2. Center Album Art & Info
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ParallaxArtworkCard(
                        track: track,
                        isPlaying: playback.isPlaying,
                        primaryColor: primary,
                        size: 125,
                        onSingleTap: () => _handleArtworkGesture(displaySettings.singleTapAction, track),
                        onDoubleTap: () => _handleArtworkGesture(displaySettings.doubleTapAction, track),
                        onLongPress: () => _handleArtworkGesture(displaySettings.longPressAction, track),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              track?.title ?? 'No Track Playing',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              track != null ? '${track.artist} • ${track.album}' : 'Select music from library',
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            _buildAudioSpecsBanner(context, track, theme, primary),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: Image.asset(
                                    'assets/images/baydev_logo.png',
                                    width: 10,
                                    height: 10,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'BAYDEV AUDIO ENGINE',
                                  style: TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            // Unified Studio DSP & AutoEQ Bento Capsule
                            const StudioDspBentoCapsule(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 4),

                // 3. Customizable Time Bar
                const _NowPlayingIsolatedProgressBar(),

                const SizedBox(height: 6),

                // 4. Main Playback Controls Deck
                _buildPlaybackControlsDeck(context, playback, primary, theme),
              ],
            ),
          ),

          const SizedBox(width: 14),

          // RIGHT PANE (58%): Multi-Tab Workstation (Up Next Queue / Lyrics / DSP Rack)
          Expanded(
            flex: 7,
            child: DualPaneWorkstationPane(
              lyricsResult: _lyricsResult,
              isLoadingLyrics: _isLoadingLyrics,
              onRefreshLyrics: track != null ? () => _fetchLyrics(track, forceOnline: true) : null,
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

