import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/studio_surface_theme.dart';
import '../../data/playback_analytics_service.dart';
import '../../data/wrapped_image_exporter.dart';
import '../../domain/studio_wrapped_data.dart';
import 'widgets/abstract_aura_view.dart';
import 'widgets/artist_lineup_poster_view.dart';
import 'widgets/bento_studio_view.dart';
import 'widgets/cassette_jcard_view.dart';
import 'widgets/concert_ticket_view.dart';
import 'widgets/cyber_spec_card_view.dart';
import 'widgets/genre_spectrum_card_view.dart';
import 'widgets/persona_master_card_view.dart';
import 'widgets/sticker_collage_view.dart';
import 'widgets/thermal_receipt_view.dart';
import 'widgets/top_tracks_chart_view.dart';
import 'widgets/vinyl_gatefold_view.dart';

enum WrappedTemplateCategory {
  allInOne,
  dedicatedFocus,
}

extension WrappedTemplateCategoryExt on WrappedTemplateCategory {
  String get label {
    switch (this) {
      case WrappedTemplateCategory.allInOne:
        return 'All-in-One Recaps';
      case WrappedTemplateCategory.dedicatedFocus:
        return 'Dedicated Focus Cards';
    }
  }

  IconData get icon {
    switch (this) {
      case WrappedTemplateCategory.allInOne:
        return LucideIcons.sparkles;
      case WrappedTemplateCategory.dedicatedFocus:
        return LucideIcons.target;
    }
  }
}

enum WrappedTemplateStyle {
  // All-in-One Category
  receipt,
  stickers,
  bento,
  cassette,
  abstractAura,
  vinylGatefold,
  concertTicket,
  cyberSpec,
  // Dedicated Focus Category
  personaCard,
  lineupPoster,
  genreSpectrum,
  topTracksChart,
}

extension WrappedTemplateStyleExt on WrappedTemplateStyle {
  WrappedTemplateCategory get category {
    switch (this) {
      case WrappedTemplateStyle.receipt:
      case WrappedTemplateStyle.stickers:
      case WrappedTemplateStyle.bento:
      case WrappedTemplateStyle.cassette:
      case WrappedTemplateStyle.abstractAura:
      case WrappedTemplateStyle.vinylGatefold:
      case WrappedTemplateStyle.concertTicket:
      case WrappedTemplateStyle.cyberSpec:
        return WrappedTemplateCategory.allInOne;
      case WrappedTemplateStyle.personaCard:
      case WrappedTemplateStyle.lineupPoster:
      case WrappedTemplateStyle.genreSpectrum:
      case WrappedTemplateStyle.topTracksChart:
        return WrappedTemplateCategory.dedicatedFocus;
    }
  }

  String get label {
    switch (this) {
      case WrappedTemplateStyle.receipt:
        return 'Receipt';
      case WrappedTemplateStyle.stickers:
        return 'Stickers';
      case WrappedTemplateStyle.bento:
        return 'Bento';
      case WrappedTemplateStyle.cassette:
        return 'Cassette';
      case WrappedTemplateStyle.abstractAura:
        return 'Aura Wave';
      case WrappedTemplateStyle.vinylGatefold:
        return 'Vinyl LP';
      case WrappedTemplateStyle.concertTicket:
        return 'VIP Ticket';
      case WrappedTemplateStyle.cyberSpec:
        return 'Cyber HUD';
      case WrappedTemplateStyle.personaCard:
        return 'Persona Archetype';
      case WrappedTemplateStyle.lineupPoster:
        return 'Festival Lineup';
      case WrappedTemplateStyle.genreSpectrum:
        return 'Sonic Spectrum';
      case WrappedTemplateStyle.topTracksChart:
        return 'Tracks Chart';
    }
  }

  IconData get icon {
    switch (this) {
      case WrappedTemplateStyle.receipt:
        return LucideIcons.receipt;
      case WrappedTemplateStyle.stickers:
        return LucideIcons.sparkles;
      case WrappedTemplateStyle.bento:
        return LucideIcons.layoutGrid;
      case WrappedTemplateStyle.cassette:
        return LucideIcons.disc;
      case WrappedTemplateStyle.abstractAura:
        return LucideIcons.audioWaveform;
      case WrappedTemplateStyle.vinylGatefold:
        return LucideIcons.disc3;
      case WrappedTemplateStyle.concertTicket:
        return LucideIcons.ticket;
      case WrappedTemplateStyle.cyberSpec:
        return LucideIcons.cpu;
      case WrappedTemplateStyle.personaCard:
        return LucideIcons.user;
      case WrappedTemplateStyle.lineupPoster:
        return LucideIcons.mic;
      case WrappedTemplateStyle.genreSpectrum:
        return LucideIcons.sliders;
      case WrappedTemplateStyle.topTracksChart:
        return LucideIcons.award;
    }
  }
}

class StudioWrappedExportHub extends ConsumerStatefulWidget {
  final WrappedTemplateStyle? initialStyle;

  const StudioWrappedExportHub({
    super.key,
    this.initialStyle,
  });

  @override
  ConsumerState<StudioWrappedExportHub> createState() => _StudioWrappedExportHubState();
}

class _StudioWrappedExportHubState extends ConsumerState<StudioWrappedExportHub> {
  final GlobalKey _cardKey = GlobalKey();
  late WrappedTemplateCategory _selectedCategory;
  late WrappedTemplateStyle _selectedTemplate;
  bool _isReceiptDark = true;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _selectedTemplate = widget.initialStyle ?? WrappedTemplateStyle.receipt;
    _selectedCategory = _selectedTemplate.category;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSolid = ref.isSolidStyle;
    final wrappedData = ref.watch(studioWrappedDataProvider);
    final activeFilter = ref.watch(studioWrappedFilterProvider);

    final currentCategoryTemplates = WrappedTemplateStyle.values
        .where((s) => s.category == _selectedCategory)
        .toList();

    return Scaffold(
      backgroundColor: StudioSurfaceTheme.surface(context, isSolid: isSolid),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, size: 20, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'STUDIO RECAP GALLERY',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: theme.colorScheme.onSurface,
              ),
            ),
            Text(
              activeFilter.label.toUpperCase(),
              style: TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        actions: [
          // Time Filter Dropdown / Menu
          PopupMenuButton<RecapTimeFilter>(
            icon: Icon(LucideIcons.calendar, size: 18, color: theme.colorScheme.onSurface),
            tooltip: 'Select Time Range',
            onSelected: (filter) {
              ref.read(studioWrappedFilterProvider.notifier).state = filter;
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: RecapTimeFilter.year2026,
                child: Text('2026 Studio Wrapped', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ),
              const PopupMenuItem(
                value: RecapTimeFilter.last30Days,
                child: Text('Last 30 Days Recap', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ),
              const PopupMenuItem(
                value: RecapTimeFilter.allTime,
                child: Text('All-Time Journey', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // ─── 1. CATEGORY TIER SWITCHER (All-in-One vs Dedicated Focus) ──
          Container(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
            child: Row(
              children: WrappedTemplateCategory.values.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        setState(() {
                          _selectedCategory = cat;
                          final matching = WrappedTemplateStyle.values.where((s) => s.category == cat).toList();
                          if (!matching.contains(_selectedTemplate)) {
                            _selectedTemplate = matching.first;
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.primary.withValues(alpha: 0.18)
                              : StudioSurfaceTheme.surfaceContainer(context, isSolid: isSolid),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : StudioSurfaceTheme.outline(context, isSolid: isSolid),
                            width: isSelected ? 1.4 : 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              cat.icon,
                              size: 14,
                              color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                cat.label.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                                  letterSpacing: 0.6,
                                  color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // ─── 2. TEMPLATE SELECTOR HORIZONTAL BAR ──────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: currentCategoryTemplates.map((style) {
                  final isSelected = _selectedTemplate == style;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        setState(() {
                          _selectedTemplate = style;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.primary.withValues(alpha: 0.22)
                              : StudioSurfaceTheme.surfaceContainer(context, isSolid: isSolid),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : StudioSurfaceTheme.outline(context, isSolid: isSolid),
                            width: isSelected ? 1.5 : 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              style.icon,
                              size: 13,
                              color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              style.label.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                                letterSpacing: 0.5,
                                color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // ─── 3. LIVE INTERACTIVE CARD PREVIEW ──────────────────────
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: RepaintBoundary(
                  key: _cardKey,
                  child: _buildSelectedTemplateWidget(wrappedData),
                ),
              ),
            ),
          ),

          // ─── 4. BOTTOM ACTION BAR ──────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: BoxDecoration(
              color: StudioSurfaceTheme.surfaceContainer(context, isSolid: isSolid),
              border: Border(
                top: BorderSide(color: StudioSurfaceTheme.outline(context, isSolid: isSolid), width: 0.8),
              ),
            ),
            child: Row(
              children: [
                // Receipt Dark/Light Toggle (only for receipt style)
                if (_selectedTemplate == WrappedTemplateStyle.receipt) ...[
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _isReceiptDark = !_isReceiptDark;
                      });
                    },
                    icon: Icon(
                      _isReceiptDark ? LucideIcons.sun : LucideIcons.moon,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    tooltip: 'Toggle Paper Theme',
                  ),
                  const SizedBox(width: 10),
                ],

                // Share Button
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: isDark ? Colors.black : theme.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _isExporting ? null : _handleShare,
                      icon: _isExporting
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: isDark ? Colors.black : theme.colorScheme.onPrimary,
                              ),
                            )
                          : Icon(
                              LucideIcons.share2,
                              size: 18,
                              color: isDark ? Colors.black : theme.colorScheme.onPrimary,
                            ),
                      label: Text(
                        _isExporting ? 'GENERATING HD CARD...' : 'SHARE RECAP STORY',
                        style: TextStyle(
                          fontSize: 12.0,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                          color: isDark ? Colors.black : theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedTemplateWidget(StudioWrappedData data) {
    switch (_selectedTemplate) {
      // All-in-One templates
      case WrappedTemplateStyle.receipt:
        return ThermalReceiptView(data: data, isDarkMode: _isReceiptDark);
      case WrappedTemplateStyle.stickers:
        return StickerCollageView(data: data);
      case WrappedTemplateStyle.bento:
        return BentoStudioView(data: data);
      case WrappedTemplateStyle.cassette:
        return CassetteJCardView(data: data);
      case WrappedTemplateStyle.abstractAura:
        return AbstractSoundwaveAuraView(data: data);
      case WrappedTemplateStyle.vinylGatefold:
        return VinylGatefoldView(data: data);
      case WrappedTemplateStyle.concertTicket:
        return ConcertTicketView(data: data);
      case WrappedTemplateStyle.cyberSpec:
        return CyberSpecCardView(data: data);
      // Dedicated Focus templates
      case WrappedTemplateStyle.personaCard:
        return PersonaMasterCardView(data: data);
      case WrappedTemplateStyle.lineupPoster:
        return ArtistLineupPosterView(data: data);
      case WrappedTemplateStyle.genreSpectrum:
        return GenreSpectrumCardView(data: data);
      case WrappedTemplateStyle.topTracksChart:
        return TopTracksChartView(data: data);
    }
  }

  Future<void> _handleShare() async {
    setState(() {
      _isExporting = true;
    });

    try {
      final success = await WrappedImageExporter.shareRecapCard(
        _cardKey,
        subject: 'Baydev HiFi 2026 Studio Wrapped',
      );

      if (!mounted) return;
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to export recap image. Please try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }
}

