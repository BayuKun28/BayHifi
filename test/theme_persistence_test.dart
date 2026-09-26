import 'package:flutter_test/flutter_test.dart';
import 'package:baydev_hifi/app/theme/theme_mode_controller.dart';
import 'package:baydev_hifi/core/database/local_persistence_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Theme Persistence Tests', () {
    test('LocalPersistenceService saves and loads theme settings correctly', () async {
      final persistence = LocalPersistenceService.instance;
      
      await persistence.saveThemeSettings(
        paletteId: 'amber_tube',
        themeModeIndex: AppThemeMode.light.index,
        customAccentColorValue: 0xFFF59E0B,
        dynamicAlbumArtEnabled: true,
      );

      final loaded = persistence.getThemeSettings();
      expect(loaded['palette_id'], 'amber_tube');
      expect(loaded['theme_mode'], AppThemeMode.light.index);
      expect(loaded['custom_accent'], 0xFFF59E0B);
      expect(loaded['dynamic_album_art'], true);
    });

    test('ThemeController initializes with saved theme and updates persistence', () async {
      final persistence = LocalPersistenceService.instance;
      await persistence.saveThemeSettings(
        paletteId: 'pastel_sage',
        themeModeIndex: AppThemeMode.dark.index,
        customAccentColorValue: 0xFF93D5C0,
        dynamicAlbumArtEnabled: false,
      );

      final controller = ThemeController();
      expect(controller.state.currentPalette.id, 'pastel_sage');
      expect(controller.state.themeMode, AppThemeMode.dark);
      expect(controller.state.dynamicAlbumArtEnabled, false);

      // Change palette to pastel_sky
      controller.setPalette(AppPalette.pastelSky);
      expect(controller.state.currentPalette.id, 'pastel_sky');
      
      final updatedSettings = persistence.getThemeSettings();
      expect(updatedSettings['palette_id'], 'pastel_sky');

      // Change theme mode
      controller.setThemeMode(AppThemeMode.light);
      expect(persistence.getThemeSettings()['theme_mode'], AppThemeMode.light.index);
    });
  });
}
