import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/studio_surface_theme.dart';
import '../../../player/domain/track.dart';
import '../../../player/presentation/controllers/player_controller.dart';
import '../../data/metadata_tagger_service.dart';
import '../controllers/library_controller.dart';

class MetadataTagEditorSheet extends ConsumerStatefulWidget {
  final Track track;

  const MetadataTagEditorSheet({super.key, required this.track});

  static Future<void> show(BuildContext context, Track track) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MetadataTagEditorSheet(track: track),
    );
  }

  @override
  ConsumerState<MetadataTagEditorSheet> createState() => _MetadataTagEditorSheetState();
}

class _MetadataTagEditorSheetState extends ConsumerState<MetadataTagEditorSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _artistController;
  late final TextEditingController _albumController;
  late final TextEditingController _albumArtistController;
  late final TextEditingController _genreController;
  late final TextEditingController _yearController;
  late final TextEditingController _trackNumController;
  late final TextEditingController _trackTotalController;
  late final TextEditingController _discNumController;
  late final TextEditingController _discTotalController;
  late final TextEditingController _lyricsController;

  Uint8List? _artworkBytes;
  String? _artworkMimeType;
  bool _isSaving = false;

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
    'Hi-Res',
  ];

  @override
  void initState() {
    super.initState();
    final t = widget.track;
    _titleController = TextEditingController(text: t.title);
    _artistController = TextEditingController(text: t.artist);
    _albumController = TextEditingController(text: t.album);
    _albumArtistController = TextEditingController(text: t.albumArtist ?? t.artist);
    _genreController = TextEditingController(text: t.genre ?? '');
    _yearController = TextEditingController(text: t.year?.toString() ?? '');
    _trackNumController = TextEditingController(text: t.trackNumber?.toString() ?? '');
    _trackTotalController = TextEditingController(text: t.trackTotal?.toString() ?? '');
    _discNumController = TextEditingController(text: t.discNumber?.toString() ?? '');
    _discTotalController = TextEditingController(text: t.discTotal?.toString() ?? '');
    _lyricsController = TextEditingController(text: t.lyrics ?? '');
    _artworkBytes = t.albumArtBytes;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _albumController.dispose();
    _albumArtistController.dispose();
    _genreController.dispose();
    _yearController.dispose();
    _trackNumController.dispose();
    _trackTotalController.dispose();
    _discNumController.dispose();
    _discTotalController.dispose();
    _lyricsController.dispose();
    super.dispose();
  }

  Future<void> _pickNewArtwork() async {
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
          });
          HapticFeedback.selectionClick();
        }
      }
    } catch (e) {
      debugPrint('[MetadataTagEditorSheet] Error picking image: $e');
    }
  }

  void _clearArtwork() {
    setState(() {
      _artworkBytes = null;
      _artworkMimeType = null;
    });
    HapticFeedback.selectionClick();
  }

  Future<void> _saveMetadata() async {
    final newTitle = _titleController.text.trim();
    final newArtist = _artistController.text.trim();
    final newAlbum = _albumController.text.trim();

    if (newTitle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Title cannot be empty'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      final tagData = AudioTagData(
        title: newTitle,
        artist: newArtist.isNotEmpty ? newArtist : 'Unknown Artist',
        album: newAlbum.isNotEmpty ? newAlbum : 'Unknown Album',
        albumArtist: _albumArtistController.text.trim().isNotEmpty
            ? _albumArtistController.text.trim()
            : null,
        genre: _genreController.text.trim().isNotEmpty
            ? _genreController.text.trim()
            : null,
        year: int.tryParse(_yearController.text.trim()),
        trackNumber: int.tryParse(_trackNumController.text.trim()),
        trackTotal: int.tryParse(_trackTotalController.text.trim()),
        discNumber: int.tryParse(_discNumController.text.trim()),
        discTotal: int.tryParse(_discTotalController.text.trim()),
        lyrics: _lyricsController.text.trim().isNotEmpty
            ? _lyricsController.text.trim()
            : null,
        artworkBytes: _artworkBytes,
        artworkMimeType: _artworkMimeType,
        filePath: widget.track.filePath,
      );

      final updatedTrack = await ref
          .read(unifiedLibraryProvider.notifier)
          .updateTrackTags(widget.track.id, tagData, writeToFile: true);

      if (updatedTrack != null) {
        ref.read(playerControllerProvider.notifier).updateTrackMetadata(updatedTrack);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Updated metadata for "$newTitle"'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save tags: $e'),
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
          maxHeight: MediaQuery.of(context).size.height * 0.88,
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
                          icon: HugeIcons.strokeRoundedEdit02,
                          size: 20,
                          color: primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'STUDIO TAG EDITOR',
                          style: AppTypography.badge(color: primary),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: StudioSurfaceTheme.surfaceContainerLow(context, isSolid: isSolid),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: outline, width: 0.8),
                      ),
                      child: Text(
                        widget.track.hiResBadgeText,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurfaceVariant,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: outline),

              // ─── SCROLLABLE FORM ─────────────────────────────────────────
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ─── ARTWORK PICKER BENTO CARD ───────────────────────
                      _buildArtworkPicker(cs, outline, primary, isSolid),
                      const SizedBox(height: 16),

                      // ─── PRIMARY TRACK DETAILS ───────────────────────────
                      _buildStudioTextField(
                        controller: _titleController,
                        label: 'TRACK TITLE',
                        icon: HugeIcons.strokeRoundedMusicNote01,
                        primaryColor: primary,
                        colorScheme: cs,
                        outline: outline,
                        isSolid: isSolid,
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: _buildStudioTextField(
                              controller: _artistController,
                              label: 'TRACK ARTIST',
                              icon: HugeIcons.strokeRoundedUser,
                              primaryColor: primary,
                              colorScheme: cs,
                              outline: outline,
                              isSolid: isSolid,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildStudioTextField(
                              controller: _albumArtistController,
                              label: 'ALBUM ARTIST',
                              icon: HugeIcons.strokeRoundedUserGroup,
                              primaryColor: primary,
                              colorScheme: cs,
                              outline: outline,
                              isSolid: isSolid,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: _buildStudioTextField(
                              controller: _albumController,
                              label: 'ALBUM NAME',
                              icon: HugeIcons.strokeRoundedAlbum01,
                              primaryColor: primary,
                              colorScheme: cs,
                              outline: outline,
                              isSolid: isSolid,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 1,
                            child: _buildStudioTextField(
                              controller: _yearController,
                              label: 'YEAR',
                              icon: HugeIcons.strokeRoundedCalendar03,
                              primaryColor: primary,
                              colorScheme: cs,
                              outline: outline,
                              keyboardType: TextInputType.number,
                              isSolid: isSolid,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // ─── TRACK & DISC NUMBERS ────────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: _buildStudioTextField(
                              controller: _trackNumController,
                              label: 'TRACK NO.',
                              icon: HugeIcons.strokeRoundedPlaylist01,
                              primaryColor: primary,
                              colorScheme: cs,
                              outline: outline,
                              keyboardType: TextInputType.number,
                              isSolid: isSolid,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildStudioTextField(
                              controller: _trackTotalController,
                              label: 'TOTAL TRACKS',
                              icon: HugeIcons.strokeRoundedPlaylist01,
                              primaryColor: primary,
                              colorScheme: cs,
                              outline: outline,
                              keyboardType: TextInputType.number,
                              isSolid: isSolid,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildStudioTextField(
                              controller: _discNumController,
                              label: 'DISC NO.',
                              icon: HugeIcons.strokeRoundedAlbum01,
                              primaryColor: primary,
                              colorScheme: cs,
                              outline: outline,
                              keyboardType: TextInputType.number,
                              isSolid: isSolid,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildStudioTextField(
                              controller: _discTotalController,
                              label: 'TOTAL DISCS',
                              icon: HugeIcons.strokeRoundedLayers01,
                              primaryColor: primary,
                              colorScheme: cs,
                              outline: outline,
                              keyboardType: TextInputType.number,
                              isSolid: isSolid,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // ─── GENRE WITH PRESET CHIPS ─────────────────────────
                      _buildStudioTextField(
                        controller: _genreController,
                        label: 'GENRE',
                        icon: HugeIcons.strokeRoundedTag01,
                        primaryColor: primary,
                        colorScheme: cs,
                        outline: outline,
                        isSolid: isSolid,
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _genrePresets.map((g) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ActionChip(
                                label: Text(g),
                                labelStyle: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: _genreController.text == g
                                      ? primary
                                      : cs.onSurfaceVariant,
                                ),
                                padding: EdgeInsets.zero,
                                backgroundColor: _genreController.text == g
                                    ? StudioSurfaceTheme.tintedContainer(context, primary, isSolid: isSolid, translucentAlpha: 0.15, solidBlendAlpha: 0.20)
                                    : StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid),
                                side: BorderSide(
                                  color: _genreController.text == g
                                      ? primary
                                      : outline,
                                  width: 0.8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _genreController.text = g;
                                  });
                                  HapticFeedback.selectionClick();
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ─── LYRICS MULTILINE ────────────────────────────────
                      _buildStudioTextField(
                        controller: _lyricsController,
                        label: 'UNSYNCHRONIZED LYRICS',
                        icon: HugeIcons.strokeRoundedQuoteDown,
                        primaryColor: primary,
                        colorScheme: cs,
                        outline: outline,
                        maxLines: 4,
                        isSolid: isSolid,
                      ),
                      const SizedBox(height: 16),

                      // ─── TECHNICAL FILE INFO BENTO ───────────────────────
                      if (widget.track.filePath != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: StudioSurfaceTheme.surfaceContainerLow(context, isSolid: isSolid),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: outline, width: 0.8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  HugeIcon(
                                    icon: HugeIcons.strokeRoundedFolder01,
                                    size: 14,
                                    color: primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'PHYSICAL FILE TARGET',
                                    style: TextStyle(
                                      color: primary,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.track.filePath!,
                                style: TextStyle(
                                  color: cs.onSurfaceVariant,
                                  fontSize: 10,
                                  fontFamily: 'monospace',
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),

              // ─── BOTTOM ACTION BUTTONS ───────────────────────────────────
              Divider(height: 1, color: outline),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
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
                        onPressed: _isSaving ? null : _saveMetadata,
                        icon: _isSaving
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: cs.onPrimary,
                                ),
                              )
                            : HugeIcon(
                                icon: HugeIcons.strokeRoundedCheckmarkCircle01,
                                size: 16,
                                color: cs.onPrimary,
                              ),
                        label: Text(
                          _isSaving ? 'Writing Tags...' : 'Save Tags to File',
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
          ),
        ),
      ),
    );
  }

  Widget _buildArtworkPicker(ColorScheme cs, Color outline, Color primary, bool isSolid) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: StudioSurfaceTheme.surfaceContainerLow(context, isSolid: isSolid),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: outline, width: 0.8),
      ),
      child: Row(
        children: [
          // Artwork Preview Squircle
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: outline, width: 0.8),
            ),
            clipBehavior: Clip.antiAlias,
            child: _artworkBytes != null
                ? Image.memory(
                    _artworkBytes!,
                    fit: BoxFit.cover,
                  )
                : Center(
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedAlbum01,
                      size: 28,
                      color: cs.onSurfaceVariant.withAlpha(120),
                    ),
                  ),
          ),
          const SizedBox(width: 14),

          // Action buttons
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EMBEDDED COVER ART',
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _artworkBytes != null
                      ? '${(_artworkBytes!.lengthInBytes / 1024).toStringAsFixed(0)} KB Image Embedded'
                      : 'No cover art embedded in file',
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    InkWell(
                      onTap: _pickNewArtwork,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: StudioSurfaceTheme.tintedContainer(context, primary, isSolid: isSolid, translucentAlpha: 0.15, solidBlendAlpha: 0.20),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: primary.withAlpha(80), width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            HugeIcon(
                              icon: HugeIcons.strokeRoundedImageAdd01,
                              size: 13,
                              color: primary,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Pick Image',
                              style: TextStyle(
                                color: primary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_artworkBytes != null) ...[
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: _clearArtwork,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: outline, width: 0.8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              HugeIcon(
                                icon: HugeIcons.strokeRoundedDelete02,
                                size: 13,
                                color: cs.error,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Remove',
                                style: TextStyle(
                                  color: cs.error,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
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
          ),
        ],
      ),
    );
  }

  Widget _buildStudioTextField({
    required TextEditingController controller,
    required String label,
    required dynamic icon,
    required Color primaryColor,
    required ColorScheme colorScheme,
    required Color outline,
    required bool isSolid,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: StudioSurfaceTheme.surfaceContainerLow(context, isSolid: isSolid),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: outline, width: 0.8),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              prefixIcon: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: HugeIcon(icon: icon, size: 16, color: primaryColor),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 20),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}
