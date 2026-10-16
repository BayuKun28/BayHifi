import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import '../../../../app/theme/app_haptics.dart';
import '../../../../app/theme/studio_surface_theme.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../library/data/storage_cache_manager.dart';
import '../../../library/presentation/widgets/duplicate_tracks_resolver_modal.dart';
import '../../../library/presentation/widgets/missing_tracks_resolver_sheet.dart';

/// Storage Quota & Cache Maintenance Settings Sub-Screen
class StorageCacheSettingsScreen extends ConsumerStatefulWidget {
  final StorageUsageSummary? initialSummary;

  const StorageCacheSettingsScreen({
    super.key,
    this.initialSummary,
  });

  @override
  ConsumerState<StorageCacheSettingsScreen> createState() => _StorageCacheSettingsScreenState();
}

class _StorageCacheSettingsScreenState extends ConsumerState<StorageCacheSettingsScreen> {
  StorageUsageSummary? _summary;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialSummary != null) {
      _summary = widget.initialSummary;
      _isLoading = false;
    } else {
      _loadStorageSummary();
    }
  }

  Future<void> _loadStorageSummary({bool showLoading = false}) async {
    if (showLoading && mounted) {
      setState(() => _isLoading = true);
    }
    final summary = await StorageCacheManager.instance.calculateStorageUsage();
    if (mounted) {
      setState(() {
        _summary = summary;
        _isLoading = false;
      });
    }
  }

  Future<void> _clearArtworkCache() async {
    AppHaptics.mediumImpact();
    await StorageCacheManager.instance.clearArtworkCache();
    await _loadStorageSummary();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Album artwork cache cleared.'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _clearLyricsCache() async {
    AppHaptics.mediumImpact();
    await StorageCacheManager.instance.clearLyricsCache();
    await _loadStorageSummary();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lyrics cache cleared.'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _clearPlaybackHistory() async {
    AppHaptics.mediumImpact();
    await StorageCacheManager.instance.clearPlaybackHistory();
    await _loadStorageSummary();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Playback history cleared.'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _clearAllCaches() async {
    AppHaptics.mediumImpact();
    await StorageCacheManager.instance.clearAllNonEssentialCache();
    await _loadStorageSummary();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All temporary caches purged.'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isSolid = ref.isSolidStyle;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('STORAGE & CACHE QUOTA'),
        leading: M3EIconButton(
          variant: M3EIconButtonVariant.standard,
          icon: Icon(
            LucideIcons.arrowLeft,
            size: 22,
            color: theme.colorScheme.onSurface,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          M3EIconButton(
            variant: M3EIconButtonVariant.standard,
            onPressed: () {
              AppHaptics.lightImpact();
              _loadStorageSummary(showLoading: true);
            },
            icon: Icon(
              LucideIcons.refreshCw,
              size: 22,
              color: primary,
            ),
            tooltip: 'Refresh Storage Metrics',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: M3EProgressIndicator.circular())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              children: [
                // ─── 1. HERO DISK QUOTA GAUGE BENTO BANNER ────────────────────────
                _buildStorageOverviewCard(theme, primary, isSolid),
                const SizedBox(height: 18),

                // ─── 2. CACHE BREAKDOWN & RECLAMATION ─────────────────────────────
                _buildSectionHeader(context, 'CACHE BREAKDOWN & RECLAMATION', LucideIcons.database),
                const SizedBox(height: 8),

                _buildCacheItemCard(
                  title: 'Album Artwork Cache',
                  subtitle: 'Thumbnail covers cached from local files & Navidrome',
                  sizeText: _summary?.formattedArtworkCache ?? '0 B',
                  icon: LucideIcons.disc,
                  onClear: _clearArtworkCache,
                  theme: theme,
                  primary: primary,
                  isSolid: isSolid,
                ),
                const SizedBox(height: 8),

                _buildCacheItemCard(
                  title: 'Lyrics & LRCLIB Cache',
                  subtitle: 'Cached plain and synchronized LRC lyrics files',
                  sizeText: _summary?.formattedLyricsCache ?? '0 B',
                  icon: LucideIcons.type,
                  onClear: _clearLyricsCache,
                  theme: theme,
                  primary: primary,
                  isSolid: isSolid,
                ),
                const SizedBox(height: 8),

                _buildCacheItemCard(
                  title: 'Playback History & Statistics',
                  subtitle: '${_summary?.playbackHistoryCount ?? 0} logged playback sessions',
                  sizeText: '${_summary?.playbackHistoryCount ?? 0} tracks',
                  icon: LucideIcons.clock,
                  onClear: _clearPlaybackHistory,
                  theme: theme,
                  primary: primary,
                  isSolid: isSolid,
                ),
                const SizedBox(height: 20),

                // ─── 3. LIBRARY INDEXER & INTEGRITY ───────────────────────────────
                _buildSectionHeader(context, 'LIBRARY INDEXER & INTEGRITY', LucideIcons.folderSync),
                const SizedBox(height: 8),

                _buildActionCard(
                  title: 'Missing Tracks Resolver',
                  subtitle: 'Locate moved files and repair dead library references',
                  icon: LucideIcons.folderSync,
                  actionLabel: 'Scan Missing',
                  onTap: () => MissingTracksResolverSheet.show(context),
                  theme: theme,
                  primary: primary,
                  isSolid: isSolid,
                ),
                const SizedBox(height: 8),

                _buildActionCard(
                  title: 'Duplicate Tracks Resolver',
                  subtitle: 'Scan and deduplicate audio files favoring Hi-Res masters',
                  icon: LucideIcons.layers,
                  actionLabel: 'Scan Duplicates',
                  onTap: () => DuplicateTracksResolverModal.show(context),
                  theme: theme,
                  primary: primary,
                  isSolid: isSolid,
                ),
                const SizedBox(height: 24),

                // ─── 4. 1-CLICK MASTER PURGE BUTTON ───────────────────────────────
                M3EButton.filled(
                  onPressed: () {
                    AppHaptics.heavyImpact();
                    _clearAllCaches();
                  },
                  icon: Icon(
                    LucideIcons.trash2,
                    size: 16,
                    color: theme.colorScheme.onError,
                  ),
                  label: const Text(
                    'PURGE ALL TEMPORARY CACHES',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStorageOverviewCard(ThemeData theme, Color primary, bool isSolid) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: StudioSurfaceTheme.cardDecoration(
        context: context,
        isSolid: isSolid,
        radius: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: StudioSurfaceTheme.tintedContainer(
                    context,
                    primary,
                    isSolid: isSolid,
                    translucentAlpha: 0.12,
                    solidBlendAlpha: 0.16,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  LucideIcons.database,
                  size: 18,
                  color: primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STORAGE QUOTA OVERVIEW',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Aggregated disk space utilized by artwork, lyrics & database indexes',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatColumn('Total Cache', _summary?.formattedTotalCache ?? '0 B', theme, primary),
              _buildStatColumn('Database Size', _summary?.formattedDatabaseSize ?? '0 B', theme, primary),
              _buildStatColumn('Library Tracks', '${_summary?.libraryTracksCount ?? 0}', theme, primary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, ThemeData theme, Color primary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: theme.colorScheme.onSurface,
            fontFeatures: AppTypography.audioFigures,
          ),
        ),
      ],
    );
  }

  Widget _buildCacheItemCard({
    required String title,
    required String subtitle,
    required String sizeText,
    required IconData icon,
    required VoidCallback onClear,
    required ThemeData theme,
    required Color primary,
    required bool isSolid,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSolid
            ? theme.colorScheme.surfaceContainerHighest
            : StudioSurfaceTheme.surfaceContainerLow(context, isSolid: isSolid),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 10.5, color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: StudioSurfaceTheme.tintedContainer(
                context,
                primary,
                isSolid: isSolid,
                translucentAlpha: 0.12,
                solidBlendAlpha: 0.16,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              sizeText,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: primary,
                fontFeatures: AppTypography.audioFigures,
              ),
            ),
          ),
          const SizedBox(width: 8),
          M3EIconButton(
            variant: M3EIconButtonVariant.standard,
            onPressed: onClear,
            icon: Icon(LucideIcons.trash2, size: 20, color: theme.colorScheme.error),
            tooltip: 'Clear',
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String actionLabel,
    required VoidCallback onTap,
    required ThemeData theme,
    required Color primary,
    required bool isSolid,
  }) {
    return Material(
      color: isSolid
          ? theme.colorScheme.surfaceContainerHighest
          : StudioSurfaceTheme.surfaceContainerLow(context, isSolid: isSolid),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          AppHaptics.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 10.5, color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: StudioSurfaceTheme.tintedContainer(
                    context,
                    primary,
                    isSolid: isSolid,
                    translucentAlpha: 0.15,
                    solidBlendAlpha: 0.20,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  actionLabel,
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 15, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
            fontSize: 11.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }
}

