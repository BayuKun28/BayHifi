import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import '../../../../app/theme/app_haptics.dart';
import '../../../../app/theme/simple_as_f_theme.dart';
import '../../domain/fr_curve_data.dart';
import '../controllers/eq_controller.dart';

/// Modal bottom sheet allowing users to view, manage, load, export, and delete
/// their saved frequency response curves (Drivers and Targets).
class SavedCurvesLibrarySheet extends ConsumerStatefulWidget {
  const SavedCurvesLibrarySheet({
    super.key,
    this.initialCategory = 'driver',
  });

  final String initialCategory;

  static Future<void> show(BuildContext context, {String initialCategory = 'driver'}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SavedCurvesLibrarySheet(initialCategory: initialCategory),
    );
  }

  @override
  ConsumerState<SavedCurvesLibrarySheet> createState() => _SavedCurvesLibrarySheetState();
}

class _SavedCurvesLibrarySheetState extends ConsumerState<SavedCurvesLibrarySheet> {
  late String _activeCategory;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _activeCategory = widget.initialCategory;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleImportNew(BuildContext context) async {
    final notifier = ref.read(eqControllerProvider.notifier);
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'csv'],
      );

      if (files.isNotEmpty && files.first.path != null) {
        final file = File(files.first.path!);
        final content = await file.readAsString();
        final rawName = files.first.name.replaceAll('.txt', '').replaceAll('.csv', '');

        final curve = FrCurveData.autoDetectAndParse(
          content,
          name: rawName,
        ).copyWith(
          category: _activeCategory,
          sourceFileName: files.first.name,
          importedAt: DateTime.now(),
        );

        if (_activeCategory == 'target') {
          notifier.importTarget(curve);
        } else {
          notifier.importDriver(curve);
        }

        AppHaptics.mediumImpact();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Successfully imported ${_activeCategory.toUpperCase()}: ${curve.name} (${curve.frequencies.length} points)',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to import curve: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleExportCurve(BuildContext context, FrCurveData curve) async {
    try {
      final content = _activeCategory == 'target'
          ? curve.exportToSquiglinkCsv()
          : curve.exportToRewText();
      final ext = _activeCategory == 'target' ? 'csv' : 'txt';
      final cleanFileName = '${curve.name.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_')}.$ext';
      final bytes = Uint8List.fromList(utf8.encode(content));

      final savedUri = await FilePicker.saveFile(
        dialogTitle: 'Export Frequency Response Curve',
        fileName: cleanFileName,
        bytes: bytes,
        type: FileType.custom,
        allowedExtensions: [ext],
      );

      if (savedUri != null) {
        AppHaptics.mediumImpact();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Curve exported: $cleanFileName'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export curve: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final eqState = ref.watch(eqControllerProvider);
    final notifier = ref.read(eqControllerProvider.notifier);

    final rawList = _activeCategory == 'target'
        ? eqState.availableTargets
        : eqState.availableDrivers;

    final filteredList = rawList.where((c) {
      if (_searchQuery.isEmpty) return true;
      return c.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: SimpleAsFTheme.sheetTopBorderRadius,
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    LucideIcons.folder,
                    size: 20,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FR CURVE LIBRARY',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'User saved headphone drivers and sound target signatures',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                M3EIconButton(
                  variant: M3EIconButtonVariant.tonal,
                  icon: Icon(
                    LucideIcons.x,
                    size: 22,
                    color: colorScheme.onSurface,
                  ),
                  tooltip: 'Close',
                  onPressed: () {
                    AppHaptics.selectionClick();
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Category Switcher (Tabs)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: _buildCategoryTab(
                    label: 'Drivers / IEMs',
                    icon: LucideIcons.headphones,
                    count: eqState.availableDrivers.length,
                    isSelected: _activeCategory == 'driver',
                    onTap: () {
                      AppHaptics.selectionClick();
                      setState(() => _activeCategory = 'driver');
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildCategoryTab(
                    label: 'Target Curves',
                    icon: LucideIcons.target,
                    count: eqState.availableTargets.length,
                    isSelected: _activeCategory == 'target',
                    onTap: () {
                      AppHaptics.selectionClick();
                      setState(() => _activeCategory = 'target');
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Search Bar & Import Action
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    decoration: InputDecoration(
                      hintText: 'Search ${_activeCategory == "target" ? "targets" : "drivers"}...',
                      hintStyle: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      prefixIconConstraints: const BoxConstraints(minWidth: 38, minHeight: 20),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 12, right: 8),
                        child: Icon(
                          LucideIcons.search,
                          size: 15,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest,
                      suffixIcon: _searchQuery.isNotEmpty
                          ? Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: M3EIconButton(
                                variant: M3EIconButtonVariant.standard,
                                icon: Icon(
                                  LucideIcons.x,
                                  size: 16,
                                  color: colorScheme.onSurface,
                                ),
                                tooltip: 'Clear',
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              ),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                M3EButton.filled(
                  icon: const Icon(
                    LucideIcons.plus,
                    size: 16,
                  ),
                  label: const Text('IMPORT'),
                  onPressed: () => _handleImportNew(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Curves List
          Expanded(
            child: filteredList.isEmpty
                ? _buildEmptyState(colorScheme)
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    itemCount: filteredList.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, idx) {
                      final curve = filteredList[idx];
                      final isSelected = _activeCategory == 'target'
                          ? eqState.targetFr?.name == curve.name
                          : eqState.driverFr?.name == curve.name;

                      return _buildCurveTile(
                        context: context,
                        curve: curve,
                        isSelected: isSelected,
                        notifier: notifier,
                        colorScheme: colorScheme,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTab({
    required String label,
    required IconData icon,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 42,
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outlineVariant.withValues(alpha: 0.4),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primary.withValues(alpha: 0.2)
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurveTile({
    required BuildContext context,
    required FrCurveData curve,
    required bool isSelected,
    required EqController notifier,
    required ColorScheme colorScheme,
  }) {
    final isDefault = curve.isDefault;

    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? colorScheme.primaryContainer.withValues(alpha: 0.35)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.outlineVariant.withValues(alpha: 0.4),
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          // Icon badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isSelected ? colorScheme.primary : colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(
              _activeCategory == 'target'
                  ? LucideIcons.target
                  : LucideIcons.headphones,
              size: 18,
              color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),

          // Name and Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  curve.name,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    // Points count
                    Text(
                      '${curve.frequencies.length} pts',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Built-in vs User chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: isDefault
                            ? colorScheme.secondaryContainer
                            : colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isDefault ? 'BUILT-IN' : 'USER IMPORT',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                          color: isDefault
                              ? colorScheme.onSecondaryContainer
                              : colorScheme.onTertiaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Export button
              M3EIconButton(
                variant: M3EIconButtonVariant.standard,
                icon: Icon(
                  LucideIcons.download,
                  size: 16,
                  color: colorScheme.onSurface,
                ),
                tooltip: 'Export as text',
                onPressed: () => _handleExportCurve(context, curve),
              ),

              // Delete button (Only for non-default curves)
              if (!isDefault)
                M3EIconButton(
                  variant: M3EIconButtonVariant.standard,
                  icon: Icon(
                    LucideIcons.trash2,
                    size: 16,
                    color: colorScheme.error,
                  ),
                  tooltip: 'Delete curve',
                  onPressed: () async {
                    AppHaptics.mediumImpact();
                    await notifier.deleteSavedCurve(curve, category: _activeCategory);
                  },
                ),

              const SizedBox(width: 4),

              // Load / Apply Button
              M3EButton.filled(
                decoration: const M3EButtonDecoration(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                onPressed: isSelected
                    ? null
                    : () {
                        AppHaptics.selectionClick();
                        if (_activeCategory == 'target') {
                          notifier.selectTarget(curve);
                        } else {
                          notifier.selectDriver(curve);
                        }
                        Navigator.pop(context);
                      },
                child: Text(
                  isSelected ? 'ACTIVE' : 'LOAD',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.folder,
            size: 40,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'No ${_activeCategory == "target" ? "targets" : "drivers"} found',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap IMPORT to load a .txt or .csv curve from disk.',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
