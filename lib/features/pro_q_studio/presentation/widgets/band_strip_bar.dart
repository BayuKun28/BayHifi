import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../app/theme/studio_surface_theme.dart';
import '../../domain/eq_band.dart';
import '../controllers/eq_controller.dart';

class BandStripBar extends ConsumerWidget {
  const BandStripBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eqState = ref.watch(eqControllerProvider);
    final notifier = ref.read(eqControllerProvider.notifier);
    final selectedBand = eqState.selectedBand;
    final isSolid = ref.isSolidStyle;
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 620;

        if (isCompact) {
          // Mobile Portrait View: Two neat tiers
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: StudioSurfaceTheme.surface(context, isSolid: isSolid),
              border: Border(
                top: BorderSide(
                  color: StudioSurfaceTheme.outline(context, isSolid: isSolid),
                  width: 1.0,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tier 1: Horizontal scrolling band pills
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: eqState.bands.length,
                    separatorBuilder: (_, index) => const SizedBox(width: 6),
                    itemBuilder: (context, index) {
                      final band = eqState.bands[index];
                      final isSelected = band.index == eqState.selectedBandIndex;

                      return _BandPill(
                        band: band,
                        isSelected: isSelected,
                        compact: true,
                        isSolid: isSolid,
                        onTap: () => notifier.selectBand(band.index),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 6),
                // Tier 2: Controls & Readouts
                SizedBox(
                  height: 38,
                  child: Row(
                    children: [
                      _ActionButton(
                        icon: HugeIcons.strokeRoundedAdd01,
                        tooltip: 'Add Band',
                        color: const Color(0xFF00E5FF),
                        isSolid: isSolid,
                        onPressed: () => notifier.addBand(),
                      ),
                      const SizedBox(width: 4),
                      _ActionButton(
                        icon: HugeIcons.strokeRoundedDelete02,
                        tooltip: 'Delete Selected Band',
                        color: const Color(0xFFEF5350),
                        isSolid: isSolid,
                        onPressed: selectedBand != null && eqState.bands.length > 1
                            ? () => notifier.removeBand(selectedBand.index)
                            : null,
                      ),
                      const SizedBox(width: 4),
                      _ActionButton(
                        icon: HugeIcons.strokeRoundedRefresh,
                        tooltip: 'Reset Active Band Gain',
                        color: theme.colorScheme.onSurfaceVariant,
                        isSolid: isSolid,
                        onPressed: selectedBand != null ? () => notifier.resetActiveBand() : null,
                      ),
                      const Spacer(),
                      _ReadoutBox(
                        label: 'FREQ',
                        value: selectedBand != null ? '${selectedBand.formattedFreq}Hz' : '--',
                        color: theme.colorScheme.onSurface,
                        isSolid: isSolid,
                      ),
                      const SizedBox(width: 4),
                      _ReadoutBox(
                        label: 'GAIN',
                        value: selectedBand != null ? '${selectedBand.formattedGain}dB' : '--',
                        color: selectedBand != null && selectedBand.gainDb > 0
                            ? const Color(0xFFFF9F0A)
                            : const Color(0xFF64D2FF),
                        isSolid: isSolid,
                      ),
                      const SizedBox(width: 4),
                      _ReadoutBox(
                        label: 'Q',
                        value: selectedBand != null ? selectedBand.q.toStringAsFixed(2) : '--',
                        color: theme.colorScheme.onSurfaceVariant,
                        isSolid: isSolid,
                      ),
                      const SizedBox(width: 6),
                      _PreampBox(
                        safePreampDb: eqState.safePreampDb,
                        isAuto: eqState.autoPreampEnabled,
                        isSolid: isSolid,
                        onTap: () => _showPreampModalSheet(context, ref, isSolid),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        // Desktop / Landscape View: Single unified row matching reference screenshot 1
        return Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: StudioSurfaceTheme.surface(context, isSolid: isSolid),
            border: Border(
              top: BorderSide(
                color: StudioSurfaceTheme.outline(context, isSolid: isSolid),
                width: 1.0,
              ),
            ),
          ),
          child: Row(
            children: [
              // 1. Scrollable Band Pills
              Expanded(
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: eqState.bands.length,
                  separatorBuilder: (_, index) => const SizedBox(width: 6),
                  itemBuilder: (context, index) {
                    final band = eqState.bands[index];
                    final isSelected = band.index == eqState.selectedBandIndex;

                    return _BandPill(
                      band: band,
                      isSelected: isSelected,
                      compact: false,
                      isSolid: isSolid,
                      onTap: () => notifier.selectBand(band.index),
                    );
                  },
                ),
              ),

              const SizedBox(width: 10),

              // 2. Action Buttons: Add, Delete, Reset
              _ActionButton(
                icon: HugeIcons.strokeRoundedAdd01,
                tooltip: 'Add Band',
                color: const Color(0xFF00E5FF),
                isSolid: isSolid,
                onPressed: () => notifier.addBand(),
              ),
              const SizedBox(width: 6),
              _ActionButton(
                icon: HugeIcons.strokeRoundedDelete02,
                tooltip: 'Delete Selected Band',
                color: const Color(0xFFEF5350),
                isSolid: isSolid,
                onPressed: selectedBand != null && eqState.bands.length > 1
                    ? () => notifier.removeBand(selectedBand.index)
                    : null,
              ),
              const SizedBox(width: 6),
              _ActionButton(
                icon: HugeIcons.strokeRoundedRefresh,
                tooltip: 'Reset Active Band Gain',
                color: theme.colorScheme.onSurfaceVariant,
                isSolid: isSolid,
                onPressed: selectedBand != null ? () => notifier.resetActiveBand() : null,
              ),

              const SizedBox(width: 10),

              // 3. Precision Readouts: FREQ, GAIN, Q
              _ReadoutBox(
                label: 'FREQ',
                value: selectedBand != null ? '${selectedBand.formattedFreq}Hz' : '--',
                color: theme.colorScheme.onSurface,
                isSolid: isSolid,
              ),
              const SizedBox(width: 6),
              _ReadoutBox(
                label: 'GAIN',
                value: selectedBand != null ? '${selectedBand.formattedGain}dB' : '--',
                color: selectedBand != null && selectedBand.gainDb > 0
                    ? const Color(0xFFFF9F0A)
                    : const Color(0xFF64D2FF),
                isSolid: isSolid,
              ),
              const SizedBox(width: 6),
              _ReadoutBox(
                label: 'Q',
                value: selectedBand != null ? selectedBand.q.toStringAsFixed(2) : '--',
                color: theme.colorScheme.onSurfaceVariant,
                isSolid: isSolid,
              ),

              const SizedBox(width: 10),

              // 4. Safe Preamp Box
              _PreampBox(
                safePreampDb: eqState.safePreampDb,
                isAuto: eqState.autoPreampEnabled,
                isSolid: isSolid,
                onTap: () => _showPreampModalSheet(context, ref, isSolid),
              ),
            ],
          ),
        );
      },
    );
  }

  static void _showPreampModalSheet(BuildContext context, WidgetRef ref, bool isSolid) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Consumer(
          builder: (context, ref, _) {
            final state = ref.watch(eqControllerProvider);
            final notifier = ref.read(eqControllerProvider.notifier);
            final theme = Theme.of(context);

            return Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              decoration: BoxDecoration(
                color: StudioSurfaceTheme.surface(context, isSolid: isSolid),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border.all(
                  color: StudioSurfaceTheme.outline(context, isSolid: isSolid),
                  width: 1.2,
                ),
                boxShadow: isSolid
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 24,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 3),
                        ),
                      ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Grabber handle
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: StudioSurfaceTheme.outline(context, isSolid: isSolid),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: StudioSurfaceTheme.tintedContainer(
                            context,
                            const Color(0xFFEF5350),
                            isSolid: isSolid,
                            translucentAlpha: 0.15,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSolid ? theme.colorScheme.outline : const Color(0xFFEF5350).withValues(alpha: 0.4),
                          ),
                        ),
                        child: const HugeIcon(
                          icon: HugeIcons.strokeRoundedVolumeLow,
                          size: 18,
                          color: Color(0xFFEF5350),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PRE-AMP & DIGITAL HEADROOM',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                              ),
                            ),
                            Text(
                              state.autoPreampEnabled
                                  ? 'Auto-Headroom Active (Zero Inter-Sample Peak Clipping)'
                                  : 'Manual Headroom Gain Stage',
                              style: TextStyle(
                                color: state.autoPreampEnabled
                                    ? const Color(0xFF00E676)
                                    : theme.colorScheme.onSurfaceVariant,
                                fontSize: 10.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: HugeIcon(
                          icon: HugeIcons.strokeRoundedCancel01,
                          size: 18,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Gain Value Big Display
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      color: StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: state.safePreampDb < -0.05
                            ? (isSolid ? theme.colorScheme.outline : const Color(0xFFEF5350).withValues(alpha: 0.6))
                            : StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'PRE-AMP GAIN',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Text(
                          '${state.safePreampDb >= 0 ? '+' : ''}${state.safePreampDb.toStringAsFixed(1)} dB',
                          style: TextStyle(
                            color: state.safePreampDb < 0
                                ? const Color(0xFFEF5350)
                                : (state.safePreampDb > 0
                                    ? const Color(0xFFFF9F0A)
                                    : theme.colorScheme.onSurface),
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Slider
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: const Color(0xFFEF5350),
                      inactiveTrackColor: StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid),
                      thumbColor: const Color(0xFFEF5350),
                      overlayColor: const Color(0xFFEF5350).withValues(alpha: 0.2),
                      trackHeight: 3.5,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                    ),
                    child: Slider(
                      value: state.safePreampDb.clamp(-24.0, 12.0),
                      min: -24.0,
                      max: 12.0,
                      divisions: 72,
                      onChanged: (val) {
                        notifier.setPreamp(val, isAuto: false);
                      },
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Auto Headroom Toggle Row
                  InkWell(
                    onTap: () => notifier.toggleAutoPreamp(),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: state.autoPreampEnabled
                            ? StudioSurfaceTheme.tintedContainer(
                                context,
                                const Color(0xFF00E676),
                                isSolid: isSolid,
                                translucentAlpha: 0.12,
                              )
                            : StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: state.autoPreampEnabled
                              ? (isSolid ? theme.colorScheme.outline : const Color(0xFF00E676))
                              : StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          HugeIcon(
                            icon: state.autoPreampEnabled
                                ? HugeIcons.strokeRoundedCheckmarkCircle02
                                : HugeIcons.strokeRoundedSecurityCheck,
                            size: 18,
                            color: state.autoPreampEnabled
                                ? const Color(0xFF00E676)
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Auto-Headroom Calculation',
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Automatically sets -max(EQ Boost) - 0.5 dB to prevent clipping',
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: state.autoPreampEnabled,
                            activeThumbColor: const Color(0xFF00E676),
                            onChanged: (_) => notifier.toggleAutoPreamp(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Quick preset chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildQuickPreampChip(
                          context: context,
                          label: '0 dB FLAT',
                          isSolid: isSolid,
                          onTap: () => notifier.setPreamp(0.0, isAuto: false),
                        ),
                        const SizedBox(width: 6),
                        _buildQuickPreampChip(
                          context: context,
                          label: '-1.0 dB',
                          isSolid: isSolid,
                          onTap: () => notifier.setPreamp(-1.0, isAuto: false),
                        ),
                        const SizedBox(width: 6),
                        _buildQuickPreampChip(
                          context: context,
                          label: '-3.0 dB',
                          isSolid: isSolid,
                          onTap: () => notifier.setPreamp(-3.0, isAuto: false),
                        ),
                        const SizedBox(width: 6),
                        _buildQuickPreampChip(
                          context: context,
                          label: '-6.0 dB',
                          isSolid: isSolid,
                          onTap: () => notifier.setPreamp(-6.0, isAuto: false),
                        ),
                        const SizedBox(width: 6),
                        _buildQuickPreampChip(
                          context: context,
                          label: '-12.0 dB',
                          isSolid: isSolid,
                          onTap: () => notifier.setPreamp(-12.0, isAuto: false),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static Widget _buildQuickPreampChip({
    required BuildContext context,
    required String label,
    required bool isSolid,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid),
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 10.5,
            fontWeight: FontWeight.bold,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}

class _PreampBox extends StatelessWidget {
  final double safePreampDb;
  final bool isAuto;
  final bool isSolid;
  final VoidCallback onTap;

  const _PreampBox({
    required this.safePreampDb,
    this.isAuto = true,
    this.isSolid = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: StudioSurfaceTheme.tintedContainer(
            context,
            const Color(0xFFEF5350),
            isSolid: isSolid,
            translucentAlpha: 0.15,
          ),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSolid ? theme.colorScheme.outline : const Color(0xFFEF5350).withValues(alpha: 0.8),
            width: 1.2,
          ),
          boxShadow: isSolid
              ? null
              : [
                  BoxShadow(
                    color: const Color(0xFFEF5350).withValues(alpha: 0.2),
                    blurRadius: 6,
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'PRE',
                  style: TextStyle(
                    color: Color(0xFFEF5350),
                    fontSize: 8.0,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                if (isAuto) ...[
                  const SizedBox(width: 2),
                  Container(
                    width: 3.5,
                    height: 3.5,
                    decoration: const BoxDecoration(
                      color: Color(0xFF00E676),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
            Text(
              '${safePreampDb >= 0 ? '+' : ''}${safePreampDb.toStringAsFixed(1)} dB',
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BandPill extends StatelessWidget {
  final EqBand band;
  final bool isSelected;
  final bool compact;
  final bool isSolid;
  final VoidCallback onTap;

  const _BandPill({
    required this.band,
    required this.isSelected,
    this.compact = false,
    this.isSolid = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: compact ? 68 : 74,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected
              ? StudioSurfaceTheme.tintedContainer(
                  context,
                  band.color,
                  isSolid: isSolid,
                  translucentAlpha: 0.2,
                  solidBlendAlpha: 0.2,
                )
              : StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? (isSolid ? theme.colorScheme.outline : band.color.withValues(alpha: 0.8))
                : StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid),
            width: isSelected ? 1.4 : 0.8,
          ),
          boxShadow: isSelected && !isSolid
              ? [
                  BoxShadow(
                    color: band.color.withValues(alpha: 0.25),
                    blurRadius: 6,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: band.color,
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                const SizedBox(width: 3),
                Text(
                  'B${band.index}',
                  style: TextStyle(
                    color: isSelected ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 1),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    band.formattedFreq,
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 9.0,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    band.formattedGain,
                    style: TextStyle(
                      color: band.gainDb > 0
                          ? const Color(0xFF00E676)
                          : (band.gainDb < 0 ? const Color(0xFFFFB74D) : theme.colorScheme.onSurfaceVariant),
                      fontSize: 9.0,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
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
}

class _ActionButton extends StatelessWidget {
  final dynamic icon;
  final String tooltip;
  final Color color;
  final bool isSolid;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    this.isSolid = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = onPressed != null;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isEnabled
                  ? (isSolid ? theme.colorScheme.outline : color.withValues(alpha: 0.5))
                  : StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid),
              width: 1.0,
            ),
          ),
          child: Center(
            child: HugeIcon(
              icon: icon,
              size: 16,
              color: isEnabled ? color : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReadoutBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isSolid;

  const _ReadoutBox({
    required this.label,
    required this.value,
    required this.color,
    this.isSolid = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 50,
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
      decoration: BoxDecoration(
        color: StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid),
          width: 0.8,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 7.0,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 10.0,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
