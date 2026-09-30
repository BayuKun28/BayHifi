import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import '../../../app/theme/app_haptics.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/studio_surface_theme.dart';
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
import 'widgets/now_playing_queue_sheet.dart';
import 'widgets/parallax_artwork_card.dart';
import 'widgets/playback_speed_pitch_sheet.dart';
import 'widgets/sleep_timer_sheet.dart';
import 'widgets/spectrum_visualizer.dart';
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
      case ArtworkGestureAction.none:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final playback = ref.watch(playerControllerProvider);
    final sleepTimer = ref.watch(sleepTimerControllerProvider);
    final libraryState = ref.watch(unifiedLibraryProvider);
    final libraryController = ref.read(unifiedLibraryProvider.notifier);
    final displaySettings = ref.watch(playerCustomizationProvider);
    final eqState = ref.watch(eqControllerProvider);

    final track = playback.currentTrack;
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    final isFav = track != null && libraryState.favoriteTrackIds.contains(track.id);

    // Auto-fetch lyrics when track changes
    if (track != null && track.id != _loadedTrackId && !_isLoadingLyrics) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchLyrics(track);
      });
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
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
    );
  }

  // ─── TOP HEADER BAR (Collapse, NOW PLAYING info, Sleep Timer, Favorite) ───
  Widget _buildMinimalistTopBar(
    BuildContext context,
    ThemeData theme,
    Color primary,
    Track? track,
    bool isFav,
    UnifiedLibraryController libraryController,
    SleepTimerState sleepTimer,
  ) {
    final isSolid = ref.isSolidStyle;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left: Collapse Chevron Button
        if (widget.onCollapse != null)
          IconButton(
            onPressed: widget.onCollapse,
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedArrowDown01,
              size: 22,
              color: theme.colorScheme.onSurface,
            ),
            tooltip: 'Collapse to MiniPlayer',
          )
        else
          const SizedBox(width: 48),

        // Center: Clean Title & Format Badge
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: Image.asset(
                      'assets/images/baydev_logo.png',
                      width: 14,
                      height: 14,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'NOW PLAYING',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              if (track != null)
                Text(
                  '${track.format.name.toUpperCase()} • ${track.sampleRate ?? 44100}Hz / ${track.bitDepth ?? 16}bit',
                  style: TextStyle(
                    fontFeatures: AppTypography.audioFigures,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: track.isHiRes ? StudioCategoryColors.hiResGold : primary,
                    letterSpacing: 0.4,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              else
                Text(
                  'Studio Engine Ready',
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),

        // Right Actions: Sleep Timer + Favorite Heart
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Proportional Sleep Timer Button with Countdown Badge
            InkWell(
              onTap: () {
                AppHaptics.lightImpact();
                SleepTimerSheet.show(context);
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedHourglass,
                      size: 20,
                      color: sleepTimer.isActive
                          ? StudioCategoryColors.sleepTimer
                          : theme.colorScheme.onSurface.withValues(alpha: 0.65),
                    ),
                    if (sleepTimer.isActive) ...[
                      const SizedBox(width: 4),
                      Text(
                        sleepTimer.formattedRemaining,
                        style: TextStyle(
                          fontFeatures: AppTypography.audioFigures,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: StudioCategoryColors.sleepTimer,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 4),

            // Favorite Button
            if (track != null)
              IconButton(
                onPressed: () {
                  AppHaptics.selectionClick();
                  libraryController.toggleFavorite(track.id);
                },
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedFavourite,
                  color: isFav ? const Color(0xFFFF2D55) : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  size: 22,
                ),
                tooltip: isFav ? 'Remove from Favorites' : 'Add to Favorites',
              )
            else
              const SizedBox(width: 44),
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
          IconButton(
            onPressed: widget.onCollapse,
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedArrowDown01,
              size: 20,
              color: theme.colorScheme.onSurface,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
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
              IconButton(
                onPressed: _pickAndPlayFile,
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedFolder01,
                  size: 18,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                tooltip: 'Open Audio File',
              ),

              // 2. Playback Speed & Pitch Engine
              IconButton(
                onPressed: () {
                  AppHaptics.lightImpact();
                  PlaybackSpeedPitchSheet.show(context);
                },
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedDashboardSpeed01,
                  size: 18,
                  color: (playback.playbackSpeed != 1.0 || playback.pitchSemitones != 0.0)
                      ? primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.75),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                tooltip: 'Speed & Pitch (${playback.playbackSpeed.toStringAsFixed(1)}x)',
              ),

              // 3. Studio Desk & Car Docking Mode
              IconButton(
                onPressed: () {
                  AppHaptics.lightImpact();
                  StudioDeskDockingScreen.show(context);
                },
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedCar01,
                  size: 18,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                tooltip: 'Studio Desk & Car Mode',
              ),

              // 4. Full-Screen Pro-Q Studio Equalizer
              IconButton(
                onPressed: () {
                  AppHaptics.selectionClick();
                  widget.onOpenProQStudio();
                },
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedSlidersVertical,
                  size: 18,
                  color: primary,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                tooltip: 'Pro-Q Studio Equalizer',
              ),

              // 5. Technical Audio Specs Inspector
              if (track != null)
                IconButton(
                  onPressed: () {
                    AppHaptics.lightImpact();
                    AudioFileInspectorSheet.show(context, track);
                  },
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedInformationCircle,
                    size: 18,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
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
                IconButton(
                  onPressed: () {
                    AppHaptics.selectionClick();
                    libraryController.toggleFavorite(track.id);
                  },
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedFavourite,
                    color: isFav ? const Color(0xFFFF2D55) : theme.colorScheme.onSurface.withValues(alpha: 0.75),
                    size: 18,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
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

    // Studio Proportional Padding & Sizing Formula:
    final albumArtSize = (availableHeight * 0.355).clamp(210.0, availableWidth - 44.0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 4.0, 20.0, 24.0),
      child: Column(
        children: [
          // 1. Top Bar with Sleep Timer & Favorite
          _buildMinimalistTopBar(
            context,
            theme,
            primary,
            track,
            isFav,
            libraryController,
            sleepTimer,
          ),

          // 2. Main Center: Lyrics View (if toggled) OR (Hero Album Art + Studio DSP Bento Capsule)
          Expanded(
            child: _showLyrics
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: SynchronizedLyricsView(
                      key: const ValueKey('lyrics_view'),
                      lyricsResult: _lyricsResult,
                      currentPosition: playback.position,
                      isLoading: _isLoadingLyrics,
                      onRefresh: track != null ? () => _fetchLyrics(track, forceOnline: true) : null,
                      trackId: track?.id,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ParallaxArtworkCard(
                        track: track,
                        isPlaying: playback.isPlaying,
                        primaryColor: primary,
                        size: albumArtSize,
                        onSingleTap: () => _handleArtworkGesture(displaySettings.singleTapAction, track),
                        onDoubleTap: () => _handleArtworkGesture(displaySettings.doubleTapAction, track),
                        onLongPress: () => _handleArtworkGesture(displaySettings.longPressAction, track),
                      ),
                      const SizedBox(height: 12),

                      // Unified Studio DSP & AutoEQ Bento Capsule
                      const StudioDspBentoCapsule(),
                    ],
                  ),
          ),

          const SizedBox(height: 10),

          // 3. Track Title & Artist & Technical Specs
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                track?.title ?? 'No track currently playing',
                style: const TextStyle(
                  fontSize: 18.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.2,
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
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                    Text(
                      ' • ',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
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
                              fontSize: 12.5,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else
                Text(
                  'Tap folder icon in action strip to open files',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 5),
              // Dedicated Technical Specs Badge
              _buildAudioSpecsBanner(context, track, theme, primary),
              const SizedBox(height: 3),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
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
            ],
          ),

          const SizedBox(height: 6),

          // 4. Customizable RTA Spectrum Visualizer (Bars / Wave / Dots / Beam)
          const SpectrumVisualizer(height: 32),

          const SizedBox(height: 6),

          // 5. Customizable Time Bar (Slim / Capsule / Segmented / Waveform)
          CustomTimeBar(
            position: playback.position,
            duration: playback.duration,
            style: displaySettings.timeBarStyle,
            primaryColor: primary,
            timeDisplayMode: playback.timeDisplayMode,
            onToggleTimeDisplayMode: () =>
                ref.read(playerControllerProvider.notifier).toggleTimeDisplayMode(),
            onSeek: (newPos) => ref.read(playerControllerProvider.notifier).seek(newPos),
          ),

          const SizedBox(height: 6),

          // 6. Main Playback Controls Deck
          _buildPlaybackControlsDeck(context, playback, primary, theme),

          const SizedBox(height: 14),
          _buildBottomStudioActionStrip(context, playback, sleepTimer, track, theme, primary),
        ],
      ),
    );
  }

  // ─── MAIN PLAYBACK CONTROLS DECK ──────────────────────────────────────────
  // ─── MAIN PLAYBACK CONTROLS DECK ──────────────────────────────────────────
  Widget _buildPlaybackControlsDeck(
    BuildContext context,
    PlaybackState playback,
    Color primary,
    ThemeData theme,
  ) {
    final isSolid = ref.isSolidStyle;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Shuffle
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: playback.isShuffle
                ? StudioSurfaceTheme.tintedContainer(context, primary, isSolid: isSolid, translucentAlpha: 0.15)
                : (isSolid ? theme.colorScheme.surfaceContainer : theme.colorScheme.surfaceContainer.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              AppHaptics.selectionClick();
              ref.read(playerControllerProvider.notifier).toggleShuffle();
            },
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedShuffle,
              color: playback.isShuffle
                  ? primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.6),
              size: 20,
            ),
            tooltip: 'Shuffle Playback',
          ),
        ),

        // Previous
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: StudioSurfaceTheme.surfaceContainer(context, isSolid: isSolid),
            borderRadius: BorderRadius.circular(16),
          ),
          child: GestureDetector(
            onLongPress: () {
              AppHaptics.mediumImpact();
              ref.read(playerControllerProvider.notifier).seekBackward();
            },
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                AppHaptics.lightImpact();
                ref.read(playerControllerProvider.notifier).skipPrevious();
              },
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedPrevious,
                size: 24,
                color: theme.colorScheme.onSurface,
              ),
              tooltip: 'Previous Track',
            ),
          ),
        ),

        // Play/Pause Centerpiece
        Container(
          width: 66,
          height: 66,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: primary,
            boxShadow: [
              BoxShadow(
                color: isSolid
                    ? Colors.black.withValues(alpha: 0.25)
                    : primary.withValues(alpha: 0.35),
                blurRadius: isSolid ? 10 : 18,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            iconSize: 32,
            onPressed: () {
              AppHaptics.mediumImpact();
              ref.read(playerControllerProvider.notifier).togglePlayPause();
            },
            icon: playback.isLoading
                ? SizedBox(
                    width: 26,
                    height: 26,
                    child: M3EProgressIndicator.circular(
                      strokeWidth: 2.8,
                      color: theme.colorScheme.onPrimary,
                    ),
                  )
                : HugeIcon(
                    icon: playback.isPlaying
                        ? HugeIcons.strokeRoundedPause
                        : HugeIcons.strokeRoundedPlay,
                    color: theme.colorScheme.onPrimary,
                    size: 30,
                  ),
            tooltip: playback.isLoading
                ? 'Buffering...'
                : (playback.isPlaying ? 'Pause' : 'Play'),
          ),
        ),

        // Next
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: StudioSurfaceTheme.surfaceContainer(context, isSolid: isSolid),
            borderRadius: BorderRadius.circular(16),
          ),
          child: GestureDetector(
            onLongPress: () {
              AppHaptics.mediumImpact();
              ref.read(playerControllerProvider.notifier).seekForward();
            },
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                AppHaptics.lightImpact();
                ref.read(playerControllerProvider.notifier).skipNext();
              },
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedNext,
                size: 24,
                color: theme.colorScheme.onSurface,
              ),
              tooltip: 'Next Track',
            ),
          ),
        ),

        // Repeat
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: playback.repeatMode != PlaybackRepeatMode.off
                ? StudioSurfaceTheme.tintedContainer(context, primary, isSolid: isSolid, translucentAlpha: 0.15)
                : (isSolid ? theme.colorScheme.surfaceContainer : theme.colorScheme.surfaceContainer.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
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
                  : theme.colorScheme.onSurface.withValues(alpha: 0.6),
              size: 20,
            ),
            tooltip: 'Repeat Mode (${playback.repeatMode.name.toUpperCase()})',
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

  // ─── BOTTOM STUDIO ACTION STRIP (Open, Desk Mode, Lyric, Queue, Spec) ─────
  Widget _buildBottomStudioActionStrip(
    BuildContext context,
    PlaybackState playback,
    SleepTimerState sleepTimer,
    Track? track,
    ThemeData theme,
    Color primary,
  ) {
    final isSolid = ref.isSolidStyle;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      decoration: BoxDecoration(
        color: StudioSurfaceTheme.surfaceContainer(context, isSolid: isSolid),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 1. Open Local File
          Expanded(
            child: _buildStudioActionItem(
              icon: HugeIcons.strokeRoundedFolder01,
              label: 'Open',
              isActive: false,
              iconColor: primary,
              activeColor: primary,
              onTap: _pickAndPlayFile,
            ),
          ),

          // 2. Studio Desk & Car Docking Mode
          Expanded(
            child: _buildStudioActionItem(
              icon: HugeIcons.strokeRoundedCar01,
              label: 'Desk Mode',
              isActive: false,
              iconColor: primary,
              activeColor: primary,
              onTap: () {
                AppHaptics.lightImpact();
                StudioDeskDockingScreen.show(context);
              },
            ),
          ),

          // 3. Synchronized Lyrics Toggle
          Expanded(
            child: _buildStudioActionItem(
              icon: HugeIcons.strokeRoundedTextFont,
              label: 'Lyric',
              isActive: _showLyrics,
              iconColor: primary,
              activeColor: primary,
              onTap: () {
                AppHaptics.lightImpact();
                setState(() => _showLyrics = !_showLyrics);
              },
            ),
          ),

          // 4. Up Next Playback Queue
          Expanded(
            child: _buildStudioActionItem(
              icon: HugeIcons.strokeRoundedPlaylist01,
              label: playback.queue.isNotEmpty ? 'Queue (${playback.queue.length})' : 'Queue',
              isActive: playback.queue.isNotEmpty,
              iconColor: primary,
              activeColor: primary,
              onTap: () {
                AppHaptics.lightImpact();
                NowPlayingQueueSheet.show(context);
              },
            ),
          ),

          // 5. Speed & Pitch Semitone Engine
          Expanded(
            child: _buildStudioActionItem(
              icon: HugeIcons.strokeRoundedDashboardSpeed01,
              label: '${playback.playbackSpeed.toStringAsFixed(1)}x',
              isActive: playback.playbackSpeed != 1.0 || playback.pitchSemitones != 0.0,
              iconColor: primary,
              activeColor: primary,
              onTap: () {
                AppHaptics.lightImpact();
                PlaybackSpeedPitchSheet.show(context);
              },
            ),
          ),

          // 6. Technical Audio Specs Inspector
          Expanded(
            child: _buildStudioActionItem(
              icon: HugeIcons.strokeRoundedInformationCircle,
              label: 'Spec',
              isActive: false,
              iconColor: primary,
              activeColor: primary,
              onTap: () {
                AppHaptics.lightImpact();
                if (track != null) {
                  AudioFileInspectorSheet.show(context, track);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudioActionItem({
    required dynamic icon,
    required String label,
    required bool isActive,
    required Color activeColor,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isSolid = ref.isSolidStyle;
    final displayIconColor = isActive ? activeColor : (iconColor ?? theme.colorScheme.onSurface.withValues(alpha: 0.7));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: isActive
            ? BoxDecoration(
                color: StudioSurfaceTheme.tintedContainer(
                  context,
                  activeColor,
                  isSolid: isSolid,
                  translucentAlpha: 0.16,
                  solidBlendAlpha: 0.2,
                ),
                borderRadius: BorderRadius.circular(10),
              )
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              icon: icon,
              size: 20,
              color: displayIconColor,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontFeatures: AppTypography.audioFigures,
                fontSize: 9.5,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                color: isActive ? activeColor : theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
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
                CustomTimeBar(
                  position: playback.position,
                  duration: playback.duration,
                  style: displaySettings.timeBarStyle,
                  primaryColor: primary,
                  timeDisplayMode: playback.timeDisplayMode,
                  onToggleTimeDisplayMode: () =>
                      ref.read(playerControllerProvider.notifier).toggleTimeDisplayMode(),
                  onSeek: (newPos) => ref.read(playerControllerProvider.notifier).seek(newPos),
                ),

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
