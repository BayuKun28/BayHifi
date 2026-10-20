import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/theme/studio_surface_theme.dart';
import '../../../../core/widgets/studio_alphabetical_scroller.dart';
import '../../domain/library_collection_models.dart';
import '../controllers/library_controller.dart';
import '../widgets/artist_avatar_widget.dart';

/// Modular Presentation Tab for Library Artists View (Responsive Circular Grid / List)
class LibraryArtistsTab extends ConsumerWidget {
  final ScrollController scrollController;
  final double bottomPadding;
  final void Function(ArtistModel artist)? onOpenArtist;
  final Widget? emptyView;

  const LibraryArtistsTab({
    super.key,
    required this.scrollController,
    required this.bottomPadding,
    this.onOpenArtist,
    this.emptyView,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryState = ref.watch(unifiedLibraryProvider);
    final artists = libraryState.artists;
    final theme = Theme.of(context);
    final isSolid = ref.isSolidStyle;

    if (artists.isEmpty) {
      return emptyView ?? const Center(child: Text('No artists found.'));
    }

    if (libraryState.layoutMode == ViewLayoutMode.list) {
      return StudioAlphabeticalScroller(
        scrollController: scrollController,
        itemCount: artists.length,
        itemHeight: 72.0,
        isAlphabetical: true,
        letterSelector: (i) => i < artists.length ? artists[i].name : '',
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: ListView.builder(
          controller: scrollController,
          itemExtent: 72.0,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(14, 4, 28, bottomPadding),
          itemCount: artists.length,
          itemBuilder: (ctx, index) {
            final artist = artists[index];
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
                  leading: ArtistAvatarWidget(
                    artistName: artist.name,
                    fallbackCoverBytes: artist.coverBytes,
                    fallbackCoverUrl: artist.coverUrl,
                    radius: 22,
                    iconSize: 20,
                  ),
                  title: Text(
                    artist.name,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  subtitle: Text(
                    '${artist.albumsCount} Albums • ${artist.tracksCount} Tracks',
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: Icon(
                    LucideIcons.chevronRight,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                  onTap: () => onOpenArtist?.call(artist),
                ),
              ),
            );
          },
        ),
      );
    }

    // Responsive Grid View (3-8 Column Circular Studio Artist Presentation)
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
            final double avatarRadius;
            final double iconSize;

            if (width < 600) {
              crossAxisCount = 3;
              childAspectRatio = 0.78;
              avatarRadius = 40;
              iconSize = 32;
            } else if (width < 850) {
              crossAxisCount = 4;
              childAspectRatio = 0.86;
              avatarRadius = 44;
              iconSize = 34;
            } else if (width < 1150) {
              crossAxisCount = 6;
              childAspectRatio = 0.90;
              avatarRadius = 44;
              iconSize = 34;
            } else if (width < 1450) {
              crossAxisCount = 7;
              childAspectRatio = 0.92;
              avatarRadius = 46;
              iconSize = 36;
            } else {
              crossAxisCount = 8;
              childAspectRatio = 0.94;
              avatarRadius = 48;
              iconSize = 38;
            }

            return GridView.builder(
              controller: scrollController,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(14, 12, 14, bottomPadding),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 16,
                childAspectRatio: childAspectRatio,
              ),
              itemCount: artists.length,
              itemBuilder: (ctx, index) {
                final artist = artists[index];
                return InkWell(
                  onTap: () => onOpenArtist?.call(artist),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.18),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ArtistAvatarWidget(
                            artistName: artist.name,
                            fallbackCoverBytes: artist.coverBytes,
                            fallbackCoverUrl: artist.coverUrl,
                            radius: avatarRadius,
                            iconSize: iconSize,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          artist.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${artist.albumsCount > 0 ? "${artist.albumsCount} Alb • " : ""}${artist.tracksCount} Tracks',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            fontFeatures: const [FontFeature.tabularFigures()],
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
