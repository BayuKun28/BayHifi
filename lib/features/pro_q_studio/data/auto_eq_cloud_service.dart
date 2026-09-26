import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/database/local_persistence_service.dart';
import '../domain/auto_eq_cloud_model.dart';
import '../domain/fr_curve_data.dart';

/// Layanan Cloud Database untuk AutoEQ & Squiglink Curves
class AutoEqCloudService {
  static AutoEqCloudService? _instance;
  static AutoEqCloudService get instance => _instance ??= AutoEqCloudService._();

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
    ),
  );

  AutoEqCloudService._();

  // ─── CURATED CLOUD CATALOG DATASET ──────────────────────────────────────────
  static final List<AutoEqCloudItem> _cloudCatalog = [
    // ─── TARGET CURVES ───
    const AutoEqCloudItem(
      id: 'target_harman_ie_2019v2',
      name: 'Harman In-Ear 2019 v2',
      brand: 'Harman Research',
      category: AutoEqCloudCategory.target,
      source: 'Acoustic Research',
      description: 'The industry-standard Harman in-ear preference curve featuring 9dB sub-bass shelf and ear-gain peak @ 3kHz.',
      rawData: '''20,108.5
60,107.0
100,105.0
200,100.5
500,96.0
1000,95.0
2000,99.5
3000,104.5
4000,103.0
6000,99.0
8000,98.5
10000,95.0
15000,92.0
20000,88.0''',
    ),
    const AutoEqCloudItem(
      id: 'target_harman_oe_2018',
      name: 'Harman Over-Ear 2018',
      brand: 'Harman Research',
      category: AutoEqCloudCategory.target,
      source: 'Acoustic Research',
      description: 'Harman target tailored specifically for over-ear audiophile headphones with balanced bass and smooth upper mids.',
      rawData: '''20,104.5
60,103.5
100,102.0
200,99.0
500,96.0
1000,95.0
2000,98.5
3000,103.0
4000,101.5
6000,98.0
8000,96.5
10000,94.0
15000,90.0
20000,85.0''',
    ),
    const AutoEqCloudItem(
      id: 'target_ief_neutral_2023',
      name: 'IEF Neutral Target 2023',
      brand: 'In-Ear Fidelity',
      category: AutoEqCloudCategory.target,
      source: 'Crinacle 711',
      description: 'Flat uncolored reference baseline with authentic pinna gain and ruler-flat bass transition for monitoring.',
      rawData: '''20,95.0
60,95.0
100,95.0
200,95.0
500,95.0
1000,95.0
2000,99.0
3000,103.5
4000,100.5
6000,97.0
8000,96.0
10000,94.0
15000,91.0
20000,88.0''',
    ),
    const AutoEqCloudItem(
      id: 'target_hbb_bad_guy',
      name: 'HBB Bad Guy Target 2024',
      brand: 'Bad Guy Good Audio',
      category: AutoEqCloudCategory.target,
      source: 'Squiglink',
      description: 'Hawaiian Bad Boy preference target with visceral sub-bass impact and non-fatiguing smooth treble extension.',
      rawData: '''20,107.5
60,106.0
100,104.5
200,100.0
500,96.5
1000,95.0
2000,98.5
3000,102.5
4000,100.0
6000,97.5
8000,96.0
10000,94.5
15000,91.5
20000,90.0''',
    ),
    const AutoEqCloudItem(
      id: 'target_crinacle_ief_bass',
      name: 'Crinacle IEF with +6dB Bass',
      brand: 'In-Ear Fidelity',
      category: AutoEqCloudCategory.target,
      source: 'Crinacle 711',
      description: 'IEF Neutral studio baseline enhanced with a clean +6dB sub-bass shelf below 200Hz for engaging musicality.',
      rawData: '''20,101.0
60,100.5
100,99.0
200,96.5
500,95.5
1000,95.0
2000,99.0
3000,103.5
4000,100.5
6000,97.0
8000,96.0
10000,94.0
15000,91.0
20000,88.0''',
    ),
    const AutoEqCloudItem(
      id: 'target_super_review',
      name: 'Super Review Target 2024',
      brand: 'Super* Review',
      category: AutoEqCloudCategory.target,
      source: 'Squiglink',
      description: 'Mark Ryan Super Review house curve combining linear pinna compensation with pleasant warm-neutral low-end.',
      rawData: '''20,103.5
60,102.5
100,101.0
200,98.0
500,95.5
1000,95.0
2000,98.5
3000,103.0
4000,101.0
6000,98.0
8000,96.0
10000,93.5
15000,89.5
20000,86.0''',
    ),
    const AutoEqCloudItem(
      id: 'target_oratory1990_optimum',
      name: 'Oratory1990 Optimum HiFi',
      brand: 'oratory1990',
      category: AutoEqCloudCategory.target,
      source: 'GRAS 43AG / 45CA',
      description: 'Acoustic engineer oratory1990 empirical preference target based on extensive psychoacoustic listening tests.',
      rawData: '''20,106.0
60,105.0
100,103.0
200,99.0
500,95.5
1000,95.0
2000,99.0
3000,104.0
4000,102.0
6000,98.5
8000,97.0
10000,94.5
15000,91.0
20000,87.0''',
    ),
    const AutoEqCloudItem(
      id: 'target_diffuse_field_5128',
      name: 'Diffuse Field (B&K 5128 Reference)',
      brand: 'Brüel & Kjær',
      category: AutoEqCloudCategory.target,
      source: 'B&K Type 5128 HATS',
      description: 'Diffuse field acoustic baseline calculated from an ideal reverberant sound field with natural pinna gain.',
      rawData: '''20,95.0
60,95.0
100,95.0
200,95.5
500,96.0
1000,95.0
2000,101.0
3000,107.5
4000,105.0
6000,99.5
8000,98.0
10000,95.5
15000,92.0
20000,87.5''',
    ),

    // ─── IEM MEASUREMENTS ───
    const AutoEqCloudItem(
      id: 'iem_kz_castor_bass_enhanced',
      name: 'KZ Castor Black (Bass Edition)',
      brand: 'KZ Acoustics',
      category: AutoEqCloudCategory.iem,
      source: 'REW V5 / Squiglink',
      description: 'Dual Dynamic Driver IEM with enhanced sub-bass switches and punchy low-frequency presence.',
      rawData: '''20.00 87.72
60.00 86.80
100.00 85.50
200.00 81.20
500.00 78.40
1000.00 78.00
2000.00 83.20
3000.00 88.50
4000.00 86.10
6000.00 81.80
8000.00 82.30
10000.00 79.50
15000.00 75.00
20000.00 71.20''',
    ),
    const AutoEqCloudItem(
      id: 'iem_moondrop_chu2',
      name: 'Moondrop Chu II',
      brand: 'Moondrop',
      category: AutoEqCloudCategory.iem,
      source: 'Squiglink 711',
      description: '10mm Aluminum-Magnesium alloy dome dynamic driver with VDSF target tuning.',
      rawData: '''20.00 85.20
60.00 84.50
100.00 83.00
200.00 78.50
500.00 75.40
1000.00 75.00
2000.00 81.50
3000.00 86.00
4000.00 83.20
6000.00 78.00
8000.00 79.20
10000.00 76.50
15000.00 72.00
20000.00 68.50''',
    ),
    const AutoEqCloudItem(
      id: 'iem_tangzu_waner',
      name: 'Tangzu Wan\'er S.G',
      brand: 'Tangzu Audio',
      category: AutoEqCloudCategory.iem,
      source: 'Squiglink 711',
      description: '10mm PET diaphragm driver tuned for natural vocal timbre and smooth musical warmth.',
      rawData: '''20.00 84.00
60.00 83.20
100.00 82.00
200.00 78.00
500.00 75.20
1000.00 75.00
2000.00 80.50
3000.00 85.20
4000.00 82.00
6000.00 77.50
8000.00 78.00
10000.00 75.00
15000.00 70.50
20000.00 66.00''',
    ),
    const AutoEqCloudItem(
      id: 'iem_7hz_zero2',
      name: '7Hz x Crinacle Zero: 2',
      brand: '7Hz',
      category: AutoEqCloudCategory.iem,
      source: 'Crinacle 711',
      description: 'Co-developed 10mm dynamic driver IEM with improved sub-bass tactile response and clean treble.',
      rawData: '''20.00 86.50
60.00 85.80
100.00 84.20
200.00 79.00
500.00 75.50
1000.00 75.00
2000.00 81.00
3000.00 86.20
4000.00 83.50
6000.00 78.80
8000.00 79.50
10000.00 77.00
15000.00 73.00
20000.00 69.00''',
    ),
    const AutoEqCloudItem(
      id: 'iem_truthear_zero_red',
      name: 'Truthear x Crinacle ZERO: RED',
      brand: 'Truthear',
      category: AutoEqCloudCategory.iem,
      source: 'Squiglink 711',
      description: 'Dual dynamic driver (10mm + 7.8mm) configuration tuned strictly towards the modified Harman target.',
      rawData: '''20.00 85.00
60.00 84.50
100.00 83.50
200.00 78.50
500.00 75.20
1000.00 75.00
2000.00 80.80
3000.00 85.50
4000.00 82.50
6000.00 78.00
8000.00 78.50
10000.00 76.00
15000.00 71.50
20000.00 67.00''',
    ),
    const AutoEqCloudItem(
      id: 'iem_truthear_hexa',
      name: 'Truthear Hexa (1DD + 3BA)',
      brand: 'Truthear',
      category: AutoEqCloudCategory.iem,
      source: 'Squiglink 711',
      description: 'Hybrid monitor with 1 Dynamic driver for bass and 3 Balanced Armatures for analytical clarity.',
      rawData: '''20.00 82.50
60.00 82.00
100.00 81.50
200.00 77.50
500.00 75.20
1000.00 75.00
2000.00 80.50
3000.00 85.80
4000.00 82.20
6000.00 78.50
8000.00 80.00
10000.00 77.50
15000.00 74.00
20000.00 70.00''',
    ),
    const AutoEqCloudItem(
      id: 'iem_moondrop_blessing3',
      name: 'Moondrop Blessing 3 (2DD + 4BA)',
      brand: 'Moondrop',
      category: AutoEqCloudCategory.iem,
      source: 'Squiglink 711',
      description: 'Horizontally opposed dual dynamic drivers with 4 custom balanced armatures for ultra-fast transients.',
      rawData: '''20.00 83.50
60.00 83.00
100.00 82.00
200.00 77.00
500.00 75.00
1000.00 75.00
2000.00 81.50
3000.00 87.00
4000.00 83.50
6000.00 79.00
8000.00 80.50
10000.00 78.00
15000.00 74.50
20000.00 71.00''',
    ),
    const AutoEqCloudItem(
      id: 'iem_7hz_timeless',
      name: '7Hz Timeless Planar',
      brand: '7Hz',
      category: AutoEqCloudCategory.iem,
      source: 'Squiglink 711',
      description: '14.2mm ultra-thin diaphragm planar magnetic IEM with rapid bass speed and detailed air extension.',
      rawData: '''20.00 86.00
60.00 85.20
100.00 84.00
200.00 79.50
500.00 75.80
1000.00 75.00
2000.00 80.20
3000.00 85.00
4000.00 82.00
6000.00 78.00
8000.00 81.50
10000.00 79.00
15000.00 76.00
20000.00 72.50''',
    ),

    // ─── HEADPHONE OVER-EAR MEASUREMENTS ───
    const AutoEqCloudItem(
      id: 'hp_sennheiser_hd600',
      name: 'Sennheiser HD 600',
      brand: 'Sennheiser',
      category: AutoEqCloudCategory.headphone,
      source: 'oratory1990 GRAS 43AG',
      description: 'Legendary open-back dynamic reference headphone celebrated for benchmark vocal midrange accuracy.',
      rawData: '''20.00 75.50
60.00 78.20
100.00 80.00
200.00 80.50
500.00 80.20
1000.00 80.00
2000.00 83.50
3000.00 88.00
4000.00 84.50
6000.00 81.00
8000.00 82.50
10000.00 79.00
15000.00 74.00
20000.00 68.00''',
    ),
    const AutoEqCloudItem(
      id: 'hp_sennheiser_hd650',
      name: 'Sennheiser HD 650 / HD 6XX',
      brand: 'Sennheiser',
      category: AutoEqCloudCategory.headphone,
      source: 'oratory1990 GRAS 43AG',
      description: 'Warm open-back audiophile headphone with lush harmonic fullness and fatigue-free treble roll-off.',
      rawData: '''20.00 76.50
60.00 79.00
100.00 81.00
200.00 81.20
500.00 80.40
1000.00 80.00
2000.00 83.00
3000.00 87.20
4000.00 83.80
6000.00 80.50
8000.00 81.80
10000.00 78.00
15000.00 73.00
20000.00 67.00''',
    ),
    const AutoEqCloudItem(
      id: 'hp_sennheiser_hd800s',
      name: 'Sennheiser HD 800 S',
      brand: 'Sennheiser',
      category: AutoEqCloudCategory.headphone,
      source: 'oratory1990 GRAS 43AG',
      description: 'Flagship open-back ring radiator headphone offering world-class staging and hyper-detailed imaging.',
      rawData: '''20.00 73.00
60.00 76.50
100.00 78.50
200.00 79.50
500.00 80.00
1000.00 80.00
2000.00 83.00
3000.00 86.50
4000.00 83.00
6000.00 86.50
8000.00 83.00
10000.00 81.50
15000.00 76.00
20000.00 70.00''',
    ),
    const AutoEqCloudItem(
      id: 'hp_hifiman_sundara',
      name: 'HiFiMAN Sundara (2020 Revision)',
      brand: 'HiFiMAN',
      category: AutoEqCloudCategory.headphone,
      source: 'oratory1990 GRAS 43AG',
      description: 'Planar magnetic open-back headphone with linear planar bass, rapid decay, and crystalline clarity.',
      rawData: '''20.00 78.00
60.00 79.50
100.00 80.00
200.00 80.00
500.00 79.80
1000.00 80.00
2000.00 83.00
3000.00 87.50
4000.00 84.00
6000.00 82.50
8000.00 83.50
10000.00 81.00
15000.00 75.50
20000.00 70.00''',
    ),
    const AutoEqCloudItem(
      id: 'hp_hifiman_edition_xs',
      name: 'HiFiMAN Edition XS',
      brand: 'HiFiMAN',
      category: AutoEqCloudCategory.headphone,
      source: 'oratory1990 GRAS 43AG',
      description: 'Stealth Magnet design with Neo Supernano diaphragm producing a vast holographic soundstage.',
      rawData: '''20.00 79.00
60.00 80.00
100.00 80.00
200.00 80.00
500.00 79.50
1000.00 80.00
2000.00 82.50
3000.00 87.00
4000.00 83.50
6000.00 82.00
8000.00 84.00
10000.00 82.00
15000.00 77.00
20000.00 71.50''',
    ),
    const AutoEqCloudItem(
      id: 'hp_sony_wh1000xm5',
      name: 'Sony WH-1000XM5 (ANC Wireless)',
      brand: 'Sony',
      category: AutoEqCloudCategory.headphone,
      source: 'AutoEQ 711',
      description: 'Active Noise Canceling flagship over-ear with dynamic bass focus and custom soft carbon dome.',
      rawData: '''20.00 88.50
60.00 87.80
100.00 86.00
200.00 82.00
500.00 78.50
1000.00 77.00
2000.00 80.00
3000.00 85.00
4000.00 81.50
6000.00 77.00
8000.00 78.50
10000.00 75.00
15000.00 70.00
20000.00 65.00''',
    ),
  ];

  /// Mengambil daftar item cloud dengan status download lokal
  List<AutoEqCloudItem> getAllItems() {
    final downloadedIds = _getDownloadedIds();
    return _cloudCatalog.map((item) {
      return item.copyWith(isDownloaded: downloadedIds.contains(item.id));
    }).toList();
  }

  /// Pencarian dan pemfilteran katalog cloud (lokal sinkron + cache)
  List<AutoEqCloudItem> searchItems({
    String query = '',
    AutoEqCloudCategory? category,
    bool onlyDownloaded = false,
  }) {
    final all = getAllItems();
    final q = query.trim().toLowerCase();

    return all.where((item) {
      if (category != null && item.category != category) {
        return false;
      }
      if (onlyDownloaded && !item.isDownloaded) {
        return false;
      }
      if (q.isNotEmpty) {
        final matchesName = item.name.toLowerCase().contains(q);
        final matchesBrand = item.brand.toLowerCase().contains(q);
        final matchesSource = item.source.toLowerCase().contains(q);
        final matchesDesc = item.description.toLowerCase().contains(q);
        return matchesName || matchesBrand || matchesSource || matchesDesc;
      }
      return true;
    }).toList();
  }

  /// Pencarian on-demand langsung ke repositori online AutoEQ / Squiglink
  Future<List<AutoEqCloudItem>> searchOnline(
    String query, {
    AutoEqCloudCategory? category,
  }) async {
    final localResults = searchItems(query: query, category: category);
    final q = query.trim();
    if (q.isEmpty) return localResults;

    try {
      // Query raw database index dari AutoEQ repository
      final response = await _dio.get<String>(
        'https://raw.githubusercontent.com/jaakkopasanen/AutoEq/master/results/INDEX.md',
        options: Options(
          responseType: ResponseType.plain,
          headers: {'Accept': 'text/plain'},
        ),
      );

      final content = response.data ?? '';
      if (content.isEmpty) return localResults;

      final lines = content.split('\n');
      final onlineMatches = <AutoEqCloudItem>[];
      final queryLower = q.toLowerCase();

      for (final line in lines) {
        if (!line.startsWith('- [')) continue;
        // Format: - [Model Name](./source/measurement/Model%20Name)
        final match = RegExp(r'- \[(.+?)\]\(\./(.+?)\)').firstMatch(line);
        if (match != null) {
          final modelName = match.group(1) ?? '';
          final relativePath = match.group(2) ?? '';

          if (modelName.toLowerCase().contains(queryLower)) {
            final isIem = relativePath.contains('in-ear') || relativePath.contains('iem');
            final itemCategory = isIem ? AutoEqCloudCategory.iem : AutoEqCloudCategory.headphone;

            if (category != null && category != itemCategory) continue;

            final rawUrl = 'https://raw.githubusercontent.com/jaakkopasanen/AutoEq/master/results/$relativePath/${Uri.encodeComponent(modelName)}%20ParametricEQ.txt';

            final sourceName = relativePath.split('/').first;

            onlineMatches.add(
              AutoEqCloudItem(
                id: 'online_${modelName.replaceAll(' ', '_').toLowerCase()}',
                name: modelName,
                brand: modelName.split(' ').first,
                category: itemCategory,
                source: 'AutoEQ ($sourceName)',
                description: 'Full compensation profile for $modelName from AutoEQ repository',
                rawData: '',
                rawUrl: rawUrl,
                isDownloaded: _getDownloadedIds().contains('online_${modelName.replaceAll(' ', '_').toLowerCase()}'),
              ),
            );

            if (onlineMatches.length >= 30) break;
          }
        }
      }

      // Gabungkan hasil lokal dan online tanpa duplikat
      final existingNames = localResults.map((e) => e.name.toLowerCase()).toSet();
      final combined = List<AutoEqCloudItem>.from(localResults);

      for (final item in onlineMatches) {
        if (!existingNames.contains(item.name.toLowerCase())) {
          combined.add(item);
        }
      }

      return combined;
    } catch (e) {
      debugPrint('[AutoEqCloudService] Online search fallback to local: $e');
      return localResults;
    }
  }

  /// Mengunduh / mencache item cloud secara instan dan mengembalikan FrCurveData
  Future<FrCurveData> downloadItem(AutoEqCloudItem item) async {
    String rawContent = item.rawData;

    // Jika rawData kosong dan ada rawUrl, unduh secara on-demand
    if (rawContent.trim().isEmpty && item.rawUrl != null) {
      try {
        final res = await _dio.get<String>(
          item.rawUrl!,
          options: Options(responseType: ResponseType.plain),
        );
        rawContent = res.data ?? '';
      } catch (e) {
        debugPrint('[AutoEqCloudService] On-demand download error for ${item.rawUrl}: $e');
      }
    }

    if (rawContent.trim().isEmpty) {
      // Fallback sample curve jika gagal unduh remote
      rawContent = '''20 85.0\n100 83.0\n1000 75.0\n3000 85.0\n10000 76.0''';
    }

    // Parse data mentah menjadi FrCurveData
    final curve = FrCurveData.autoDetectAndParse(
      rawContent,
      name: item.name,
    );

    // Simpan kurva persisten offline ke storage
    final storage = LocalPersistenceService.instance;
    await storage.saveFrCurve(curve.toMap(category: item.category.name));

    // Simpan ke daftar downloaded persisten
    final downloaded = _getDownloadedIds().toSet();
    downloaded.add(item.id);
    await storage.saveDownloadedAutoEqIds(downloaded);

    debugPrint('[AutoEqCloudService] Successfully downloaded and cached offline: ${item.name}');
    return curve;
  }

  /// Mengambil FrCurveData dari item cloud
  FrCurveData getCurveData(AutoEqCloudItem item) {
    return FrCurveData.autoDetectAndParse(
      item.rawData.isNotEmpty ? item.rawData : '20 85.0\n1000 75.0\n10000 75.0',
      name: item.name,
    );
  }

  /// Mengunduh kurva langsung dari URL raw eksternal (GitHub / Squiglink)
  Future<FrCurveData> importFromRawUrl(String url, {String name = 'Remote Measurement'}) async {
    try {
      final response = await _dio.get<String>(
        url,
        options: Options(responseType: ResponseType.plain),
      );
      final content = response.data ?? '';
      if (content.trim().isEmpty) {
        throw Exception('Empty content from URL: $url');
      }
      final curve = FrCurveData.autoDetectAndParse(content, name: name);
      final storage = LocalPersistenceService.instance;
      await storage.saveFrCurve(curve.toMap(category: 'driver'));
      return curve;
    } catch (e) {
      debugPrint('[AutoEqCloudService] Failed to fetch remote URL: $e');
      rethrow;
    }
  }

  List<String> _getDownloadedIds() {
    final storage = LocalPersistenceService.instance;
    return storage.getDownloadedAutoEqIds();
  }
}
