/// Kategori kurva pada basis data cloud AutoEQ & Squiglink
enum AutoEqCloudCategory {
  target,
  iem,
  headphone,
}

/// Model data item kurva respon frekuensi dari cloud database
class AutoEqCloudItem {
  final String id;
  final String name;
  final String brand;
  final AutoEqCloudCategory category;
  final String source; // misal: 'Squiglink', 'AutoEQ', 'Crinacle 711', 'Oratory1990', 'Harman Acoustic'
  final String description;
  final String rawData; // Data mentah (format REW V5 atau CSV Squiglink)
  final String? rawUrl; // URL raw data online jika diunduh on-demand
  final bool isDownloaded;

  const AutoEqCloudItem({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.source,
    required this.description,
    required this.rawData,
    this.rawUrl,
    this.isDownloaded = false,
  });

  AutoEqCloudItem copyWith({
    String? id,
    String? name,
    String? brand,
    AutoEqCloudCategory? category,
    String? source,
    String? description,
    String? rawData,
    String? rawUrl,
    bool? isDownloaded,
  }) {
    return AutoEqCloudItem(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      category: category ?? this.category,
      source: source ?? this.source,
      description: description ?? this.description,
      rawData: rawData ?? this.rawData,
      rawUrl: rawUrl ?? this.rawUrl,
      isDownloaded: isDownloaded ?? this.isDownloaded,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'category': category.name,
      'source': source,
      'description': description,
      'rawData': rawData,
      'rawUrl': rawUrl,
      'isDownloaded': isDownloaded,
    };
  }

  factory AutoEqCloudItem.fromJson(Map<String, dynamic> json) {
    return AutoEqCloudItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      brand: json['brand'] as String? ?? '',
      category: AutoEqCloudCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => AutoEqCloudCategory.target,
      ),
      source: json['source'] as String? ?? 'Cloud DB',
      description: json['description'] as String? ?? '',
      rawData: json['rawData'] as String? ?? '',
      rawUrl: json['rawUrl'] as String?,
      isDownloaded: json['isDownloaded'] as bool? ?? false,
    );
  }
}
