import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../player/domain/track.dart';
import '../../player/presentation/controllers/player_controller.dart';
import '../../navidrome/domain/subsonic_models.dart';
import '../../navidrome/presentation/widgets/navidrome_connect_dialog.dart';
import 'controllers/library_controller.dart';

/// Halaman Pustaka Terpadu (Unified Library: Offline Local + Navidrome Cloud)
class UnifiedLibraryScreen extends ConsumerStatefulWidget {
  const UnifiedLibraryScreen({super.key});

  @override
  ConsumerState<UnifiedLibraryScreen> createState() => _UnifiedLibraryScreenState();
}

class _UnifiedLibraryScreenState extends ConsumerState<UnifiedLibraryScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final libraryState = ref.watch(unifiedLibraryProvider);
    final controller = ref.read(unifiedLibraryProvider.notifier);
    final playback = ref.watch(playerControllerProvider);
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    final filteredTracks = libraryState.filteredTracks;
    final isNavidromeConnected =
        libraryState.navidromeConnectionStatus == NavidromeConnectionStatus.connected;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: primaryColor.withValues(alpha: 0.4)),
              ),
              child: Icon(Icons.library_music_rounded, color: primaryColor, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'UNIFIED LIBRARY',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                Text(
                  '${libraryState.totalTracksCount} Lagu • Offline & Navidrome Cloud',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Navidrome Cloud Server Connection Button
          IconButton(
            icon: Icon(
              isNavidromeConnected ? Icons.cloud_done_rounded : Icons.cloud_outlined,
              color: isNavidromeConnected ? const Color(0xFF00E676) : theme.colorScheme.onSurface,
            ),
            tooltip: 'Navidrome Server Settings',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const NavidromeConnectDialog(),
              );
            },
          ),
          // Local Folder Scanner Button
          IconButton(
            icon: const Icon(Icons.folder_open_rounded),
            tooltip: 'Pindai Musik Lokal',
            onPressed: () => controller.scanLocalMusic(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // 1. Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => controller.setSearchQuery(val),
              decoration: InputDecoration(
                hintText: 'Cari judul lagu, artis, atau album...',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                ),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          controller.setSearchQuery('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? const Color(0xFF141820) : const Color(0xFFE9ECF2),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // 2. Filter Chips Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(
                    context,
                    label: 'All Sources (${libraryState.totalTracksCount})',
                    filter: LibrarySourceFilter.all,
                    currentFilter: libraryState.selectedFilter,
                    onSelected: () => controller.setFilter(LibrarySourceFilter.all),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    context,
                    label: 'Offline Local (${libraryState.offlineTracksCount})',
                    filter: LibrarySourceFilter.offline,
                    currentFilter: libraryState.selectedFilter,
                    icon: Icons.folder_rounded,
                    onSelected: () => controller.setFilter(LibrarySourceFilter.offline),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    context,
                    label: 'Navidrome Cloud (${libraryState.navidromeTracksCount})',
                    filter: LibrarySourceFilter.navidrome,
                    currentFilter: libraryState.selectedFilter,
                    icon: Icons.cloud_rounded,
                    onSelected: () => controller.setFilter(LibrarySourceFilter.navidrome),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    context,
                    label: 'Hi-Res Lossless (${libraryState.hiResTracksCount})',
                    filter: LibrarySourceFilter.hiRes,
                    currentFilter: libraryState.selectedFilter,
                    icon: Icons.stars_rounded,
                    accentColor: const Color(0xFFFFB74D),
                    onSelected: () => controller.setFilter(LibrarySourceFilter.hiRes),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // 3. Track List or Empty State
          Expanded(
            child: filteredTracks.isEmpty
                ? _buildEmptyState(context, libraryState, controller)
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 120),
                    itemCount: filteredTracks.length,
                    itemBuilder: (context, index) {
                      final track = filteredTracks[index];
                      final isCurrentTrack = playback.currentTrack?.id == track.id;

                      return _buildTrackTile(
                        context,
                        track: track,
                        isPlaying: isCurrentTrack && playback.isPlaying,
                        isCurrentTrack: isCurrentTrack,
                        onTap: () {
                          ref.read(playerControllerProvider.notifier).playTrack(track);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required LibrarySourceFilter filter,
    required LibrarySourceFilter currentFilter,
    required VoidCallback onSelected,
    IconData? icon,
    Color? accentColor,
  }) {
    final theme = Theme.of(context);
    final isSelected = filter == currentFilter;
    final color = accentColor ?? theme.colorScheme.primary;

    return FilterChip(
      selected: isSelected,
      showCheckmark: false,
      avatar: icon != null
          ? Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.black : color,
            )
          : null,
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 11.5,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? Colors.black : theme.colorScheme.onSurface.withValues(alpha: 0.8),
      ),
      selectedColor: color,
      backgroundColor: theme.colorScheme.surface,
      side: BorderSide(
        color: isSelected ? color : theme.colorScheme.onSurface.withValues(alpha: 0.15),
        width: 1,
      ),
      onSelected: (_) => onSelected(),
    );
  }

  Widget _buildTrackTile(
    BuildContext context, {
    required Track track,
    required bool isPlaying,
    required bool isCurrentTrack,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    final isOffline = track.filePath != null && track.filePath!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isCurrentTrack
            ? primaryColor.withValues(alpha: 0.12)
            : (isDark ? const Color(0xFF141720) : const Color(0xFFF1F3F8)),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrentTrack
              ? primaryColor.withValues(alpha: 0.5)
              : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
          width: isCurrentTrack ? 1.5 : 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isCurrentTrack ? primaryColor.withValues(alpha: 0.2) : const Color(0xFF1E2330),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isCurrentTrack ? primaryColor : Colors.white12,
              width: 1,
            ),
          ),
          child: Center(
            child: isPlaying
                ? Icon(Icons.graphic_eq_rounded, color: primaryColor, size: 22)
                : Icon(
                    isOffline ? Icons.folder_rounded : Icons.cloud_rounded,
                    color: isCurrentTrack ? primaryColor : Colors.white54,
                    size: 20,
                  ),
          ),
        ),
        title: Text(
          track.title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isCurrentTrack ? primaryColor : theme.colorScheme.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            // Hi-Res Badge
            if (track.isHiRes) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB74D).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFFFB74D), width: 0.8),
                ),
                child: Text(
                  track.hiResBadgeText,
                  style: const TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: Color(0xFFFFB74D),
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ] else ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  track.format.name.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 8.5,
                    fontFamily: 'monospace',
                    color: Colors.white70,
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: Text(
                '${track.artist} • ${track.album}',
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatDuration(track.duration),
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
              color: isCurrentTrack ? primaryColor : theme.colorScheme.onSurface.withValues(alpha: 0.4),
              size: 28,
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    UnifiedLibraryState state,
    UnifiedLibraryController controller,
  ) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.music_off_rounded,
              size: 56,
              color: primaryColor.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              state.searchQuery.isNotEmpty
                  ? 'Tidak ada lagu yang cocok dengan "${state.searchQuery}"'
                  : 'Belum Ada Lagu di Kategori Ini',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              state.selectedFilter == LibrarySourceFilter.navidrome
                  ? 'Hubungkan server Navidrome Subsonic Anda untuk streaming lossless jarak jauh.'
                  : 'Pindai folder musik perangkat untuk mendeteksi file audio FLAC, WAV, MP3, OPUS, dan DSD.',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                if (state.selectedFilter == LibrarySourceFilter.navidrome) {
                  showDialog(
                    context: context,
                    builder: (_) => const NavidromeConnectDialog(),
                  );
                } else {
                  controller.scanLocalMusic();
                }
              },
              icon: Icon(
                state.selectedFilter == LibrarySourceFilter.navidrome
                    ? Icons.add_link_rounded
                    : Icons.folder_open_rounded,
                size: 18,
              ),
              label: Text(
                state.selectedFilter == LibrarySourceFilter.navidrome
                    ? 'Hubungkan Server Navidrome'
                    : 'Pindai Folder Musik Lokal',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
