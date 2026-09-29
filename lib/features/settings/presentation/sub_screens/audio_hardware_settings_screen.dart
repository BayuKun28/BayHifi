import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../app/theme/studio_surface_theme.dart';
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
    final storage = LocalPersistenceService.instance;
    final isSolid = ref.isSolidStyle;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('AUDIO HARDWARE & DAC ENGINE'),
        leading: IconButton(
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
          _buildSectionHeader(context, 'HARDWARE AUDIO & BIT-PERFECT DAC', HugeIcons.strokeRoundedCpu),
          const SizedBox(height: 8),
          Material(
            color: StudioSurfaceTheme.surfaceContainer(context, isSolid: isSolid),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: StudioSurfaceTheme.outline(context, isSolid: isSolid),
                width: 1.0,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'SoLoud C++ Audio Engine',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: StudioSurfaceTheme.tintedContainer(
                          context,
                          theme.colorScheme.primary,
                          isSolid: isSolid,
                          translucentAlpha: 0.15,
                          solidBlendAlpha: 0.20,
                        ),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.4), width: 0.8),
                      ),
                      child: Text(
                        'ONLINE',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text('Output Audio Device', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                DropdownButton<String>(
                  value: _outputDevice,
                  isExpanded: true,
                  underline: Container(height: 1, color: StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid)),
                  dropdownColor: StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid),
                  items: [
                    'Default System Audio (ALSA)',
                    'USB DAC Direct Exclusive Mode',
                    'Low-Latency OpenSL ES / AAudio',
                  ].map((d) {
                    return DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 11.5)));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _outputDevice = val);
                      storage.saveSetting('output_device', val);
                    }
                  },
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Buffer Latency Tuning', style: TextStyle(fontSize: 11.5)),
                    Text('${_bufferLatency.toInt()} ms', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                  ],
                ),
                Slider(
                  value: _bufferLatency,
                  min: 20.0,
                  max: 200.0,
                  divisions: 18,
                  onChanged: (val) {
                    setState(() => _bufferLatency = val);
                    storage.saveSetting('buffer_latency', val);
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _bitPerfect,
                  title: const Text('Bit-Perfect Resampling Bypass', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Stream direct bit-perfect PCM to DAC without OS resampling', style: TextStyle(fontSize: 10.5)),
                  onChanged: (val) {
                    setState(() => _bitPerfect = val);
                    storage.saveSetting('bit_perfect', val);
                  },
                ),
              ],
            ),
          ),
        ),
      ],
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
}
