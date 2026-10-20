import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/theme/studio_surface_theme.dart';
import '../../domain/library_collection_models.dart';
import '../controllers/library_controller.dart';
import '../widgets/batch_track_tag_editor_modal.dart';

/// Modular Presentation Tab for Library Folders View
class LibraryFoldersTab extends ConsumerWidget {
  final ScrollController scrollController;
  final double bottomPadding;
  final void Function(FolderModel folder)? onOpenFolder;
  final Widget? emptyView;

  const LibraryFoldersTab({
    super.key,
    required this.scrollController,
    required this.bottomPadding,
    this.onOpenFolder,
    this.emptyView,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryState = ref.watch(unifiedLibraryProvider);
    final folders = libraryState.folders;
    final theme = Theme.of(context);
    final isSolid = ref.isSolidStyle;

    if (folders.isEmpty) {
      return emptyView ?? const Center(child: Text('No audio folders found.'));
    }

    return Theme(
      data: theme.copyWith(
        scrollbarTheme: ScrollbarThemeData(
          thumbColor: WidgetStatePropertyAll(theme.colorScheme.primary.withValues(alpha: 0.5)),
          radius: const Radius.circular(8),
          thickness: const WidgetStatePropertyAll(4.5),
        ),
      ),
      child: Scrollbar(
        controller: scrollController,
        thumbVisibility: true,
        interactive: true,
        child: ListView.builder(
          controller: scrollController,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(14, 4, 14, bottomPadding),
          itemCount: folders.length,
          itemBuilder: (ctx, index) {
            final folder = folders[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: StudioSurfaceTheme.surface(context, isSolid: isSolid),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: StudioSurfaceTheme.tintedContainer(
                        context,
                        theme.colorScheme.primary,
                        isSolid: isSolid,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      LucideIcons.folder,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    folder.name,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  subtitle: Text(
                    '${folder.path} • ${folder.trackCount} Tracks',
                    style: const TextStyle(fontSize: 10.5),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Batch Edit Folder Tags',
                        icon: Icon(
                          LucideIcons.pencil,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        onPressed: () {
                          BatchTrackTagEditorModal.show(context, folder.tracks);
                        },
                      ),
                      Icon(
                        LucideIcons.chevronRight,
                        size: 16,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ],
                  ),
                  onTap: () => onOpenFolder?.call(folder),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
