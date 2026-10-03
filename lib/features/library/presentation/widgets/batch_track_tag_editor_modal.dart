import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../app/theme/app_haptics.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/studio_surface_theme.dart';
import '../../../../core/storage/storage_permission_dialog.dart';
import '../../../../core/storage/storage_permission_service.dart';
import '../../../player/domain/track.dart';
import '../../../player/presentation/controllers/player_controller.dart';
import '../../data/metadata_tagger_service.dart';
import '../controllers/library_controller.dart';
import 'online_batch_auto_tagger_modal.dart';

class BatchTrackTagEditorModal extends ConsumerStatefulWidget {
  final List<Track> tracks;

  const BatchTrackTagEditorModal({super.key, required this.tracks});

  static Future<void> show(BuildContext context, List<Track> tracks) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BatchTrackTagEditorModal(tracks: tracks),
    );
  }

  @override
  ConsumerState<BatchTrackTagEditorModal> createState() => _BatchTrackTagEditorModalState();
}

class _BatchTrackTagEditorModalState extends ConsumerState<BatchTrackTagEditorModal> {
  late final List<Track> _trackList;

  late final TextEditingController _artistController;
  late final TextEditingController _albumArtistController;
  late final TextEditingController _albumController;
  late final TextEditingController _genreController;
  late final TextEditingController _yearController;
  late final TextEditingController _startTrackNumController;

  bool _applyArtist = false;
  bool _applyAlbumArtist = false;
  bool _applyAlbum = false;
  bool _applyGenre = false;
  bool _applyYear = false;
  bool _applyArtwork = false;
  bool _enableAutoNumbering = false;
  bool _applyPatternToTitles = false;
  String _selectedPattern = '%artist% - %title%';

  Uint8List? _artworkBytes;
  String? _artworkMimeType;

  bool _isProcessing = false;
  double _progress = 0.0;
  String _currentProcessingTrack = '';

  static const List<String> _genrePresets = [
    'Audiophile',
    'Classical',
    'Jazz',
    'Acoustic',
    'Rock',
    'Electronic',
    'Ambient',
    'Pop',
    'Metal',
  ];

  static const List<String> _patterns = [
    '%artist% - %title%',
    '%track% - %title%',
    '%track%. %title%',
    '%track% - %artist% - %title%',
    '%title%',
  ];

  @override
  void initState() {
    super.initState();
    _trackList = List.from(widget.tracks);

    // Populate default placeholders if all tracks share the same field
    final first = _trackList.first;
    final allSameArtist = _trackList.every((t) => t.artist == first.artist);
    final allSameAlbum = _trackList.every((t) => t.album == first.album);
    final allSameGenre = _trackList.every((t) => t.genre == first.genre && t.genre != null);
    final allSameYear = _trackList.every((t) => t.year == first.year && t.year != null);

    _artistController = TextEditingController(text: allSameArtist ? first.artist : '');
    _albumArtistController = TextEditingController(text: allSameArtist ? (first.albumArtist ?? first.artist) : '');
    _albumController = TextEditingController(text: allSameAlbum ? first.album : '');
    _genreController = TextEditingController(text: allSameGenre ? (first.genre ?? '') : '');
    _yearController = TextEditingController(text: allSameYear ? (first.year?.toString() ?? '') : '');
    _startTrackNumController = TextEditingController(text: '1');

    if (allSameArtist && first.artist.isNotEmpty) _applyArtist = true;
    if (allSameAlbum && first.album.isNotEmpty) _applyAlbum = true;
    if (allSameGenre && first.genre != null) _applyGenre = true;
    if (allSameYear && first.year != null) _applyYear = true;
  }

  @override
  void dispose() {
    _artistController.dispose();
    _albumArtistController.dispose();
    _albumController.dispose();
    _genreController.dispose();
    _yearController.dispose();
    _startTrackNumController.dispose();
    super.dispose();
  }

  Future<void> _pickArtwork() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.image,
      );

      if (files.isNotEmpty) {
        final path = files.first.path;
        if (path != null) {
          final file = File(path);
          final bytes = await file.readAsBytes();
          final isPng = path.toLowerCase().endsWith('.png');
          setState(() {
            _artworkBytes = bytes;
            _artworkMimeType = isPng ? 'image/png' : 'image/jpeg';
            _applyArtwork = true;
          });
          AppHaptics.selectionClick();
        }
      }
    } catch (e) {
      debugPrint('[BatchTrackTagEditorModal] Error picking artwork: $e');
    }
  }

  void _clearArtwork() {
    setState(() {
      _artworkBytes = null;
      _artworkMimeType = null;
      _applyArtwork = false;
    });
    AppHaptics.selectionClick();
  }

  Future<void> _executeBatchTagging() async {
    if (Platform.isAndroid) {
      final hasManage = await StoragePermissionService.instance.hasManageExternalStoragePermission();
      if (!hasManage && mounted) {
        final granted = await StoragePermissionDialog.show(
          context,
          featureName: 'Batch Physical Audio Tagging',
          rationale:
              'Baydev HiFi requires "All Files Access" to write ID3 tags directly into multiple audio files simultaneously on your device storage.',
        );
        if (granted) {
          await Future.delayed(const Duration(milliseconds: 300));
        }
      }
    }

    setState(() {
      _isProcessing = true;
      _progress = 0.0;
    });

    AppHaptics.mediumImpact();

    try {
      final items = <BatchTaggingItem>[];
      final startNum = int.tryParse(_startTrackNumController.text.trim()) ?? 1;

      for (int i = 0; i < _trackList.length; i++) {
        final track = _trackList[i];
        var tagData = AudioTagData.fromTrack(track);

        // Apply shared fields if selected
        if (_applyArtist && _artistController.text.trim().isNotEmpty) {
          tagData = tagData.copyWith(artist: _artistController.text.trim());
        }
        if (_applyAlbumArtist && _albumArtistController.text.trim().isNotEmpty) {
          tagData = tagData.copyWith(albumArtist: _albumArtistController.text.trim());
        }
        if (_applyAlbum && _albumController.text.trim().isNotEmpty) {
          tagData = tagData.copyWith(album: _albumController.text.trim());
        }
        if (_applyGenre && _genreController.text.trim().isNotEmpty) {
          tagData = tagData.copyWith(genre: _genreController.text.trim());
        }
        if (_applyYear) {
          final yr = int.tryParse(_yearController.text.trim());
          if (yr != null) {
            tagData = tagData.copyWith(year: yr);
          }
        }
        if (_applyArtwork && _artworkBytes != null) {
          tagData = tagData.copyWith(
            artworkBytes: _artworkBytes,
            artworkMimeType: _artworkMimeType,
          );
        }

        // Apply Auto-Numbering if enabled
        if (_enableAutoNumbering) {
          tagData = tagData.copyWith(
            trackNumber: startNum + i,
            trackTotal: _trackList.length,
          );
        }

        // Apply Pattern to Title if enabled
        if (_applyPatternToTitles && track.filePath != null) {
          final fileName = track.filePath!.split(Platform.pathSeparator).last;
          final nameWithoutExt = fileName.contains('.')
              ? fileName.substring(0, fileName.lastIndexOf('.'))
              : fileName;
          final parsed = TagPatternParser.parse(nameWithoutExt, _selectedPattern);
          if (parsed.containsKey('title') && parsed['title']!.isNotEmpty) {
            tagData = tagData.copyWith(title: parsed['title']);
          }
          if (parsed.containsKey('artist') && parsed['artist']!.isNotEmpty && !_applyArtist) {
            tagData = tagData.copyWith(artist: parsed['artist']);
          }
        }

        items.add(BatchTaggingItem(track: track, tagData: tagData));
      }

      final result = await ref
          .read(unifiedLibraryProvider.notifier)
          .updateBatchTracksTags(
            items,
            onProgress: (current, total, currentFile) {
              if (mounted) {
                setState(() {
                  _progress = current / total;
                  _currentProcessingTrack = currentFile;
                });
              }
            },
          );

      // Sync active player if any updated track is in queue or currently playing
      ref.read(playerControllerProvider.notifier).updateBatchTracksMetadata(result.updatedTracks);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully updated tags for ${result.successCount} tracks.',
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Batch tagging notice: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final primary = cs.primary;
    final isSolid = ref.isSolidStyle;
    final surfaceContainer = StudioSurfaceTheme.surfaceContainer(context, isSolid: isSolid);
    final outline = StudioSurfaceTheme.outline(context, isSolid: isSolid);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
        decoration: BoxDecoration(
          color: surfaceContainer,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: outline, width: 1.0),
          boxShadow: const [
            BoxShadow(
              color: Colors.black87,
              blurRadius: 32,
              offset: Offset(0, -6),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ─── DRAG HANDLE ─────────────────────────────────────────────
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.outlineVariant.withAlpha(120),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ─── HEADER BAR ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedLayers01,
                          size: 20,
                          color: primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'BATCH TAG EDITOR',
                          style: AppTypography.badge(color: primary),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: StudioSurfaceTheme.surfaceContainerLow(context, isSolid: isSolid),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: outline, width: 0.8),
                      ),
                      child: Text(
                        '${_trackList.length} TRACKS SELECTED',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: primary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: outline),

              // ─── BODY / FORM OR PROCESSING STATE ─────────────────────────
              Flexible(
                child: _isProcessing
                    ? _buildProcessingState(cs, primary, isSolid)
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ─── ONLINE BATCH AUTO-TAGGER QUICK ACCESS ─────
                            InkWell(
                              onTap: () {
                                Navigator.of(context).pop();
                                OnlineBatchAutoTaggerModal.show(context, _trackList);
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: StudioSurfaceTheme.tintedContainer(
                                    context,
                                    StudioCategoryColors.warmTubeAmber,
                                    isSolid: isSolid,
                                    solidBlendAlpha: 0.16,
                                    translucentAlpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: StudioCategoryColors.warmTubeAmber.withValues(alpha: 0.35),
                                    width: 0.8,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const HugeIcon(
                                      icon: HugeIcons.strokeRoundedSparkles,
                                      size: 20,
                                      color: StudioCategoryColors.warmTubeAmber,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Auto-Match All from Internet',
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.bold,
                                              color: StudioCategoryColors.warmTubeAmber,
                                            ),
                                          ),
                                          Text(
                                            'Automatically query iTunes & MusicBrainz for these ${_trackList.length} tracks.',
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              color: cs.onSurfaceVariant.withValues(alpha: 0.8),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 14,
                                      color: StudioCategoryColors.warmTubeAmber,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // ─── SHARED COVER ART BENTO ────────────────────
                            _buildSharedArtworkCard(cs, outline, primary, isSolid),
                            const SizedBox(height: 16),

                            // ─── SHARED METADATA FIELDS ────────────────────
                            _buildSectionHeader('COMMON TAGS (APPLY TO ALL)', HugeIcons.strokeRoundedEdit02, primary),
                            const SizedBox(height: 8),

                            _buildCheckboxField(
                              label: 'ALBUM ARTIST',
                              controller: _albumArtistController,
                              icon: HugeIcons.strokeRoundedUserGroup,
                              isChecked: _applyAlbumArtist,
                              onChanged: (val) => setState(() => _applyAlbumArtist = val ?? false),
                              cs: cs,
                              outline: outline,
                              primary: primary,
                              isSolid: isSolid,
                            ),
                            const SizedBox(height: 10),

                            _buildCheckboxField(
                              label: 'TRACK ARTIST',
                              controller: _artistController,
                              icon: HugeIcons.strokeRoundedUser,
                              isChecked: _applyArtist,
                              onChanged: (val) => setState(() => _applyArtist = val ?? false),
                              cs: cs,
                              outline: outline,
                              primary: primary,
                              isSolid: isSolid,
                            ),
                            const SizedBox(height: 10),

                            _buildCheckboxField(
                              label: 'ALBUM NAME',
                              controller: _albumController,
                              icon: HugeIcons.strokeRoundedAlbum01,
                              isChecked: _applyAlbum,
                              onChanged: (val) => setState(() => _applyAlbum = val ?? false),
                              cs: cs,
                              outline: outline,
                              primary: primary,
                              isSolid: isSolid,
                            ),
                            const SizedBox(height: 10),

                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: _buildCheckboxField(
                                    label: 'GENRE',
                                    controller: _genreController,
                                    icon: HugeIcons.strokeRoundedTag01,
                                    isChecked: _applyGenre,
                                    onChanged: (val) => setState(() => _applyGenre = val ?? false),
                                    cs: cs,
                                    outline: outline,
                                    primary: primary,
                                    isSolid: isSolid,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: _buildCheckboxField(
                                    label: 'YEAR',
                                    controller: _yearController,
                                    icon: HugeIcons.strokeRoundedCalendar03,
                                    isChecked: _applyYear,
                                    onChanged: (val) => setState(() => _applyYear = val ?? false),
                                    cs: cs,
                                    outline: outline,
                                    primary: primary,
                                    keyboardType: TextInputType.number,
                                    isSolid: isSolid,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Genre presets
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: _genrePresets.map((g) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: ActionChip(
                                      label: Text(g),
                                      labelStyle: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w600,
                                        color: _genreController.text == g ? primary : cs.onSurfaceVariant,
                                      ),
                                      padding: EdgeInsets.zero,
                                      backgroundColor: _genreController.text == g
                                          ? StudioSurfaceTheme.tintedContainer(context, primary, isSolid: isSolid, translucentAlpha: 0.15, solidBlendAlpha: 0.20)
                                          : StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid),
                                      side: BorderSide(
                                        color: _genreController.text == g ? primary : outline,
                                        width: 0.8,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _genreController.text = g;
                                          _applyGenre = true;
                                        });
                                        AppHaptics.selectionClick();
                                      },
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // ─── AUTO NUMBERING BENTO ──────────────────────
                            _buildAutoNumberingCard(cs, outline, primary, isSolid),
                            const SizedBox(height: 16),

                            // ─── FILENAME PATTERN TAGGER ───────────────────
                            _buildPatternTaggerCard(cs, outline, primary, isSolid),
                            const SizedBox(height: 16),

                            // ─── TRACK ORDER REORDERABLE PREVIEW ───────────
                            _buildSectionHeader('SELECTED TRACKS QUEUE', HugeIcons.strokeRoundedPlaylist01, primary),
                            const SizedBox(height: 8),
                            _buildTracksPreviewList(cs, outline, primary, isSolid),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
              ),

              // ─── BOTTOM ACTION BUTTONS ───────────────────────────────────
              if (!_isProcessing) ...[
                Divider(height: 1, color: outline),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: outline),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed: _executeBatchTagging,
                          icon: HugeIcon(
                            icon: HugeIcons.strokeRoundedCheckmarkCircle01,
                            size: 16,
                            color: cs.onPrimary,
                          ),
                          label: Text(
                            'Apply to ${_trackList.length} Tracks',
                            style: TextStyle(
                              color: cs.onPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: primary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, dynamic icon, Color primary) {
    return Row(
      children: [
        HugeIcon(icon: icon, size: 14, color: primary),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            color: primary,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }

  Widget _buildSharedArtworkCard(ColorScheme cs, Color outline, Color primary, bool isSolid) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: StudioSurfaceTheme.surfaceContainerLow(context, isSolid: isSolid),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: outline, width: 0.8),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: outline, width: 0.8),
            ),
            clipBehavior: Clip.antiAlias,
            child: _artworkBytes != null
                ? Image.memory(_artworkBytes!, fit: BoxFit.cover)
                : Center(
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedAlbum01,
                      size: 26,
                      color: cs.onSurfaceVariant.withAlpha(120),
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
                    Text(
                      'BATCH COVER ARTWORK',
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const Spacer(),
                    Checkbox(
                      value: _applyArtwork,
                      activeColor: primary,
                      onChanged: _artworkBytes != null
                          ? (val) => setState(() => _applyArtwork = val ?? false)
                          : null,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
                Text(
                  _artworkBytes != null
                      ? 'Custom artwork selected (Apply to all)'
                      : 'No batch cover chosen',
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    InkWell(
                      onTap: _pickArtwork,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: StudioSurfaceTheme.tintedContainer(context, primary, isSolid: isSolid, translucentAlpha: 0.15, solidBlendAlpha: 0.20),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: primary.withAlpha(80), width: 0.8),
                        ),
                        child: Text(
                          'Pick Image',
                          style: TextStyle(
                            color: primary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    if (_artworkBytes != null) ...[
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: _clearArtwork,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: outline, width: 0.8),
                          ),
                          child: Text(
                            'Remove',
                            style: TextStyle(
                              color: cs.error,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoNumberingCard(ColorScheme cs, Color outline, Color primary, bool isSolid) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: StudioSurfaceTheme.surfaceContainerLow(context, isSolid: isSolid),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: outline, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedPlaylist01,
                size: 16,
                color: primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'AUTO-NUMBERING SEQUENCER',
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Switch(
                value: _enableAutoNumbering,
                onChanged: (val) => setState(() => _enableAutoNumbering = val),
              ),
            ],
          ),
          if (_enableAutoNumbering) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Start from track index:',
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 60,
                  height: 36,
                  child: TextField(
                    controller: _startTrackNumController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: outline),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Total: ${_trackList.length} tracks',
                  style: TextStyle(
                    color: primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPatternTaggerCard(ColorScheme cs, Color outline, Color primary, bool isSolid) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: StudioSurfaceTheme.surfaceContainerLow(context, isSolid: isSolid),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: outline, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedTextFont,
                size: 16,
                color: primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'EXTRACT TITLE FROM FILENAME',
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Switch(
                value: _applyPatternToTitles,
                onChanged: (val) => setState(() => _applyPatternToTitles = val),
              ),
            ],
          ),
          if (_applyPatternToTitles) ...[
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedPattern,
              dropdownColor: StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: outline),
                ),
              ),
              items: _patterns.map((p) {
                return DropdownMenuItem(
                  value: p,
                  child: Text(
                    p,
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 11.5,
                      fontFamily: 'monospace',
                    ),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedPattern = val);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTracksPreviewList(ColorScheme cs, Color outline, Color primary, bool isSolid) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 180),
      decoration: BoxDecoration(
        color: StudioSurfaceTheme.surfaceContainerLow(context, isSolid: isSolid),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: outline, width: 0.8),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: _trackList.length,
        separatorBuilder: (_, _) => Divider(height: 1, color: outline.withAlpha(20)),
        itemBuilder: (context, index) {
          final t = _trackList[index];
          final trackNum = _enableAutoNumbering
              ? ((int.tryParse(_startTrackNumController.text.trim()) ?? 1) + index)
              : (t.trackNumber ?? (index + 1));

          return ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            leading: Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: outline, width: 0.8),
              ),
              child: Text(
                '$trackNum',
                style: TextStyle(
                  color: primary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            title: Text(
              t.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              _applyArtist && _artistController.text.isNotEmpty
                  ? _artistController.text
                  : t.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: 10.5,
              ),
            ),
            trailing: HugeIcon(
              icon: HugeIcons.strokeRoundedCheckmarkCircle01,
              size: 16,
              color: primary.withAlpha(150),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCheckboxField({
    required String label,
    required TextEditingController controller,
    required dynamic icon,
    required bool isChecked,
    required ValueChanged<bool?> onChanged,
    required ColorScheme cs,
    required Color outline,
    required Color primary,
    required bool isSolid,
    TextInputType? keyboardType,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: StudioSurfaceTheme.surfaceContainerLow(context, isSolid: isSolid),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isChecked ? primary.withAlpha(90) : outline, width: 0.8),
      ),
      child: Row(
        children: [
          Checkbox(
            value: isChecked,
            activeColor: primary,
            onChanged: onChanged,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          const SizedBox(width: 4),
          HugeIcon(icon: icon, size: 16, color: isChecked ? primary : cs.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              enabled: isChecked,
              style: TextStyle(
                color: isChecked ? cs.onSurface : cs.onSurfaceVariant.withAlpha(120),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                isDense: true,
                hintText: label,
                hintStyle: TextStyle(
                  color: cs.onSurfaceVariant.withAlpha(100),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                border: InputBorder.none,
              ),
              onChanged: (_) {
                if (!isChecked) onChanged(true);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingState(ColorScheme cs, Color primary, bool isSolid) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: CircularProgressIndicator(
              value: _progress > 0 ? _progress : null,
              strokeWidth: 4,
              color: primary,
              backgroundColor: StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'WRITING METADATA TAGS',
            style: TextStyle(
              color: primary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Processing: $_currentProcessingTrack',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '${(_progress * 100).toStringAsFixed(0)}% Completed',
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 11,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
