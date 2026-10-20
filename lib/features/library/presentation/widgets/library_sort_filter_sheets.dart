import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/theme/app_haptics.dart';
import '../../../../app/theme/studio_surface_theme.dart';
import '../../../../app/theme/theme_mode_controller.dart';
import '../../../player/domain/track.dart';
import '../../domain/library_collection_models.dart';
import '../controllers/library_controller.dart';
import '../controllers/library_selection_controller.dart';

/// Studio Sort & Playlist Bottom Sheets for Unified Library Screen
class LibrarySortFilterSheets {
  const LibrarySortFilterSheets._();

  /// Shows the Sort Collection Bottom Sheet with field choices and ascending/descending toggle
  static void showSortSheet(BuildContext context, WidgetRef ref) {
    final controller = ref.read(unifiedLibraryProvider.notifier);
    final theme = Theme.of(context);
    final fillStyle = ref.watch(themeControllerProvider.select((s) => s.surfaceFillStyle ?? SurfaceFillStyle.solid));
    final isSolid = fillStyle == SurfaceFillStyle.solid;

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final curState = ref.watch(unifiedLibraryProvider);
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.dividerColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'SORT COLLECTION',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                        IconButton.filledTonal(
                          onPressed: () {
                            AppHaptics.selectionClick();
                            controller.toggleSortDirection();
                            setModalState(() {});
                          },
                          icon: Icon(
                            curState.sortDirection == SortDirection.ascending
                                ? LucideIcons.arrowUp
                                : LucideIcons.arrowDown,
                            size: 18,
                            color: theme.colorScheme.onSurface,
                          ),
                          tooltip: curState.sortDirection.label,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: SortField.values.map((field) {
                        final isSelected = curState.sortField == field;
                        return ChoiceChip(
                          showCheckmark: false,
                          label: Text(field.label),
                          selected: isSelected,
                          onSelected: (val) {
                            if (val) {
                              AppHaptics.selectionClick();
                              controller.setSortField(field);
                              setModalState(() {});
                            }
                          },
                          selectedColor: theme.colorScheme.primary.withValues(alpha: 0.18),
                          backgroundColor: StudioSurfaceTheme.surfaceContainerLow(context, isSolid: isSolid),
                          side: BorderSide(
                            color: isSelected
                                ? theme.colorScheme.primary.withValues(alpha: 0.5)
                                : StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid),
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            fontSize: 12,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Shows the Add To Playlist modal for a single track or batch of tracks
  static void showAddToPlaylistSheet(BuildContext context, WidgetRef ref, List<Track> tracks) {
    final playlists = ref.read(unifiedLibraryProvider).customPlaylists;
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ADD ${tracks.length} TRACK${tracks.length > 1 ? 'S' : ''} TO PLAYLIST',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              if (playlists.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'No custom playlists found. Create a new playlist first.',
                      style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                ...playlists.map(
                  (p) => ListTile(
                    leading: Icon(
                      LucideIcons.listMusic,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(p.name),
                    subtitle: Text('${p.trackCount} tracks'),
                    onTap: () {
                      for (final t in tracks) {
                        ref.read(unifiedLibraryProvider.notifier).addTrackToPlaylist(p.id, t);
                      }
                      Navigator.of(ctx).pop();
                      ref.read(librarySelectionProvider.notifier).clear();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Added ${tracks.length} track${tracks.length > 1 ? 's' : ''} to "${p.name}".')),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
