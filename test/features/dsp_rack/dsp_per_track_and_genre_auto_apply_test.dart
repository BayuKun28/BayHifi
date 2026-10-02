import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baydev_hifi/core/database/local_persistence_service.dart';
import 'package:baydev_hifi/features/dsp_rack/domain/dsp_models.dart';
import 'package:baydev_hifi/features/dsp_rack/presentation/controllers/dsp_rack_controller.dart';
import 'package:baydev_hifi/features/dsp_rack/presentation/widgets/genre_rules_config_modal.dart';
import 'package:baydev_hifi/features/dsp_rack/presentation/widgets/studio_track_dsp_preset_sheet.dart';
import 'package:baydev_hifi/features/player/domain/track.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('bayhifi_dsp_test_');
    await LocalPersistenceService.instance.init(customPath: '${tempDir.path}/test_storage.json');
  });

  tearDown(() {
    try {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  group('GenrePresetMatcher Tests', () {
    test('Matches standard genre names accurately', () {
      final rockMatch = GenrePresetMatcher.match('Rock');
      expect(rockMatch, isNotNull);
      expect(rockMatch!.genreKey, 'rock');
      expect(rockMatch.targetPresetId, 'genre_rock');

      final metalMatch = GenrePresetMatcher.match('Heavy Metal');
      expect(metalMatch, isNotNull);
      expect(metalMatch!.genreKey, 'metal');
      expect(metalMatch.targetPresetId, 'genre_metal');

      final popMatch = GenrePresetMatcher.match('Synthpop');
      expect(popMatch, isNotNull);
      expect(popMatch!.genreKey, 'pop');
      expect(popMatch.targetPresetId, 'genre_pop');

      final edmMatch = GenrePresetMatcher.match('EDM / Electro House');
      expect(edmMatch, isNotNull);
      expect(edmMatch!.genreKey, 'edm');
      expect(edmMatch.targetPresetId, 'genre_edm');

      final jazzMatch = GenrePresetMatcher.match('Smooth Jazz');
      expect(jazzMatch, isNotNull);
      expect(jazzMatch!.genreKey, 'jazz');
      expect(jazzMatch.targetPresetId, 'genre_jazz');

      final classicalMatch = GenrePresetMatcher.match('Symphonic Orchestra');
      expect(classicalMatch, isNotNull);
      expect(classicalMatch!.genreKey, 'classical');
      expect(classicalMatch.targetPresetId, 'genre_classical');
    });

    test('Handles multi-genre delimited strings and complex tags', () {
      final multi1 = GenrePresetMatcher.match('Alternative Rock, Shoegaze; Post-Punk');
      expect(multi1, isNotNull);
      expect(multi1!.genreKey, 'rock');

      final multi2 = GenrePresetMatcher.match('Indie Folk & Acoustic Guitar');
      expect(multi2, isNotNull);
      expect(multi2!.genreKey, 'acoustic');

      final multi3 = GenrePresetMatcher.match('Chillhop / Lo-Fi Beats');
      expect(multi3, isNotNull);
      expect(multi3!.genreKey, 'lofi');
    });

    test('Returns null for null, empty or unrecognized genres', () {
      expect(GenrePresetMatcher.match(null), isNull);
      expect(GenrePresetMatcher.match('   '), isNull);
      expect(GenrePresetMatcher.match('Unidentified Soundscape 999'), isNull);
    });

    test('Respects custom mapping overrides', () {
      final customOverrides = {'rock': 'studio_warmth'};
      final match = GenrePresetMatcher.match('Hard Rock', customMappingOverrides: customOverrides);
      expect(match, isNotNull);
      expect(match!.genreKey, 'rock');
      expect(match.targetPresetId, 'studio_warmth');
    });
  });

  group('DspRackController Per-Track & Genre Resolution Tests', () {
    test('Resolves Track Override with highest priority', () async {
      final controller = DspRackController();
      const track1 = Track(
        id: 'track_1',
        title: 'Song One',
        artist: 'Artist One',
        album: 'Album One',
        duration: Duration(minutes: 3),
        genre: 'Rock',
      );

      // By default without override, matches Rock genre
      final autoResult = controller.resolvePresetForTrack(track1);
      expect(autoResult.source, DspResolutionSource.genreAuto);
      expect(autoResult.preset.id, 'genre_rock');

      // Now pin custom preset 'spacious_cinema' to this track
      final cinemaPreset = DspPreset.studioPresets.firstWhere((p) => p.id == 'spacious_cinema');
      await controller.pinPresetForTrack(track1.id, cinemaPreset, trackTitle: track1.title);

      expect(controller.isTrackPinned(track1.id), isTrue);

      final pinnedResult = controller.resolvePresetForTrack(track1);
      expect(pinnedResult.source, DspResolutionSource.trackOverride);
      expect(pinnedResult.preset.id, 'spacious_cinema');

      // Unpin and verify fallback to genre
      await controller.unpinPresetForTrack(track1.id);
      expect(controller.isTrackPinned(track1.id), isFalse);

      final unpinnedResult = controller.resolvePresetForTrack(track1);
      expect(unpinnedResult.source, DspResolutionSource.genreAuto);
      expect(unpinnedResult.preset.id, 'genre_rock');
    });

    test('Resolves Genre Auto-Apply when no track override exists', () {
      final controller = DspRackController();
      const jazzTrack = Track(
        id: 'track_jazz',
        title: 'Autumn Leaves',
        artist: 'Miles Davis',
        album: 'Blue Note',
        duration: Duration(minutes: 5),
        genre: 'Bebop / Jazz',
      );

      final result = controller.resolvePresetForTrack(jazzTrack);
      expect(result.source, DspResolutionSource.genreAuto);
      expect(result.preset.id, 'genre_jazz');
    });

    test('Fallbacks to Manual/Default when genre auto-apply is disabled', () async {
      final controller = DspRackController();
      await controller.setAutoApplyGenreEnabled(false);

      const edmTrack = Track(
        id: 'track_edm',
        title: 'Levels',
        artist: 'Avicii',
        album: 'Levels EP',
        duration: Duration(minutes: 4),
        genre: 'EDM / Dance',
      );

      final result = controller.resolvePresetForTrack(edmTrack);
      expect(result.source, DspResolutionSource.manual);
    });

    test('Updates and persists custom genre mappings', () async {
      final controller = DspRackController();
      await controller.updateGenreMapping('pop', 'deep_bass');

      expect(controller.customGenreMappings['pop'], 'deep_bass');

      const popTrack = Track(
        id: 'track_pop',
        title: 'Pop Star',
        artist: 'Singer',
        album: 'Pop Album',
        duration: Duration(minutes: 3),
        genre: 'K-Pop',
      );

      final result = controller.resolvePresetForTrack(popTrack);
      expect(result.source, DspResolutionSource.genreAuto);
      expect(result.preset.id, 'deep_bass');
    });
  });

  group('Widget Tests: DSP Per-Track and Genre Modals', () {
    testWidgets('StudioTrackDspPresetSheet renders correctly and pins preset', (tester) async {
      const track = Track(
        id: 'widget_track_1',
        title: 'Bohemian Rhapsody',
        artist: 'Queen',
        album: 'A Night at the Opera',
        duration: Duration(minutes: 6),
        genre: 'Classic Rock',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: StudioTrackDspPresetSheet(track: track),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check header info
      expect(find.text('Bohemian Rhapsody'), findsOneWidget);
      expect(find.textContaining('Queen'), findsOneWidget);
      expect(find.text('GENRE: CLASSIC ROCK'), findsOneWidget);

      // Check genre optimized section
      expect(find.text('GENRE-OPTIMIZED PRESETS'), findsOneWidget);
      expect(find.text('Dynamic Rock & Alternative'), findsWidgets);

      // Tap on Rock preset tile to pin
      await tester.tap(find.widgetWithText(InkWell, 'Dynamic Rock & Alternative'));
      await tester.pumpAndSettle();

      // Check pinned status indicator appears
      expect(find.text('PINNED TRACK OVERRIDE'), findsOneWidget);
      expect(find.text('UNPIN'), findsOneWidget);
    });

    testWidgets('GenreRulesConfigModal toggles auto-apply and renders genre list', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: GenreRulesConfigModal(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('GENRE AUTO-PRESET RULES'), findsOneWidget);
      expect(find.text('Auto-Apply by Track Genre'), findsOneWidget);

      // Check initially visible genre categories
      expect(find.text('ROCK & ALTERNATIVE'), findsOneWidget);
      expect(find.text('METAL & HEAVY'), findsOneWidget);
      expect(find.text('POP & COMMERCIAL'), findsOneWidget);

      // Scroll to find lower genres
      await tester.scrollUntilVisible(
        find.text('JAZZ & BLUES'),
        100.0,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('JAZZ & BLUES'), findsOneWidget);
    });
  });
}
