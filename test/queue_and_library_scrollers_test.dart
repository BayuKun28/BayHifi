import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:baydev_hifi/audio_engine/soloud_controller.dart';
import 'package:baydev_hifi/core/widgets/studio_alphabetical_scroller.dart';
import 'package:baydev_hifi/features/player/domain/playback_state.dart';
import 'package:baydev_hifi/features/player/domain/track.dart';
import 'package:baydev_hifi/features/player/presentation/controllers/player_controller.dart';
import 'package:baydev_hifi/features/player/presentation/widgets/now_playing_queue_sheet.dart';
import 'package:baydev_hifi/features/library/domain/library_collection_models.dart';
import 'package:baydev_hifi/features/library/presentation/controllers/library_controller.dart';
import 'package:baydev_hifi/features/library/presentation/unified_library_screen.dart';

List<Track> _createSampleTracks(int count) {
  const titles = [
    'Air on the G String',
    'Bohemian Rhapsody',
    'Clair de Lune',
    'Despacito',
    'Eine kleine Nachtmusik',
    'Fur Elise',
    'Gymnopedie No. 1',
    'Hotel California',
    'Imagine',
    'Jupiter, Bringer of Jollity',
    'Kashmir',
    'Let It Be',
    'Moonlight Sonata',
    'Nocturne in E-flat',
    'Ode to Joy',
    'Paranoid Android',
    'Quantum Realm',
    'Radioactive',
    'Stairway to Heaven',
    'Time',
    'Unfinished Symphony',
    'Vivaldi Spring',
    'Water Music',
    'Xanadu',
    'Yellow',
    'Zadok the Priest',
    '1999',
  ];

  return List.generate(count, (i) {
    final title = titles[i % titles.length];
    return Track(
      id: 'track_$i',
      title: title,
      artist: 'Artist ${String.fromCharCode(65 + (i % 26))}',
      album: 'Album $i',
      duration: Duration(seconds: 180 + i * 10),
      bitDepth: 24,
      sampleRate: 96000,
    );
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return '/tmp/bayhifi_scroller_test_dir';
    });
  });

  group('StudioAlphabeticalScroller Unit & Widget Tests', () {
    test('extractLeadingLetter extracts valid A-Z or # for numerals & symbols', () {
      expect(StudioAlphabeticalScroller.extractLeadingLetter('Bohemian Rhapsody'), 'B');
      expect(StudioAlphabeticalScroller.extractLeadingLetter('clair de lune'), 'C');
      expect(StudioAlphabeticalScroller.extractLeadingLetter('1999 Prince'), '#');
      expect(StudioAlphabeticalScroller.extractLeadingLetter('...And Justice For All'), '#');
      expect(StudioAlphabeticalScroller.extractLeadingLetter('  Yesterday  '), 'Y');
      expect(StudioAlphabeticalScroller.extractLeadingLetter(''), '#');
    });

    testWidgets('Renders A-Z alphabet rail when isAlphabetical is true', (tester) async {
      final controller = ScrollController();
      final tracks = _createSampleTracks(20);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: StudioAlphabeticalScroller(
              scrollController: controller,
              itemCount: tracks.length,
              isAlphabetical: true,
              letterSelector: (i) => tracks[i].title,
              child: ListView.builder(
                controller: controller,
                itemCount: tracks.length,
                itemBuilder: (_, i) => SizedBox(height: 72, child: Text(tracks[i].title)),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check alphabet rail existence
      expect(find.text('A'), findsAtLeastNWidgets(1));
      expect(find.text('B'), findsAtLeastNWidgets(1));
      expect(find.text('Z'), findsAtLeastNWidgets(1));
      expect(find.text('#'), findsAtLeastNWidgets(1));
    });

    testWidgets('Renders standard Scrollbar when isAlphabetical is false', (tester) async {
      final controller = ScrollController();
      final tracks = _createSampleTracks(20);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: StudioAlphabeticalScroller(
              scrollController: controller,
              itemCount: tracks.length,
              isAlphabetical: false,
              letterSelector: (i) => tracks[i].title,
              child: ListView.builder(
                controller: controller,
                itemCount: tracks.length,
                itemBuilder: (_, i) => SizedBox(height: 72, child: Text(tracks[i].title)),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Scrollbar), findsOneWidget);
    });

    testWidgets('Tapping letter on alphabet rail jumps to corresponding target index', (tester) async {
      final controller = ScrollController();
      final tracks = List.generate(30, (i) {
        final letter = String.fromCharCode(65 + (i % 26)); // A-Z
        return Track(
          id: 'track_$i',
          title: '$letter Song $i',
          artist: 'Artist',
          album: 'Album',
          duration: const Duration(minutes: 3),
        );
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: StudioAlphabeticalScroller(
              scrollController: controller,
              itemCount: tracks.length,
              itemHeight: 74.0,
              isAlphabetical: true,
              letterSelector: (i) => tracks[i].title,
              child: ListView.builder(
                controller: controller,
                itemCount: tracks.length,
                itemBuilder: (_, i) => SizedBox(key: ValueKey('item_$i'), height: 74.0, child: Text(tracks[i].title)),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on letter 'E' in the alphabet rail (index 4 in tracks: E Song 4)
      final letterE = find.text('E');
      expect(letterE, findsAtLeastNWidgets(1));
      await tester.tap(letterE.first);
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      // Index of E Song is 4, 4 * 74 = 296
      expect(controller.offset, closeTo(296.0, 1.0));
    });
  });

  group('NowPlayingQueueSheet Centering & Scrollbar Tests', () {
    testWidgets('NowPlayingQueueSheet renders scrollbar and active queue items', (tester) async {
      final tracks = _createSampleTracks(15);

      final container = ProviderContainer(
        overrides: [
          playerControllerProvider.overrideWith((ref) {
            final notifier = PlayerController(SoLoudController.instance);
            notifier.state = notifier.state.copyWith(
              queue: tracks,
              originalQueue: tracks,
              queueIndex: 5,
              currentTrack: tracks[5],
              status: PlaybackStatus.playing,
            );
            return notifier;
          }),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: const Scaffold(
              body: NowPlayingQueueSheet(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('UP NEXT QUEUE'), findsOneWidget);
      expect(find.text('6 of 15 Tracks'), findsOneWidget);
      expect(find.byType(Scrollbar), findsOneWidget);
      expect(find.byType(ReorderableListView), findsOneWidget);
    });
  });

  group('UnifiedLibraryScreen Contextual Scroller Tests', () {
    testWidgets('Renders StudioAlphabeticalScroller in alphabetical mode when sortField is Title', (tester) async {
      final tracks = _createSampleTracks(10);

      final container = ProviderContainer(
        overrides: [
          unifiedLibraryProvider.overrideWith((ref) {
            final notifier = UnifiedLibraryController();
            notifier.state = notifier.state.copyWith(
              tracks: tracks,
              sortField: SortField.title,
            );
            return notifier;
          }),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: const Scaffold(
              body: UnifiedLibraryScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(StudioAlphabeticalScroller), findsAtLeastNWidgets(1));
    });

    testWidgets('Renders StudioAlphabeticalScroller with standard scrollbar when sortField is Duration', (tester) async {
      final tracks = _createSampleTracks(10);

      final container = ProviderContainer(
        overrides: [
          unifiedLibraryProvider.overrideWith((ref) {
            final notifier = UnifiedLibraryController();
            notifier.state = notifier.state.copyWith(
              tracks: tracks,
              sortField: SortField.duration,
            );
            return notifier;
          }),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: const Scaffold(
              body: UnifiedLibraryScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(StudioAlphabeticalScroller), findsAtLeastNWidgets(1));
      expect(find.byType(Scrollbar), findsAtLeastNWidgets(1));
    });
  });
}
