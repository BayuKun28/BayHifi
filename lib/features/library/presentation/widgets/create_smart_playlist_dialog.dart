import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../domain/smart_playlist_evaluator.dart';
import '../../domain/smart_playlist_models.dart';
import '../controllers/library_controller.dart';

/// Material 3 Expressive Modal Sheet / Dialog to create or edit Smart Playlists
class CreateSmartPlaylistDialog extends ConsumerStatefulWidget {
  final SmartPlaylist? initialPlaylist;

  const CreateSmartPlaylistDialog({
    super.key,
    this.initialPlaylist,
  });

  static Future<SmartPlaylist?> show(
    BuildContext context, {
    SmartPlaylist? initialPlaylist,
  }) {
    final theme = Theme.of(context);
    return showModalBottomSheet<SmartPlaylist>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => CreateSmartPlaylistDialog(initialPlaylist: initialPlaylist),
    );
  }

  @override
  ConsumerState<CreateSmartPlaylistDialog> createState() => _CreateSmartPlaylistDialogState();
}

class _CreateSmartPlaylistDialogState extends ConsumerState<CreateSmartPlaylistDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late final TextEditingController _limitController;

  late SmartPlaylistMatchMode _matchMode;
  late List<SmartPlaylistRule> _rules;
  late String _sortBy;
  late bool _sortAscending;

  final _evaluator = const SmartPlaylistEvaluator();

  @override
  void initState() {
    super.initState();
    final p = widget.initialPlaylist;
    _nameController = TextEditingController(text: p?.name ?? '');
    _descController = TextEditingController(text: p?.description ?? '');
    _limitController = TextEditingController(
      text: p?.limit != null ? p!.limit.toString() : '',
    );
    _matchMode = p?.matchMode ?? SmartPlaylistMatchMode.all;
    _rules = p?.rules != null
        ? List<SmartPlaylistRule>.from(p!.rules)
        : [
            const SmartPlaylistRule(
              field: SmartPlaylistField.title,
              operator: SmartPlaylistOperator.contains,
              value: '',
            ),
          ];
    _sortBy = p?.sortBy ?? 'title';
    _sortAscending = p?.sortAscending ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _limitController.dispose();
    super.dispose();
  }

  SmartPlaylist _buildCurrentDraft() {
    final limitVal = int.tryParse(_limitController.text.trim());
    return SmartPlaylist(
      id: widget.initialPlaylist?.id ?? 'smart_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim().isNotEmpty
          ? _nameController.text.trim()
          : 'Untitled Smart Playlist',
      description: _descController.text.trim(),
      matchMode: _matchMode,
      rules: _rules,
      limit: limitVal != null && limitVal > 0 ? limitVal : null,
      sortBy: _sortBy,
      sortAscending: _sortAscending,
      createdAt: widget.initialPlaylist?.createdAt ?? DateTime.now(),
      isPreset: false,
    );
  }

  void _addRule() {
    setState(() {
      _rules.add(
        const SmartPlaylistRule(
          field: SmartPlaylistField.artist,
          operator: SmartPlaylistOperator.contains,
          value: '',
        ),
      );
    });
  }

  void _removeRule(int index) {
    if (_rules.length <= 1) return;
    setState(() {
      _rules.removeAt(index);
    });
  }

  void _updateRule(int index, SmartPlaylistRule newRule) {
    setState(() {
      _rules[index] = newRule;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final libraryState = ref.watch(unifiedLibraryProvider);

    // Live preview evaluation
    final draft = _buildCurrentDraft();
    final matchedTracks = _evaluator.evaluate(
      playlist: draft,
      allTracks: libraryState.tracks,
      favoriteTrackIds: libraryState.favoriteTrackIds,
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Sheet Drag Handle
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Top Title & Live Counter Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: primary.withValues(alpha: 0.4)),
                      ),
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedFilterHorizontal,
                        size: 20,
                        color: primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.initialPlaylist != null
                                ? 'EDIT SMART PLAYLIST'
                                : 'NEW SMART PLAYLIST',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                          Text(
                            'Dynamic rule engine automatically updates playlist contents',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Live Matched Count Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: primary.withValues(alpha: 0.5), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedMusicNote01,
                            size: 13,
                            color: primary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${matchedTracks.length} Matched',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              fontFeatures: const [FontFeature.tabularFigures()],
                              color: primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 24),

              // Main Form Body
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  children: [
                    // Name input
                    TextField(
                      controller: _nameController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Playlist Name',
                        hintText: 'e.g. 24-bit 96k Studio Acoustic',
                        prefixIcon: HugeIcon(
                          icon: HugeIcons.strokeRoundedPlaylist01,
                          size: 18,
                          color: primary,
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Description input
                    TextField(
                      controller: _descController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Description (Optional)',
                        hintText: 'Filter definition notes',
                        prefixIcon: HugeIcon(
                          icon: HugeIcons.strokeRoundedNote01,
                          size: 18,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Match Mode Selector Chips
                    Text(
                      'MATCH LOGIC',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(
                              child: Text('Match ALL (AND)', style: TextStyle(fontSize: 12)),
                            ),
                            selected: _matchMode == SmartPlaylistMatchMode.all,
                            onSelected: (val) {
                              if (val) setState(() => _matchMode = SmartPlaylistMatchMode.all);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(
                              child: Text('Match ANY (OR)', style: TextStyle(fontSize: 12)),
                            ),
                            selected: _matchMode == SmartPlaylistMatchMode.any,
                            onSelected: (val) {
                              if (val) setState(() => _matchMode = SmartPlaylistMatchMode.any);
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Rules Header & Add Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'CONDITIONS (${_rules.length})',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _addRule,
                          icon: const HugeIcon(icon: HugeIcons.strokeRoundedAddCircle, size: 16, color: null),
                          label: const Text('Add Rule', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // List of Rule Cards
                    ..._rules.asMap().entries.map((entry) {
                      final index = entry.key;
                      final rule = entry.value;
                      return _buildRuleCard(context, index, rule);
                    }),

                    const SizedBox(height: 20),

                    // Sorting & Limit Row
                    Text(
                      'SORTING & LIMITS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.4)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: DropdownButtonFormField<String>(
                                  initialValue: _sortBy,
                                  decoration: InputDecoration(
                                    labelText: 'Sort By',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: 'title', child: Text('Track Title')),
                                    DropdownMenuItem(value: 'artist', child: Text('Artist Name')),
                                    DropdownMenuItem(value: 'album', child: Text('Album Name')),
                                    DropdownMenuItem(value: 'duration', child: Text('Duration')),
                                    DropdownMenuItem(value: 'sampleRate', child: Text('Sample Rate')),
                                    DropdownMenuItem(value: 'bitDepth', child: Text('Bit Depth')),
                                    DropdownMenuItem(value: 'dateAdded', child: Text('Date Added')),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) setState(() => _sortBy = val);
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () => setState(() => _sortAscending = !_sortAscending),
                                  child: Container(
                                    height: 48,
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: theme.dividerColor),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        HugeIcon(
                                          icon: _sortAscending
                                              ? HugeIcons.strokeRoundedSorting01
                                              : HugeIcons.strokeRoundedSorting02,
                                          size: 16,
                                          color: primary,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _sortAscending ? 'Asc' : 'Desc',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _limitController,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              labelText: 'Max Tracks Limit (Optional)',
                              hintText: 'e.g. 50 (leave empty for unlimited)',
                              prefixIcon: HugeIcon(
                                icon: HugeIcons.strokeRoundedLayers01,
                                size: 18,
                                color: primary,
                              ),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom Confirmation Actions
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border(top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.4))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: () {
                          final name = _nameController.text.trim();
                          if (name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter a playlist name.')),
                            );
                            return;
                          }
                          final result = _buildCurrentDraft();
                          ref.read(unifiedLibraryProvider.notifier).saveSmartPlaylist(result);
                          Navigator.of(context).pop(result);
                        },
                        icon: const HugeIcon(
                          icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                          size: 18,
                          color: null,
                        ),
                        label: Text(
                          widget.initialPlaylist != null ? 'Update Playlist' : 'Save Smart Playlist',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRuleCard(BuildContext context, int index, SmartPlaylistRule rule) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final operators = SmartPlaylistOperator.operatorsForType(rule.field.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: primary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<SmartPlaylistField>(
                  initialValue: rule.field,
                  isDense: true,
                  decoration: InputDecoration(
                    labelText: 'Field',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  items: SmartPlaylistField.values.map((f) {
                    return DropdownMenuItem(
                      value: f,
                      child: Text(f.label, style: const TextStyle(fontSize: 12.5)),
                    );
                  }).toList(),
                  onChanged: (newField) {
                    if (newField != null) {
                      final newOps = SmartPlaylistOperator.operatorsForType(newField.type);
                      _updateRule(
                        index,
                        SmartPlaylistRule(
                          field: newField,
                          operator: newOps.first,
                          value: newField.type == SmartPlaylistFieldType.boolean ? 'true' : '',
                        ),
                      );
                    }
                  },
                ),
              ),
              if (_rules.length > 1) ...[
                const SizedBox(width: 6),
                IconButton(
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedDelete02,
                    size: 18,
                    color: theme.colorScheme.error,
                  ),
                  onPressed: () => _removeRule(index),
                  tooltip: 'Delete Condition',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Operator Dropdown
              Expanded(
                flex: 4,
                child: DropdownButtonFormField<SmartPlaylistOperator>(
                  initialValue: operators.contains(rule.operator) ? rule.operator : operators.first,
                  isDense: true,
                  decoration: InputDecoration(
                    labelText: 'Operator',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  items: operators.map((op) {
                    return DropdownMenuItem(
                      value: op,
                      child: Text(
                        op.label,
                        style: const TextStyle(fontSize: 11.5),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (newOp) {
                    if (newOp != null) {
                      _updateRule(index, rule.copyWith(operator: newOp));
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Value Input (conditional based on field type)
              Expanded(
                flex: 5,
                child: _buildValueInput(rule, index),
              ),
            ],
          ),
          // Secondary input for "between" operator
          if (rule.operator == SmartPlaylistOperator.between) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const SizedBox(width: 24, child: Text('to', style: TextStyle(fontSize: 11))),
                Expanded(
                  child: TextFormField(
                    initialValue: rule.secondaryValue ?? '',
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      labelText: 'Upper Range Limit',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    onChanged: (val) {
                      _updateRule(index, rule.copyWith(secondaryValue: val));
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildValueInput(SmartPlaylistRule rule, int index) {
    if (rule.field.type == SmartPlaylistFieldType.boolean) {
      return DropdownButtonFormField<String>(
        initialValue: rule.value == 'false' ? 'false' : 'true',
        isDense: true,
        decoration: InputDecoration(
          labelText: 'Value',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        ),
        items: const [
          DropdownMenuItem(value: 'true', child: Text('Yes / True', style: TextStyle(fontSize: 12))),
          DropdownMenuItem(value: 'false', child: Text('No / False', style: TextStyle(fontSize: 12))),
        ],
        onChanged: (val) {
          if (val != null) {
            _updateRule(index, rule.copyWith(value: val));
          }
        },
      );
    }

    return TextFormField(
      initialValue: rule.value,
      keyboardType: rule.field.type == SmartPlaylistFieldType.number
          ? TextInputType.number
          : TextInputType.text,
      style: const TextStyle(fontSize: 12),
      decoration: InputDecoration(
        labelText: rule.field.type == SmartPlaylistFieldType.number ? 'Target Value' : 'Keyword',
        hintText: rule.field == SmartPlaylistField.duration ? 'Seconds (e.g. 180)' : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      onChanged: (val) {
        _updateRule(index, rule.copyWith(value: val));
      },
    );
  }
}
