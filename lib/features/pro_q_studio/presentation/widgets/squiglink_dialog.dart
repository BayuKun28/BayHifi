import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
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

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 440),
        width: double.infinity,
        height: 400,
        decoration: BoxDecoration(
          color: const Color(0xFF131822),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2C3542), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
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
                const HugeIcon(
                  icon: HugeIcons.strokeRoundedSparkles,
                  size: 16,
                  color: Color(0xFFCE93D8),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'SQUIGLINK & EQUALIZER APO ENGINE',
                    style: TextStyle(
                      color: Colors.white,
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
                    child: const HugeIcon(
                      icon: HugeIcons.strokeRoundedCancel01,
                      size: 16,
                      color: Color(0xFF90A4AE),
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
                color: const Color(0xFF19202B),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF25303D), width: 0.8),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: const Color(0xFF7B1FA2),
                  borderRadius: BorderRadius.circular(5),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: const Color(0xFF90A4AE),
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
                  _buildImportTab(notifier),

                  // Tab 2: Export
                  _buildExportTab(exportedSquiglink, exportedWavelet),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportTab(EqController notifier) {
    return Column(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0F131A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF25303D), width: 1.0),
            ),
            child: TextField(
              controller: _importTextController,
              maxLines: null,
              expands: true,
              style: const TextStyle(
                color: Color(0xFFECEFF1),
                fontSize: 10.5,
                fontFamily: 'monospace',
                height: 1.35,
              ),
              decoration: const InputDecoration(
                hintText:
                    'Paste Squiglink / Equalizer APO text here...\nExample:\nPreamp: -4.3 dB\nFilter 1: ON PK Fc 63 Hz Gain -1.1 dB Q 1.414',
                hintStyle: TextStyle(
                  color: Color(0xFF546E7A),
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
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF90A4AE),
                side: const BorderSide(color: Color(0xFF37474F)),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              onPressed: () {
                _importTextController.text = _demoSquiglinkText;
              },
              icon: const HugeIcon(icon: HugeIcons.strokeRoundedFile01, size: 13, color: Color(0xFF90A4AE)),
              label: const Text(
                'LOAD DEMO',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF29B6F6),
                side: const BorderSide(color: Color(0xFF0288D1)),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              onPressed: () async {
                final data = await Clipboard.getData('text/plain');
                if (data?.text != null && data!.text!.isNotEmpty) {
                  setState(() {
                    _importTextController.text = data.text!;
                  });
                }
              },
              icon: const HugeIcon(icon: HugeIcons.strokeRoundedClipboard, size: 13, color: Color(0xFF29B6F6)),
              label: const Text(
                'PASTE',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E676),
                foregroundColor: const Color(0xFF091A10),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              onPressed: () {
                final text = _importTextController.text.trim();
                if (text.isEmpty) return;

                final success = notifier.importSquiglinkText(text);
                if (success) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Squiglink EQ successfully imported to DSP rack.'),
                      backgroundColor: Color(0xFF1B5E20),
                      duration: Duration(seconds: 2),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Invalid Squiglink text format. Could not parse filters.'),
                      backgroundColor: Color(0xFFB71C1C),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              icon: const HugeIcon(icon: HugeIcons.strokeRoundedCheckmarkCircle02, size: 14, color: Color(0xFF091A10)),
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

  Widget _buildExportTab(String exportedSquiglink, String exportedWavelet) {
    return Column(
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0F131A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF25303D), width: 1.0),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                exportedSquiglink,
                style: const TextStyle(
                  color: Color(0xFF81C784),
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
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B1FA2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: exportedSquiglink));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Squiglink EQ text copied to clipboard!'),
                    backgroundColor: Color(0xFF4A148C),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const HugeIcon(icon: HugeIcons.strokeRoundedCopy01, size: 13, color: Colors.white),
              label: const Text(
                'COPY SQUIGLINK',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF00E676),
                side: const BorderSide(color: Color(0xFF00897B)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: exportedWavelet));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Wavelet GraphicEQ text copied to clipboard!'),
                    backgroundColor: Color(0xFF1B5E20),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const HugeIcon(icon: HugeIcons.strokeRoundedAudioWaveform, size: 13, color: Color(0xFF00E676)),
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
