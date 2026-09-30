import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../app/theme/app_haptics.dart';
import '../../../../app/theme/studio_surface_theme.dart';
import '../../../dsp_rack/presentation/dsp_rack_screen.dart';

class MasteringDspBentoCard extends ConsumerWidget {
  const MasteringDspBentoCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isSolid = ref.isSolidStyle;

    return InkWell(
      onTap: () {
        AppHaptics.lightImpact();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const DspRackScreen(),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: StudioSurfaceTheme.cardDecoration(
          context: context,
          isSolid: isSolid,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: StudioCategoryColors.dspMastering.withValues(alpha: isSolid ? 0.18 : 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const HugeIcon(
                    icon: HugeIcons.strokeRoundedCpu,
                    size: 15,
                    color: StudioCategoryColors.dspMastering,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'DSP RACK',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: StudioCategoryColors.dspMastering.withValues(alpha: isSolid ? 0.18 : 0.14),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '10+ FX',
                    style: TextStyle(
                      color: StudioCategoryColors.dspMastering,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Modules 2x2 Grid
            Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildModuleChip(context, isSolid, 'Tube Exciter', true, StudioCategoryColors.dspTubeWarmth)),
                    const SizedBox(width: 6),
                    Expanded(child: _buildModuleChip(context, isSolid, 'Limiter', true, StudioCategoryColors.limiter)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(child: _buildModuleChip(context, isSolid, 'Compressor', true, StudioCategoryColors.compressor)),
                    const SizedBox(width: 6),
                    Expanded(child: _buildModuleChip(context, isSolid, 'Crossfeed', false, StudioCategoryColors.dspMastering)),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Launch Action Pill
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4.5),
              decoration: BoxDecoration(
                color: StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      'Mastering Rack',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: StudioCategoryColors.dspMastering,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 3),
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedArrowRight01,
                    size: 11,
                    color: StudioCategoryColors.dspMastering,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleChip(BuildContext context, bool isSolid, String label, bool isActive, Color categoryColor) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? categoryColor.withValues(alpha: isSolid ? 0.16 : 0.12)
            : StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: isActive ? categoryColor : theme.colorScheme.onSurface.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 8.5,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                color: isActive ? categoryColor : theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
