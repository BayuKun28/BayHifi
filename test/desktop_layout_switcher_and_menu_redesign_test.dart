import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:baydev_hifi/core/desktop/desktop_layout_controller.dart';
import 'package:baydev_hifi/core/desktop/desktop_window_service.dart';
import 'package:baydev_hifi/features/dsp_rack/presentation/dsp_rack_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Desktop Layout Controller Tests', () {
    test('initial state is auto mode', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(desktopLayoutModeProvider), equals(DesktopLayoutMode.auto));
    });

    test('updates state to mobile, tablet, and desktop modes', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(desktopLayoutModeProvider.notifier);

      controller.setLayoutMode(DesktopLayoutMode.mobile);
      expect(container.read(desktopLayoutModeProvider), equals(DesktopLayoutMode.mobile));

      controller.setLayoutMode(DesktopLayoutMode.tablet);
      expect(container.read(desktopLayoutModeProvider), equals(DesktopLayoutMode.tablet));

      controller.setLayoutMode(DesktopLayoutMode.desktop);
      expect(container.read(desktopLayoutModeProvider), equals(DesktopLayoutMode.desktop));

      controller.setLayoutMode(DesktopLayoutMode.auto);
      expect(container.read(desktopLayoutModeProvider), equals(DesktopLayoutMode.auto));
    });
  });

  group('Desktop Window Service Sizing API Tests', () {
    test('setMobileSize, setTabletSize, setDesktopSize execute safely', () {
      final service = DesktopWindowService.instance;
      expect(() => service.setMobileSize(), returnsNormally);
      expect(() => service.setTabletSize(), returnsNormally);
      expect(() => service.setDesktopSize(), returnsNormally);
    });
  });

  group('DSP Category Filter Tests', () {
    test('DspCategoryFilter enum defines all 4 categories', () {
      expect(DspCategoryFilter.values.length, equals(4));
      expect(DspCategoryFilter.all.label, contains('All Modules'));
      expect(DspCategoryFilter.dynamics.label, equals('Dynamics'));
      expect(DspCategoryFilter.tone.label, equals('Tone & EQ'));
      expect(DspCategoryFilter.spatial.label, equals('Spatial & Tube'));
    });
  });
}
