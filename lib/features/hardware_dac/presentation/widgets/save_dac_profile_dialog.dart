import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dacState = ref.watch(dacBridgeControllerProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: 1.0,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedBookmark02,
                      size: 22,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Save DAC Profile',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Save current hardware tuning to your profile library',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Tuning snapshot capsule
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildSnapshotItem(
                        label: 'BANDS',
                        value: '${dacState.bands.length}',
                        colorScheme: colorScheme,
                      ),
                    ),
                    Container(width: 1, height: 24, color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                    Expanded(
                      child: _buildSnapshotItem(
                        label: 'PREAMP',
                        value: '${dacState.globalGainDb >= 0 ? "+" : ""}${dacState.globalGainDb.toStringAsFixed(1)} dB',
                        colorScheme: colorScheme,
                      ),
                    ),
                    Container(width: 1, height: 24, color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                    Expanded(
                      child: _buildSnapshotItem(
                        label: 'CHIPSET',
                        value: dacState.device?.chipset.displayName ?? 'KT0211L',
                        colorScheme: colorScheme,
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
                    color: colorScheme.errorContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.error.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedAlertCircle,
                        size: 18,
                        color: colorScheme.error,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: colorScheme.onErrorContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Profile Name Field
              TextField(
                controller: _nameController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Profile Name',
                  hintText: 'e.g. Warm Vocal Studio / Harman IEM',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 20),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 14, right: 8),
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedBookmark02,
                      size: 15,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Description Field (Optional)
              TextField(
                controller: _descController,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'e.g. Tuned for Kiwi Ears with punchy sub-bass',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 20),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 14, right: 8),
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedNote,
                      size: 15,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: M3EButton.outlined(
                      icon: HugeIcon(
                        icon: HugeIcons.strokeRoundedCancel01,
                        size: 16,
                        color: colorScheme.onSurface,
                      ),
                      label: const Text('CANCEL'),
                      onPressed: _isSaving
                          ? null
                          : () {
                              AppHaptics.selectionClick();
                              Navigator.pop(context);
                            },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: M3EButton.filled(
                      onPressed: _isSaving ? null : _submit,
                      child: _isSaving
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.onPrimary,
                              ),
                            )
                          : const Text(
                              'SAVE PROFILE',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
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
    required ColorScheme colorScheme,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
