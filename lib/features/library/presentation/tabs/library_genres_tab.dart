import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/theme/studio_surface_theme.dart';
import '../../domain/genre_icon_helper.dart';
import '../../domain/library_collection_models.dart';
import '../controllers/library_controller.dart';

/// Modular Presentation Tab for Library Genres View
class LibraryGenresTab extends ConsumerWidget {
  final ScrollController scrollController;
  final double bottomPadding;
  final void Function(GenreModel genre)? onOpenGenre;
  final Widget? emptyView;

  const LibraryGenresTab({
    super.key,
    required this.scrollController,
    required this.bottomPadding,
    this.onOpenGenre,
    this.emptyView,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryState = ref.watch(unifiedLibraryProvider);
    final genres = libraryState.genres;
    final theme = Theme.of(context);
    final isSolid = ref.isSolidStyle;

    if (genres.isEmpty) {
      return emptyView ?? const Center(child: Text('No genres found.'));
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
          itemCount: genres.length,
          itemBuilder: (ctx, index) {
            final genre = genres[index];
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
                      GenreIconHelper.getGenreIcon(genre.name),
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    genre.name,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  subtitle: Text(
                    '${genre.trackCount} Tracks',
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: Icon(
                    LucideIcons.chevronRight,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                  onTap: () => onOpenGenre?.call(genre),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
