import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import '../../../../app/theme/studio_surface_theme.dart';
import '../controllers/eq_controller.dart';

/// Modal dialog for Importing and Exporting EQ configuration in Squiglink / Equalizer APO / Wavelet format
class SquiglinkDialog extends ConsumerStatefulWidget {
  const SquiglinkDialog({super.key});

  @override
  ConsumerState<SquiglinkDialog> createState() => _SquiglinkDialogState();
}

class _SquiglinkDialogState extends ConsumerState<SquiglinkDialog>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _importTextController = TextEditingController();

  static const String _demoSquiglinkText = '''Preamp: -4.3 dB
Filter 1: ON PK Fc 63 Hz Gain -1.1 dB Q 1.414
Filter 2: ON PK Fc 226 Hz Gain 4.4 dB Q 1.800
Filter 3: ON PK Fc 1100 Hz Gain -0.9 dB Q 2.000
Filter 4: ON PK Fc 1700 Hz Gain 0.6 dB Q 1.414
Filter 5: ON PK Fc 3200 Hz Gain 1.8 dB Q 2.000
Filter 6: ON PK Fc 4600 Hz Gain -2.4 dB Q 2.500
Filter 7: ON PK Fc 6300 Hz Gain 1.1 dB Q 2.000
Filter 8: ON PK Fc 8000 Hz Gain -3.2 dB Q 3.000
Filter 9: ON PK Fc 11500 Hz Gain 2.5 dB Q 2.000
Filter 10: ON PK Fc 16000 Hz Gain -1.0 dB Q 1.414''';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _importTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(eqControllerProvider.notifier);
    final exportedSquiglink = notifier.exportSquiglinkText();
    final exportedWavelet = notifier.exportWaveletText();
    final theme = Theme.of(context);
    final isSolid = ref.isSolidStyle;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 440),
        width: double.infinity,
        height: 400,
        decoration: BoxDecoration(
          color: StudioSurfaceTheme.surface(context, isSolid: isSolid),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: StudioSurfaceTheme.outline(context, isSolid: isSolid), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isSolid ? 0.4 : 0.6),
              blurRadius: 24,
              spreadRadius: 4,
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Icon(
                  LucideIcons.sparkles,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'SQUIGLINK & EQUALIZER APO ENGINE',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 12.0,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      LucideIcons.x,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Tab bar
            Container(
              height: 32,
              decoration: BoxDecoration(
                color: StudioSurfaceTheme.surfaceContainerLow(context, isSolid: isSolid),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid), width: 0.8),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: StudioSurfaceTheme.tintedContainer(
                    context,
                    theme.colorScheme.primary,
                    isSolid: isSolid,
                    translucentAlpha: 0.35,
                    solidBlendAlpha: 0.25,
                  ),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: isSolid ? theme.colorScheme.primary : theme.colorScheme.primary.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                labelStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
                tabs: const [
                  Tab(text: 'IMPORT / PASTE'),
                  Tab(text: 'EXPORT PRESET'),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Import
                  _buildImportTab(notifier, isSolid, theme),

                  // Tab 2: Export
                  _buildExportTab(exportedSquiglink, exportedWavelet, isSolid, theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportTab(EqController notifier, bool isSolid, ThemeData theme) {
    return Column(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: StudioSurfaceTheme.surfaceContainerLow(context, isSolid: isSolid),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid), width: 1.0),
            ),
            child: TextField(
              controller: _importTextController,
              maxLines: null,
              expands: true,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 10.5,
                fontFamily: 'monospace',
                height: 1.35,
              ),
              decoration: InputDecoration(
                hintText:
                    'Paste Squiglink / Equalizer APO text here...\nExample:\nPreamp: -4.3 dB\nFilter 1: ON PK Fc 63 Hz Gain -1.1 dB Q 1.414',
                hintStyle: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  fontSize: 10.5,
                  fontFamily: 'monospace',
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            M3EButton.outlined(
              onPressed: () {
                _importTextController.text = _demoSquiglinkText;
              },
              icon: Icon(LucideIcons.fileText, size: 13, color: theme.colorScheme.onSurfaceVariant),
              label: const Text(
                'LOAD DEMO',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
            M3EButton.outlined(
              onPressed: () async {
                final data = await Clipboard.getData('text/plain');
                if (data?.text != null && data!.text!.isNotEmpty) {
                  setState(() {
                    _importTextController.text = data.text!;
                  });
                }
              },
              icon: Icon(LucideIcons.clipboard, size: 13, color: theme.colorScheme.primary),
              label: const Text(
                'PASTE',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
            M3EButton.filled(
              onPressed: () {
                final text = _importTextController.text.trim();
                if (text.isEmpty) return;

                final success = notifier.importSquiglinkText(text);
                if (success) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Squiglink EQ successfully imported to DSP rack.'),
                      backgroundColor: theme.colorScheme.primary,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Invalid Squiglink text format. Could not parse filters.'),
                      backgroundColor: theme.colorScheme.error,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              icon: Icon(LucideIcons.circleCheck, size: 14, color: theme.colorScheme.onPrimary),
              label: const Text(
                'APPLY FILTERS',
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExportTab(String exportedSquiglink, String exportedWavelet, bool isSolid, ThemeData theme) {
    return Column(
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: StudioSurfaceTheme.surfaceContainerLow(context, isSolid: isSolid),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid), width: 1.0),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                exportedSquiglink,
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontSize: 10.5,
                  fontFamily: 'monospace',
                  height: 1.35,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            M3EButton.filled(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: exportedSquiglink));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Squiglink EQ text copied to clipboard!'),
                    backgroundColor: theme.colorScheme.primary,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              icon: Icon(LucideIcons.copy, size: 13, color: theme.colorScheme.onPrimary),
              label: const Text(
                'COPY SQUIGLINK',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
            M3EButton.outlined(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: exportedWavelet));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Wavelet GraphicEQ text copied to clipboard!'),
                    backgroundColor: theme.colorScheme.secondary,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              icon: Icon(LucideIcons.audioWaveform, size: 13, color: theme.colorScheme.secondary),
              label: const Text(
                'COPY WAVELET',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
