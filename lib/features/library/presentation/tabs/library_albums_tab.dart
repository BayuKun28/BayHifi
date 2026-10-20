import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/theme/studio_surface_theme.dart';
import '../../../../core/widgets/studio_artwork_widget.dart';
import '../../domain/library_collection_models.dart';
import '../controllers/library_controller.dart';
import '../../../../core/widgets/studio_alphabetical_scroller.dart';

/// Modular Presentation Tab for Library Albums View (Responsive Grid / List)
class LibraryAlbumsTab extends ConsumerWidget {
  final ScrollController scrollController;
  final double bottomPadding;
  final void Function(AlbumModel album)? onOpenAlbum;
  final Widget? emptyView;

  const LibraryAlbumsTab({
    super.key,
    required this.scrollController,
    required this.bottomPadding,
    this.onOpenAlbum,
    this.emptyView,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryState = ref.watch(unifiedLibraryProvider);
    final albums = libraryState.albums;
    final theme = Theme.of(context);
    final isSolid = ref.isSolidStyle;

    if (albums.isEmpty) {
      return emptyView ?? const Center(child: Text('No albums found.'));
    }

    if (libraryState.layoutMode == ViewLayoutMode.list) {
      return StudioAlphabeticalScroller(
        scrollController: scrollController,
        itemCount: albums.length,
        itemHeight: 72.0,
        isAlphabetical: true,
        letterSelector: (i) => i < albums.length ? albums[i].name : '',
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: ListView.builder(
          controller: scrollController,
          itemExtent: 72.0,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(14, 4, 28, bottomPadding),
          itemCount: albums.length,
          itemBuilder: (ctx, index) {
            final album = albums[index];
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
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 46,
                      height: 46,
                      child: StudioArtworkWidget(
                        track: album.firstTrack,
                        bytes: album.coverBytes,
                        url: album.coverUrl,
                        borderRadius: BorderRadius.circular(10),
                        fallbackIcon: LucideIcons.disc,
                        fallbackIconSize: 22,
                      ),
                    ),
                  ),
                  title: Text(
                    album.name,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  subtitle: Text(
                    '${album.artist} • ${album.trackCount} tracks',
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: Icon(
                    LucideIcons.chevronRight,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                  onTap: () => onOpenAlbum?.call(album),
                ),
              ),
            );
          },
        ),
      );
    }

    // Responsive Grid View (2-6 Column Squircle) with standard Studio Scrollbar
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final int crossAxisCount;
            final double childAspectRatio;

            if (width < 600) {
              crossAxisCount = 2;
              childAspectRatio = 0.80;
            } else if (width < 840) {
              crossAxisCount = 3;
              childAspectRatio = 0.82;
            } else if (width < 1100) {
              crossAxisCount = 4;
              childAspectRatio = 0.82;
            } else if (width < 1400) {
              crossAxisCount = 5;
              childAspectRatio = 0.84;
            } else {
              crossAxisCount = 6;
              childAspectRatio = 0.84;
            }

            return GridView.builder(
              controller: scrollController,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(14, 8, 14, bottomPadding),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: childAspectRatio,
              ),
              itemCount: albums.length,
              itemBuilder: (ctx, index) {
                final album = albums[index];
                return InkWell(
                  onTap: () => onOpenAlbum?.call(album),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    decoration: BoxDecoration(
                      color: StudioSurfaceTheme.surface(context, isSolid: isSolid),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
                            ),
                            child: StudioArtworkWidget(
                              track: album.firstTrack,
                              bytes: album.coverBytes,
                              url: album.coverUrl,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
                              fallbackIconSize: 48,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                album.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                album.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${album.trackCount} Tracks',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (album.isHiRes)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: StudioSurfaceTheme.tintedContainer(
                                          context,
                                          theme.colorScheme.primary,
                                          isSolid: isSolid,
                                        ),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: Text(
                                        'HI-RES',
                                        style: TextStyle(
                                          fontSize: 8,
                                          fontWeight: FontWeight.w900,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
