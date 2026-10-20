import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_haptics.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/studio_surface_theme.dart';
import '../../../../app/theme/simple_as_f_theme.dart';
import '../../../../core/storage/storage_permission_dialog.dart';
import '../../../../core/storage/storage_permission_service.dart';
import '../../../player/domain/track.dart';
import '../../../player/presentation/controllers/player_controller.dart';
import '../../data/metadata_tagger_service.dart';
import '../controllers/library_controller.dart';
import 'online_candidate_picker_modal.dart';

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
  bool _hasManagePermission = true;

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
    _checkStoragePermission();
  }

  Future<void> _checkStoragePermission() async {
    if (kIsWeb || !Platform.isAndroid || widget.track.filePath == null) return;
    final hasManage = await StoragePermissionService.instance.hasManageExternalStoragePermission();
    if (mounted) {
      setState(() {
        _hasManagePermission = hasManage;
      });
    }
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

  Future<void> _autoFetchFromInternet() async {
    final result = await OnlineCandidatePickerModal.show(context, widget.track);
    if (result != null) {
      final c = result.candidate;
      setState(() {
        _titleController.text = c.title;
        _artistController.text = c.artist;
        _albumController.text = c.album;
        _albumArtistController.text = c.albumArtist ?? c.artist;
        if (c.genre != null && c.genre!.isNotEmpty) {
          _genreController.text = c.genre!;
        }
        if (c.year != null) {
          _yearController.text = c.year.toString();
        }
        if (c.trackNumber != null) {
          _trackNumController.text = c.trackNumber.toString();
        }
        if (c.trackTotal != null) {
          _trackTotalController.text = c.trackTotal.toString();
        }
        if (c.discNumber != null) {
          _discNumController.text = c.discNumber.toString();
        }
        if (c.discTotal != null) {
          _discTotalController.text = c.discTotal.toString();
        }
        if (result.lyrics != null && result.lyrics!.isNotEmpty) {
          _lyricsController.text = result.lyrics!;
        }
        if (result.artwork != null) {
          _artworkBytes = result.artwork!.bytes;
          _artworkMimeType = result.artwork!.mimeType;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Applied online tags & artwork from ${c.source.name.toUpperCase()} (${(c.confidenceScore * 100).round()}% match)',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
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
          AppHaptics.selectionClick();
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
    AppHaptics.selectionClick();
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

    if (Platform.isAndroid && widget.track.filePath != null) {
      final hasManage = await StoragePermissionService.instance.hasManageExternalStoragePermission();
      if (!hasManage && mounted) {
        final granted = await StoragePermissionDialog.show(
          context,
          featureName: 'Direct Physical Audio Tagging',
          rationale:
              'Baydev HiFi requires "All Files Access" to permanently embed tags and artwork directly into this audio file on disk.',
        );
        if (granted) {
          await _checkStoragePermission();
        }
      }
    }

    setState(() => _isSaving = true);
    AppHaptics.mediumImpact();

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
          borderRadius: SimpleAsFTheme.sheetTopBorderRadius,
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
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.filePen,
                            size: 20,
                            color: primary,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'STUDIO TAG EDITOR',
                              style: AppTypography.badge(color: primary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Auto-Fetch Header Action Button
                        InkWell(
                          onTap: _autoFetchFromInternet,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                            decoration: BoxDecoration(
                              color: StudioCategoryColors.warmTubeAmber.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: StudioCategoryColors.warmTubeAmber.withValues(alpha: 0.45),
                                width: 0.8,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.sparkles,
                                  size: 13,
                                  color: StudioCategoryColors.warmTubeAmber,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  'Auto-Fetch Online',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: StudioCategoryColors.warmTubeAmber,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
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
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: outline),

              // ─── STORAGE STATUS INDICATOR ─────────────────────────────────
              if (widget.track.filePath != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: InkWell(
                    onTap: _hasManagePermission
                        ? null
                        : () async {
                            final granted = await StoragePermissionDialog.show(
                              context,
                              featureName: 'Direct Physical Audio Tagging',
                            );
                            if (granted) {
                              await _checkStoragePermission();
                            }
                          },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _hasManagePermission
                            ? cs.primaryContainer.withValues(alpha: 0.25)
                            : cs.errorContainer.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _hasManagePermission
                              ? cs.primary.withValues(alpha: 0.3)
                              : cs.error.withValues(alpha: 0.4),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _hasManagePermission
                                ? LucideIcons.circleCheck
                                : LucideIcons.alertCircle,
                            size: 15,
                            color: _hasManagePermission ? cs.primary : cs.error,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _hasManagePermission
                                  ? 'Physical Tagging Active — Tags will be written permanently to disk'
                                  : 'App-Only Storage — Tap to enable All Files Access for direct file write',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: _hasManagePermission ? cs.onSurface : cs.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],

              // ─── SCROLLABLE FORM ─────────────────────────────────────────
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ─── AUTO-FETCH QUICK BANNER ─────────────────────────
                      InkWell(
                        onTap: _autoFetchFromInternet,
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
                              const Icon(
                                LucideIcons.cloudDownload,
                                size: 20,
                                color: StudioCategoryColors.warmTubeAmber,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Auto-Fill Metadata & Artwork',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                        color: StudioCategoryColors.warmTubeAmber,
                                      ),
                                    ),
                                    Text(
                                      'Fetch tags, 1400×1400 cover art, and LRCLIB lyrics from iTunes/MusicBrainz.',
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

                      // ─── ARTWORK PICKER BENTO CARD ───────────────────────
                      _buildArtworkPicker(cs, outline, primary, isSolid),
                      const SizedBox(height: 16),

                      // ─── PRIMARY TRACK DETAILS ───────────────────────────
                      _buildStudioTextField(
                        controller: _titleController,
                        label: 'TRACK TITLE',
                        icon: LucideIcons.music,
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
                              icon: LucideIcons.user,
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
                              icon: LucideIcons.users,
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
                              icon: LucideIcons.disc,
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
                              icon: LucideIcons.calendar,
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
                              icon: LucideIcons.listMusic,
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
                              icon: LucideIcons.listMusic,
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
                              icon: LucideIcons.disc,
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
                              icon: LucideIcons.layers,
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
                        icon: LucideIcons.tag,
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
                                  AppHaptics.selectionClick();
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
                        icon: LucideIcons.quote,
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
                                  Icon(
                                    LucideIcons.folder,
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
                            : Icon(
                                LucideIcons.circleCheck,
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
                    child: Icon(
                      LucideIcons.disc,
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
                            Icon(
                              LucideIcons.imagePlus,
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
                              Icon(
                                LucideIcons.trash2,
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
    required IconData icon,
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
                child: Icon(icon, size: 16, color: primaryColor),
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
