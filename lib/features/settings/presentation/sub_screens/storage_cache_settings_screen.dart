import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
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
    HapticFeedback.mediumImpact();
    await StorageCacheManager.instance.clearArtworkCache();
    await _loadStorageSummary();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Album artwork cache cleared.'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _clearLyricsCache() async {
    HapticFeedback.mediumImpact();
    await StorageCacheManager.instance.clearLyricsCache();
    await _loadStorageSummary();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lyrics cache cleared.'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _clearPlaybackHistory() async {
    HapticFeedback.mediumImpact();
    await StorageCacheManager.instance.clearPlaybackHistory();
    await _loadStorageSummary();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Playback history cleared.'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _clearAllCaches() async {
    HapticFeedback.mediumImpact();
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

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('STORAGE & CACHE QUOTA'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadStorageSummary,
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedRefresh,
              size: 20,
              color: primary,
            ),
            tooltip: 'Refresh Storage Metrics',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // 1. Hero Disk Quota Gauge Bento Banner
                _buildStorageOverviewCard(theme, primary),
                const SizedBox(height: 16),

                // 2. Cache Categories Section Header
                _buildSectionHeader(context, 'CACHE BREAKDOWN & RECLAMATION', HugeIcons.strokeRoundedDatabase),
                const SizedBox(height: 8),

                // Artwork Cache Card
                _buildCacheItemCard(
                  title: 'Album Artwork Cache',
                  subtitle: 'Thumbnail covers cached from local files and Navidrome',
                  sizeText: _summary?.formattedArtworkCache ?? '0 B',
                  icon: HugeIcons.strokeRoundedAlbum01,
                  onClear: _clearArtworkCache,
                  theme: theme,
                  primary: primary,
                ),
                const SizedBox(height: 8),

                // Lyrics Cache Card
                _buildCacheItemCard(
                  title: 'Lyrics & LRCLIB Cache',
                  subtitle: 'Cached plain and synchronized LRC lyrics files',
                  sizeText: _summary?.formattedLyricsCache ?? '0 B',
                  icon: HugeIcons.strokeRoundedTextFont,
                  onClear: _clearLyricsCache,
                  theme: theme,
                  primary: primary,
                ),
                const SizedBox(height: 8),

                // Playback History Card
                _buildCacheItemCard(
                  title: 'Playback History & Statistics',
                  subtitle: '${_summary?.playbackHistoryCount ?? 0} logged playback sessions',
                  sizeText: '${_summary?.playbackHistoryCount ?? 0} tracks',
                  icon: HugeIcons.strokeRoundedClock01,
                  onClear: _clearPlaybackHistory,
                  theme: theme,
                  primary: primary,
                ),
                const SizedBox(height: 16),

                // 3. Database Maintenance & Indexer Section
                _buildSectionHeader(context, 'LIBRARY INDEXER & INTEGRITY', HugeIcons.strokeRoundedFolderSync),
                const SizedBox(height: 8),

                // Missing Tracks Card
                _buildActionCard(
                  title: 'Missing Tracks Resolver',
                  subtitle: 'Locate moved files and repair dead library references',
                  icon: HugeIcons.strokeRoundedFolderSync,
                  actionLabel: 'Scan Missing',
                  onTap: () => MissingTracksResolverSheet.show(context),
                  theme: theme,
                  primary: primary,
                ),
                const SizedBox(height: 8),

                // Duplicate Resolver Card
                _buildActionCard(
                  title: 'Duplicate Tracks Resolver',
                  subtitle: 'Scan and deduplicate audio files favoring Hi-Res masters',
                  icon: HugeIcons.strokeRoundedLayers01,
                  actionLabel: 'Scan Duplicates',
                  onTap: () => DuplicateTracksResolverModal.show(context),
                  theme: theme,
                  primary: primary,
                ),
                const SizedBox(height: 20),

                // 4. 1-Click Master Purge Button
                FilledButton.icon(
                  onPressed: _clearAllCaches,
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedDelete02,
                    size: 16,
                    color: theme.colorScheme.onError,
                  ),
                  label: const Text(
                    '1-Click Purge All Temporary Caches',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
    );
  }

  Widget _buildStorageOverviewCard(ThemeData theme, Color primary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HugeIcon(icon: HugeIcons.strokeRoundedDatabase, size: 20, color: primary),
              const SizedBox(width: 8),
              Text(
                'STORAGE QUOTA OVERVIEW',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
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
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  Widget _buildCacheItemCard({
    required String title,
    required String subtitle,
    required String sizeText,
    required dynamic icon,
    required VoidCallback onClear,
    required ThemeData theme,
    required Color primary,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6), width: 0.8),
      ),
      child: Row(
        children: [
          HugeIcon(icon: icon, size: 20, color: primary),
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
          Text(
            sizeText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: primary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onClear,
            icon: HugeIcon(icon: HugeIcons.strokeRoundedDelete02, size: 16, color: theme.colorScheme.error),
            tooltip: 'Clear',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required dynamic icon,
    required String actionLabel,
    required VoidCallback onTap,
    required ThemeData theme,
    required Color primary,
  }) {
    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6), width: 0.8),
          ),
          child: Row(
            children: [
              HugeIcon(icon: icon, size: 20, color: primary),
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
                  color: primary.withValues(alpha: 0.15),
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

  Widget _buildSectionHeader(BuildContext context, String title, dynamic icon) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4, top: 8),
      child: Row(
        children: [
          HugeIcon(icon: icon, size: 14, color: primary),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
