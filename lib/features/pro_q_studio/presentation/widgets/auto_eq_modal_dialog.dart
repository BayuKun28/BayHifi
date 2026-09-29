import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../app/theme/studio_surface_theme.dart';
import '../../domain/auto_eq_optimizer.dart';
import '../../domain/fr_curve_data.dart';
import '../controllers/eq_controller.dart';
import '../controllers/eq_state.dart';
import 'auto_eq_cloud_browser_dialog.dart';
import 'squiglink_dialog.dart';

/// Modal dialog utama "Auto EQ Studio & Target Matching"
/// Dirancang presisi sesuai tangkapan layar referensi studio landscape.
class AutoEqModalDialog extends ConsumerStatefulWidget {
  const AutoEqModalDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (context) => const AutoEqModalDialog(),
    );
  }

  @override
  ConsumerState<AutoEqModalDialog> createState() => _AutoEqModalDialogState();
}

class _AutoEqModalDialogState extends ConsumerState<AutoEqModalDialog> {
  // Built-in presets untuk kemudahan switching langsung
  static final List<FrCurveData> _defaultTargets = [
    FrCurveData(
      name: 'HBB Target',
      frequencies: const [20, 100, 1000, 3000, 8000, 20000],
      splDb: const [107.5, 105.0, 95.0, 102.5, 96.0, 90.0],
      referenceSpl1kHz: 95.0,
    ),
    FrCurveData(
      name: 'Harman In-Ear 2019v2',
      frequencies: const [20, 100, 1000, 3000, 8000, 20000],
      splDb: const [108.0, 106.0, 95.0, 104.0, 98.0, 88.0],
      referenceSpl1kHz: 95.0,
    ),
    FrCurveData(
      name: 'IEF Neutral Target',
      frequencies: const [20, 100, 1000, 3000, 8000, 20000],
      splDb: const [95.0, 95.0, 95.0, 103.0, 97.0, 90.0],
      referenceSpl1kHz: 95.0,
    ),
  ];

  static final List<FrCurveData> _defaultDrivers = [
    FrCurveData(
      name: 'KZ CASTOR BLACK DUDU R',
      frequencies: const [20, 100, 1000, 3000, 8000, 20000],
      splDb: const [87.7, 86.5, 78.0, 88.5, 82.0, 72.0],
      referenceSpl1kHz: 78.0,
    ),
    FrCurveData(
      name: 'Moondrop Chu II',
      frequencies: const [20, 100, 1000, 3000, 8000, 20000],
      splDb: const [85.0, 83.0, 75.0, 86.0, 79.0, 70.0],
      referenceSpl1kHz: 75.0,
    ),
    FrCurveData(
      name: 'Sennheiser HD600',
      frequencies: const [20, 100, 1000, 3000, 8000, 20000],
      splDb: const [78.0, 80.0, 80.0, 88.0, 82.0, 74.0],
      referenceSpl1kHz: 80.0,
    ),
  ];

  // Helper to decode URL-encoded and underscore names for clean UI display
  String _cleanName(String? s) {
    if (s == null || s.trim().isEmpty) return '';
    try {
      return Uri.decodeComponent(s).replaceAll('%20', ' ').replaceAll('_', ' ');
    } catch (_) {
      return s.replaceAll('%20', ' ').replaceAll('_', ' ');
    }
  }

  @override
  Widget build(BuildContext context) {
    final eqState = ref.watch(eqControllerProvider);
    final notifier = ref.read(eqControllerProvider.notifier);
    final theme = Theme.of(context);
    final isSolid = ref.isSolidStyle;

    final selectedDriver = eqState.driverFr;
    final selectedTarget = eqState.targetFr;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width < 400 ? 10 : 16,
        vertical: MediaQuery.of(context).size.height * 0.02,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxWidth: 560,
              maxHeight: MediaQuery.of(context).size.height * 0.90,
            ),
            decoration: BoxDecoration(
              color: StudioSurfaceTheme.surface(context, isSolid: isSolid),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: StudioSurfaceTheme.outline(context, isSolid: isSolid), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isSolid ? 0.4 : 0.7),
                  blurRadius: 32,
                  spreadRadius: 6,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Draggable Grabber Handle
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: StudioSurfaceTheme.outline(context, isSolid: isSolid),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Header Row: Sparkle + Title & Subtitle + Close Button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: StudioSurfaceTheme.tintedContainer(
                          context,
                          theme.colorScheme.primary,
                          isSolid: isSolid,
                          translucentAlpha: 0.12,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedSparkles,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'AUTO EQ STUDIO & TARGET MATCHING',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Match headphone driver FR against target curve or import Squiglink files',
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 10.0,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: HugeIcon(
                        icon: HugeIcons.strokeRoundedCancel01,
                        size: 18,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      tooltip: 'Close',
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Main Content Body (Scrollable to prevent any screen overflow)
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ─── SECTION 1: DRIVER PROFILE ──────────────────────────
                        _buildSectionHeader(
                          title: 'HEADPHONE / SPEAKER DRIVER',
                          hasRemove: selectedDriver != null,
                          onRemove: () => notifier.deleteDriver(),
                          theme: theme,
                        ),
                        const SizedBox(height: 5),
                        _buildDriverDropdown(eqState, notifier, isSolid, theme),
                        const SizedBox(height: 6),
                        _buildActionOutlinedButton(
                          icon: HugeIcons.strokeRoundedHeadphones,
                          label: 'IMPORT DRIVER FR (TXT/CSV)',
                          borderColor: isSolid ? theme.colorScheme.secondary : theme.colorScheme.secondary.withValues(alpha: 0.6),
                          color: theme.colorScheme.secondary,
                          bgColor: StudioSurfaceTheme.tintedContainer(context, theme.colorScheme.secondary, isSolid: isSolid, translucentAlpha: 0.12),
                          onTap: () => _handleImportDriver(context, notifier),
                        ),
                        const SizedBox(height: 10),

                        // ─── SECTION 2: TARGET CURVE ────────────────────────────
                        _buildSectionHeader(
                          title: 'TARGET RESPONSE CURVE',
                          hasRemove: selectedTarget != null,
                          onRemove: () => notifier.deleteTarget(),
                          theme: theme,
                        ),
                        const SizedBox(height: 5),
                        _buildTargetDropdown(eqState, notifier, isSolid, theme),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionOutlinedButton(
                                icon: HugeIcons.strokeRoundedTarget02,
                                label: 'IMPORT TARGET',
                                borderColor: isSolid ? const Color(0xFFFF9F0A) : const Color(0xFFFF9F0A).withValues(alpha: 0.6),
                                color: const Color(0xFFFF9F0A),
                                bgColor: StudioSurfaceTheme.tintedContainer(context, const Color(0xFFFF9F0A), isSolid: isSolid, translucentAlpha: 0.12),
                                onTap: () => _handleImportTarget(context, notifier),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: _buildActionOutlinedButton(
                                icon: HugeIcons.strokeRoundedCloudDownload,
                                label: 'CLOUD DB',
                                borderColor: isSolid ? theme.colorScheme.primary : theme.colorScheme.primary.withValues(alpha: 0.6),
                                color: theme.colorScheme.primary,
                                bgColor: StudioSurfaceTheme.tintedContainer(context, theme.colorScheme.primary, isSolid: isSolid, translucentAlpha: 0.12),
                                onTap: () => AutoEqCloudBrowserDialog.show(context),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: _buildActionOutlinedButton(
                                icon: HugeIcons.strokeRoundedSparkles,
                                label: 'SQUIGLINK',
                                borderColor: isSolid ? theme.colorScheme.tertiary : theme.colorScheme.tertiary.withValues(alpha: 0.6),
                                color: theme.colorScheme.tertiary,
                                bgColor: StudioSurfaceTheme.tintedContainer(context, theme.colorScheme.tertiary, isSolid: isSolid, translucentAlpha: 0.12),
                                onTap: () {
                                  showDialog<void>(
                                    context: context,
                                    builder: (context) => const SquiglinkDialog(),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // ─── SECTION 3: BAND RESOLUTION ─────────────────────────
                        Text(
                          'BAND RESOLUTION',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: BandResolution.values.map((res) {
                            final isSelected = eqState.bandResolution == res;
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                                child: InkWell(
                                  onTap: () => notifier.setBandResolution(res),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    height: 30,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? StudioSurfaceTheme.tintedContainer(
                                              context,
                                              theme.colorScheme.primary,
                                              isSolid: isSolid,
                                              translucentAlpha: 0.2,
                                              solidBlendAlpha: 0.25,
                                            )
                                          : StudioSurfaceTheme.surfaceContainerLow(context, isSolid: isSolid),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: isSelected
                                            ? (isSolid ? theme.colorScheme.primary : theme.colorScheme.primary.withValues(alpha: 0.8))
                                            : StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid),
                                        width: isSelected ? 1.2 : 0.8,
                                      ),
                                    ),
                                    child: Text(
                                      res.label,
                                      style: TextStyle(
                                        color: isSelected
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme.onSurfaceVariant,
                                        fontSize: 10.5,
                                        fontWeight: isSelected
                                            ? FontWeight.w900
                                            : FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),

                        // ─── SECTION 4: TUNING & A/B COMPARISON ──────────────────
                        Row(
                          children: [
                            // Tuning Mode
                            Expanded(
                              flex: 5,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'TUNING MODE',
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontSize: 9.0,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: StudioSurfaceTheme.surfaceContainerLow(context, isSolid: isSolid),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        _buildTuningModeChip(
                                          label: 'Normal',
                                          isSelected: eqState.tuningMode == TuningMode.normal,
                                          onTap: () => notifier.setTuningMode(TuningMode.normal),
                                          isSolid: isSolid,
                                          theme: theme,
                                        ),
                                        _buildTuningModeChip(
                                          label: 'Safe',
                                          isSelected: eqState.tuningMode == TuningMode.safe,
                                          onTap: () => notifier.setTuningMode(TuningMode.safe),
                                          isSolid: isSolid,
                                          theme: theme,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),

                            // A/B Comparison
                            Expanded(
                              flex: 6,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'A/B COMPARISON',
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontSize: 9.0,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: StudioSurfaceTheme.surfaceContainerLow(context, isSolid: isSolid),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        _buildAbChip(
                                          label: 'A: RAW',
                                          isSelected: eqState.abMode == AbComparisonMode.aRaw,
                                          activeColor: theme.colorScheme.secondary,
                                          onTap: () => notifier.setAbComparison(AbComparisonMode.aRaw),
                                          isSolid: isSolid,
                                        ),
                                        _buildAbChip(
                                          label: 'B: ACTIVE',
                                          isSelected: eqState.abMode == AbComparisonMode.bActive,
                                          activeColor: theme.colorScheme.primary,
                                          onTap: () => notifier.setAbComparison(AbComparisonMode.bActive),
                                          isSolid: isSolid,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // ─── SECTION 5: APPLY TO DSP BUTTON ─────────────────────
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              final success = notifier.applyAutoEq();
                              if (success) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'AutoEQ Applied! Fitted ${eqState.bandResolution.count} biquads (${_cleanName(selectedDriver?.name) != "" ? _cleanName(selectedDriver?.name) : "Driver"} → ${_cleanName(selectedTarget?.name) != "" ? _cleanName(selectedTarget?.name) : "Target"}). Preamp: ${eqState.safePreampDb.toStringAsFixed(1)} dB',
                                    ),
                                    backgroundColor: theme.colorScheme.primary,
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Please select both a Driver and Target curve before applying.'),
                                    backgroundColor: theme.colorScheme.error,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: isSolid
                                        ? Colors.black.withValues(alpha: 0.3)
                                        : theme.colorScheme.primary.withValues(alpha: 0.35),
                                    blurRadius: 14,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  HugeIcon(
                                    icon: HugeIcons.strokeRoundedChartBarLine,
                                    size: 20,
                                    color: theme.colorScheme.onPrimary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'APPLY TO DSP',
                                    style: TextStyle(
                                      color: theme.colorScheme.onPrimary,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Section 6: Clear Visualizer Curves
                        Center(
                          child: InkWell(
                            onTap: () {
                              notifier.clearFrCurves();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Visualizer FR curves cleared from canvas.'),
                                  duration: const Duration(seconds: 2),
                                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  HugeIcon(
                                    icon: HugeIcons.strokeRoundedCancelSquare,
                                    size: 13,
                                    color: theme.colorScheme.error,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'CLEAR VISUALIZER FR CURVES',
                                    style: TextStyle(
                                      color: theme.colorScheme.error,
                                      fontSize: 10.0,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required bool hasRemove,
    required VoidCallback onRemove,
    required ThemeData theme,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (hasRemove)
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedDelete02,
                    size: 12,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    'REMOVE',
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDriverDropdown(EqState state, EqController notifier, bool isSolid, ThemeData theme) {
    final driver = state.driverFr;
    final allDrivers = [
      ..._defaultDrivers,
      ...state.availableDrivers.where((d) => !_defaultDrivers.any((x) => x.name == d.name)),
    ];

    return PopupMenuButton<FrCurveData>(
      color: StudioSurfaceTheme.surfaceContainer(context, isSolid: isSolid),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: StudioSurfaceTheme.outline(context, isSolid: isSolid), width: 1),
      ),
      onSelected: (d) => notifier.selectDriver(d),
      itemBuilder: (context) => allDrivers.map((d) {
        final isSelected = driver?.name == d.name;
        return PopupMenuItem<FrCurveData>(
          value: d,
          child: Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedHeadphones,
                size: 14,
                color: isSelected ? theme.colorScheme.secondary : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _cleanName(d.name),
                  style: TextStyle(
                    color: isSelected ? theme.colorScheme.secondary : theme.colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: StudioSurfaceTheme.surfaceContainerLow(context, isSolid: isSolid),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid), width: 1.0),
        ),
        child: Row(
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedCloud,
              size: 15,
              color: theme.colorScheme.secondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                driver != null ? _cleanName(driver.name) : 'Select Headphone Driver...',
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 11.0,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            HugeIcon(
              icon: HugeIcons.strokeRoundedArrowDown01,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetDropdown(EqState state, EqController notifier, bool isSolid, ThemeData theme) {
    final target = state.targetFr;
    final allTargets = [
      ..._defaultTargets,
      ...state.availableTargets.where((t) => !_defaultTargets.any((x) => x.name == t.name)),
    ];

    return PopupMenuButton<FrCurveData>(
      color: StudioSurfaceTheme.surfaceContainer(context, isSolid: isSolid),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: StudioSurfaceTheme.outline(context, isSolid: isSolid), width: 1),
      ),
      onSelected: (t) => notifier.selectTarget(t),
      itemBuilder: (context) => allTargets.map((t) {
        final isSelected = target?.name == t.name;
        return PopupMenuItem<FrCurveData>(
          value: t,
          child: Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedTarget02,
                size: 14,
                color: isSelected ? const Color(0xFFFF9F0A) : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _cleanName(t.name),
                  style: TextStyle(
                    color: isSelected ? const Color(0xFFFF9F0A) : theme.colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: StudioSurfaceTheme.surfaceContainerLow(context, isSolid: isSolid),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid), width: 1.0),
        ),
        child: Row(
          children: [
            const HugeIcon(
              icon: HugeIcons.strokeRoundedCloud,
              size: 15,
              color: Color(0xFFFF9F0A),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                target != null ? _cleanName(target.name) : 'Select Target Response...',
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 11.0,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            HugeIcon(
              icon: HugeIcons.strokeRoundedArrowDown01,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTuningModeChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isSolid,
    required ThemeData theme,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(5),
        child: Container(
          margin: const EdgeInsets.all(2),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? StudioSurfaceTheme.tintedContainer(
                    context,
                    theme.colorScheme.primary,
                    isSolid: isSolid,
                    translucentAlpha: 0.3,
                    solidBlendAlpha: 0.35,
                  )
                : Colors.transparent,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
              fontSize: 10.0,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAbChip({
    required String label,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
    required bool isSolid,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(5),
        child: Container(
          margin: const EdgeInsets.all(2),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? StudioSurfaceTheme.tintedContainer(
                    context,
                    activeColor,
                    isSolid: isSolid,
                    translucentAlpha: 0.18,
                    solidBlendAlpha: 0.25,
                  )
                : Colors.transparent,
            borderRadius: BorderRadius.circular(5),
            border: isSelected
                ? Border.all(
                    color: isSolid ? activeColor : activeColor.withValues(alpha: 0.8),
                    width: 1.0,
                  )
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? activeColor : Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 9.5,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionOutlinedButton({
    required dynamic icon,
    required String label,
    required Color borderColor,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 32,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: 1.0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HugeIcon(icon: icon, size: 12, color: color),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleImportDriver(BuildContext context, EqController notifier) async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'csv'],
      );

      if (files.isNotEmpty && files.first.path != null) {
        final file = File(files.first.path!);
        final content = await file.readAsString();
        final name = files.first.name.replaceAll('.txt', '').replaceAll('.csv', '');

        final driver = FrCurveData.autoDetectAndParse(content, name: name);
        notifier.importDriver(driver);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully imported driver FR: $name (${driver.frequencies.length} points)'),
              backgroundColor: const Color(0xFF0288D1),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to import driver: $e'),
            backgroundColor: const Color(0xFFB71C1C),
          ),
        );
      }
    }
  }

  Future<void> _handleImportTarget(BuildContext context, EqController notifier) async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'csv'],
      );

      if (files.isNotEmpty && files.first.path != null) {
        final file = File(files.first.path!);
        final content = await file.readAsString();
        final name = files.first.name.replaceAll('.txt', '').replaceAll('.csv', '');

        final target = FrCurveData.autoDetectAndParse(content, name: name);
        notifier.importTarget(target);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully imported target response: $name (${target.frequencies.length} points)'),
              backgroundColor: const Color(0xFF00897B),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to import target: $e'),
            backgroundColor: const Color(0xFFB71C1C),
          ),
        );
      }
    }
  }
}
