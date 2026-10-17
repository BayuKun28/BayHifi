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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final dialogBg = isDark ? const Color(0xFF16181F) : colorScheme.surfaceContainer;
    final outlineColor = isDark ? const Color(0xFF262936) : colorScheme.outlineVariant;
    final capsuleBg = isDark ? const Color(0xFF1E212B) : colorScheme.surfaceContainerHighest;
    final textPrimary = isDark ? Colors.white : colorScheme.onSurface;
    final textSecondary = isDark ? const Color(0xFF8A9A90) : colorScheme.onSurfaceVariant;
    final hintColor = isDark ? const Color(0xFF555D6E) : colorScheme.outline;
    final fieldFill = isDark ? const Color(0xFF1E212B) : colorScheme.surfaceContainerHighest;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: dialogBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: outlineColor,
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
                      color: capsuleBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: outlineColor),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      LucideIcons.bookmark,
                      size: 20,
                      color: Color(0xFF4ADE80),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Save DAC Profile',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          'Save current hardware tuning to your profile library',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: textSecondary,
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
                  color: capsuleBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: outlineColor),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildSnapshotItem(
                        context: context,
                        label: 'BANDS',
                        value: '${dacState.bands.length}',
                      ),
                    ),
                    Container(width: 1, height: 22, color: outlineColor),
                    Expanded(
                      child: _buildSnapshotItem(
                        context: context,
                        label: 'PREAMP',
                        value: '${dacState.globalGainDb >= 0 ? "+" : ""}${dacState.globalGainDb.toStringAsFixed(1)} dB',
                      ),
                    ),
                    Container(width: 1, height: 22, color: outlineColor),
                    Expanded(
                      child: _buildSnapshotItem(
                        context: context,
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
                style: TextStyle(color: textPrimary, fontSize: 13.5),
                decoration: InputDecoration(
                  labelText: 'Profile Name',
                  labelStyle: TextStyle(color: textSecondary, fontSize: 12),
                  hintText: 'e.g. Warm Vocal Studio / Harman IEM',
                  hintStyle: TextStyle(color: hintColor, fontSize: 12),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  prefixIconConstraints: const BoxConstraints(minWidth: 38, minHeight: 20),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 12, right: 8),
                    child: Icon(
                      LucideIcons.bookmark,
                      size: 15,
                      color: textSecondary,
                    ),
                  ),
                  filled: true,
                  fillColor: fieldFill,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: outlineColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: colorScheme.primary),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Description Field (Optional)
              TextField(
                controller: _descController,
                style: TextStyle(color: textPrimary, fontSize: 13.5),
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  labelStyle: TextStyle(color: textSecondary, fontSize: 12),
                  hintText: 'e.g. Tuned for Kiwi Ears with punchy sub-bass',
                  hintStyle: TextStyle(color: hintColor, fontSize: 12),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  prefixIconConstraints: const BoxConstraints(minWidth: 38, minHeight: 20),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 12, right: 8),
                    child: Icon(
                      LucideIcons.fileText,
                      size: 15,
                      color: textSecondary,
                    ),
                  ),
                  filled: true,
                  fillColor: fieldFill,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: outlineColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: colorScheme.primary),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: Icon(
                        LucideIcons.x,
                        size: 15,
                        color: textSecondary,
                      ),
                      label: Text(
                        'CANCEL',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: textSecondary),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: outlineColor),
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
    required BuildContext context,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: isDark ? const Color(0xFF8A9A90) : colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
