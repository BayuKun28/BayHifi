import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/widgets/two_tone_header.dart';
import '../../domain/models/dac_peq_profile.dart';
import '../controllers/dac_bridge_controller.dart';
import '../controllers/dac_bridge_state.dart';
import '../widgets/dac_action_toolbar.dart';
import '../widgets/dac_band_slider_tile.dart';
import '../widgets/dac_global_gain_card.dart';
import '../widgets/dac_hero_status_card.dart';
import '../widgets/dac_profile_manager_modal.dart';
import '../widgets/hardware_curve_visualizer.dart';

/// Full Hardware DAC Studio screen for configuring onboard DSP registers,
/// auditioning real-time biquad changes, and flashing EEPROM memory on USB DACs.
///
/// Ergonomically responsive for mobile, tablet, and desktop displays.
class HardwareDacStudioScreen extends ConsumerStatefulWidget {
  const HardwareDacStudioScreen({super.key});

  static const String routePath = '/hardware-dac-studio';

  @override
  ConsumerState<HardwareDacStudioScreen> createState() => _HardwareDacStudioScreenState();
}

class _HardwareDacStudioScreenState extends ConsumerState<HardwareDacStudioScreen> {
  int? _selectedBandIndex = 0;

  @override
  Widget build(BuildContext context) {
    final dacState = ref.watch(dacBridgeControllerProvider);
    final controller = ref.read(dacBridgeControllerProvider.notifier);

    // Listen for status banner or error messages
    ref.listen<DacBridgeState>(dacBridgeControllerProvider, (prev, next) {
      if (next.errorMessage != null && next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(next.errorMessage!),
              backgroundColor: const Color(0xFF381E24),
              behavior: SnackBarBehavior.floating,
            ),
          );
      } else if (next.statusBannerMessage != null &&
          next.statusBannerMessage != prev?.statusBannerMessage) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(next.statusBannerMessage!),
              backgroundColor: const Color(0xFF1E2B22),
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
    });

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final iconColor = isDark ? const Color(0xFF8A9A90) : colorScheme.onSurfaceVariant;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const TwoToneHeader(
          primaryText: 'HARDWARE',
          accentText: 'DAC STUDIO',
          fontSize: 18,
          letterSpacing: 0.2,
        ),
        actions: [
          if (dacState.isBusy)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.0),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF4ADE80),
                  ),
                ),
              ),
            ),
          IconButton(
            icon: Icon(
              LucideIcons.bookmark,
              size: 20,
              color: iconColor,
            ),
            tooltip: 'DAC Profile Library',
            onPressed: () => DacProfileManagerModal.show(context),
          ),
          IconButton(
            icon: Icon(
              LucideIcons.refreshCw,
              size: 20,
              color: iconColor,
            ),
            tooltip: 'Rescan USB DAC',
            onPressed: dacState.isBusy
                ? null
                : () => controller.scanAndConnect(isManual: true),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: _buildContent(context, dacState, controller),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    DacBridgeState state,
    DacBridgeController controller,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 840;
        if (isWide) {
          return _buildWideLayout(context, state, controller);
        }
        return _buildMobileLayout(context, state, controller);
      },
    );
  }

  /// Ergonomic dual-pane workstation layout for Desktop and Tablet horizontal views.
  Widget _buildWideLayout(
    BuildContext context,
    DacBridgeState state,
    DacBridgeController controller,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Workstation Column (Hero, Curve, Toolbar, Pre-Amp)
          Expanded(
            flex: 5,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(right: 12, bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DacHeroStatusCard(
                    device: state.device,
                    status: state.status,
                    isEqEnabled: state.isEqEnabled,
                    hasUnsavedChanges: state.hasUnsavedFlashChanges,
                    onToggleEq: (enabled) => controller.toggleHardwareEq(enabled),
                    onRefresh: () => controller.refreshFromHardware(),
                    onDisconnect: () => controller.disconnect(),
                    onConnectWebHid: () => controller.requestAndConnectWebHid(),
                  ),
                  const SizedBox(height: 16),
                  HardwareCurveVisualizer(
                    bands: state.bands,
                    isEqEnabled: state.isEqEnabled,
                    preampDb: state.globalGainDb,
                    selectedBandIndex: _selectedBandIndex,
                    onBandSelected: (index) {
                      setState(() {
                        _selectedBandIndex = index;
                      });
                    },
                    onBandDragged: (index, freq, gain) {
                      controller.updateBand(index, frequency: freq, gainDb: gain);
                    },
                    height: 220,
                  ),
                  const SizedBox(height: 16),
                  DacActionToolbar(
                    isConnected: state.isConnected,
                    isBusy: state.isBusy,
                    hasUnsavedChanges: state.hasUnsavedFlashChanges,
                    presets: state.availablePresets,
                    onBurnToFlash: () => controller.burnToFlash(),
                    onReadFromHardware: () => controller.refreshFromHardware(),
                    onImportAutoEq: () => _showAutoEqImportSelector(context, state, controller),
                    onSelectPreset: (preset) => controller.applyProfile(preset),
                    onResetDefault: () => controller.clearFlash(),
                  ),
                  if (state.device?.chipset.hasGlobalGain ?? true) ...[
                    const SizedBox(height: 16),
                    DacGlobalGainCard(
                      globalGainDb: state.globalGainDb,
                      isConnected: state.isConnected,
                      onChanged: (val) => controller.setGlobalGain(val),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Right Column (Filter Bands)
          Expanded(
            flex: 5,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(left: 12, bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'HARDWARE FILTER BANDS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: isDark ? const Color(0xFF8A9A90) : colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E212B) : colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isDark ? const Color(0xFF262936) : colorScheme.outlineVariant,
                            ),
                          ),
                          child: Text(
                            '5-BAND BIQUAD REGISTERS',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: isDark ? const Color(0xFF8A9A90) : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  for (int index = 0; index < state.bands.length; index++) ...[
                    DacBandSliderTile(
                      band: state.bands[index],
                      isSelected: _selectedBandIndex == index,
                      onTap: () {
                        setState(() {
                          _selectedBandIndex = index;
                        });
                      },
                      onChanged: (updatedBand) {
                        controller.updateBand(
                          index,
                          frequency: updatedBand.frequency,
                          gainDb: updatedBand.gainDb,
                          qFactor: updatedBand.qFactor,
                          filterType: updatedBand.filterType,
                          isBypassed: updatedBand.isBypassed,
                        );
                      },
                    ),
                    if (index < state.bands.length - 1) const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Compact single-column vertical layout for Mobile and narrow tablet views.
  Widget _buildMobileLayout(
    BuildContext context,
    DacBridgeState state,
    DacBridgeController controller,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DacHeroStatusCard(
                      device: state.device,
                      status: state.status,
                      isEqEnabled: state.isEqEnabled,
                      hasUnsavedChanges: state.hasUnsavedFlashChanges,
                      onToggleEq: (enabled) => controller.toggleHardwareEq(enabled),
                      onRefresh: () => controller.refreshFromHardware(),
                      onDisconnect: () => controller.disconnect(),
                      onConnectWebHid: () => controller.requestAndConnectWebHid(),
                    ),
                    const SizedBox(height: 16),
                    HardwareCurveVisualizer(
                      bands: state.bands,
                      isEqEnabled: state.isEqEnabled,
                      preampDb: state.globalGainDb,
                      selectedBandIndex: _selectedBandIndex,
                      onBandSelected: (index) {
                        setState(() {
                          _selectedBandIndex = index;
                        });
                      },
                      onBandDragged: (index, freq, gain) {
                        controller.updateBand(index, frequency: freq, gainDb: gain);
                      },
                    ),
                    const SizedBox(height: 16),
                    DacActionToolbar(
                      isConnected: state.isConnected,
                      isBusy: state.isBusy,
                      hasUnsavedChanges: state.hasUnsavedFlashChanges,
                      presets: state.availablePresets,
                      onBurnToFlash: () => controller.burnToFlash(),
                      onReadFromHardware: () => controller.refreshFromHardware(),
                      onImportAutoEq: () => _showAutoEqImportSelector(context, state, controller),
                      onSelectPreset: (preset) => controller.applyProfile(preset),
                      onResetDefault: () => controller.clearFlash(),
                    ),
                    const SizedBox(height: 16),
                    if (state.device?.chipset.hasGlobalGain ?? true) ...[
                      DacGlobalGainCard(
                        globalGainDb: state.globalGainDb,
                        isConnected: state.isConnected,
                        onChanged: (val) => controller.setGlobalGain(val),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'HARDWARE FILTER BANDS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: isDark ? const Color(0xFF8A9A90) : colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E212B) : colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isDark ? const Color(0xFF262936) : colorScheme.outlineVariant,
                            ),
                          ),
                          child: Text(
                            '5-BAND BIQUAD',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: isDark ? const Color(0xFF8A9A90) : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final band = state.bands[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: DacBandSliderTile(
                        band: band,
                        isSelected: _selectedBandIndex == index,
                        onTap: () {
                          setState(() {
                            _selectedBandIndex = index;
                          });
                        },
                        onChanged: (updatedBand) {
                          controller.updateBand(
                            index,
                            frequency: updatedBand.frequency,
                            gainDb: updatedBand.gainDb,
                            qFactor: updatedBand.qFactor,
                            filterType: updatedBand.filterType,
                            isBypassed: updatedBand.isBypassed,
                          );
                        },
                      ),
                    );
                  },
                  childCount: state.bands.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAutoEqImportSelector(
    BuildContext context,
    DacBridgeState state,
    DacBridgeController controller,
  ) {
    if (state.device == null) return;
    final isDesktopOrTablet = MediaQuery.of(context).size.width >= 650;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final sheetBg = isDark ? const Color(0xFF16181F) : colorScheme.surfaceContainer;
    final outlineColor = isDark ? const Color(0xFF262936) : colorScheme.outlineVariant;
    final cardBg = isDark ? const Color(0xFF1E212B) : colorScheme.surfaceContainerHighest;
    final textPrimary = isDark ? Colors.white : colorScheme.onSurface;
    final textSecondary = isDark ? const Color(0xFF8A9A90) : colorScheme.onSurfaceVariant;

    Widget contentBuilder(BuildContext ctx) {
      return Container(
        constraints: BoxConstraints(
          maxWidth: isDesktopOrTablet ? 480 : double.infinity,
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: BorderRadius.circular(isDesktopOrTablet ? 20 : 0),
          border: isDesktopOrTablet ? Border.all(color: outlineColor) : null,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'IMPORT TARGET CURVE',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: Icon(LucideIcons.x, size: 18, color: textSecondary),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: DacPeqProfile.builtInPresets.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final preset = DacPeqProfile.builtInPresets[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: outlineColor),
                        ),
                        child: ListTile(
                          leading: const Icon(
                            LucideIcons.sliders,
                            size: 18,
                            color: Color(0xFF4ADE80),
                          ),
                          title: Text(
                            preset.name,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            preset.description,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 11,
                              color: textSecondary,
                            ),
                          ),
                          onTap: () {
                            Navigator.of(ctx).pop();
                            controller.applyProfile(preset);
                          },
                        ),
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

    if (isDesktopOrTablet) {
      showDialog(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.65),
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: contentBuilder(ctx),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        backgroundColor: sheetBg,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) => contentBuilder(ctx),
      );
    }
  }
}
