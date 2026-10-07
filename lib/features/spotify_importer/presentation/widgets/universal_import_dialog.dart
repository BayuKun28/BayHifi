import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../../../app/theme/app_haptics.dart';
import '../../../../app/theme/studio_surface_theme.dart';
import '../../../../core/widgets/studio_artwork_widget.dart';
import '../../../download_manager/presentation/controllers/download_controller.dart';
import '../../../library/domain/library_collection_models.dart';
import '../../../library/presentation/controllers/library_controller.dart';
import '../../../player/presentation/controllers/player_controller.dart';
import '../../../youtube_music/data/youtube_music_service.dart';
import '../../data/spotify_metadata_service.dart';
import '../../domain/spotify_models.dart';

/// Material 3 Expressive Universal Import Dialog for Spotify & YouTube URLs
class UniversalImportDialog extends ConsumerStatefulWidget {
  final String? initialUrl;

  const UniversalImportDialog({
    super.key,
    this.initialUrl,
  });

  static Future<void> show(BuildContext context, {String? initialUrl}) {
    return showDialog(
      context: context,
      builder: (_) => UniversalImportDialog(initialUrl: initialUrl),
    );
  }

  @override
  ConsumerState<UniversalImportDialog> createState() =>
      _UniversalImportDialogState();
}

class _UniversalImportDialogState extends ConsumerState<UniversalImportDialog> {
  late final TextEditingController _urlController;
  bool _isLoading = false;
  String? _errorMessage;
  UniversalImportPreview? _preview;
  String _detectedSource = ''; // 'spotify' or 'youtube'

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.initialUrl ?? '');
    if (widget.initialUrl != null && widget.initialUrl!.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _resolveUrl());
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _resolveUrl() async {
    final raw = _urlController.text.trim();
    if (raw.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _preview = null;
    });

    try {
      if (raw.contains('spotify.com') || raw.startsWith('spotify:')) {
        _detectedSource = 'spotify';
        final preview = await SpotifyMetadataService.instance.resolveUrl(raw);
        if (!mounted) return;
        if (preview != null) {
          setState(() {
            _preview = preview;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'Could not resolve Spotify content. Please check the URL.';
            _isLoading = false;
          });
        }
      } else if (raw.contains('youtube.com') || raw.contains('youtu.be')) {
        _detectedSource = 'youtube';
        // Resolve YouTube Playlist or Video via YouTubeMusicService
        final ytTracks = await YouTubeMusicService.instance.search(raw, limit: 100);
        if (!mounted) return;

        if (ytTracks.isNotEmpty) {
          final totalDur = ytTracks.fold<Duration>(
            Duration.zero,
            (prev, t) => prev + t.duration,
          );
          final first = ytTracks.first;

          final preview = UniversalImportPreview(
            type: ytTracks.length > 1 ? SpotifyItemType.playlist : SpotifyItemType.track,
            title: ytTracks.length > 1 ? (first.album.isNotEmpty ? first.album : 'YouTube Playlist') : first.title,
            subtitle: ytTracks.length > 1
                ? '${ytTracks.length} tracks • YouTube Music'
                : '${first.artist} • YouTube',
            coverUrl: first.albumArtUrl,
            trackCount: ytTracks.length,
            totalDuration: totalDur,
            tracks: ytTracks
                .map((t) => SpotifyTrack(
                      id: t.id.replaceFirst('yt_', ''),
                      title: t.title,
                      artist: t.artist,
                      artists: [t.artist],
                      album: t.album,
                      duration: t.duration,
                      albumArtUrl: t.albumArtUrl,
                    ))
                .toList(),
            rawUrl: raw,
          );

          setState(() {
            _preview = preview;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'Could not find audio on YouTube. Please check the URL.';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Please enter a valid Spotify or YouTube link.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error resolving metadata: $e';
        _isLoading = false;
      });
    }
  }

  void _handleStreamNow() {
    if (_preview == null || _preview!.tracks.isEmpty) return;
    AppHaptics.mediumImpact();

    final bayTracks = _preview!.tracks.map((st) => st.toTrack()).toList();
    ref.read(playerControllerProvider.notifier).setQueue(bayTracks, initialIndex: 0);
    Navigator.of(context).pop();
  }

  void _handleImportPlaylist() {
    if (_preview == null || _preview!.tracks.isEmpty) return;
    AppHaptics.mediumImpact();

    final bayTracks = _preview!.tracks.map((st) => st.toTrack()).toList();
    final playlist = PlaylistModel(
      id: 'import_${DateTime.now().millisecondsSinceEpoch}',
      name: _preview!.title,
      description: _preview!.subtitle,
      tracks: bayTracks,
      isCustom: true,
      createdAt: DateTime.now(),
      sourceType: _detectedSource,
      coverUrl: _preview!.coverUrl,
    );

    ref.read(unifiedLibraryProvider.notifier).importStreamingPlaylist(playlist);
    Navigator.of(context).pop();
  }

  void _handleDownloadAll() {
    if (_preview == null || _preview!.tracks.isEmpty) return;
    AppHaptics.mediumImpact();

    final bayTracks = _preview!.tracks.map((st) => st.toTrack()).toList();
    final playlist = PlaylistModel(
      id: 'import_${DateTime.now().millisecondsSinceEpoch}',
      name: _preview!.title,
      description: _preview!.subtitle,
      tracks: bayTracks,
      isCustom: true,
      createdAt: DateTime.now(),
      sourceType: _detectedSource,
      coverUrl: _preview!.coverUrl,
    );

    ref.read(unifiedLibraryProvider.notifier).importStreamingPlaylist(playlist);
    ref.read(downloadControllerProvider.notifier).enqueueTracks(bayTracks);
    Navigator.of(context).pop();
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (h > 0) {
      return '$h hr $m min';
    }
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSolid = ref.isSolidStyle;
    final primary = theme.colorScheme.primary;

    return Dialog(
      backgroundColor: StudioSurfaceTheme.surface(context, isSolid: isSolid),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid),
          width: 1,
        ),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── HEADER ───────────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: StudioSurfaceTheme.tintedContainer(
                        context,
                        primary,
                        isSolid: isSolid,
                        translucentAlpha: 0.16,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedLink01,
                      size: 20,
                      color: primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'IMPORT SPOTIFY & YOUTUBE',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Paste track, album, or playlist links to stream or download',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ─── URL INPUT ────────────────────────────────────────────────
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: StudioSurfaceTheme.surfaceContainerLow(context, isSolid: isSolid),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedSearch01,
                      size: 18,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _urlController,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'https://open.spotify.com/... or https://youtube.com/...',
                          hintStyle: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onSubmitted: (_) => _resolveUrl(),
                      ),
                    ),
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: M3EProgressIndicator.circular(strokeWidth: 2),
                        ),
                      )
                    else
                      M3EIconButton(
                        icon: const HugeIcon(
                          icon: HugeIcons.strokeRoundedArrowRight01,
                          size: 18,
                          color: Colors.grey,
                        ),
                        onPressed: _resolveUrl,
                      ),
                  ],
                ),
              ),

              // ─── ERROR STATE ──────────────────────────────────────────────
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedAlertCircle,
                        size: 16,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // ─── PREVIEW CARD ─────────────────────────────────────────────
              if (_preview != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: StudioSurfaceTheme.surfaceContainer(context, isSolid: isSolid),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 64,
                          height: 64,
                          child: StudioArtworkWidget(
                            url: _preview!.coverUrl,
                            width: 64,
                            height: 64,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _detectedSource == 'spotify'
                                        ? const Color(0xFF1DB954).withValues(alpha: 0.2)
                                        : StudioCategoryColors.youtubeMusic.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    _detectedSource.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w900,
                                      color: _detectedSource == 'spotify'
                                          ? const Color(0xFF1DB954)
                                          : StudioCategoryColors.youtubeMusic,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${_preview!.trackCount} ${_preview!.trackCount == 1 ? "track" : "tracks"} • ${_formatDuration(_preview!.totalDuration)}',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                    fontFeatures: const [FontFeature.tabularFigures()],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _preview!.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _preview!.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ─── ACTION BUTTONS ─────────────────────────────────────────
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: [
                    M3EButton.outlined(
                      icon: const HugeIcon(icon: HugeIcons.strokeRoundedPlay, size: 16, color: Colors.grey),
                      label: const Text('Stream Now', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      onPressed: _handleStreamNow,
                    ),
                    M3EButton.tonal(
                      icon: HugeIcon(icon: HugeIcons.strokeRoundedPlaylist01, size: 16, color: primary),
                      label: const Text('Import Playlist', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      onPressed: _handleImportPlaylist,
                    ),
                    M3EButton.filled(
                      icon: const HugeIcon(icon: HugeIcons.strokeRoundedDownload01, size: 16, color: Colors.white),
                      label: const Text('Download All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                      onPressed: _handleDownloadAll,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
