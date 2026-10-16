import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_haptics.dart';
import '../../../../app/theme/simple_as_f_theme.dart';
import '../../../../core/widgets/studio_artwork_widget.dart';
import '../../../library/presentation/controllers/library_controller.dart';
import '../../../library/presentation/screens/album_detail_screen.dart';
import '../../../player/presentation/controllers/player_controller.dart';

/// 2-Column squircle grid for albums and playlists adhering to Screen 1 of Dribbble 27089924.
/// Clean, high-breathability layout with metadata displayed directly below each squircle card.
class SimpleAsFDiscoveryGrid extends ConsumerWidget {
  const SimpleAsFDiscoveryGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryState = ref.watch(unifiedLibraryProvider);
    final albums = libraryState.albums;

    if (albums.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: SimpleAsFTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.06),
            width: 0.8,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: SimpleAsFTheme.emeraldMint.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Center(
                child: Icon(
                  LucideIcons.music,
                  size: 20,
                  color: SimpleAsFTheme.emeraldMint,
                ),
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No albums indexed yet',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Scan local music folders or connect Navidrome.',
                    style: TextStyle(
                      fontSize: 11,
                      color: SimpleAsFTheme.sageSlate,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final displayAlbums = albums.take(10).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final int crossAxisCount;
        if (width >= 1200) {
          crossAxisCount = 5;
        } else if (width >= 900) {
          crossAxisCount = 4;
        } else if (width >= 600) {
          crossAxisCount = 3;
        } else {
          crossAxisCount = 2;
        }

        final count = crossAxisCount == 2
            ? (displayAlbums.length > 6 ? 6 : displayAlbums.length)
            : displayAlbums.length;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 14,
            mainAxisSpacing: 16,
            childAspectRatio: 0.78,
          ),
          itemCount: count,
      itemBuilder: (context, index) {
        final album = displayAlbums[index];
        final firstTrack = album.tracks.isNotEmpty ? album.tracks.first : null;

        return InkWell(
          onTap: () {
            AppHaptics.lightImpact();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AlbumDetailScreen(album: album),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Squircle Album Art Card
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(19),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (firstTrack != null)
                          StudioArtworkWidget(
                            track: firstTrack,
                            width: double.infinity,
                            height: double.infinity,
                            borderRadius: BorderRadius.circular(19),
                            fallbackIcon: LucideIcons.disc,
                            fallbackIconSize: 32,
                          )
                        else
                          Container(
                            color: const Color(0xFF14221A),
                            child: const Center(
                              child: Icon(
                                LucideIcons.disc,
                                size: 32,
                                color: SimpleAsFTheme.sageSlate,
                              ),
                            ),
                          ),

                        // Subtle play button overlay
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: GestureDetector(
                            onTap: () {
                              if (album.tracks.isNotEmpty) {
                                AppHaptics.mediumImpact();
                                ref.read(playerControllerProvider.notifier).setQueue(
                                  album.tracks,
                                  initialIndex: 0,
                                );
                              }
                            },
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: SimpleAsFTheme.accent(context),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.35),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  LucideIcons.play,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.onPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Title below artwork
              Text(
                album.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),

              // Subtitle / Artist below title
              Text(
                album.artist.isNotEmpty ? album.artist : '${album.tracks.length} Tracks',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: SimpleAsFTheme.sageSlate,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
      },
    );
  }
}
