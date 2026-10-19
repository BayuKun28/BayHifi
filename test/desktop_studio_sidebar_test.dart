import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baydev_hifi/audio_engine/virtual_dsp_service.dart';
import 'package:baydev_hifi/core/desktop/desktop_studio_sidebar.dart';

class _FakeDspService extends ChangeNotifier implements VirtualDspService {
  @override
  bool get eqEnabled => false;
  @override
  bool get bassBoostEnabled => false;
  @override
  bool get compressorEnabled => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestWidget({
    required int selectedIndex,
    required ValueChanged<int> onDestinationSelected,
    bool? isCompact,
    VoidCallback? onToggleCompact,
  }) {
    return ProviderScope(
      overrides: [
        virtualDspServiceProvider.overrideWith((ref) => _FakeDspService()),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: DesktopStudioSidebar(
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            isCompact: isCompact,
            onToggleCompact: onToggleCompact,
          ),
        ),
      ),
    );
  }

  group('DesktopStudioSidebar Expand / Collapse Tests', () {
    testWidgets('Renders in expanded mode by default with logo, labels, and collapse button', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      int selected = 0;

      await tester.pumpWidget(
        buildTestWidget(
          selectedIndex: selected,
          onDestinationSelected: (idx) => selected = idx,
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      // Verify branding and destination labels in expanded mode
      expect(find.text('Baydev HiFi'), findsOneWidget);
      expect(find.text('STUDIO MASTER'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('DSP Rack'), findsOneWidget);
      expect(find.text('Library'), findsOneWidget);
      expect(find.text('Playlists'), findsOneWidget);
      expect(find.text('YouTube'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      // Verify collapse button tooltip is present
      expect(find.byTooltip('Collapse sidebar (Ctrl+B)'), findsOneWidget);
    });

    testWidgets('Tapping collapse button switches sidebar to compact mode with expand button', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      int selected = 0;

      await tester.pumpWidget(
        buildTestWidget(
          selectedIndex: selected,
          onDestinationSelected: (idx) => selected = idx,
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      // Tap the collapse button
      final collapseBtn = find.byTooltip('Collapse sidebar (Ctrl+B)');
      expect(collapseBtn, findsOneWidget);
      await tester.tap(collapseBtn);
      await tester.pumpAndSettle();

      // Verify labels are hidden and expand button is present
      expect(find.text('Baydev HiFi'), findsNothing);
      expect(find.text('STUDIO MASTER'), findsNothing);
      expect(find.text('Dashboard'), findsNothing);
      expect(find.byTooltip('Expand sidebar (Ctrl+B)'), findsOneWidget);

      // Tap the expand button to return to expanded mode
      final expandBtn = find.byTooltip('Expand sidebar (Ctrl+B)');
      await tester.tap(expandBtn);
      await tester.pumpAndSettle();

      // Verify expanded mode returns
      expect(find.text('Baydev HiFi'), findsOneWidget);
      expect(find.text('STUDIO MASTER'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.byTooltip('Collapse sidebar (Ctrl+B)'), findsOneWidget);
    });

    testWidgets('Destination selection works in both expanded and compact modes', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      int selected = 0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            virtualDspServiceProvider.overrideWith((ref) => _FakeDspService()),
          ],
          child: StatefulBuilder(
            builder: (context, setState) {
              return MaterialApp(
                home: Scaffold(
                  body: DesktopStudioSidebar(
                    selectedIndex: selected,
                    onDestinationSelected: (idx) => setState(() => selected = idx),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      // Tap Library in expanded mode
      await tester.tap(find.text('Library'));
      await tester.pumpAndSettle();
      expect(selected, 2);

      // Collapse sidebar
      await tester.tap(find.byTooltip('Collapse sidebar (Ctrl+B)'));
      await tester.pumpAndSettle();

      // Tap Settings by tooltip in compact mode
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      expect(selected, 5);
    });
  });
}
