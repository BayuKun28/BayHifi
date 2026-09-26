import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../domain/eq_band.dart';
import '../controllers/eq_controller.dart';

class BandStripBar extends ConsumerWidget {
  const BandStripBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eqState = ref.watch(eqControllerProvider);
    final notifier = ref.read(eqControllerProvider.notifier);
    final selectedBand = eqState.selectedBand;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 620;

        if (isCompact) {
          // Mobile Portrait View: Two neat tiers
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: const BoxDecoration(
              color: Color(0xFF090B0E),
              border: Border(
                top: BorderSide(
                  color: Color(0xFF1E232B),
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
                        onPressed: () => notifier.addBand(),
                      ),
                      const SizedBox(width: 4),
                      _ActionButton(
                        icon: HugeIcons.strokeRoundedDelete02,
                        tooltip: 'Delete Selected Band',
                        color: const Color(0xFFEF5350),
                        onPressed: selectedBand != null && eqState.bands.length > 1
                            ? () => notifier.removeBand(selectedBand.index)
                            : null,
                      ),
                      const SizedBox(width: 4),
                      _ActionButton(
                        icon: HugeIcons.strokeRoundedRefresh,
                        tooltip: 'Reset Active Band Gain',
                        color: const Color(0xFF90A4AE),
                        onPressed: selectedBand != null ? () => notifier.resetActiveBand() : null,
                      ),
                      const Spacer(),
                      _ReadoutBox(
                        label: 'FREQ',
                        value: selectedBand != null ? '${selectedBand.formattedFreq}Hz' : '--',
                        color: const Color(0xFFCFD8DC),
                      ),
                      const SizedBox(width: 4),
                      _ReadoutBox(
                        label: 'GAIN',
                        value: selectedBand != null ? '${selectedBand.formattedGain}dB' : '--',
                        color: selectedBand != null && selectedBand.gainDb > 0
                            ? const Color(0xFFFF9F0A)
                            : const Color(0xFF64D2FF),
                      ),
                      const SizedBox(width: 4),
                      _ReadoutBox(
                        label: 'Q',
                        value: selectedBand != null ? selectedBand.q.toStringAsFixed(2) : '--',
                        color: const Color(0xFFB0BEC5),
                      ),
                      const SizedBox(width: 6),
                      _PreampBox(safePreampDb: eqState.safePreampDb),
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
          decoration: const BoxDecoration(
            color: Color(0xFF090B0E),
            border: Border(
              top: BorderSide(
                color: Color(0xFF1E232B),
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
                onPressed: () => notifier.addBand(),
              ),
              const SizedBox(width: 6),
              _ActionButton(
                icon: HugeIcons.strokeRoundedDelete02,
                tooltip: 'Delete Selected Band',
                color: const Color(0xFFEF5350),
                onPressed: selectedBand != null && eqState.bands.length > 1
                    ? () => notifier.removeBand(selectedBand.index)
                    : null,
              ),
              const SizedBox(width: 6),
              _ActionButton(
                icon: HugeIcons.strokeRoundedRefresh,
                tooltip: 'Reset Active Band Gain',
                color: const Color(0xFF90A4AE),
                onPressed: selectedBand != null ? () => notifier.resetActiveBand() : null,
              ),

              const SizedBox(width: 10),

              // 3. Precision Readouts: FREQ, GAIN, Q
              _ReadoutBox(
                label: 'FREQ',
                value: selectedBand != null ? '${selectedBand.formattedFreq}Hz' : '--',
                color: const Color(0xFFCFD8DC),
              ),
              const SizedBox(width: 6),
              _ReadoutBox(
                label: 'GAIN',
                value: selectedBand != null ? '${selectedBand.formattedGain}dB' : '--',
                color: selectedBand != null && selectedBand.gainDb > 0
                    ? const Color(0xFFFF9F0A)
                    : const Color(0xFF64D2FF),
              ),
              const SizedBox(width: 6),
              _ReadoutBox(
                label: 'Q',
                value: selectedBand != null ? selectedBand.q.toStringAsFixed(2) : '--',
                color: const Color(0xFFB0BEC5),
              ),

              const SizedBox(width: 10),

              // 4. Safe Preamp Box
              _PreampBox(safePreampDb: eqState.safePreampDb),
            ],
          ),
        );
      },
    );
  }
}

class _PreampBox extends StatelessWidget {
  final double safePreampDb;

  const _PreampBox({required this.safePreampDb});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF261012),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: const Color(0xFFEF5350).withValues(alpha: 0.8),
          width: 1.2,
        ),
        boxShadow: [
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
          const Text(
            'PRE',
            style: TextStyle(
              color: Color(0xFFEF5350),
              fontSize: 8.0,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          Text(
            '${safePreampDb.toStringAsFixed(1)} dB',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _BandPill extends StatelessWidget {
  final EqBand band;
  final bool isSelected;
  final bool compact;
  final VoidCallback onTap;

  const _BandPill({
    required this.band,
    required this.isSelected,
    this.compact = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: compact ? 68 : 74,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1C222B)
              : const Color(0xFF11141A),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? band.color.withValues(alpha: 0.8)
                : const Color(0xFF262C36),
            width: isSelected ? 1.4 : 0.8,
          ),
          boxShadow: isSelected
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
                    color: isSelected ? Colors.white : const Color(0xFFB0BEC5),
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
                    style: const TextStyle(
                      color: Color(0xFF90A4AE),
                      fontSize: 9.0,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    band.formattedGain,
                    style: TextStyle(
                      color: band.gainDb > 0
                          ? const Color(0xFF00E676)
                          : (band.gainDb < 0 ? const Color(0xFFFFB74D) : const Color(0xFF78909C)),
                      fontSize: 9.0,
                      fontWeight: FontWeight.w600,
                      fontFeatures: [FontFeature.tabularFigures()],
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
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
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
            color: const Color(0xFF141820),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isEnabled
                  ? color.withValues(alpha: 0.5)
                  : const Color(0xFF263238),
              width: 1.0,
            ),
          ),
          child: Center(
            child: HugeIcon(
              icon: icon,
              size: 16,
              color: isEnabled ? color : const Color(0xFF546E7A),
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

  const _ReadoutBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF11141A),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF202630), width: 0.8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF78909C),
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
