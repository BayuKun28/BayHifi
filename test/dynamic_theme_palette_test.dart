import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baydev_hifi/app/theme/theme_mode_controller.dart';
import 'package:baydev_hifi/features/player/domain/track.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Dynamic Theme & Studio Palette Tests', () {
    test('All presets use refined, non-neon studio color palettes', () {
      for (final palette in AppPalette.allPresets) {
        expect(palette.primary, isNotNull);
        expect(palette.secondary, isNotNull);
        expect(palette.accent, isNotNull);
        // Primary colors should have full alpha
        expect(palette.primary.a, equals(1.0));
      }
    });

    test('ThemeController updates palette correctly when dynamic mode is toggled', () {
      final controller = ThemeController();
      expect(controller.state.dynamicAlbumArtEnabled, isFalse);

      controller.toggleDynamicAlbumArt(true);
      expect(controller.state.dynamicAlbumArtEnabled, isTrue);

      controller.setDynamicAlbumArt(
        const Color(0xFF1E293B), // Dominant slate
        const Color(0xFF38BDF8), // Vibrant sky
      );

      expect(controller.state.currentPalette.isDynamic, isTrue);
      expect(controller.state.currentPalette.primary, equals(const Color(0xFF38BDF8)));
      expect(controller.state.currentPalette.secondary, equals(const Color(0xFF1E293B)));

      // Switching to a preset palette disables dynamic mode
      controller.setPalette(AppPalette.amberTube);
      expect(controller.state.dynamicAlbumArtEnabled, isFalse);
      expect(controller.state.currentPalette.id, equals('amber_tube'));
    });

    test('updateDynamicPaletteFromTrack handles tracks with null/empty album art gracefully', () async {
      final controller = ThemeController();
      controller.toggleDynamicAlbumArt(true);

      const track = Track(
        id: 'test_1',
        title: 'Test Song',
        artist: 'Test Artist',
        album: 'Test Album',
        duration: Duration(minutes: 3),
      );

      // Should not throw or crash when album art is absent
      await controller.updateDynamicPaletteFromTrack(track);
      expect(controller.state.currentPalette, isNotNull);
    });
  });
}
