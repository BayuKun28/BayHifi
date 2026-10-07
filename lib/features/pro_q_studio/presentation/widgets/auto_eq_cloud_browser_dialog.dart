import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import '../../../../app/theme/studio_surface_theme.dart';
import '../../data/auto_eq_cloud_service.dart';
import '../../domain/auto_eq_cloud_model.dart';
import '../controllers/eq_controller.dart';

/// Modal Dialog Browser untuk AutoEQ & Squiglink Cloud Database
class AutoEqCloudBrowserDialog extends ConsumerStatefulWidget {
  const AutoEqCloudBrowserDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (context) => const AutoEqCloudBrowserDialog(),
    );
  }

  @override
  ConsumerState<AutoEqCloudBrowserDialog> createState() => _AutoEqCloudBrowserDialogState();
}

class _AutoEqCloudBrowserDialogState extends ConsumerState<AutoEqCloudBrowserDialog> {
  final TextEditingController _searchController = TextEditingController();
  final AutoEqCloudService _service = AutoEqCloudService.instance;

  String _searchQuery = '';
  AutoEqCloudCategory? _selectedCategory;
  bool _onlyDownloaded = false;
  bool _isSearchingOnline = false;
  List<AutoEqCloudItem>? _onlineResults;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    setState(() {
      _searchQuery = val;
      _onlineResults = null;
    });

    if (val.trim().length >= 2) {
      _triggerOnlineSearch(val.trim());
    }
  }

  Future<void> _triggerOnlineSearch(String query) async {
    setState(() => _isSearchingOnline = true);
    try {
      final results = await _service.searchOnline(query, category: _selectedCategory);
      if (mounted && _searchQuery.trim() == query) {
        setState(() {
          _onlineResults = results;
          _isSearchingOnline = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSearchingOnline = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final eqState = ref.watch(eqControllerProvider);
    final eqNotifier = ref.read(eqControllerProvider.notifier);
    final theme = Theme.of(context);
    final isSolid = ref.isSolidStyle;

    final items = _onlineResults ??
        _service.searchItems(
          query: _searchQuery,
          category: _selectedCategory,
          onlyDownloaded: _onlyDownloaded,
        );

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isPortrait = constraints.maxWidth < 520;

          return Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxWidth: 680,
              maxHeight: MediaQuery.of(context).size.height * 0.88,
            ),
            decoration: BoxDecoration(
              color: StudioSurfaceTheme.surface(context, isSolid: isSolid),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: StudioSurfaceTheme.outline(context, isSolid: isSolid), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isSolid ? 0.4 : 0.7),
                  blurRadius: 30,
                  spreadRadius: 8,
                ),
              ],
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── 1. HEADER ROW ───────────────────────────────────────────────
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: StudioSurfaceTheme.tintedContainer(
                          context,
                          theme.colorScheme.primary,
                          isSolid: isSolid,
                          translucentAlpha: 0.15,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSolid ? theme.colorScheme.primary : theme.colorScheme.primary.withValues(alpha: 0.4),
                        ),
                      ),
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedCloudDownload,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AUTOEQ & SQUIGLINK CLOUD DATABASE',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Search & download curves directly to Pro-Q DSP',
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 10.0,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    M3EIconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: HugeIcon(
                        icon: HugeIcons.strokeRoundedCancel01,
                        size: 18,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      tooltip: 'Close',
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ─── 2. SEARCH BAR (tap to open fullscreen keyboard) ─────────────
                GestureDetector(
                  onTap: () async {
                    final result = await Navigator.of(context).push<String>(
                      MaterialPageRoute(
                        fullscreenDialog: true,
                        builder: (ctx) => _FullscreenCloudSearchPage(
                          initialValue: _searchQuery,
                        ),
                      ),
                    );
                    if (result != null) {
                      _searchController.text = result;
                      _onSearchChanged(result);
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: StudioSurfaceTheme.surfaceContainerLow(context, isSolid: isSolid),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                    child: Row(
                      children: [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedSearch01,
                          size: 15,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _searchQuery.isNotEmpty
                                ? _searchQuery
                                : 'Search model (Castor, Chu II, HD600, Harman)...',
                            style: TextStyle(
                              color: _searchQuery.isNotEmpty
                                  ? theme.colorScheme.onSurface
                                  : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
                              fontSize: 12.0,
                            ),
                          ),
                        ),
                        if (_isSearchingOnline)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: SizedBox(
                              width: 13,
                              height: 13,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        if (_searchQuery.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: HugeIcon(
                                icon: HugeIcons.strokeRoundedCancel01,
                                size: 13,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // ─── 3. CATEGORY FILTER TABS ─────────────────────────────────────
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterTab(
                        label: 'ALL',
                        isSelected: _selectedCategory == null && !_onlyDownloaded,
                        onTap: () => setState(() {
                          _selectedCategory = null;
                          _onlyDownloaded = false;
                        }),
                        isSolid: isSolid,
                        theme: theme,
                      ),
                      const SizedBox(width: 6),
                      _buildFilterTab(
                        label: 'TARGETS',
                        isSelected: _selectedCategory == AutoEqCloudCategory.target,
                        onTap: () => setState(() {
                          _selectedCategory = AutoEqCloudCategory.target;
                          _onlyDownloaded = false;
                        }),
                        isSolid: isSolid,
                        theme: theme,
                      ),
                      const SizedBox(width: 6),
                      _buildFilterTab(
                        label: 'IEMs',
                        isSelected: _selectedCategory == AutoEqCloudCategory.iem,
                        onTap: () => setState(() {
                          _selectedCategory = AutoEqCloudCategory.iem;
                          _onlyDownloaded = false;
                        }),
                        isSolid: isSolid,
                        theme: theme,
                      ),
                      const SizedBox(width: 6),
                      _buildFilterTab(
                        label: 'HEADPHONES',
                        isSelected: _selectedCategory == AutoEqCloudCategory.headphone,
                        onTap: () => setState(() {
                          _selectedCategory = AutoEqCloudCategory.headphone;
                          _onlyDownloaded = false;
                        }),
                        isSolid: isSolid,
                        theme: theme,
                      ),
                      const SizedBox(width: 6),
                      _buildFilterTab(
                        label: 'DOWNLOADED',
                        isSelected: _onlyDownloaded,
                        onTap: () => setState(() {
                          _onlyDownloaded = true;
                          _selectedCategory = null;
                        }),
                        isSolid: isSolid,
                        theme: theme,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // ─── 4. LIST OF CLOUD ITEMS ──────────────────────────────────────
                Expanded(
                  child: items.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              HugeIcon(
                                icon: HugeIcons.strokeRoundedSearch01,
                                size: 30,
                                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'No measurement or target curve matches your query.',
                                style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 11.5),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: items.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            final isTarget = item.category == AutoEqCloudCategory.target;
                            final isSelectedAsDriver = eqState.driverFr?.name == item.name;
                            final isSelectedAsTarget = eqState.targetFr?.name == item.name;
                            final isSelected = isSelectedAsDriver || isSelectedAsTarget;

                            final Color targetColor = const Color(0xFFFF9F0A);
                            final Color driverColor = theme.colorScheme.secondary;

                            final Widget setButton = isTarget
                                ? M3EButton.elevated(
                                    onPressed: () async {
                                      final curve = await _service.downloadItem(item);
                                      eqNotifier.importTarget(curve);
                                      setState(() {});
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Target set: ${item.name}'),
                                            duration: const Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                    },
                                    icon: HugeIcon(
                                      icon: isSelectedAsTarget
                                          ? HugeIcons.strokeRoundedCheckmarkCircle02
                                          : HugeIcons.strokeRoundedTarget02,
                                      size: 13,
                                      color: isSelectedAsTarget ? theme.colorScheme.onPrimary : Colors.black,
                                    ),
                                    label: Text(
                                      isSelectedAsTarget ? 'ACTIVE TARGET' : 'SET TARGET',
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  )
                                : M3EButton.elevated(
                                    onPressed: () async {
                                      final curve = await _service.downloadItem(item);
                                      eqNotifier.importDriver(curve);
                                      setState(() {});
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Driver measurement set: ${item.name}'),
                                            duration: const Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                    },
                                    icon: HugeIcon(
                                      icon: isSelectedAsDriver
                                          ? HugeIcons.strokeRoundedCheckmarkCircle02
                                          : HugeIcons.strokeRoundedHeadphones,
                                      size: 13,
                                      color: isSelectedAsDriver ? theme.colorScheme.onPrimary : theme.colorScheme.onSecondary,
                                    ),
                                    label: Text(
                                      isSelectedAsDriver ? 'ACTIVE DRIVER' : 'SET DRIVER',
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );

                            final Widget solveButton = M3EButton.outlined(
                              onPressed: () async {
                                final curve = await _service.downloadItem(item);
                                if (isTarget) {
                                  eqNotifier.importTarget(curve);
                                } else {
                                  eqNotifier.importDriver(curve);
                                }

                                final success = eqNotifier.applyAutoEq();
                                if (success) {
                                  if (context.mounted) {
                                    Navigator.of(context).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        backgroundColor: theme.colorScheme.primary,
                                        content: Text(
                                          'AutoEQ Solved and Applied directly to Pro-Q DSP!',
                                          style: TextStyle(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.bold),
                                        ),
                                        duration: const Duration(seconds: 3),
                                      ),
                                    );
                                  }
                                } else {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          isTarget
                                              ? 'Target set! Please select a Driver measurement to solve.'
                                              : 'Driver set! Please select a Target curve to solve.',
                                        ),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                }
                              },
                              label: Text(
                                'SOLVE',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );

                            if (isPortrait) {
                              // Portrait Mode: 2-tier card to prevent collision & horizontal overflow
                              return Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: StudioSurfaceTheme.surfaceContainer(context, isSolid: isSolid),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? (isSolid ? theme.colorScheme.primary : theme.colorScheme.primary.withValues(alpha: 0.8))
                                        : StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid),
                                    width: isSelected ? 1.4 : 1.0,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: StudioSurfaceTheme.tintedContainer(
                                              context,
                                              isTarget ? targetColor : driverColor,
                                              isSolid: isSolid,
                                              translucentAlpha: 0.15,
                                            ),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: isSolid
                                                  ? (isTarget ? targetColor : driverColor)
                                                  : (isTarget ? targetColor : driverColor).withValues(alpha: 0.4),
                                            ),
                                          ),
                                          child: Center(
                                            child: HugeIcon(
                                              icon: isTarget
                                                  ? HugeIcons.strokeRoundedTarget02
                                                  : (item.category == AutoEqCloudCategory.headphone
                                                      ? HugeIcons.strokeRoundedHeadphones
                                                      : HugeIcons.strokeRoundedAudioWaveform),
                                              size: 16,
                                              color: isTarget ? targetColor : driverColor,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      item.name,
                                                      style: TextStyle(
                                                        color: theme.colorScheme.onSurface,
                                                        fontSize: 12.0,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                                    decoration: BoxDecoration(
                                                      color: StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid),
                                                      borderRadius: BorderRadius.circular(4),
                                                      border: Border.all(
                                                        color: StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid),
                                                        width: 0.6,
                                                      ),
                                                    ),
                                                    child: Text(
                                                      item.source,
                                                      style: TextStyle(
                                                        color: theme.colorScheme.onSurfaceVariant,
                                                        fontSize: 8.5,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                item.description,
                                                style: TextStyle(
                                                  color: theme.colorScheme.onSurfaceVariant,
                                                  fontSize: 10.0,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(child: setButton),
                                        const SizedBox(width: 6),
                                        solveButton,
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }

                            // Landscape Mode: Clean single-row layout
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: StudioSurfaceTheme.surfaceContainer(context, isSolid: isSolid),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? (isSolid ? theme.colorScheme.primary : theme.colorScheme.primary.withValues(alpha: 0.8))
                                      : StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid),
                                  width: isSelected ? 1.4 : 1.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Icon & Mini Category Badge
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: StudioSurfaceTheme.tintedContainer(
                                        context,
                                        isTarget ? targetColor : driverColor,
                                        isSolid: isSolid,
                                        translucentAlpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isSolid
                                            ? (isTarget ? targetColor : driverColor)
                                            : (isTarget ? targetColor : driverColor).withValues(alpha: 0.4),
                                      ),
                                    ),
                                    child: Center(
                                      child: HugeIcon(
                                        icon: isTarget
                                            ? HugeIcons.strokeRoundedTarget02
                                            : (item.category == AutoEqCloudCategory.headphone
                                                ? HugeIcons.strokeRoundedHeadphones
                                                : HugeIcons.strokeRoundedAudioWaveform),
                                        size: 18,
                                        color: isTarget ? targetColor : driverColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Item Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                item.name,
                                                style: TextStyle(
                                                  color: theme.colorScheme.onSurface,
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid),
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(
                                                  color: StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid),
                                                  width: 0.6,
                                                ),
                                              ),
                                              child: Text(
                                                item.source,
                                                style: TextStyle(
                                                  color: theme.colorScheme.onSurfaceVariant,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          item.description,
                                          style: TextStyle(
                                            color: theme.colorScheme.onSurfaceVariant,
                                            fontSize: 10.5,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  // Action Buttons
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 130,
                                        child: setButton,
                                      ),
                                      const SizedBox(width: 6),
                                      solveButton,
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterTab({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isSolid,
    required ThemeData theme,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? StudioSurfaceTheme.tintedContainer(
                  context,
                  theme.colorScheme.primary,
                  isSolid: isSolid,
                  translucentAlpha: 0.18,
                  solidBlendAlpha: 0.25,
                )
              : StudioSurfaceTheme.surfaceContainerLow(context, isSolid: isSolid),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? (isSolid ? theme.colorScheme.primary : theme.colorScheme.primary.withValues(alpha: 0.8))
                : StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid),
            width: isSelected ? 1.2 : 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ─── Fullscreen Cloud Search Input Page ─────────────────────────────────────

/// Full-screen search page for the Cloud DB — provides a proper landscape
/// keyboard experience by using a dedicated route instead of an inline TextField.
class _FullscreenCloudSearchPage extends StatefulWidget {
  final String initialValue;
  const _FullscreenCloudSearchPage({required this.initialValue});

  @override
  State<_FullscreenCloudSearchPage> createState() => _FullscreenCloudSearchPageState();
}

class _FullscreenCloudSearchPageState extends State<_FullscreenCloudSearchPage> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: M3EIconButton(
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          onPressed: () => Navigator.of(context).pop(null),
          tooltip: 'Back',
        ),
        title: Text(
          'CLOUD DB SEARCH',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            color: theme.colorScheme.onSurface,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: M3EButton.filled(
              onPressed: _submit,
              label: const Text(
                'SEARCH',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: theme.colorScheme.outlineVariant,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _submit(),
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: 'e.g. Sennheiser HD600, KZ Castor, Harman IEM...',
            hintStyle: TextStyle(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
              fontSize: 14,
            ),
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 2,
              ),
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedSearch01,
                size: 20,
                color: theme.colorScheme.primary,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 44),
            suffixIcon: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _controller,
              builder: (_, value, child) => value.text.isEmpty
                  ? const SizedBox.shrink()
                  : M3EIconButton(
                      icon: HugeIcon(
                        icon: HugeIcons.strokeRoundedCancel01,
                        size: 18,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      onPressed: () => _controller.clear(),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
