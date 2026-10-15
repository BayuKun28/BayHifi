import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
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
              backgroundColor: colorScheme.errorContainer,
            ),
          );
      } else if (next.statusBannerMessage != null &&
          next.statusBannerMessage != prev?.statusBannerMessage) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(next.statusBannerMessage!),
              backgroundColor: colorScheme.secondaryContainer,
            ),
          );
      }
    });

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        title: const TwoToneHeader(
          primaryText: 'HARDWARE',
          accentText: 'DAC STUDIO',
          fontSize: 18,
          letterSpacing: 0.2,
        ),
        actions: [
          if (dacState.isBusy)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: M3EProgressIndicator.circular(strokeWidth: 2.5),
                ),
              ),
            ),
          M3EIconButton(
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedBookmark02,
              size: 22,
            ),
            tooltip: 'DAC Profile Library',
            onPressed: () => DacProfileManagerModal.show(context),
          ),
          M3EIconButton(
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedRefresh,
              size: 22,
            ),
            tooltip: 'Rescan USB DAC',
            onPressed: dacState.isBusy
                ? null
                : () => controller.scanAndConnect(isManual: true),
          ),
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
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Hero Status Card
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

                // 2. Interactive Curve Graph
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

                // 3. Quick Action Toolbar
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

                // 4. Master Pre-Amp Global Gain
                if (state.device?.chipset.hasGlobalGain ?? true) ...[
                  DacGlobalGainCard(
                    globalGainDb: state.globalGainDb,
                    isConnected: state.isConnected,
                    onChanged: (val) => controller.setGlobalGain(val),
                  ),
                  const SizedBox(height: 16),
                ],

                // Section Header
                Text(
                  'Hardware Filter Bands (5-Band Biquad Registers)',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),

        // 4. 5-Band Slider Tiles
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
    );
  }

  void _showAutoEqImportSelector(
    BuildContext context,
    DacBridgeState state,
    DacBridgeController controller,
  ) {
    if (state.device == null) return;

    // Show selection dialog for popular AutoEQ targets
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Import Target Curve to Hardware DAC',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                ...DacPeqProfile.builtInPresets.map((preset) {
                  return ListTile(
                    leading: const HugeIcon(
                      icon: HugeIcons.strokeRoundedSlidersVertical,
                      size: 20,
                    ),
                    title: Text(preset.name),
                    subtitle: Text(preset.description, maxLines: 1),
                    onTap: () {
                      Navigator.of(context).pop();
                      controller.applyProfile(preset);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
