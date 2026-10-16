import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_haptics.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/studio_surface_theme.dart';
import '../../../player/domain/track.dart';
import '../../data/online_metadata_service.dart';
import '../controllers/library_controller.dart';

/// Modal bottom sheet for searching and selecting online metadata candidate
class OnlineCandidatePickerModal extends ConsumerStatefulWidget {
  final Track track;

  const OnlineCandidatePickerModal({super.key, required this.track});

  static Future<OnlineMetadataCandidateResult?> show(
    BuildContext context,
    Track track,
  ) {
    return showModalBottomSheet<OnlineMetadataCandidateResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => OnlineCandidatePickerModal(track: track),
    );
  }

  @override
  ConsumerState<OnlineCandidatePickerModal> createState() =>
      _OnlineCandidatePickerModalState();
}

/// Result containing selected candidate, downloaded artwork, and lyrics
class OnlineMetadataCandidateResult {
  final OnlineMetadataCandidate candidate;
  final DownloadedArtwork? artwork;
  final String? lyrics;
  final bool isLyricsSynced;

  const OnlineMetadataCandidateResult({
    required this.candidate,
    this.artwork,
    this.lyrics,
    this.isLyricsSynced = false,
  });
}

class _OnlineCandidatePickerModalState
    extends ConsumerState<OnlineCandidatePickerModal> {
  late final TextEditingController _searchController;
  bool _isLoading = true;
  bool _isApplying = false;
  String? _applyingMessage;
  List<OnlineMetadataCandidate> _candidates = const [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final initialQuery = QuerySanitizer.cleanQuery(widget.track.title);
    final artistHint = (widget.track.artist.isNotEmpty &&
            widget.track.artist.toLowerCase() != 'unknown artist')
        ? widget.track.artist
        : null;

    final fullSearchText = (artistHint != null &&
            !initialQuery.toLowerCase().contains(artistHint.toLowerCase()))
        ? '$artistHint $initialQuery'
        : initialQuery;

    _searchController = TextEditingController(text: fullSearchText);
    _performSearch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final service = ref.read(onlineMetadataServiceProvider);
      final results = await service.searchCandidates(
        query: query,
        targetDurationSeconds: widget.track.duration.inSeconds > 0
            ? widget.track.duration.inSeconds
            : null,
      );

      if (mounted) {
        setState(() {
          _candidates = results;
          _isLoading = false;
          if (results.isEmpty) {
            _errorMessage = 'No online metadata found for "$query". Try refining the query.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Search error: $e';
        });
      }
    }
  }

  Future<void> _applyCandidate(OnlineMetadataCandidate candidate) async {
    setState(() {
      _isApplying = true;
      _applyingMessage = 'Downloading high-res artwork & querying lyrics...';
    });
    AppHaptics.mediumImpact();

    DownloadedArtwork? artwork;
    String? lyrics;
    bool isSynced = false;

    try {
      final service = ref.read(onlineMetadataServiceProvider);

      // 1. Download artwork if available
      if (candidate.artworkUrl != null && candidate.artworkUrl!.isNotEmpty) {
        artwork = await service.downloadArtwork(candidate.artworkUrl!);
      }

      // 2. Fetch lyrics from LRCLIB
      final lyricsRes = await service.fetchLyrics(
        title: candidate.title,
        artist: candidate.artist,
        album: candidate.album,
        durationSeconds: candidate.durationSeconds ?? widget.track.duration.inSeconds,
      );
      lyrics = lyricsRes.lyrics;
      isSynced = lyricsRes.isSynced;
    } catch (e) {
      debugPrint('[OnlineCandidatePicker] Resource fetch error: $e');
    }

    if (mounted) {
      Navigator.of(context).pop(
        OnlineMetadataCandidateResult(
          candidate: candidate,
          artwork: artwork,
          lyrics: lyrics,
          isLyricsSynced: isSynced,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isSolid = ref.isSolidStyle;
    final primary = cs.primary;
    final mediaQuery = MediaQuery.of(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: mediaQuery.size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: StudioSurfaceTheme.surfaceContainer(context, isSolid: isSolid),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid),
          width: 1.0,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ─── MODAL DRAG HANDLE & HEADER ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 6),
            child: Container(
              width: 38,
              height: 4.5,
              decoration: BoxDecoration(
                color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: StudioCategoryColors.warmTubeAmber.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    LucideIcons.sparkles,
                    size: 18,
                    color: StudioCategoryColors.warmTubeAmber,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Online Metadata Search',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        'iTunes • MusicBrainz • Deezer • LRCLIB',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    LucideIcons.x,
                    size: 18,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // ─── SEARCH INPUT ROW ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Container(
              decoration: BoxDecoration(
                color: StudioSurfaceTheme.surfaceContainerLow(context, isSolid: isSolid),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid),
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 12, right: 8),
                    child: Icon(
                      LucideIcons.search,
                      size: 18,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(fontSize: 13.5, color: cs.onSurface),
                      decoration: const InputDecoration(
                        hintText: 'Search title, artist, or album...',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      onSubmitted: (_) => _performSearch(),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(LucideIcons.x, size: 16),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    ),
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: cs.onPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _isLoading ? null : _performSearch,
                      child: const Text('Search', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ─── CANDIDATES LIST OR LOADING STATE ──────────────────────────
          Expanded(
            child: _isApplying
                ? _buildApplyingOverlay(cs)
                : _isLoading
                    ? _buildLoadingState(cs)
                    : _errorMessage != null
                        ? _buildErrorState(cs)
                        : _buildCandidatesList(cs, isSolid),
          ),
        ],
      ),
    );
  }

  Widget _buildApplyingOverlay(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(strokeWidth: 3),
          const SizedBox(height: 16),
          Text(
            _applyingMessage ?? 'Applying metadata...',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(strokeWidth: 2.5),
          const SizedBox(height: 14),
          Text(
            'Querying online audio databases...',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.alertCircle,
              size: 36,
              color: cs.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'No metadata found',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCandidatesList(ColorScheme cs, bool isSolid) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
      itemCount: _candidates.length,
      itemBuilder: (context, index) {
        final candidate = _candidates[index];
        final matchPercent = (candidate.confidenceScore * 100).round();

        final Color confidenceColor = matchPercent >= 85
            ? StudioCategoryColors.bitPerfect
            : (matchPercent >= 65
                ? StudioCategoryColors.storageIndigo
                : StudioCategoryColors.warmTubeAmber);

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: StudioSurfaceTheme.surfaceContainerLow(context, isSolid: isSolid),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid),
              width: 0.8,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Artwork Thumbnail
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid),
                      width: 0.8,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: candidate.artworkUrl != null && candidate.artworkUrl!.isNotEmpty
                        ? Image.network(
                            candidate.artworkUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Center(
                              child: Icon(
                                LucideIcons.music,
                                size: 24,
                              ),
                            ),
                          )
                        : const Center(
                            child: Icon(
                              LucideIcons.disc,
                              size: 24,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),

                // 2. Metadata details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Source + Confidence Pill Row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: confidenceColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '$matchPercent% MATCH',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: confidenceColor,
                                fontFeatures: AppTypography.audioFigures,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              candidate.source.name.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ),
                          if (candidate.year != null) ...[
                            const SizedBox(width: 6),
                            Text(
                              '${candidate.year}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                                fontFeatures: AppTypography.audioFigures,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Track Title
                      Text(
                        candidate.title,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),

                      // Artist & Album
                      Text(
                        '${candidate.artist} • ${candidate.album}',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: cs.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      // Genre & Track Number
                      if (candidate.genre != null || candidate.trackNumber != null)
                        Text(
                          [
                            if (candidate.genre != null) candidate.genre!,
                            if (candidate.trackNumber != null)
                              'Track ${candidate.trackNumber}${candidate.trackTotal != null ? '/${candidate.trackTotal}' : ''}',
                          ].join(' • '),
                          style: TextStyle(
                            fontSize: 10.5,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.65),
                            fontFeatures: AppTypography.audioFigures,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // 3. Apply Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    minimumSize: const Size(60, 36),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => _applyCandidate(candidate),
                  child: const Text(
                    'Apply',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
