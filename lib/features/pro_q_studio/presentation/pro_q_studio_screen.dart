import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../app/theme/studio_surface_theme.dart';
import '../../settings/presentation/controllers/player_customization_controller.dart';
import '../domain/pro_q_rta_style.dart';
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
    final eqState = state;

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

                  // [∿ RTA Quick Group (Toggle + Style Dropdown)]
                  _buildRtaToolbarGroup(context, state, notifier, isSolid),

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

                  // [PRESETS] Popup Button — shows built-in & custom presets
                  _buildPresetsPopup(context, eqState, notifier, theme, isSolid, primary),

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

          // ─── 2.5 SMART SAVE / NEW PRESET BUTTON ──────────────────────────
          if (state.isDirty)
            // SAVE button — update the currently-loaded preset
            Tooltip(
              message: state.isCustomPresetLoaded
                  ? 'Save changes to "${state.activePresetName}"'
                  : 'Save current EQ as new preset',
              child: InkWell(
                onTap: () => _handleSaveTap(context, eqState, notifier),
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
                      color: isSolid
                          ? theme.colorScheme.outline
                          : const Color(0xFF00E676).withValues(alpha: 0.6),
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
            )
          else
            // "+" button — create a brand new named preset
            Tooltip(
              message: 'Save current EQ as new preset',
              child: InkWell(
                onTap: () => _handleNewPresetTap(context, eqState, notifier),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 32,
                  width: 32,
                  decoration: BoxDecoration(
                    color: StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid),
                      width: 1.0,
                    ),
                  ),
                  child: Center(
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedAdd01,
                      size: 15,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),

          const SizedBox(width: 8),

          // ─── 3. FIXED RIGHT: Power ON/OFF Button ────────────────────────────
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

  // ─── Presets Popup: Built-in + Custom with long-press delete ─────────────────

  Widget _buildPresetsPopup(
    BuildContext context,
    EqState eqState,
    EqController notifier,
    ThemeData theme,
    bool isSolid,
    Color primary,
  ) {
    const builtIn = kBuiltInEqPresets;
    final custom = eqState.customPresetNames;

    return PopupMenuButton<String>(
      color: StudioSurfaceTheme.surface(context, isSolid: isSolid),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: StudioSurfaceTheme.outline(context, isSolid: isSolid),
          width: 1,
        ),
      ),
      onSelected: (val) => notifier.applyPreset(val),
      itemBuilder: (ctx) {
        final items = <PopupMenuEntry<String>>[];

        // Built-in header
        items.add(PopupMenuItem<String>(
          enabled: false,
          height: 28,
          child: Text(
            'FACTORY PRESETS',
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ));

        for (final p in builtIn) {
          final isCurr = eqState.activePresetName == p;
          items.add(PopupMenuItem<String>(
            value: p,
            child: Row(
              children: [
                HugeIcon(
                  icon: isCurr
                      ? HugeIcons.strokeRoundedCheckmarkCircle02
                      : HugeIcons.strokeRoundedCircle,
                  size: 13,
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
          ));
        }

        // Custom presets section (if any)
        if (custom.isNotEmpty) {
          items.add(const PopupMenuDivider());
          items.add(PopupMenuItem<String>(
            enabled: false,
            height: 28,
            child: Text(
              'MY PRESETS',
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
          ));
          for (final p in custom) {
            final isCurr = eqState.activePresetName == p;
            items.add(PopupMenuItem<String>(
              value: p,
              child: Row(
                children: [
                  HugeIcon(
                    icon: isCurr
                        ? HugeIcons.strokeRoundedCheckmarkCircle02
                        : HugeIcons.strokeRoundedFloppyDisk,
                    size: 13,
                    color: isCurr ? primary : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      p,
                      style: TextStyle(
                        color: isCurr ? primary : theme.colorScheme.onSurface,
                        fontSize: 12,
                        fontWeight: isCurr ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                  // Delete button for custom presets
                  GestureDetector(
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _confirmDeletePreset(context, p, notifier);
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedDelete02,
                        size: 13,
                        color: theme.colorScheme.error.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ));
          }
        }

        return items;
      },
      child: _buildToolbarButton(
        context: context,
        icon: HugeIcons.strokeRoundedBookmark02,
        label: 'PRESETS',
        color: primary,
        isActive: false,
        isSolid: isSolid,
        onTap: null,
      ),
    );
  }

  // ─── Save Handlers ─────────────────────────────────────────────────────────

  /// Called when SAVE button is tapped (isDirty = true).
  /// If a custom preset is loaded → overwrite silently.
  /// Otherwise → open fullscreen name dialog.
  Future<void> _handleSaveTap(
    BuildContext context,
    EqState state,
    EqController notifier,
  ) async {
    if (state.isCustomPresetLoaded) {
      // Overwrite the currently loaded custom preset
      await notifier.saveToCurrentPreset();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Preset "${state.activePresetName}" updated'),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      // Built-in or Custom (unnamed) → ask for a name
      await _openNameDialogAndSave(context, state, notifier);
    }
  }

  /// Called when "+" button is tapped (isDirty = false).
  /// Always opens the name dialog for a new preset.
  Future<void> _handleNewPresetTap(
    BuildContext context,
    EqState state,
    EqController notifier,
  ) async {
    await _openNameDialogAndSave(context, state, notifier);
  }

  /// Opens a fullscreen name entry page and saves the result as a preset.
  Future<void> _openNameDialogAndSave(
    BuildContext context,
    EqState state,
    EqController notifier,
  ) async {
    final suggested = _suggestPresetName(state);
    final name = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) => _FullscreenPresetNamePage(initialValue: suggested),
      ),
    );
    if (name == null || name.trim().isEmpty) return;
    await notifier.saveAsNewPreset(name.trim());
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Preset "$name" saved'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _suggestPresetName(EqState state) {
    if (state.targetFr != null) return '${state.targetFr!.name} Tuned';
    if (state.activePresetName != 'Custom' &&
        state.activePresetName != 'Custom AutoEQ') {
      return state.activePresetName;
    }
    return 'My Custom EQ';
  }

  void _confirmDeletePreset(
    BuildContext context,
    String name,
    EqController notifier,
  ) {
    showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Preset'),
        content: Text('Delete "$name"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('DELETE'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        notifier.deleteCustomPreset(name);
      }
    });
  }

  // ─── Utility Widgets ───────────────────────────────────────────────────────

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

  Widget _buildRtaToolbarGroup(
    BuildContext context,
    EqState state,
    EqController notifier,
    bool isSolid,
  ) {
    final theme = Theme.of(context);
    const rtaCyan = Color(0xFF00E5FF);
    final isActive = state.isRtaEnabled;
    final currentStyle = ref.watch(playerCustomizationProvider).proQRtaStyle;

    return Container(
      height: 28,
      decoration: BoxDecoration(
        color: isActive
            ? StudioSurfaceTheme.tintedContainer(
                context,
                rtaCyan,
                isSolid: isSolid,
                translucentAlpha: 0.12,
              )
            : StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isActive
              ? (isSolid ? theme.colorScheme.outline : rtaCyan.withValues(alpha: 0.8))
              : StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid),
          width: 1.0,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: rtaCyan.withValues(alpha: isSolid ? 0.15 : 0.25),
                  blurRadius: 6,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Toggle RTA ON/OFF
          InkWell(
            onTap: () => notifier.toggleRta(),
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(5)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedAudioWaveform,
                    size: 11.5,
                    color: isActive ? rtaCyan : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'RTA',
                    style: TextStyle(
                      color: isActive ? rtaCyan : theme.colorScheme.onSurfaceVariant,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Vertical separator
          Container(
            width: 1.0,
            height: 14,
            color: isActive
                ? rtaCyan.withValues(alpha: 0.35)
                : StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid),
          ),

          // 2. Style Dropdown Quick Switcher
          PopupMenuButton<ProQRtaStyle>(
            color: StudioSurfaceTheme.surface(context, isSolid: isSolid),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(
                color: StudioSurfaceTheme.outline(context, isSolid: isSolid),
                width: 1,
              ),
            ),
            tooltip: 'RTA Spectrum Graph Style',
            onSelected: (style) {
              ref.read(playerCustomizationProvider.notifier).setProQRtaStyle(style);
              notifier.setRtaStyle(style);
            },
            itemBuilder: (ctx) {
              final items = <PopupMenuEntry<ProQRtaStyle>>[];
              items.add(PopupMenuItem<ProQRtaStyle>(
                enabled: false,
                height: 28,
                child: Text(
                  'RTA SPECTRUM STYLE',
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
              ));

              for (final s in ProQRtaStyle.values) {
                final isCurr = currentStyle == s;
                items.add(PopupMenuItem<ProQRtaStyle>(
                  value: s,
                  child: Row(
                    children: [
                      HugeIcon(
                        icon: isCurr
                            ? HugeIcons.strokeRoundedCheckmarkCircle02
                            : _getProQRtaIcon(s),
                        size: 13,
                        color: isCurr ? rtaCyan : theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              s.label,
                              style: TextStyle(
                                color: isCurr ? rtaCyan : theme.colorScheme.onSurface,
                                fontSize: 11.5,
                                fontWeight: isCurr ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                            Text(
                              s.description,
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 9.0,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ));
              }
              return items;
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getRtaShortLabel(currentStyle),
                    style: TextStyle(
                      color: isActive ? rtaCyan : theme.colorScheme.onSurfaceVariant,
                      fontSize: 9.0,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(width: 2),
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedArrowDown01,
                    size: 10,
                    color: isActive ? rtaCyan : theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getRtaShortLabel(ProQRtaStyle style) {
    switch (style) {
      case ProQRtaStyle.bars:
        return 'BARS';
      case ProQRtaStyle.filledCurve:
        return 'FILL';
      case ProQRtaStyle.wireframe:
        return 'LINE';
      case ProQRtaStyle.m3Pillars:
        return 'M3';
      case ProQRtaStyle.peakDots:
        return 'DOTS';
      case ProQRtaStyle.laserBeam:
        return 'LASER';
    }
  }

  dynamic _getProQRtaIcon(ProQRtaStyle style) {
    switch (style) {
      case ProQRtaStyle.bars:
        return HugeIcons.strokeRoundedSlidersVertical;
      case ProQRtaStyle.filledCurve:
        return HugeIcons.strokeRoundedAudioWaveform;
      case ProQRtaStyle.wireframe:
        return HugeIcons.strokeRoundedActivity01;
      case ProQRtaStyle.m3Pillars:
        return HugeIcons.strokeRoundedLayers01;
      case ProQRtaStyle.peakDots:
        return HugeIcons.strokeRoundedGrid;
      case ProQRtaStyle.laserBeam:
        return HugeIcons.strokeRoundedSparkles;
    }
  }
}


// ─── Fullscreen Name Input Page ─────────────────────────────────────────────

/// A fullscreen page used for entering a preset name in landscape mode.
/// The keyboard fills the available space — recommended for landscape inputs.
class _FullscreenPresetNamePage extends StatefulWidget {
  final String initialValue;

  const _FullscreenPresetNamePage({required this.initialValue});

  @override
  State<_FullscreenPresetNamePage> createState() => _FullscreenPresetNamePageState();
}

class _FullscreenPresetNamePageState extends State<_FullscreenPresetNamePage> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isNotEmpty) Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedCancel01,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          onPressed: () => Navigator.of(context).pop(null),
          tooltip: 'Cancel',
        ),
        title: Row(
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedFloppyDisk,
              size: 18,
              color: const Color(0xFF00E676),
            ),
            const SizedBox(width: 10),
            Text(
              'Save EQ Preset',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF00E676),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              onPressed: _submit,
              child: const Text(
                'SAVE',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: theme.colorScheme.outlineVariant,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Name your EQ preset to save band settings and preamp gain.',
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: 'e.g. My Audiophile Tune, HBB Target Matched...',
                hintStyle: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
                  fontSize: 14,
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outlineVariant,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF00E676),
                    width: 2,
                  ),
                ),
                prefixIcon: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedText,
                    size: 18,
                    color: Color(0xFF00E676),
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 44),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Legend Line Painter ────────────────────────────────────────────────────

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
