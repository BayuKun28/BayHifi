import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../../app/theme/studio_surface_theme.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/two_tone_header.dart';
import 'controllers/library_controller.dart';
import 'screens/playlist_detail_screen.dart';
import 'screens/smart_playlists_screen.dart';
import 'widgets/create_custom_playlist_modal.dart';
import 'widgets/create_smart_playlist_dialog.dart';
import 'widgets/studio_playlist_action_sheet.dart';
import '../../spotify_importer/presentation/widgets/universal_import_dialog.dart';
import '../../../core/widgets/studio_artwork_widget.dart';

/// Studio Dedicated Playlists Screen
/// Features unified Studio Collections row (Favorites, Hi-Res Masters, Dynamic Smart Playlists)
/// and Custom User Playlists with bottom action sheets and dedicated detail screens.
class PlaylistsScreen extends ConsumerStatefulWidget {
  const PlaylistsScreen({super.key});

  @override
  ConsumerState<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends ConsumerState<PlaylistsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _showCreateOptionsSheet(BuildContext context) {
    final theme = Theme.of(context);
    final isSolid = ref.isSolidStyle;
    final primary = theme.colorScheme.primary;

    showModalBottomSheet(
      context: context,
      backgroundColor: StudioSurfaceTheme.surface(context, isSolid: isSolid),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  'CREATE PLAYLIST OPTIONS',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                ),
              ),
              const SizedBox(height: 10),
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: StudioSurfaceTheme.tintedContainer(context, primary, isSolid: isSolid, translucentAlpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(LucideIcons.listMusic, size: 18, color: primary),
                ),
                title: const Text('New Custom Playlist', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                subtitle: const Text('Curate individual tracks from your library', style: TextStyle(fontSize: 11)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  CreateCustomPlaylistModal.show(context);
                },
              ),
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: StudioSurfaceTheme.tintedContainer(context, theme.colorScheme.secondary, isSolid: isSolid, translucentAlpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(LucideIcons.slidersHorizontal, size: 18, color: theme.colorScheme.secondary),
                ),
                title: const Text('New Dynamic Smart Playlist', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                subtitle: const Text('Rules auto-update based on audio codec, rating & metadata', style: TextStyle(fontSize: 11)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  CreateSmartPlaylistDialog.show(context);
                },
              ),
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: StudioSurfaceTheme.tintedContainer(context, const Color(0xFF1DB954), isSolid: isSolid, translucentAlpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(LucideIcons.link, size: 18, color: Color(0xFF1DB954)),
                ),
                title: const Text('Import from Spotify & YouTube', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                subtitle: const Text('Paste link to stream immediately or download for offline', style: TextStyle(fontSize: 11)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  UniversalImportDialog.show(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final libraryState = ref.watch(unifiedLibraryProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final isSolid = ref.isSolidStyle;

    final studioPlaylists = libraryState.playlists.where((p) => !p.isCustom).toList();
    final customPlaylists = libraryState.customPlaylists;
    final smartPlaylists = libraryState.smartPlaylists;

    final favPlaylist = studioPlaylists.firstWhere(
      (p) => p.id == 'favorites',
      orElse: () => libraryState.playlists.first,
    );
    final hiresPlaylist = studioPlaylists.firstWhere(
      (p) => p.id == 'hires_master',
      orElse: () => libraryState.playlists.first,
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        toolbarHeight: 56.0,
        elevation: 0,
        titleSpacing: 18,
        title: const TwoToneHeader(
          primaryText: 'STUDIO',
          accentText: 'PLAYLISTS',
          fontSize: 18,
        ),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.plus, size: 20, color: isDark ? Colors.white : theme.colorScheme.onSurface),
            tooltip: 'Create Playlist Options',
            onPressed: () => _showCreateOptionsSheet(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        interactive: true,
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: [
            // ─── 1. STUDIO COLLECTIONS & DYNAMIC SMART PLAYLISTS RESPONSIVE ROW ──
            Text(
              'STUDIO COLLECTIONS',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 10),

            LayoutBuilder(
              builder: (context, constraints) {
                final favCard = _buildCollectionPillCard(
                  context: context,
                  icon: LucideIcons.heart,
                  title: favPlaylist.name,
                  subtitle: '${favPlaylist.trackCount} Tracks',
                  accentColor: primary,
                  isSolid: isSolid,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PlaylistDetailScreen(playlist: favPlaylist),
                      ),
                    );
                  },
                  onMoreTap: () {
                    StudioPlaylistActionSheet.showForPlaylist(context, playlist: favPlaylist);
                  },
                );

                final hiresCard = _buildCollectionPillCard(
                  context: context,
                  icon: LucideIcons.disc3,
                  title: hiresPlaylist.name,
                  subtitle: '${hiresPlaylist.trackCount} Tracks',
                  accentColor: theme.colorScheme.secondary,
                  isSolid: isSolid,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PlaylistDetailScreen(playlist: hiresPlaylist),
                      ),
                    );
                  },
                  onMoreTap: () {
                    StudioPlaylistActionSheet.showForPlaylist(context, playlist: hiresPlaylist);
                  },
                );

                final smartCard = _buildCollectionPillCard(
                  context: context,
                  icon: LucideIcons.slidersHorizontal,
                  title: 'Smart Rules',
                  subtitle: '${smartPlaylists.length} Rules Active',
                  accentColor: theme.colorScheme.tertiary,
                  isSolid: isSolid,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SmartPlaylistsScreen(),
                      ),
                    );
                  },
                  onMoreTap: () => _showCreateOptionsSheet(context),
                );

                if (constraints.maxWidth >= 600) {
                  return Row(
                    children: [
                      Expanded(child: favCard),
                      const SizedBox(width: 10),
                      Expanded(child: hiresCard),
                      const SizedBox(width: 10),
                      Expanded(child: smartCard),
                    ],
                  );
                }

                return SizedBox(
                  height: 104,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      favCard,
                      const SizedBox(width: 10),
                      hiresCard,
                      const SizedBox(width: 10),
                      smartCard,
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // ─── 2. CUSTOM USER PLAYLISTS SECTION ────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'USER PLAYLISTS (${customPlaylists.length})',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                InkWell(
                  onTap: () => CreateCustomPlaylistModal.show(context),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Text(
                      '+ New Playlist',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (customPlaylists.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF16181F) : theme.colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark ? const Color(0xFF262936) : theme.colorScheme.outlineVariant,
                    width: 0.8,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.listMusic,
                      size: 36,
                      color: isDark ? const Color(0xFF64748B) : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'NO CUSTOM PLAYLISTS',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: isDark ? Colors.white : theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Create custom playlists to curate your favorite tracks and mastering sessions.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
                      ),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () => CreateCustomPlaylistModal.show(context),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF252834) : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark ? const Color(0xFF383D50) : theme.colorScheme.outline,
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.plus, size: 14, color: isDark ? Colors.white : theme.colorScheme.onSurface),
                            const SizedBox(width: 7),
                            Text(
                              'CREATE PLAYLIST',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : theme.colorScheme.onSurface,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...customPlaylists.map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: StudioSurfaceTheme.surfaceContainer(context, isSolid: isSolid),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      leading: p.coverUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                width: 44,
                                height: 44,
                                child: StudioArtworkWidget(
                                  url: p.coverUrl,
                                  width: 44,
                                  height: 44,
                                ),
                              ),
                            )
                          : Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: StudioSurfaceTheme.tintedContainer(
                                  context,
                                  primary,
                                  isSolid: isSolid,
                                  translucentAlpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Icon(
                                  p.sourceType == 'spotify' || p.sourceType == 'youtube'
                                      ? LucideIcons.link
                                      : LucideIcons.listMusic,
                                  color: primary,
                                  size: 20,
                                ),
                              ),
                            ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              p.name,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (p.isStreaming)
                            Container(
                              margin: const EdgeInsets.only(left: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: primary.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                p.sourceType.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w900,
                                  color: primary,
                                ),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Text(
                        p.isStreaming
                            ? '${p.trackCount} Tracks • ${p.downloadedCount} Offline'
                            : (p.description.isNotEmpty
                                ? '${p.description} • ${p.trackCount} Tracks'
                                : '${p.trackCount} Tracks'),
                        style: TextStyle(
                          fontSize: 11,
                          fontFeatures: AppTypography.audioFigures,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          M3EIconButton(
                            variant: M3EIconButtonVariant.standard,
                            icon: Icon(
                              LucideIcons.moreVertical,
                              size: 20,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            onPressed: () {
                              StudioPlaylistActionSheet.showForPlaylist(context, playlist: p);
                            },
                            tooltip: 'Playlist Actions',
                          ),
                          Icon(
                            LucideIcons.chevronRight,
                            size: 16,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PlaylistDetailScreen(playlist: p),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollectionPillCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accentColor,
    required bool isSolid,
    required VoidCallback onTap,
    required VoidCallback onMoreTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: 146,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16181F) : theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF262936) : theme.colorScheme.outlineVariant,
          width: 0.8,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF20232E) : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark ? const Color(0xFF2E3242) : theme.colorScheme.outlineVariant,
                          width: 0.8,
                        ),
                      ),
                      child: Center(
                        child: Icon(icon, color: isDark ? Colors.white : theme.colorScheme.onSurface, size: 16),
                      ),
                    ),
                    InkWell(
                      onTap: onMoreTap,
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          LucideIcons.ellipsisVertical,
                          size: 15,
                          color: isDark ? const Color(0xFF94A3B8) : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                        color: isDark ? Colors.white : theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: isDark ? const Color(0xFF94A3B8) : theme.colorScheme.onSurfaceVariant,
                        fontFeatures: AppTypography.audioFigures,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
