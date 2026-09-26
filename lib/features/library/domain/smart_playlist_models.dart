import 'package:flutter/foundation.dart';

/// Field options that can be evaluated in a smart playlist rule
enum SmartPlaylistField {
  title('Title', SmartPlaylistFieldType.text),
  artist('Artist', SmartPlaylistFieldType.text),
  album('Album', SmartPlaylistFieldType.text),
  genre('Genre', SmartPlaylistFieldType.text),
  filePath('File Path / Extension', SmartPlaylistFieldType.text),
  duration('Duration (seconds)', SmartPlaylistFieldType.number),
  sampleRate('Sample Rate (Hz)', SmartPlaylistFieldType.number),
  bitDepth('Bit Depth (bits)', SmartPlaylistFieldType.number),
  bitrate('Bitrate (kbps)', SmartPlaylistFieldType.number),
  year('Release Year', SmartPlaylistFieldType.number),
  isHiRes('Hi-Res Lossless', SmartPlaylistFieldType.boolean),
  isFavorite('Favorite', SmartPlaylistFieldType.boolean),
  isOffline('Offline Local File', SmartPlaylistFieldType.boolean);

  final String label;
  final SmartPlaylistFieldType type;
  const SmartPlaylistField(this.label, this.type);
}

enum SmartPlaylistFieldType {
  text,
  number,
  boolean,
}

/// Comparison operators for rules
enum SmartPlaylistOperator {
  // Text operators
  contains('Contains'),
  notContains('Does Not Contain'),
  equals('Equals'),
  notEquals('Does Not Equal'),
  startsWith('Starts With'),
  endsWith('Ends With'),

  // Number operators
  greaterThan('Greater Than (>)'),
  greaterThanOrEqual('Greater or Equal (>=)'),
  lessThan('Less Than (<)'),
  lessThanOrEqual('Less or Equal (<=)'),
  between('Between (inclusive)'),

  // Boolean operators
  isTrue('Is True (Yes)'),
  isFalse('Is False (No)');

  final String label;
  const SmartPlaylistOperator(this.label);

  static List<SmartPlaylistOperator> operatorsForType(SmartPlaylistFieldType type) {
    switch (type) {
      case SmartPlaylistFieldType.text:
        return [
          SmartPlaylistOperator.contains,
          SmartPlaylistOperator.notContains,
          SmartPlaylistOperator.equals,
          SmartPlaylistOperator.notEquals,
          SmartPlaylistOperator.startsWith,
          SmartPlaylistOperator.endsWith,
        ];
      case SmartPlaylistFieldType.number:
        return [
          SmartPlaylistOperator.equals,
          SmartPlaylistOperator.greaterThan,
          SmartPlaylistOperator.greaterThanOrEqual,
          SmartPlaylistOperator.lessThan,
          SmartPlaylistOperator.lessThanOrEqual,
          SmartPlaylistOperator.between,
        ];
      case SmartPlaylistFieldType.boolean:
        return [
          SmartPlaylistOperator.isTrue,
          SmartPlaylistOperator.isFalse,
        ];
    }
  }
}

/// Match combination logic
enum SmartPlaylistMatchMode {
  all('Match ALL Conditions (AND)'),
  any('Match ANY Condition (OR)');

  final String label;
  const SmartPlaylistMatchMode(this.label);
}

/// Single rule condition
@immutable
class SmartPlaylistRule {
  final SmartPlaylistField field;
  final SmartPlaylistOperator operator;
  final String value;
  final String? secondaryValue; // Used for "between"

  const SmartPlaylistRule({
    required this.field,
    required this.operator,
    required this.value,
    this.secondaryValue,
  });

  SmartPlaylistRule copyWith({
    SmartPlaylistField? field,
    SmartPlaylistOperator? operator,
    String? value,
    String? secondaryValue,
  }) {
    return SmartPlaylistRule(
      field: field ?? this.field,
      operator: operator ?? this.operator,
      value: value ?? this.value,
      secondaryValue: secondaryValue ?? this.secondaryValue,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'field': field.name,
      'operator': operator.name,
      'value': value,
      'secondaryValue': secondaryValue,
    };
  }

  factory SmartPlaylistRule.fromMap(Map<String, dynamic> map) {
    final fieldName = map['field'] as String? ?? 'title';
    final operatorName = map['operator'] as String? ?? 'contains';

    final field = SmartPlaylistField.values.firstWhere(
      (f) => f.name == fieldName,
      orElse: () => SmartPlaylistField.title,
    );

    final defaultOp = SmartPlaylistOperator.operatorsForType(field.type).first;
    final operator = SmartPlaylistOperator.values.firstWhere(
      (o) => o.name == operatorName,
      orElse: () => defaultOp,
    );

    return SmartPlaylistRule(
      field: field,
      operator: operator,
      value: map['value']?.toString() ?? '',
      secondaryValue: map['secondaryValue']?.toString(),
    );
  }
}

/// Dynamic Smart Playlist Definition
@immutable
class SmartPlaylist {
  final String id;
  final String name;
  final String description;
  final SmartPlaylistMatchMode matchMode;
  final List<SmartPlaylistRule> rules;
  final int? limit;
  final String sortBy; // 'title', 'artist', 'album', 'duration', 'dateAdded', 'sampleRate'
  final bool sortAscending;
  final DateTime createdAt;
  final bool isPreset;

  const SmartPlaylist({
    required this.id,
    required this.name,
    required this.description,
    this.matchMode = SmartPlaylistMatchMode.all,
    this.rules = const [],
    this.limit,
    this.sortBy = 'title',
    this.sortAscending = true,
    required this.createdAt,
    this.isPreset = false,
  });

  SmartPlaylist copyWith({
    String? id,
    String? name,
    String? description,
    SmartPlaylistMatchMode? matchMode,
    List<SmartPlaylistRule>? rules,
    int? limit,
    String? sortBy,
    bool? sortAscending,
    DateTime? createdAt,
    bool? isPreset,
  }) {
    return SmartPlaylist(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      matchMode: matchMode ?? this.matchMode,
      rules: rules ?? this.rules,
      limit: limit ?? this.limit,
      sortBy: sortBy ?? this.sortBy,
      sortAscending: sortAscending ?? this.sortAscending,
      createdAt: createdAt ?? this.createdAt,
      isPreset: isPreset ?? this.isPreset,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'matchMode': matchMode.name,
      'rules': rules.map((r) => r.toMap()).toList(),
      'limit': limit,
      'sortBy': sortBy,
      'sortAscending': sortAscending,
      'createdAt': createdAt.toIso8601String(),
      'isPreset': isPreset,
    };
  }

  factory SmartPlaylist.fromMap(Map<String, dynamic> map) {
    final modeName = map['matchMode'] as String? ?? 'all';
    final matchMode = SmartPlaylistMatchMode.values.firstWhere(
      (m) => m.name == modeName,
      orElse: () => SmartPlaylistMatchMode.all,
    );

    final rawRules = map['rules'] as List? ?? [];
    final rules = rawRules
        .whereType<Map<String, dynamic>>()
        .map(SmartPlaylistRule.fromMap)
        .toList();

    return SmartPlaylist(
      id: map['id']?.toString() ?? 'smart_${DateTime.now().millisecondsSinceEpoch}',
      name: map['name']?.toString() ?? 'Untitled Smart Playlist',
      description: map['description']?.toString() ?? '',
      matchMode: matchMode,
      rules: rules,
      limit: map['limit'] as int?,
      sortBy: map['sortBy']?.toString() ?? 'title',
      sortAscending: map['sortAscending'] as bool? ?? true,
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
      isPreset: map['isPreset'] as bool? ?? false,
    );
  }
}
