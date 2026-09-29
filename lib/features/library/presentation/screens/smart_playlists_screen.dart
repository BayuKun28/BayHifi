import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/theme/studio_surface_theme.dart';
import '../../../../app/theme/app_typography.dart';
import '../../domain/smart_playlist_models.dart';
import '../controllers/library_controller.dart';
import '../widgets/create_smart_playlist_dialog.dart';
import '../widgets/studio_playlist_action_sheet.dart';
import 'playlist_detail_screen.dart';

/// Dedicated Screen for Browsing and Managing All Dynamic Smart Playlists
class SmartPlaylistsScreen extends ConsumerStatefulWidget {
  const SmartPlaylistsScreen({super.key});

  @override
  ConsumerState<SmartPlaylistsScreen> createState() => _SmartPlaylistsScreenState();
}

class _SmartPlaylistsScreenState extends ConsumerState<SmartPlaylistsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _restorePresets() {
    final theme = Theme.of(context);
    final isSolid = ref.isSolidStyle;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: StudioSurfaceTheme.surface(ctx, isSolid: isSolid),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: StudioSurfaceTheme.outline(ctx, isSolid: isSolid),
            width: 1.0,
          ),
        ),
        title: const Text(
          'RESTORE PRESETS?',
          style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, letterSpacing: 0.6),
        ),
        content: Text(
          'This will reset your smart rules to the factory studio presets (Lossless Master, Hi-Res 24-bit, Studio Acoustics, etc.).',
          style: TextStyle(
            fontSize: 12.5,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(unifiedLibraryProvider.notifier).resetSmartPlaylistsToPresets();
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Restored default smart presets.')),
              );
            },
            child: const Text('Restore Presets', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isSolid = ref.isSolidStyle;
    final libraryState = ref.watch(unifiedLibraryProvider);
    final smartPlaylists = libraryState.smartPlaylists;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('DYNAMIC SMART PLAYLISTS'),
        leading: IconButton(
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            size: 20,
            color: theme.colorScheme.onSurface,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedRefresh,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            tooltip: 'Restore Default Presets',
            onPressed: _restorePresets,
          ),
          IconButton(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedAddCircle,
              size: 20,
              color: primary,
            ),
            tooltip: 'Create Smart Rule',
            onPressed: () => CreateSmartPlaylistDialog.show(context),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        interactive: true,
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          children: [
            // Status Hero Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: StudioSurfaceTheme.cardDecoration(
                context: context,
                isSolid: isSolid,
                radius: 16,
              ),
              child: Row(
                children: [
                  Container(
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
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedFilterHorizontal,
                        size: 22,
                        color: primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'STUDIO SMART ENGINE',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${smartPlaylists.length} active dynamic rule sets auto-evaluating audio library',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                            fontFeatures: AppTypography.audioFigures,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => CreateSmartPlaylistDialog.show(context),
                    icon: HugeIcon(icon: HugeIcons.strokeRoundedAddCircle, size: 14, color: primary),
                    label: const Text('Add Rule', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            Text(
              'ACTIVE SMART RULES (${smartPlaylists.length})',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 10),

            if (smartPlaylists.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                decoration: BoxDecoration(
                  color: StudioSurfaceTheme.surfaceContainerLow(context, isSolid: isSolid, translucentAlpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedFilterHorizontal,
                      size: 36,
                      color: theme.dividerColor,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'NO SMART RULES ACTIVE',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Create custom dynamic rules or restore factory studio presets.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.tonalIcon(
                      onPressed: _restorePresets,
                      icon: HugeIcon(icon: HugeIcons.strokeRoundedRefresh, size: 15, color: primary),
                      label: const Text('RESTORE PRESETS'),
                    ),
                  ],
                ),
              )
            else
              ...smartPlaylists.map((p) {
                final tracks = libraryState.getSmartPlaylistTracks(p);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: StudioSurfaceTheme.surfaceContainer(context, isSolid: isSolid),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid),
                        width: 1.0,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: StudioSurfaceTheme.tintedContainer(
                            context,
                            primary,
                            isSolid: isSolid,
                            translucentAlpha: 0.12,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedFilterHorizontal,
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
                          if (p.isPreset)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: StudioSurfaceTheme.tintedContainer(
                                  context,
                                  theme.colorScheme.tertiary,
                                  isSolid: isSolid,
                                  translucentAlpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                'PRESET',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: theme.colorScheme.tertiary,
                                ),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Text(
                        '${tracks.length} Tracks • ${p.rules.length} Rule${p.rules.length == 1 ? '' : 's'} (${p.matchMode == SmartPlaylistMatchMode.all ? 'AND' : 'OR'})',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          fontFeatures: AppTypography.audioFigures,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: HugeIcon(
                              icon: HugeIcons.strokeRoundedMoreVertical,
                              size: 18,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                            onPressed: () {
                              StudioPlaylistActionSheet.showForSmartPlaylist(
                                context,
                                smartPlaylist: p,
                                tracks: tracks,
                              );
                            },
                          ),
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedArrowRight01,
                            size: 16,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PlaylistDetailScreen(smartPlaylist: p),
                          ),
                        );
                      },
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
