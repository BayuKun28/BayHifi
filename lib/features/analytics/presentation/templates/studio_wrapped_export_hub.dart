import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../app/theme/studio_surface_theme.dart';
import '../../data/playback_analytics_service.dart';
import '../../data/wrapped_image_exporter.dart';
import '../../domain/studio_wrapped_data.dart';
import 'widgets/abstract_aura_view.dart';
import 'widgets/bento_studio_view.dart';
import 'widgets/cassette_jcard_view.dart';
import 'widgets/concert_ticket_view.dart';
import 'widgets/cyber_spec_card_view.dart';
import 'widgets/sticker_collage_view.dart';
import 'widgets/thermal_receipt_view.dart';
import 'widgets/vinyl_gatefold_view.dart';

enum WrappedTemplateStyle {
  receipt,
  stickers,
  bento,
  cassette,
  abstractAura,
  vinylGatefold,
  concertTicket,
  cyberSpec,
}

extension WrappedTemplateStyleExt on WrappedTemplateStyle {
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
    }
  }

  dynamic get icon {
    switch (this) {
      case WrappedTemplateStyle.receipt:
        return HugeIcons.strokeRoundedInvoice01;
      case WrappedTemplateStyle.stickers:
        return HugeIcons.strokeRoundedSparkles;
      case WrappedTemplateStyle.bento:
        return HugeIcons.strokeRoundedGrid;
      case WrappedTemplateStyle.cassette:
        return HugeIcons.strokeRoundedDisc;
      case WrappedTemplateStyle.abstractAura:
        return HugeIcons.strokeRoundedAudioWave01;
      case WrappedTemplateStyle.vinylGatefold:
        return HugeIcons.strokeRoundedRecord;
      case WrappedTemplateStyle.concertTicket:
        return HugeIcons.strokeRoundedTicket01;
      case WrappedTemplateStyle.cyberSpec:
        return HugeIcons.strokeRoundedCpu;
    }
  }
}

class StudioWrappedExportHub extends ConsumerStatefulWidget {
  const StudioWrappedExportHub({super.key});

  @override
  ConsumerState<StudioWrappedExportHub> createState() => _StudioWrappedExportHubState();
}

class _StudioWrappedExportHubState extends ConsumerState<StudioWrappedExportHub> {
  final GlobalKey _cardKey = GlobalKey();
  WrappedTemplateStyle _selectedTemplate = WrappedTemplateStyle.receipt;
  bool _isReceiptDark = true;
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSolid = ref.isSolidStyle;
    final wrappedData = ref.watch(studioWrappedDataProvider);
    final activeFilter = ref.watch(studioWrappedFilterProvider);

    return Scaffold(
      backgroundColor: StudioSurfaceTheme.surface(context, isSolid: isSolid),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01, size: 20, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'STUDIO RECAP GALLERY',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
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
            icon: const HugeIcon(icon: HugeIcons.strokeRoundedCalendar03, size: 18, color: Colors.white),
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
          // ─── 1. TEMPLATE SELECTOR BAR ──────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: WrappedTemplateStyle.values.map((style) {
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
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.primary.withValues(alpha: 0.22)
                              : StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid, translucentAlpha: 0.35),
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
                            HugeIcon(
                              icon: style.icon,
                              size: 14,
                              color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              style.label.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10.0,
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

          // ─── 2. LIVE INTERACTIVE CARD PREVIEW ──────────────────────
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

          // ─── 3. BOTTOM ACTION BAR ──────────────────────────────────
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
                    icon: HugeIcon(
                      icon: _isReceiptDark ? HugeIcons.strokeRoundedSun01 : HugeIcons.strokeRoundedMoon,
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
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _isExporting ? null : _handleShare,
                      icon: _isExporting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                            )
                          : const HugeIcon(icon: HugeIcons.strokeRoundedShare01, size: 18, color: Colors.black),
                      label: Text(
                        _isExporting ? 'GENERATING HD CARD...' : 'SHARE RECAP STORY',
                        style: const TextStyle(
                          fontSize: 12.0,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
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
