import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baydev_hifi/app/theme/theme_mode_controller.dart';
import 'package:baydev_hifi/audio_engine/audio_cache_service.dart';
import 'package:baydev_hifi/core/database/local_persistence_service.dart';
import 'package:baydev_hifi/features/library/presentation/unified_library_screen.dart';
import 'package:baydev_hifi/features/player/data/lyrics_service.dart';
import 'package:baydev_hifi/features/player/presentation/widgets/synchronized_lyrics_view.dart';
import 'package:baydev_hifi/features/settings/presentation/sub_screens/theming_settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('bayhifi_phase31_test');
    await LocalPersistenceService.instance.init(customPath: '${tempDir.path}/test_storage.json');
    AudioCacheService.instance.setCacheDirForTesting(tempDir);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Phase 31.1: SurfaceFillStyle Theming State & Persistence', () {
    test('SurfaceFillStyle enum has correct labels and descriptions', () {
      expect(SurfaceFillStyle.translucent.label, 'Translucent Soft Tint');
      expect(SurfaceFillStyle.solid.label, 'Pure Solid M3');
      expect(SurfaceFillStyle.values.length, 2);
    });

    test('ThemeController updates and persists surfaceFillStyle', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(themeControllerProvider.notifier);
      expect(container.read(themeControllerProvider).surfaceFillStyle, SurfaceFillStyle.translucent);

      notifier.setSurfaceFillStyle(SurfaceFillStyle.solid);
      expect(container.read(themeControllerProvider).surfaceFillStyle, SurfaceFillStyle.solid);

      // Verify persistence
      final saved = LocalPersistenceService.instance.getThemeSettings();
      expect(saved['surface_fill_style'], 'solid');

      // Re-load
      final state = ThemeSettingsState(surfaceFillStyle: SurfaceFillStyle.solid);
      expect(state.surfaceFillStyle, SurfaceFillStyle.solid);
    });
  });

  group('Phase 31.2: AudioCacheService Helpers', () {
    test('getCacheFile and getTempFile return sanitized paths', () {
      final cacheFile = AudioCacheService.instance.getCacheFile('yt_abc123?test');
      final tempFile = AudioCacheService.instance.getTempFile('yt_abc123?test');

      expect(cacheFile.path.endsWith('yt_abc123_test.cache'), isTrue);
      expect(tempFile.path.endsWith('yt_abc123_test.tmp'), isTrue);
    });
  });

  group('Phase 31.3: SynchronizedLyricsView Viewport Centering & GlobalKeys', () {
    testWidgets('Renders synchronized lyrics lines with GlobalKeys', (tester) async {
      const lrcContent = '''[00:00.00]First line of track
[00:02.50]Second line active center
[00:05.00]Third line follows next
[00:10.00]Fourth line conclusion''';

      final lines = LrcParser.parse(lrcContent);
      final lyricsResult = LyricsResult(
        rawLyrics: lrcContent,
        lines: lines,
        isSynced: true,
        source: LyricsSource.localEmbedded,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SynchronizedLyricsView(
                lyricsResult: lyricsResult,
                currentPosition: const Duration(seconds: 3),
                trackId: 'test_track_1',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Second line active center'), findsOneWidget);
      expect(find.text('First line of track'), findsOneWidget);
      expect(find.text('Third line follows next'), findsOneWidget);
    });
  });

  group('Phase 31.4: UnifiedLibraryScreen 2x2 Bento Empty State', () {
    testWidgets('Renders compact 2x2 Bento Quick Actions and Format Pill', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: UnifiedLibraryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('NO AUDIO TRACKS LOADED'), findsOneWidget);
      expect(find.text('SCAN FOLDER'), findsOneWidget);
      expect(find.text('PICK FILES'), findsOneWidget);
      expect(find.text('NAVIDROME'), findsOneWidget);
      expect(find.text('YOUTUBE HIFI'), findsOneWidget);
      expect(find.text('FLAC • WAV • DSD • ALAC • OPUS • MP3'), findsOneWidget);
    });
  });

  group('Phase 31.5: ThemingSettingsScreen Surface Fill Style Selector', () {
    testWidgets('Renders SURFACE & COMPONENT FILL STYLE selector', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ThemingSettingsScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('SURFACE & COMPONENT FILL STYLE'), findsOneWidget);
      expect(find.text('Translucent Soft Tint'), findsOneWidget);
      expect(find.text('Pure Solid M3'), findsOneWidget);

      await tester.tap(find.text('Pure Solid M3'));
      await tester.pumpAndSettle();

      final saved = LocalPersistenceService.instance.getThemeSettings();
      expect(saved['surface_fill_style'], 'solid');
    });
  });
}

