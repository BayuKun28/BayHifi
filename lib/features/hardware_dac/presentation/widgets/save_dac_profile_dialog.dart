import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_haptics.dart';
import '../controllers/dac_bridge_controller.dart';

/// Modal dialog for saving current hardware DAC band tuning and preamp into a named profile.
class SaveDacProfileDialog extends ConsumerStatefulWidget {
  const SaveDacProfileDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (_) => const SaveDacProfileDialog(),
    );
  }

  @override
  ConsumerState<SaveDacProfileDialog> createState() => _SaveDacProfileDialogState();
}

class _SaveDacProfileDialogState extends ConsumerState<SaveDacProfileDialog> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  String? _errorMessage;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorMessage = 'Please enter a profile name');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final controller = ref.read(dacBridgeControllerProvider.notifier);
      await controller.saveCurrentAsProfile(
        name: name,
        description: _descController.text.trim(),
      );

      AppHaptics.mediumImpact();
      if (mounted) {
        setState(() => _isSaving = false);
        if (Navigator.canPop(context)) {
          Navigator.pop(context, true);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('DAC profile "$name" saved to your library'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = 'Failed to save profile: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dacState = ref.watch(dacBridgeControllerProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: const Color(0xFF16181F),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF262936),
            width: 1.0,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E212B),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF262936)),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      LucideIcons.bookmark,
                      size: 20,
                      color: Color(0xFF4ADE80),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Save DAC Profile',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Save current hardware tuning to your profile library',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF8A9A90),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Tuning snapshot capsule
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E212B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF262936)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildSnapshotItem(
                        label: 'BANDS',
                        value: '${dacState.bands.length}',
                      ),
                    ),
                    Container(width: 1, height: 22, color: const Color(0xFF262936)),
                    Expanded(
                      child: _buildSnapshotItem(
                        label: 'PREAMP',
                        value: '${dacState.globalGainDb >= 0 ? "+" : ""}${dacState.globalGainDb.toStringAsFixed(1)} dB',
                      ),
                    ),
                    Container(width: 1, height: 22, color: const Color(0xFF262936)),
                    Expanded(
                      child: _buildSnapshotItem(
                        label: 'CHIPSET',
                        value: dacState.device?.chipset.displayName ?? 'KT0211L',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Error banner if any
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF381E24),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFF87171).withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.alertCircle,
                        size: 16,
                        color: Color(0xFFF87171),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFFCA5A5),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Profile Name Field
              TextField(
                controller: _nameController,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 13.5),
                decoration: InputDecoration(
                  labelText: 'Profile Name',
                  labelStyle: const TextStyle(color: Color(0xFF8A9A90), fontSize: 12),
                  hintText: 'e.g. Warm Vocal Studio / Harman IEM',
                  hintStyle: const TextStyle(color: Color(0xFF555D6E), fontSize: 12),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  prefixIconConstraints: const BoxConstraints(minWidth: 38, minHeight: 20),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(left: 12, right: 8),
                    child: Icon(
                      LucideIcons.bookmark,
                      size: 15,
                      color: Color(0xFF8A9A90),
                    ),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF1E212B),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF262936)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF4ADE80)),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Description Field (Optional)
              TextField(
                controller: _descController,
                style: const TextStyle(color: Colors.white, fontSize: 13.5),
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  labelStyle: const TextStyle(color: Color(0xFF8A9A90), fontSize: 12),
                  hintText: 'e.g. Tuned for Kiwi Ears with punchy sub-bass',
                  hintStyle: const TextStyle(color: Color(0xFF555D6E), fontSize: 12),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  prefixIconConstraints: const BoxConstraints(minWidth: 38, minHeight: 20),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(left: 12, right: 8),
                    child: Icon(
                      LucideIcons.fileText,
                      size: 15,
                      color: Color(0xFF8A9A90),
                    ),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF1E212B),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF262936)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF4ADE80)),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(
                        LucideIcons.x,
                        size: 15,
                        color: Color(0xFF8A9A90),
                      ),
                      label: const Text(
                        'CANCEL',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF8A9A90)),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF262936)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                      ),
                      onPressed: _isSaving
                          ? null
                          : () {
                              AppHaptics.selectionClick();
                              Navigator.pop(context);
                            },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF4ADE80),
                        foregroundColor: const Color(0xFF0B110E),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                      ),
                      onPressed: _isSaving ? null : _submit,
                      child: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF0B110E),
                              ),
                            )
                          : const Text(
                              'SAVE PROFILE',
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 0.4),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSnapshotItem({
    required String label,
    required String value,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: Color(0xFF8A9A90),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
