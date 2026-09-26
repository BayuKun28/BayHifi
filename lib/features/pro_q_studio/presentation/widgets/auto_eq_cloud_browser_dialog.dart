import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
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

    final items = _onlineResults ??
        _service.searchItems(
          query: _searchQuery,
          category: _selectedCategory,
          onlyDownloaded: _onlyDownloaded,
        );

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Container(
        width: 720,
        height: 540,
        decoration: BoxDecoration(
          color: const Color(0xFF10151E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF263345), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.7),
              blurRadius: 30,
              spreadRadius: 8,
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── 1. HEADER ROW ───────────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.4)),
                  ),
                  child: const HugeIcon(
                    icon: HugeIcons.strokeRoundedCloudDownload,
                    size: 20,
                    color: Color(0xFF00E5FF),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'AUTOEQ & SQUIGLINK CLOUD DATABASE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Search and download target curves & IEM/Headphone measurements directly to Pro-Q DSP',
                        style: TextStyle(
                          color: Color(0xFF8899A6),
                          fontSize: 10.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedCancel01,
                    size: 18,
                    color: Color(0xFF8899A6),
                  ),
                  tooltip: 'Close',
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ─── 2. SEARCH BAR ───────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF161E2C),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF263345)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const HugeIcon(
                    icon: HugeIcons.strokeRoundedSearch01,
                    size: 16,
                    color: Color(0xFF78909C),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white, fontSize: 12.5),
                      decoration: const InputDecoration(
                        hintText: 'Search by model (e.g. Castor, Chu II, HD600, Harman, HBB)...',
                        hintStyle: TextStyle(color: Color(0xFF546E7A), fontSize: 11.5),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                      onChanged: _onSearchChanged,
                    ),
                  ),
                  if (_isSearchingOnline)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: Color(0xFF00E5FF),
                        ),
                      ),
                    ),
                  if (_searchQuery.isNotEmpty)
                    IconButton(
                      icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedCancel01,
                        size: 14,
                        color: Color(0xFF78909C),
                      ),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    ),
                ],
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
                  ),
                  const SizedBox(width: 6),
                  _buildFilterTab(
                    label: 'TARGET CURVES',
                    isSelected: _selectedCategory == AutoEqCloudCategory.target,
                    onTap: () => setState(() {
                      _selectedCategory = AutoEqCloudCategory.target;
                      _onlyDownloaded = false;
                    }),
                  ),
                  const SizedBox(width: 6),
                  _buildFilterTab(
                    label: 'IEMs',
                    isSelected: _selectedCategory == AutoEqCloudCategory.iem,
                    onTap: () => setState(() {
                      _selectedCategory = AutoEqCloudCategory.iem;
                      _onlyDownloaded = false;
                    }),
                  ),
                  const SizedBox(width: 6),
                  _buildFilterTab(
                    label: 'HEADPHONES',
                    isSelected: _selectedCategory == AutoEqCloudCategory.headphone,
                    onTap: () => setState(() {
                      _selectedCategory = AutoEqCloudCategory.headphone;
                      _onlyDownloaded = false;
                    }),
                  ),
                  const SizedBox(width: 6),
                  _buildFilterTab(
                    label: 'DOWNLOADED',
                    isSelected: _onlyDownloaded,
                    onTap: () => setState(() {
                      _onlyDownloaded = true;
                      _selectedCategory = null;
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ─── 4. LIST OF CLOUD ITEMS ──────────────────────────────────────
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedSearch01,
                            size: 32,
                            color: Color(0xFF546E7A),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'No measurement or target curve matches your query.',
                            style: TextStyle(color: Color(0xFF78909C), fontSize: 12),
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

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF141B26),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelectedAsDriver || isSelectedAsTarget
                                  ? const Color(0xFF00E676)
                                  : const Color(0xFF202B3A),
                              width: isSelectedAsDriver || isSelectedAsTarget ? 1.4 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Icon & Mini Category Badge
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: isTarget
                                      ? const Color(0xFFFF9F0A).withValues(alpha: 0.15)
                                      : const Color(0xFF00E5FF).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isTarget
                                        ? const Color(0xFFFF9F0A).withValues(alpha: 0.4)
                                        : const Color(0xFF00E5FF).withValues(alpha: 0.4),
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
                                    color: isTarget ? const Color(0xFFFF9F0A) : const Color(0xFF00E5FF),
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
                                            style: const TextStyle(
                                              color: Colors.white,
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
                                            color: const Color(0xFF1E2838),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: const Color(0xFF2C3C54), width: 0.6),
                                          ),
                                          child: Text(
                                            item.source,
                                            style: const TextStyle(
                                              color: Color(0xFF90A4AE),
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
                                      style: const TextStyle(
                                        color: Color(0xFF78909C),
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
                                  if (isTarget)
                                    ElevatedButton.icon(
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
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isSelectedAsTarget
                                            ? const Color(0xFF00E676)
                                            : const Color(0xFFFF9F0A),
                                        foregroundColor: Colors.black,
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      icon: HugeIcon(
                                        icon: isSelectedAsTarget
                                            ? HugeIcons.strokeRoundedCheckmarkCircle02
                                            : HugeIcons.strokeRoundedTarget02,
                                        size: 13,
                                        color: Colors.black,
                                      ),
                                      label: Text(
                                        isSelectedAsTarget ? 'ACTIVE TARGET' : 'SET TARGET',
                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    )
                                  else
                                    ElevatedButton.icon(
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
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isSelectedAsDriver
                                            ? const Color(0xFF00E676)
                                            : const Color(0xFF00E5FF),
                                        foregroundColor: Colors.black,
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      icon: HugeIcon(
                                        icon: isSelectedAsDriver
                                            ? HugeIcons.strokeRoundedCheckmarkCircle02
                                            : HugeIcons.strokeRoundedHeadphones,
                                        size: 13,
                                        color: Colors.black,
                                      ),
                                      label: Text(
                                        isSelectedAsDriver ? 'ACTIVE DRIVER' : 'SET DRIVER',
                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  const SizedBox(width: 6),
                                  // Quick Solve & Apply button
                                  OutlinedButton(
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
                                            const SnackBar(
                                              backgroundColor: Color(0xFF00E676),
                                              content: Text(
                                                'AutoEQ Solved and Applied directly to Pro-Q DSP!',
                                                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                              ),
                                              duration: Duration(seconds: 3),
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
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                      side: const BorderSide(color: Color(0xFF00E676), width: 0.8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    child: const Text(
                                      'SOLVE',
                                      style: TextStyle(
                                        color: Color(0xFF00E676),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
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
      ),
    );
  }

  Widget _buildFilterTab({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00E5FF).withValues(alpha: 0.18) : const Color(0xFF141B26),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF00E5FF) : const Color(0xFF263345),
            width: isSelected ? 1.2 : 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF90A4AE),
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
