import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/auto_eq_optimizer.dart';
import '../../domain/fr_curve_data.dart';
import '../controllers/eq_controller.dart';
import '../controllers/eq_state.dart';
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
      name: 'HBB%20Target',
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

  @override
  Widget build(BuildContext context) {
    final eqState = ref.watch(eqControllerProvider);
    final notifier = ref.read(eqControllerProvider.notifier);

    final selectedDriver = eqState.driverFr;
    final selectedTarget = eqState.targetFr;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Container(
        width: 650,
        constraints: const BoxConstraints(maxHeight: 385),
        decoration: BoxDecoration(
          color: const Color(0xFF131822),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF242F3C), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.65),
              blurRadius: 28,
              spreadRadius: 6,
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Draggable Grabber Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF374151),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Header Row: Sparkle + Title & Subtitle + Close Button
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.auto_awesome,
                  size: 17,
                  color: Color(0xFF00E676),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'AUTO EQ STUDIO & TARGET MATCHING',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Match headphone driver FR against target curve or import Squiglink EQ files',
                        style: TextStyle(
                          color: Color(0xFF8899A6),
                          fontSize: 10.0,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: Color(0xFF8899A6),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Main Two-Column Layout
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── LEFT COLUMN: Driver, Target, Bands, Modes, Clear ───────
                  Expanded(
                    flex: 14,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Section 1: HEADPHONE / SPEAKER DRIVER
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'HEADPHONE / SPEAKER DRIVER',
                                  style: TextStyle(
                                    color: Color(0xFF90A4AE),
                                    fontSize: 9.0,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                if (selectedDriver != null)
                                  InkWell(
                                    onTap: () => notifier.deleteDriver(),
                                    child: Row(
                                      children: const [
                                        Icon(
                                          Icons.delete_outline,
                                          size: 11,
                                          color: Color(0xFFEF5350),
                                        ),
                                        SizedBox(width: 2),
                                        Text(
                                          'HAPUS',
                                          style: TextStyle(
                                            color: Color(0xFFEF5350),
                                            fontSize: 9.0,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            _buildDriverDropdown(eqState, notifier),
                          ],
                        ),

                        // Section 2: TARGET RESPONSE CURVE
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'TARGET RESPONSE CURVE',
                                  style: TextStyle(
                                    color: Color(0xFF90A4AE),
                                    fontSize: 9.0,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                if (selectedTarget != null)
                                  InkWell(
                                    onTap: () => notifier.deleteTarget(),
                                    child: Row(
                                      children: const [
                                        Icon(
                                          Icons.delete_outline,
                                          size: 11,
                                          color: Color(0xFFEF5350),
                                        ),
                                        SizedBox(width: 2),
                                        Text(
                                          'HAPUS',
                                          style: TextStyle(
                                            color: Color(0xFFEF5350),
                                            fontSize: 9.0,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            _buildTargetDropdown(eqState, notifier),
                          ],
                        ),

                        // Section 3: BAND RESOLUTION
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'BAND RESOLUTION',
                              style: TextStyle(
                                color: Color(0xFF90A4AE),
                                fontSize: 9.0,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
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
                                        height: 28,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? const Color(0xFF132A20)
                                              : const Color(0xFF161D27),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: isSelected
                                                ? const Color(0xFF00E676)
                                                : const Color(0xFF26323F),
                                            width: isSelected ? 1.2 : 0.8,
                                          ),
                                        ),
                                        child: Text(
                                          res.label,
                                          style: TextStyle(
                                            color: isSelected
                                                ? const Color(0xFF00E676)
                                                : const Color(0xFF90A4AE),
                                            fontSize: 10.0,
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
                          ],
                        ),

                        // Section 4: TUNING MODE & A/B COMPARISON
                        Row(
                          children: [
                            // Tuning Mode
                            Expanded(
                              flex: 5,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'TUNING MODE',
                                    style: TextStyle(
                                      color: Color(0xFF90A4AE),
                                      fontSize: 9.0,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF161D27),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: const Color(0xFF26323F),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        _buildTuningModeChip(
                                          label: '⚡ Normal',
                                          isSelected: eqState.tuningMode == TuningMode.normal,
                                          onTap: () => notifier.setTuningMode(TuningMode.normal),
                                        ),
                                        _buildTuningModeChip(
                                          label: '🛡️ Safe',
                                          isSelected: eqState.tuningMode == TuningMode.safe,
                                          onTap: () => notifier.setTuningMode(TuningMode.safe),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),

                            // A/B Comparison
                            Expanded(
                              flex: 6,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'A/B COMPARISON',
                                    style: TextStyle(
                                      color: Color(0xFF90A4AE),
                                      fontSize: 9.0,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF161D27),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: const Color(0xFF26323F),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        _buildAbChip(
                                          label: '🎚️ A: RAW',
                                          isSelected: eqState.abMode == AbComparisonMode.aRaw,
                                          activeColor: const Color(0xFF29B6F6),
                                          onTap: () => notifier.setAbComparison(AbComparisonMode.aRaw),
                                        ),
                                        _buildAbChip(
                                          label: '🎚️ B: ACTIVE',
                                          isSelected: eqState.abMode == AbComparisonMode.bActive,
                                          activeColor: const Color(0xFF00E676),
                                          onTap: () => notifier.setAbComparison(AbComparisonMode.bActive),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Section 5: Clear Curves Action
                        InkWell(
                          onTap: () {
                            notifier.clearFrCurves();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Visualizer FR curves cleared from canvas.'),
                                duration: Duration(seconds: 2),
                                backgroundColor: Color(0xFF263238),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                            child: Row(
                              children: const [
                                Icon(
                                  Icons.block,
                                  size: 12,
                                  color: Color(0xFFEF5350),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'CLEAR VISUALIZER FR CURVES',
                                  style: TextStyle(
                                    color: Color(0xFFEF5350),
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 14),

                  // ─── RIGHT COLUMN: Action Buttons & APPLY TO DSP ───────────
                  Expanded(
                    flex: 9,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'ACTIONS & IMPORTS',
                          style: TextStyle(
                            color: Color(0xFF90A4AE),
                            fontSize: 9.0,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),

                        // Button 1: [🎧 IMPORT DRIVER]
                        _buildActionOutlinedButton(
                          icon: Icons.headphones,
                          label: 'IMPORT DRIVER',
                          borderColor: const Color(0xFF0288D1),
                          color: const Color(0xFF29B6F6),
                          bgColor: const Color(0xFF131D28),
                          onTap: () => _handleImportDriver(context, notifier),
                        ),

                        // Button 2: [🎯 IMPORT TARGET]
                        _buildActionOutlinedButton(
                          icon: Icons.adjust,
                          label: 'IMPORT TARGET',
                          borderColor: const Color(0xFF00897B),
                          color: const Color(0xFF00E676),
                          bgColor: const Color(0xFF132620),
                          onTap: () => _handleImportTarget(context, notifier),
                        ),

                        // Button 3: [✨ SQUIGLINK EQ]
                        _buildActionOutlinedButton(
                          icon: Icons.auto_awesome,
                          label: 'SQUIGLINK EQ',
                          borderColor: const Color(0xFF7B1FA2),
                          color: const Color(0xFFCE93D8),
                          bgColor: const Color(0xFF22162A),
                          onTap: () {
                            showDialog<void>(
                              context: context,
                              builder: (context) => const SquiglinkDialog(),
                            );
                          },
                        ),

                        // Button 4: [📊 APPLY TO DSP] (Big emerald button)
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
                                      'AutoEQ Applied! Fitted ${eqState.bandResolution.count} biquads (${selectedDriver?.name ?? "Driver"} → ${selectedTarget?.name ?? "Target"}). Preamp: ${eqState.safePreampDb.toStringAsFixed(1)} dB',
                                    ),
                                    backgroundColor: const Color(0xFF1B5E20),
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please select both a Driver and Target curve before applying.'),
                                    backgroundColor: Color(0xFFB71C1C),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              height: 60,
                              decoration: BoxDecoration(
                                color: const Color(0xFF00E676),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00E676).withValues(alpha: 0.35),
                                    blurRadius: 14,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    Icons.bar_chart,
                                    size: 20,
                                    color: Color(0xFF091A10),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'APPLY TO DSP',
                                    style: TextStyle(
                                      color: Color(0xFF091A10),
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.8,
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverDropdown(EqState state, EqController notifier) {
    final driver = state.driverFr;
    final allDrivers = [
      ..._defaultDrivers,
      ...state.availableDrivers.where((d) => !_defaultDrivers.any((x) => x.name == d.name)),
    ];

    return PopupMenuButton<FrCurveData>(
      color: const Color(0xFF141922),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFF2C3542), width: 1),
      ),
      onSelected: (d) => notifier.selectDriver(d),
      itemBuilder: (context) => allDrivers.map((d) {
        final isSelected = driver?.name == d.name;
        return PopupMenuItem<FrCurveData>(
          value: d,
          child: Row(
            children: [
              Icon(
                Icons.headphones,
                size: 14,
                color: isSelected ? const Color(0xFF29B6F6) : const Color(0xFF90A4AE),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  d.name,
                  style: TextStyle(
                    color: isSelected ? const Color(0xFF29B6F6) : Colors.white,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 11,
                  ),
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
          color: const Color(0xFF19202B),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF2A3545), width: 1.0),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.cloud_outlined,
              size: 15,
              color: Color(0xFF29B6F6),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                driver?.name ?? 'Select Headphone Driver...',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11.0,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(
              Icons.arrow_drop_down,
              size: 18,
              color: Color(0xFF90A4AE),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetDropdown(EqState state, EqController notifier) {
    final target = state.targetFr;
    final allTargets = [
      ..._defaultTargets,
      ...state.availableTargets.where((t) => !_defaultTargets.any((x) => x.name == t.name)),
    ];

    return PopupMenuButton<FrCurveData>(
      color: const Color(0xFF141922),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFF2C3542), width: 1),
      ),
      onSelected: (t) => notifier.selectTarget(t),
      itemBuilder: (context) => allTargets.map((t) {
        final isSelected = target?.name == t.name;
        return PopupMenuItem<FrCurveData>(
          value: t,
          child: Row(
            children: [
              Icon(
                Icons.adjust,
                size: 14,
                color: isSelected ? const Color(0xFF00E676) : const Color(0xFF90A4AE),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  t.name,
                  style: TextStyle(
                    color: isSelected ? const Color(0xFF00E676) : Colors.white,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 11,
                  ),
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
          color: const Color(0xFF19202B),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF2A3545), width: 1.0),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.cloud_outlined,
              size: 15,
              color: Color(0xFF00E676),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                target?.name ?? 'Select Target Response...',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11.0,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(
              Icons.arrow_drop_down,
              size: 18,
              color: Color(0xFF90A4AE),
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
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(5),
        child: Container(
          margin: const EdgeInsets.all(2),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0288D1) : Colors.transparent,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF90A4AE),
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
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(5),
        child: Container(
          margin: const EdgeInsets.all(2),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? activeColor.withValues(alpha: 0.18) : Colors.transparent,
            borderRadius: BorderRadius.circular(5),
            border: isSelected ? Border.all(color: activeColor, width: 1.0) : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? activeColor : const Color(0xFF90A4AE),
              fontSize: 9.5,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionOutlinedButton({
    required IconData icon,
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
        height: 33,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: 1.0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10.0,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
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
