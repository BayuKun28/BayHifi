import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:baydev_hifi/features/pro_q_studio/data/auto_eq_cloud_service.dart';
import 'package:baydev_hifi/features/pro_q_studio/domain/auto_eq_cloud_model.dart';
import 'package:baydev_hifi/features/pro_q_studio/presentation/widgets/auto_eq_cloud_browser_dialog.dart';

void main() {
  group('AutoEqCloudService Unit Tests', () {
    final service = AutoEqCloudService.instance;

    test('getAllItems returns non-empty list of targets and drivers', () {
      final items = service.getAllItems();
      expect(items.isNotEmpty, isTrue);
      expect(items.any((item) => item.category == AutoEqCloudCategory.target), isTrue);
      expect(items.any((item) => item.category == AutoEqCloudCategory.iem), isTrue);
      expect(items.any((item) => item.category == AutoEqCloudCategory.headphone), isTrue);
    });

    test('searchItems filters correctly by query and category', () {
      final harmanResults = service.searchItems(query: 'Harman');
      expect(harmanResults.isNotEmpty, isTrue);
      expect(
        harmanResults.every((item) =>
            item.name.toLowerCase().contains('harman') ||
            item.brand.toLowerCase().contains('harman') ||
            item.description.toLowerCase().contains('harman')),
        isTrue,
      );

      final iemOnly = service.searchItems(category: AutoEqCloudCategory.iem);
      expect(iemOnly.every((item) => item.category == AutoEqCloudCategory.iem), isTrue);
    });

    test('downloadItem parses valid FrCurveData', () async {
      final item = service.getAllItems().firstWhere((i) => i.id == 'target_harman_ie_2019v2');
      final curve = await service.downloadItem(item);

      expect(curve.name, item.name);
      expect(curve.frequencies.isNotEmpty, isTrue);
      expect(curve.splDb.isNotEmpty, isTrue);
      expect(curve.frequencies.length, curve.splDb.length);
    });
  });

  group('AutoEqCloudBrowserDialog Widget Tests', () {
    testWidgets('renders search bar, category tabs, and items list', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AutoEqCloudBrowserDialog(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Header
      expect(find.text('AUTOEQ & SQUIGLINK CLOUD DATABASE'), findsOneWidget);

      // Verify Tabs
      expect(find.text('ALL'), findsOneWidget);
      expect(find.text('TARGET CURVES'), findsOneWidget);
      expect(find.text('IEMs'), findsOneWidget);
      expect(find.text('HEADPHONES'), findsOneWidget);
      expect(find.text('DOWNLOADED'), findsOneWidget);

      // Verify Sample Target Item presence
      expect(find.text('Harman In-Ear 2019 v2'), findsOneWidget);
    });
  });
}
