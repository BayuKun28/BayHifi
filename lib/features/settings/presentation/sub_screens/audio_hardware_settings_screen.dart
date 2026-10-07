import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import '../../../../app/theme/app_haptics.dart';
import '../../../../app/theme/studio_surface_theme.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/database/local_persistence_service.dart';

class AudioHardwareSettingsScreen extends ConsumerStatefulWidget {
  const AudioHardwareSettingsScreen({super.key});

  @override
  ConsumerState<AudioHardwareSettingsScreen> createState() => _AudioHardwareSettingsScreenState();
}

class _AudioHardwareSettingsScreenState extends ConsumerState<AudioHardwareSettingsScreen> {
  String _outputDevice = 'Default System Audio (ALSA)';
  double _bufferLatency = 50.0;
  bool _bitPerfect = true;

  @override
  void initState() {
    super.initState();
    final storage = LocalPersistenceService.instance;
    _outputDevice = storage.getSetting<String>('output_device', 'Default System Audio (ALSA)')!;
    _bufferLatency = storage.getSetting<double>('buffer_latency', 50.0)!;
    _bitPerfect = storage.getSetting<bool>('bit_perfect', true)!;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final storage = LocalPersistenceService.instance;
    final isSolid = ref.isSolidStyle;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('AUDIO HARDWARE & DAC ENGINE'),
        leading: M3EIconButton(
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            size: 20,
            color: theme.colorScheme.onSurface,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          // ─── 1. STATUS HERO BANNER ──────────────────────────────────────────
          _buildStatusHero(context, theme, primary, isSolid),
          const SizedBox(height: 18),

          // ─── 2. HARDWARE AUDIO & BIT-PERFECT DAC ────────────────────────────
          _buildSectionHeader(context, 'HARDWARE AUDIO & BIT-PERFECT DAC', HugeIcons.strokeRoundedCpu),
          const SizedBox(height: 8),
          _buildHardwareCard(context, theme, primary, storage, isSolid),
        ],
      ),
    );
  }

  Widget _buildStatusHero(BuildContext context, ThemeData theme, Color primary, bool isSolid) {
    final hardwareColor = StudioCategoryColors.audioHardware;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: StudioSurfaceTheme.cardDecoration(
        context: context,
        isSolid: isSolid,
        radius: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: StudioSurfaceTheme.tintedContainer(
                    context,
                    hardwareColor,
                    isSolid: isSolid,
                    translucentAlpha: 0.16,
                    solidBlendAlpha: 0.2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedCpu,
                  size: 18,
                  color: hardwareColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AUDIO HARDWARE ARCHITECTURE',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Native SoLoud C++ pipeline, buffer tuning & bit-perfect hardware pass-through',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildStatusPill(
                context,
                theme,
                label: 'Engine: SoLoud Native C++',
                isActive: true,
                color: StudioCategoryColors.audioEngineSoloud,
                isSolid: isSolid,
              ),
              _buildStatusPill(
                context,
                theme,
                label: 'Buffer: ${_bufferLatency.toInt()}ms',
                isActive: true,
                color: StudioCategoryColors.proQEqualizer,
                isSolid: isSolid,
              ),
              _buildStatusPill(
                context,
                theme,
                label: _bitPerfect ? 'Bit-Perfect: ON' : 'Bit-Perfect: OFF',
                isActive: _bitPerfect,
                color: StudioCategoryColors.bitPerfect,
                isSolid: isSolid,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(
    BuildContext context,
    ThemeData theme, {
    required String label,
    required bool isActive,
    required Color color,
    required bool isSolid,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
      decoration: BoxDecoration(
        color: isSolid
            ? (isActive
                ? color.withValues(alpha: 0.16)
                : theme.colorScheme.surfaceContainerHighest)
            : (isActive
                ? color.withValues(alpha: 0.14)
                : theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isActive ? color : theme.colorScheme.onSurface.withValues(alpha: 0.65),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, dynamic icon) {
    final theme = Theme.of(context);
    return Row(
      children: [
        HugeIcon(icon: icon, size: 15, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildHardwareCard(
    BuildContext context,
    ThemeData theme,
    Color primary,
    LocalPersistenceService storage,
    bool isSolid,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: StudioSurfaceTheme.cardDecoration(
        context: context,
        isSolid: isSolid,
        radius: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'SoLoud C++ Audio Engine',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: StudioSurfaceTheme.tintedContainer(
                    context,
                    primary,
                    isSolid: isSolid,
                    translucentAlpha: 0.15,
                    solidBlendAlpha: 0.20,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'ONLINE',
                  style: TextStyle(
                    color: primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 9.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildBentoDropdownSelector<String>(
            context: context,
            title: 'Output Audio Device',
            currentValue: _outputDevice,
            items: const [
              'Default System Audio (ALSA)',
              'USB DAC Direct Exclusive Mode',
              'Low-Latency OpenSL ES / AAudio',
            ],
            itemLabel: (d) => d,
            itemDescription: (d) {
              if (d.contains('USB')) return 'Bit-perfect direct PCM transfer to external USB DAC hardware';
              if (d.contains('OpenSL')) return 'Hardware accelerated low-latency audio sub-system';
              return 'Standard high-fidelity multi-channel system mixer audio routing';
            },
            itemIcon: (d) {
              if (d.contains('USB')) return HugeIcons.strokeRoundedUsbMemory01;
              return HugeIcons.strokeRoundedHeadphones;
            },
            onChanged: (val) {
              if (val != null) {
                AppHaptics.selectionClick();
                setState(() => _outputDevice = val);
                storage.saveSetting('output_device', val);
              }
            },
            isSolid: isSolid,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Buffer Latency Tuning', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isSolid
                      ? theme.colorScheme.surfaceContainerHighest
                      : StudioSurfaceTheme.tintedContainer(context, primary, isSolid: false, translucentAlpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${_bufferLatency.toInt()} ms',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: primary,
                    fontFeatures: AppTypography.audioFigures,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          M3ESlider(
            value: _bufferLatency,
            min: 20.0,
            max: 200.0,
            divisions: 18,
            onChanged: (val) {
              setState(() => _bufferLatency = val);
              storage.saveSetting('buffer_latency', val);
            },
          ),
          const Divider(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bit-Perfect Resampling Bypass',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Stream direct bit-perfect PCM to DAC without OS resampling',
                      style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
              ),
              M3ESwitch(
                value: _bitPerfect,
                onChanged: (val) {
                  AppHaptics.lightImpact();
                  setState(() => _bitPerfect = val);
                  storage.saveSetting('bit_perfect', val);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBentoDropdownSelector<T>({
    required BuildContext context,
    required String title,
    required T currentValue,
    required List<T> items,
    required String Function(T) itemLabel,
    required String Function(T) itemDescription,
    required dynamic Function(T) itemIcon,
    required ValueChanged<T?> onChanged,
    required bool isSolid,
  }) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isSolid
            ? theme.colorScheme.surfaceContainerHighest
            : StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: false),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 4),
          DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: currentValue,
              isExpanded: true,
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedArrowDown01,
                size: 15,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              dropdownColor: isSolid
                  ? theme.colorScheme.surfaceContainerHigh
                  : theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
              items: items.map((item) {
                final isSelected = item == currentValue;
                return DropdownMenuItem<T>(
                  value: item,
                  child: Row(
                    children: [
                      HugeIcon(
                        icon: itemIcon(item),
                        size: 16,
                        color: isSelected ? primary : theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          itemLabel(item),
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? primary : theme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            itemDescription(currentValue),
            style: TextStyle(
              fontSize: 10,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

