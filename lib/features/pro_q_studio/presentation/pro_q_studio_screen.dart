import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../app/theme/studio_surface_theme.dart';
import '../../../../core/database/local_persistence_service.dart';
import 'controllers/eq_controller.dart';
import 'controllers/eq_state.dart';
import 'widgets/band_strip_bar.dart';
import '../domain/auto_eq_optimizer.dart';
import 'widgets/auto_eq_cloud_browser_dialog.dart';
import 'widgets/auto_eq_modal_dialog.dart';
import 'widgets/interactive_eq_canvas.dart';

class ProQStudioScreen extends ConsumerStatefulWidget {
  const ProQStudioScreen({super.key});

  @override
  ConsumerState<ProQStudioScreen> createState() => _ProQStudioScreenState();
}

class _ProQStudioScreenState extends ConsumerState<ProQStudioScreen> {
  @override
  void initState() {
    super.initState();
    // Lock orientation to landscape and enter immersive fullscreen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    // Restore orientation and system UI when exiting Pro-Q Studio
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eqState = ref.watch(eqControllerProvider);
    final notifier = ref.read(eqControllerProvider.notifier);
    final isSolid = ref.isSolidStyle;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Studio Toolbar & Legend with Exit (Left) and Power (Right) Fixed
            _buildTopBar(context, eqState, notifier, isSolid),

            // 2. Interactive Pro-Q Studio Canvas
            const Expanded(
              child: InteractiveEqCanvas(),
            ),

            // 3. Bottom Control Strip (Band Pills & Action Buttons)
            const BandStripBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    EqState state,
    EqController notifier,
    bool isSolid,
  ) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: StudioSurfaceTheme.surface(context, isSolid: isSolid),
        border: Border(
          bottom: BorderSide(
            color: StudioSurfaceTheme.outline(context, isSolid: isSolid),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          // ─── 1. FIXED LEFT: Exit Button (<) & Title ────────────────────────
          InkWell(
            onTap: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid),
                  width: 1.0,
                ),
              ),
              child: Center(
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowLeft01,
                  size: 15,
                  color: primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedSlidersVertical,
                size: 15,
                color: primary,
              ),
              const SizedBox(width: 6),
              Text(
                'PRO-Q STUDIO',
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(width: 4),
              Tooltip(
                message: 'Studio Parametric Equalizer with Biquad IIR Engine',
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid),
                      width: 1,
                    ),
                  ),
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedHelpCircle,
                    size: 9.0,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 12),

          // ─── 2. SCROLLABLE CENTER: Legend & Toolbar Actions ────────────────
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildLegendItem(
                    label: 'EQ',
                    color: primary,
                    isDashed: false,
                  ),
                  const SizedBox(width: 8),
                  _buildLegendItem(
                    label: 'Driver FR',
                    color: const Color(0xFF29B6F6),
                    isDashed: true,
                  ),
                  const SizedBox(width: 8),
                  _buildLegendItem(
                    label: 'Target',
                    color: const Color(0xFF00E676),
                    isDashed: true,
                  ),
                  const SizedBox(width: 6),

                  // [x HIDE FR] / [SHOW FR] Toggle Button
                  InkWell(
                    onTap: () => notifier.toggleFrCurves(),
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        state.showFrCurves ? 'HIDE FR' : 'SHOW FR',
                        style: TextStyle(
                          color: state.showFrCurves
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.onSurfaceVariant,
                          fontSize: 9.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  _buildLegendItem(
                    label: 'RTA',
                    color: const Color(0xFF00E5FF),
                    isDashed: false,
                  ),

                  const SizedBox(width: 12),

                  // [∿ RTA] Button
                  _buildToolbarButton(
                    context: context,
                    icon: HugeIcons.strokeRoundedAudioWaveform,
                    label: 'RTA',
                    color: const Color(0xFF00E5FF),
                    isActive: state.isRtaEnabled,
                    isSolid: isSolid,
                    onTap: () => notifier.toggleRta(),
                  ),

                  const SizedBox(width: 6),

                  // [AUTO EQ] Button
                  _buildToolbarButton(
                    context: context,
                    icon: HugeIcons.strokeRoundedSparkles,
                    label: 'AUTO EQ •',
                    color: const Color(0xFF00E676),
                    isActive: true,
                    isSolid: isSolid,
                    onTap: () => AutoEqModalDialog.show(context),
                  ),

                  const SizedBox(width: 6),

                  // [CLOUD DB] Button
                  _buildToolbarButton(
                    context: context,
                    icon: HugeIcons.strokeRoundedCloudDownload,
                    label: 'CLOUD DB',
                    color: const Color(0xFF00E5FF),
                    isActive: true,
                    isSolid: isSolid,
                    onTap: () => AutoEqCloudBrowserDialog.show(context),
                  ),

                  const SizedBox(width: 6),

                  // [A/B] Quick Comparison Button
                  _buildToolbarButton(
                    context: context,
                    icon: HugeIcons.strokeRoundedExchange01,
                    label: state.abMode == AbComparisonMode.aRaw ? 'A: RAW' : 'B: ACTIVE',
                    color: state.abMode == AbComparisonMode.aRaw
                        ? const Color(0xFF29B6F6)
                        : const Color(0xFF00E676),
                    isActive: true,
                    isSolid: isSolid,
                    onTap: () {
                      final next = state.abMode == AbComparisonMode.aRaw
                          ? AbComparisonMode.bActive
                          : AbComparisonMode.aRaw;
                      notifier.setAbComparison(next);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            next == AbComparisonMode.aRaw
                                ? 'A/B: Switched to [A: RAW Direct Audiophile Bypass]'
                                : 'A/B: Switched to [B: ACTIVE Target Tuned Equalizer]',
                          ),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  ),

                  const SizedBox(width: 6),

                  // [PRESETS] Popup Button
                  PopupMenuButton<String>(
                    color: StudioSurfaceTheme.surface(context, isSolid: isSolid),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: StudioSurfaceTheme.outline(context, isSolid: isSolid),
                        width: 1,
                      ),
                    ),
                    onSelected: (val) => notifier.applyPreset(val),
                    itemBuilder: (context) => [
                      'Default 10-Band',
                      'Flat',
                      'Bass Boost',
                      'V-Shape',
                      'Vocal Clarity',
                      'Treble Tamer',
                    ].map((p) {
                      final isCurr = state.activePresetName == p;
                      return PopupMenuItem(
                        value: p,
                        child: Row(
                          children: [
                            HugeIcon(
                              icon: isCurr
                                  ? HugeIcons.strokeRoundedCheckmarkCircle02
                                  : HugeIcons.strokeRoundedCircle,
                              size: 14,
                              color: isCurr ? primary : theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              p,
                              style: TextStyle(
                                color: isCurr ? primary : theme.colorScheme.onSurface,
                                fontSize: 12,
                                fontWeight: isCurr ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    child: _buildToolbarButton(
                      context: context,
                      icon: HugeIcons.strokeRoundedBookmark02,
                      label: 'PRESETS',
                      color: primary,
                      isActive: false,
                      isSolid: isSolid,
                      onTap: null,
                    ),
                  ),

                  const SizedBox(width: 6),

                  // [RESET] Button
                  _buildToolbarButton(
                    context: context,
                    icon: HugeIcons.strokeRoundedRefresh,
                    label: 'RESET',
                    color: theme.colorScheme.error,
                    isActive: false,
                    isSolid: isSolid,
                    onTap: () => notifier.resetToDefault(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          // ─── 2.5 INTERACTIVE SAVE PRESET BUTTON ───────────────────────────
          Tooltip(
            message: 'Save Pro-Q Preset & Target Profile',
            child: InkWell(
              onTap: () => _showSavePresetDialog(context, state, notifier, isSolid),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: StudioSurfaceTheme.tintedContainer(
                    context,
                    const Color(0xFF00E676),
                    isSolid: isSolid,
                    translucentAlpha: 0.15,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSolid ? theme.colorScheme.outline : const Color(0xFF00E676).withValues(alpha: 0.6),
                    width: 1.0,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedFloppyDisk,
                      size: 14,
                      color: Color(0xFF00E676),
                    ),
                    SizedBox(width: 5),
                    Text(
                      'SAVE',
                      style: TextStyle(
                        color: Color(0xFF00E676),
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // ─── 3. FIXED RIGHT: Tombol Power ON/OFF (Always Visible) ────────────
          Tooltip(
            message: state.isEnabled ? 'Bypass EQ (Turn OFF)' : 'Enable EQ (Turn ON)',
            child: InkWell(
              onTap: () => notifier.togglePower(),
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: state.isEnabled
                      ? StudioSurfaceTheme.tintedContainer(
                          context,
                          primary,
                          isSolid: isSolid,
                          translucentAlpha: 0.15,
                        )
                      : StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid),
                  border: Border.all(
                    color: state.isEnabled
                        ? (isSolid ? theme.colorScheme.outline : primary)
                        : StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid),
                    width: 1.5,
                  ),
                  boxShadow: state.isEnabled
                      ? [
                          BoxShadow(
                            color: primary.withValues(alpha: isSolid ? 0.2 : 0.4),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedPower,
                    size: 16,
                    color: state.isEnabled
                        ? primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required String label,
    required Color color,
    required bool isDashed,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: const Size(14, 2),
          painter: _LegendLinePainter(color: color, isDashed: isDashed),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10.0,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildToolbarButton({
    required BuildContext context,
    required dynamic icon,
    required String label,
    required Color color,
    required bool isActive,
    required bool isSolid,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: isActive
              ? StudioSurfaceTheme.tintedContainer(
                  context,
                  color,
                  isSolid: isSolid,
                  translucentAlpha: 0.12,
                )
              : StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isActive
                ? (isSolid ? theme.colorScheme.outline : color.withValues(alpha: 0.8))
                : StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid),
            width: 1.0,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: isSolid ? 0.15 : 0.25),
                    blurRadius: 6,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              icon: icon,
              size: 12,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSavePresetDialog(
    BuildContext context,
    EqState state,
    EqController notifier,
    bool isSolid,
  ) {
    final theme = Theme.of(context);
    final textController = TextEditingController(
      text: state.targetFr != null
          ? '${state.targetFr!.name} Tuned'
          : (state.activePresetName != 'Custom' ? state.activePresetName : 'Custom Pro-Q'),
    );

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: StudioSurfaceTheme.surface(dialogCtx, isSolid: isSolid),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: StudioSurfaceTheme.outline(dialogCtx, isSolid: isSolid),
            width: 1,
          ),
        ),
        title: const Row(
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedFloppyDisk,
              size: 20,
              color: Color(0xFF00E676),
            ),
            SizedBox(width: 10),
            Text(
              'Save EQ Preset',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Save current 10-band parametric curves, gain levels, and target matching profile.',
              style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 12),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: textController,
              autofocus: true,
              style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 13, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                labelText: 'Preset Name',
                labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
                filled: true,
                fillColor: StudioSurfaceTheme.surfaceContainerHigh(dialogCtx, isSolid: isSolid),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: StudioSurfaceTheme.subtleOutline(dialogCtx, isSolid: isSolid)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF00E676)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text('CANCEL', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E676),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              final name = textController.text.trim();
              if (name.isNotEmpty) {
                if (state.driverFr != null) {
                  LocalPersistenceService.instance.saveFrCurve(
                    state.driverFr!.toMap(category: 'driver'),
                  );
                }
                if (state.targetFr != null) {
                  LocalPersistenceService.instance.saveFrCurve(
                    state.targetFr!.toMap(category: 'target'),
                  );
                }
                Navigator.of(dialogCtx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Saved Pro-Q preset "$name" successfully'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('SAVE PRESET', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _LegendLinePainter extends CustomPainter {
  final Color color;
  final bool isDashed;

  _LegendLinePainter({required this.color, required this.isDashed});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    if (!isDashed) {
      canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), paint);
    } else {
      canvas.drawLine(Offset(0, size.height / 2), Offset(size.width * 0.38, size.height / 2), paint);
      canvas.drawLine(Offset(size.width * 0.62, size.height / 2), Offset(size.width, size.height / 2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LegendLinePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.isDashed != isDashed;
  }
}
