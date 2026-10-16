import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/theme/app_haptics.dart';
import '../../../../app/theme/studio_surface_theme.dart';
import '../../domain/library_collection_models.dart';
import '../controllers/library_controller.dart';

/// Material 3 Expressive Modal Sheet for Creating or Renaming Custom Playlists
class CreateCustomPlaylistModal extends ConsumerStatefulWidget {
  final PlaylistModel? initialPlaylist;

  const CreateCustomPlaylistModal({
    super.key,
    this.initialPlaylist,
  });

  static Future<void> show(
    BuildContext context, {
    PlaylistModel? initialPlaylist,
  }) {
    AppHaptics.lightImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => CreateCustomPlaylistModal(initialPlaylist: initialPlaylist),
    );
  }

  @override
  ConsumerState<CreateCustomPlaylistModal> createState() => _CreateCustomPlaylistModalState();
}

class _CreateCustomPlaylistModalState extends ConsumerState<CreateCustomPlaylistModal> {
  late final TextEditingController _nameController;
  late final TextEditingController _descController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialPlaylist?.name ?? '');
    _descController = TextEditingController(text: widget.initialPlaylist?.description ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a playlist name.')),
      );
      return;
    }

    AppHaptics.mediumImpact();
    final desc = _descController.text.trim();

    if (widget.initialPlaylist != null) {
      ref.read(unifiedLibraryProvider.notifier).renamePlaylist(
            widget.initialPlaylist!.id,
            name,
            newDescription: desc,
          );
    } else {
      ref.read(unifiedLibraryProvider.notifier).createPlaylist(name, desc);
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isSolid = ref.isSolidStyle;
    final isEditing = widget.initialPlaylist != null;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: theme.dividerColor.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: StudioSurfaceTheme.tintedContainer(
                    context,
                    primary,
                    isSolid: isSolid,
                    translucentAlpha: 0.15,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid),
                    width: 0.8,
                  ),
                ),
                child: Center(
                  child: Icon(
                    isEditing ? LucideIcons.filePen : LucideIcons.listMusic,
                    size: 18,
                    color: primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEditing ? 'EDIT PLAYLIST DETAILS' : 'CREATE NEW PLAYLIST',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isEditing
                          ? 'Update custom playlist title and studio description'
                          : 'Curate your favorite tracks and mastering sessions',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Name Input
          TextField(
            controller: _nameController,
            autofocus: true,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              labelText: 'Playlist Name',
              hintText: 'e.g. Audiophile Acoustic Sessions',
              prefixIcon: Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  LucideIcons.listMusic,
                  size: 18,
                  color: primary,
                ),
              ),
              filled: true,
              fillColor: isSolid
                  ? theme.colorScheme.surfaceContainerHighest
                  : StudioSurfaceTheme.surfaceContainerLow(context, isSolid: false),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: primary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),

          const SizedBox(height: 12),

          // Description Input
          TextField(
            controller: _descController,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              labelText: 'Description (Optional)',
              hintText: 'Master quality listening list',
              prefixIcon: Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  LucideIcons.fileText,
                  size: 18,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              filled: true,
              fillColor: isSolid
                  ? theme.colorScheme.surfaceContainerHighest
                  : StudioSurfaceTheme.surfaceContainerLow(context, isSolid: false),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: primary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),

          const SizedBox(height: 20),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(color: StudioSurfaceTheme.outline(context, isSolid: isSolid)),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _submit,
                  icon: Icon(
                    isEditing ? LucideIcons.circleCheck : LucideIcons.circlePlus,
                    size: 18,
                    color: Colors.black,
                  ),
                  label: Text(
                    isEditing ? 'Save Changes' : 'Create Playlist',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
