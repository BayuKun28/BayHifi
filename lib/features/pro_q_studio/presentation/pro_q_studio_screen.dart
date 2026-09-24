import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'controllers/eq_controller.dart';
import 'controllers/eq_state.dart';
import 'widgets/band_strip_bar.dart';
import 'widgets/interactive_eq_canvas.dart';

class ProQStudioScreen extends ConsumerWidget {
  const ProQStudioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eqState = ref.watch(eqControllerProvider);
    final notifier = ref.read(eqControllerProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF090B0E),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Studio Toolbar & Legend
            _buildTopBar(context, ref, eqState, notifier),

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
    WidgetRef ref,
    EqState state,
    EqController notifier,
  ) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF0D0F14),
        border: Border(
          bottom: BorderSide(
            color: Color(0xFF1E232B),
            width: 1.0,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Title: PRO-Q STUDIO (?)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.tune,
                  size: 16,
                  color: Color(0xFFFF9F0A),
                ),
                const SizedBox(width: 6),
                const Text(
                  'PRO-Q STUDIO',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 4),
                Tooltip(
                  message: 'Studio Parametric Equalizer with Biquad IIR Engine',
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF546E7A), width: 1),
                    ),
                    child: const Icon(
                      Icons.question_mark,
                      size: 9,
                      color: Color(0xFF90A4AE),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(width: 16),

            // Legend Items: — EQ, -- Driver FR, -- Target, [x HIDE FR], — RTA
            _buildLegendItem(
              label: 'EQ',
              color: const Color(0xFFFFA726),
              isDashed: false,
            ),
            const SizedBox(width: 10),
            _buildLegendItem(
              label: 'Driver FR',
              color: const Color(0xFF29B6F6),
              isDashed: true,
            ),
            const SizedBox(width: 10),
            _buildLegendItem(
              label: 'Target',
              color: const Color(0xFF00E676),
              isDashed: true,
            ),
            const SizedBox(width: 8),

            // [x HIDE FR] / [SHOW FR] Toggle Button
            InkWell(
              onTap: () => notifier.toggleFrCurves(),
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: state.showFrCurves
                      ? const Color(0xFF19202A)
                      : const Color(0xFF14171D),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: state.showFrCurves
                        ? const Color(0xFF37474F)
                        : const Color(0xFF263238),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  state.showFrCurves ? '✕ HIDE FR' : '👁 SHOW FR',
                  style: TextStyle(
                    color: state.showFrCurves
                        ? const Color(0xFFB0BEC5)
                        : const Color(0xFF78909C),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 10),

            _buildLegendItem(
              label: 'RTA',
              color: const Color(0xFF00E5FF),
              isDashed: false,
            ),

            const SizedBox(width: 16),

            // [∿ RTA] Button
            _buildToolbarButton(
              icon: Icons.graphic_eq,
              label: 'RTA',
              color: const Color(0xFF00E5FF),
              isActive: state.isRtaEnabled,
              onTap: () => notifier.toggleRta(),
            ),

            const SizedBox(width: 8),

            // [✨ AUTO EQ •] Button
            _buildToolbarButton(
              icon: Icons.auto_awesome,
              label: 'AUTO EQ •',
              color: const Color(0xFF00E676),
              isActive: true,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('AutoEQ: Target matching profile loaded (KZ Castor → HBB Target).'),
                    duration: Duration(seconds: 2),
                    backgroundColor: Color(0xFF1E2836),
                  ),
                );
              },
            ),

            const SizedBox(width: 8),

            // [🔖 PRESETS] Popup Button
            PopupMenuButton<String>(
              color: const Color(0xFF141820),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Color(0xFF263238), width: 1),
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
                      Icon(
                        isCurr ? Icons.check_circle : Icons.circle_outlined,
                        size: 14,
                        color: isCurr ? const Color(0xFFBA68C8) : const Color(0xFF546E7A),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        p,
                        style: TextStyle(
                          color: isCurr ? Colors.white : const Color(0xFFCFD8DC),
                          fontSize: 12,
                          fontWeight: isCurr ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              child: _buildToolbarButton(
                icon: Icons.bookmark_border,
                label: 'PRESETS',
                color: const Color(0xFFBA68C8),
                isActive: false,
                onTap: null, // PopupMenuButton handles it
              ),
            ),

            const SizedBox(width: 8),

            // [🔄 RESET] Button
            _buildToolbarButton(
              icon: Icons.refresh,
              label: 'RESET',
              color: const Color(0xFFEF5350),
              isActive: false,
              onTap: () => notifier.resetToDefault(),
            ),

            const SizedBox(width: 16),

            // Power Bypass Button [ ⏻ ]
            InkWell(
              onTap: () => notifier.togglePower(),
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: state.isEnabled
                      ? const Color(0xFF00E5FF).withValues(alpha: 0.15)
                      : const Color(0xFF1E232B),
                  border: Border.all(
                    color: state.isEnabled
                        ? const Color(0xFF00E5FF)
                        : const Color(0xFF455A64),
                    width: 1.5,
                  ),
                  boxShadow: state.isEnabled
                      ? [
                          BoxShadow(
                            color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  Icons.power_settings_new,
                  size: 16,
                  color: state.isEnabled
                      ? const Color(0xFF00E5FF)
                      : const Color(0xFF78909C),
                ),
              ),
            ),
          ],
        ),
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
          size: const Size(16, 2),
          painter: _LegendLinePainter(color: color, isDashed: isDashed),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required String label,
    required Color color,
    required bool isActive,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.12) : const Color(0xFF141820),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isActive ? color.withValues(alpha: 0.8) : const Color(0xFF263238),
            width: 1.0,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.25),
                    blurRadius: 6,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
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
