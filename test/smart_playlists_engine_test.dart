import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baydev_hifi/features/library/domain/m3u8_playlist_service.dart';
import 'package:baydev_hifi/features/library/domain/smart_playlist_evaluator.dart';
import 'package:baydev_hifi/features/library/domain/smart_playlist_models.dart';
import 'package:baydev_hifi/features/library/presentation/controllers/library_controller.dart';
import 'package:baydev_hifi/features/library/presentation/playlists_screen.dart';
import 'package:baydev_hifi/features/library/presentation/widgets/create_smart_playlist_dialog.dart';
import 'package:baydev_hifi/features/player/domain/track.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final trackA = const Track(
    id: 't_flac_hires',
    title: 'Autumn Leaves',
    artist: 'Cannonball Adderley',
    album: 'Somethin Else',
    genre: 'Jazz',
    duration: Duration(seconds: 655),
    filePath: '/music/autumn_leaves.flac',
    format: AudioFormat.flac,
    sampleRate: 96000,
    bitDepth: 24,
    bitrate: 2800,
    year: 1958,
  );

  final trackB = const Track(
    id: 't_wav_acoustic',
    title: 'Little Wing',
    artist: 'Jimi Hendrix',
    album: 'Axis: Bold as Love',
    genre: 'Rock',
    duration: Duration(seconds: 145),
    filePath: '/music/little_wing.wav',
    format: AudioFormat.wav,
    sampleRate: 44100,
    bitDepth: 16,
    bitrate: 1411,
    year: 1967,
  );

  final trackC = const Track(
    id: 't_mp3_cloud',
    title: 'Blue in Green',
    artist: 'Miles Davis',
    album: 'Kind of Blue',
    genre: 'Jazz',
    duration: Duration(seconds: 337),
    remoteUrl: 'https://navidrome.studio/rest/stream/blue_in_green.mp3',
    format: AudioFormat.mp3,
    sampleRate: 44100,
    bitDepth: 16,
    bitrate: 320,
    year: 1959,
  );

  final allTracks = <Track>[trackA, trackB, trackC];
  final evaluator = const SmartPlaylistEvaluator();

  group('SmartPlaylist Models & Serialization Tests', () {
    test('SmartPlaylistRule serialization to and from Map', () {
      const rule = SmartPlaylistRule(
        field: SmartPlaylistField.sampleRate,
        operator: SmartPlaylistOperator.greaterThanOrEqual,
        value: '96000',
        secondaryValue: '192000',
      );

      final map = rule.toMap();
      expect(map['field'], 'sampleRate');
      expect(map['operator'], 'greaterThanOrEqual');
      expect(map['value'], '96000');
      expect(map['secondaryValue'], '192000');

      final reconstructed = SmartPlaylistRule.fromMap(map);
      expect(reconstructed.field, SmartPlaylistField.sampleRate);
      expect(reconstructed.operator, SmartPlaylistOperator.greaterThanOrEqual);
      expect(reconstructed.value, '96000');
      expect(reconstructed.secondaryValue, '192000');
    });

    test('SmartPlaylist serialization to and from Map', () {
      final playlist = SmartPlaylist(
        id: 'smart_test_1',
        name: 'Studio Jazz Masters',
        description: 'Filtered jazz tracks with high bit depth',
        matchMode: SmartPlaylistMatchMode.all,
        rules: const [
          SmartPlaylistRule(
            field: SmartPlaylistField.genre,
            operator: SmartPlaylistOperator.contains,
            value: 'Jazz',
          ),
          SmartPlaylistRule(
            field: SmartPlaylistField.bitDepth,
            operator: SmartPlaylistOperator.greaterThanOrEqual,
            value: '24',
          ),
        ],
        limit: 25,
        sortBy: 'sampleRate',
        sortAscending: false,
        createdAt: DateTime(2026, 1, 15),
        isPreset: false,
      );

      final map = playlist.toMap();
      expect(map['id'], 'smart_test_1');
      expect(map['name'], 'Studio Jazz Masters');
      expect(map['matchMode'], 'all');
      expect((map['rules'] as List).length, 2);
      expect(map['limit'], 25);
      expect(map['sortBy'], 'sampleRate');
      expect(map['sortAscending'], false);

      final reconstructed = SmartPlaylist.fromMap(map);
      expect(reconstructed.id, 'smart_test_1');
      expect(reconstructed.name, 'Studio Jazz Masters');
      expect(reconstructed.matchMode, SmartPlaylistMatchMode.all);
      expect(reconstructed.rules.length, 2);
      expect(reconstructed.limit, 25);
      expect(reconstructed.sortBy, 'sampleRate');
      expect(reconstructed.sortAscending, false);
    });
  });

  group('SmartPlaylistEvaluator Operator Tests', () {
    test('Text Operators: contains, notContains, equals, startsWith, endsWith', () {
      // contains
      expect(
        evaluator.evaluateRule(
          trackA,
          const SmartPlaylistRule(
            field: SmartPlaylistField.title,
            operator: SmartPlaylistOperator.contains,
            value: 'leaves',
          ),
        ),
        isTrue,
      );

      // notContains
      expect(
        evaluator.evaluateRule(
          trackA,
          const SmartPlaylistRule(
            field: SmartPlaylistField.artist,
            operator: SmartPlaylistOperator.notContains,
            value: 'Hendrix',
          ),
        ),
        isTrue,
      );

      // equals (case insensitive)
      expect(
        evaluator.evaluateRule(
          trackB,
          const SmartPlaylistRule(
            field: SmartPlaylistField.genre,
            operator: SmartPlaylistOperator.equals,
            value: 'rock',
          ),
        ),
        isTrue,
      );

      // startsWith
      expect(
        evaluator.evaluateRule(
          trackC,
          const SmartPlaylistRule(
            field: SmartPlaylistField.title,
            operator: SmartPlaylistOperator.startsWith,
            value: 'Blue',
          ),
        ),
        isTrue,
      );

      // endsWith
      expect(
        evaluator.evaluateRule(
          trackA,
          const SmartPlaylistRule(
            field: SmartPlaylistField.filePath,
            operator: SmartPlaylistOperator.endsWith,
            value: '.flac',
          ),
        ),
        isTrue,
      );
    });

    test('Number Operators: greaterThan, lessThan, equals, between', () {
      // greaterThan
      expect(
        evaluator.evaluateRule(
          trackA,
          const SmartPlaylistRule(
            field: SmartPlaylistField.sampleRate,
            operator: SmartPlaylistOperator.greaterThan,
            value: '48000',
          ),
        ),
        isTrue,
      );

      // lessThan
      expect(
        evaluator.evaluateRule(
          trackB,
          const SmartPlaylistRule(
            field: SmartPlaylistField.duration,
            operator: SmartPlaylistOperator.lessThan,
            value: '200',
          ),
        ),
        isTrue,
      );

      // equals
      expect(
        evaluator.evaluateRule(
          trackC,
          const SmartPlaylistRule(
            field: SmartPlaylistField.year,
            operator: SmartPlaylistOperator.equals,
            value: '1959',
          ),
        ),
        isTrue,
      );

      // between
      expect(
        evaluator.evaluateRule(
          trackA,
          const SmartPlaylistRule(
            field: SmartPlaylistField.bitrate,
            operator: SmartPlaylistOperator.between,
            value: '2000',
            secondaryValue: '3000',
          ),
        ),
        isTrue,
      );

      expect(
        evaluator.evaluateRule(
          trackB,
          const SmartPlaylistRule(
            field: SmartPlaylistField.bitrate,
            operator: SmartPlaylistOperator.between,
            value: '2000',
            secondaryValue: '3000',
          ),
        ),
        isFalse,
      );
    });

    test('Boolean Operators: isHiRes, isFavorite, isOffline', () {
      final favs = {'t_flac_hires'};

      // isHiRes
      expect(
        evaluator.evaluateRule(
          trackA,
          const SmartPlaylistRule(
            field: SmartPlaylistField.isHiRes,
            operator: SmartPlaylistOperator.isTrue,
            value: 'true',
          ),
        ),
        isTrue,
      );

      expect(
        evaluator.evaluateRule(
          trackB,
          const SmartPlaylistRule(
            field: SmartPlaylistField.isHiRes,
            operator: SmartPlaylistOperator.isTrue,
            value: 'true',
          ),
        ),
        isFalse,
      );

      // isFavorite
      expect(
        evaluator.evaluateRule(
          trackA,
          const SmartPlaylistRule(
            field: SmartPlaylistField.isFavorite,
            operator: SmartPlaylistOperator.isTrue,
            value: 'true',
          ),
          favoriteTrackIds: favs,
        ),
        isTrue,
      );

      expect(
        evaluator.evaluateRule(
          trackB,
          const SmartPlaylistRule(
            field: SmartPlaylistField.isFavorite,
            operator: SmartPlaylistOperator.isTrue,
            value: 'true',
          ),
          favoriteTrackIds: favs,
        ),
        isFalse,
      );

      // isOffline
      expect(
        evaluator.evaluateRule(
          trackA,
          const SmartPlaylistRule(
            field: SmartPlaylistField.isOffline,
            operator: SmartPlaylistOperator.isTrue,
            value: 'true',
          ),
        ),
        isTrue,
      );

      expect(
        evaluator.evaluateRule(
          trackC,
          const SmartPlaylistRule(
            field: SmartPlaylistField.isOffline,
            operator: SmartPlaylistOperator.isTrue,
            value: 'true',
          ),
        ),
        isFalse,
      );
    });
  });

  group('Match Logic, Sorting & Limiting Tests', () {
    test('Match ALL (AND) requires all conditions to be satisfied', () {
      final playlistAnd = SmartPlaylist(
        id: 'p_and',
        name: 'Jazz & Hi-Res Only',
        description: 'Both conditions required',
        matchMode: SmartPlaylistMatchMode.all,
        rules: const [
          SmartPlaylistRule(
            field: SmartPlaylistField.genre,
            operator: SmartPlaylistOperator.equals,
            value: 'Jazz',
          ),
          SmartPlaylistRule(
            field: SmartPlaylistField.isHiRes,
            operator: SmartPlaylistOperator.isTrue,
            value: 'true',
          ),
        ],
        createdAt: DateTime.now(),
      );

      final result = evaluator.evaluate(
        playlist: playlistAnd,
        allTracks: allTracks,
      );

      // Only trackA is both Jazz and Hi-Res (trackC is Jazz but not Hi-Res)
      expect(result.length, 1);
      expect(result.first.id, 't_flac_hires');
    });

    test('Match ANY (OR) matches if at least one condition is satisfied', () {
      final playlistOr = SmartPlaylist(
        id: 'p_or',
        name: 'Rock OR Hi-Res',
        description: 'Either rock or high resolution',
        matchMode: SmartPlaylistMatchMode.any,
        rules: const [
          SmartPlaylistRule(
            field: SmartPlaylistField.genre,
            operator: SmartPlaylistOperator.equals,
            value: 'Rock',
          ),
          SmartPlaylistRule(
            field: SmartPlaylistField.isHiRes,
            operator: SmartPlaylistOperator.isTrue,
            value: 'true',
          ),
        ],
        createdAt: DateTime.now(),
      );

      final result = evaluator.evaluate(
        playlist: playlistOr,
        allTracks: allTracks,
      );

      // trackA (Hi-Res) and trackB (Rock) should match
      expect(result.length, 2);
      expect(result.map((t) => t.id).toSet(), {'t_flac_hires', 't_wav_acoustic'});
    });

    test('Sorting and Limit Capping executes deterministically', () {
      final playlistSorted = SmartPlaylist(
        id: 'p_sort',
        name: 'Longest Tracks Capped',
        description: 'Sorted by duration descending with limit 2',
        matchMode: SmartPlaylistMatchMode.all,
        rules: const [], // matches all
        sortBy: 'duration',
        sortAscending: false,
        limit: 2,
        createdAt: DateTime.now(),
      );

      final result = evaluator.evaluate(
        playlist: playlistSorted,
        allTracks: allTracks,
      );

      expect(result.length, 2);
      // Track A (655s) followed by Track C (337s)
      expect(result[0].id, 't_flac_hires');
      expect(result[1].id, 't_mp3_cloud');
    });
  });

  group('M3u8PlaylistService Export Tests', () {
    test('Generates valid Extended M3U8 content formatted per specification', () {
      final content = M3u8PlaylistService.generateM3u8(
        playlistName: 'Test Audiophile Mix',
        tracks: [trackA, trackB],
      );

      expect(content.contains('#EXTM3U'), isTrue);
      expect(content.contains('#PLAYLIST:Test Audiophile Mix'), isTrue);
      expect(content.contains('#EXTINF:655,Cannonball Adderley - Autumn Leaves'), isTrue);
      expect(content.contains('/music/autumn_leaves.flac'), isTrue);
      expect(content.contains('#EXTINF:145,Jimi Hendrix - Little Wing'), isTrue);
      expect(content.contains('/music/little_wing.wav'), isTrue);
    });
  });

  group('UnifiedLibraryController Smart Playlist Integration', () {
    test('Stores and updates smart playlists with auto-evaluation', () {
      final controller = UnifiedLibraryController(initialTracks: allTracks);

      // Verify default presets exist
      expect(controller.state.smartPlaylists.isNotEmpty, isTrue);

      final initialCount = controller.state.smartPlaylists.length;
      final customSmart = SmartPlaylist(
        id: 'custom_smart_rock',
        name: 'Classic Rock Focus',
        description: 'Rock tracks',
        rules: const [
          SmartPlaylistRule(
            field: SmartPlaylistField.genre,
            operator: SmartPlaylistOperator.equals,
            value: 'Rock',
          ),
        ],
        createdAt: DateTime.now(),
      );

      // Save custom smart playlist
      controller.saveSmartPlaylist(customSmart);
      expect(controller.state.smartPlaylists.length, initialCount + 1);

      // Dynamic evaluation through helper
      final rockTracks = controller.state.getSmartPlaylistTracks(customSmart);
      expect(rockTracks.length, 1);
      expect(rockTracks.first.title, 'Little Wing');

      // Duplicate
      controller.duplicateSmartPlaylist('custom_smart_rock');
      expect(controller.state.smartPlaylists.length, initialCount + 2);
      expect(
        controller.state.smartPlaylists.any((p) => p.name == 'Classic Rock Focus (Copy)'),
        isTrue,
      );

      // Delete
      controller.deleteSmartPlaylist('custom_smart_rock');
      expect(controller.state.smartPlaylists.any((p) => p.id == 'custom_smart_rock'), isFalse);
    });
  });

  group('PlaylistsScreen & CreateSmartPlaylistDialog Widget Tests', () {
    testWidgets('PlaylistsScreen renders Dynamic Smart Playlists and allows opening detail', (tester) async {
      final controller = UnifiedLibraryController(
        initialTracks: allTracks,
        initialSmartPlaylists: [
          SmartPlaylist(
            id: 'smart_ui_test',
            name: 'Studio Master Series',
            description: 'Filtered studio masters',
            rules: const [
              SmartPlaylistRule(
                field: SmartPlaylistField.isHiRes,
                operator: SmartPlaylistOperator.isTrue,
                value: 'true',
              ),
            ],
            createdAt: DateTime.now(),
            isPreset: false,
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            unifiedLibraryProvider.overrideWith((ref) => controller),
          ],
          child: const MaterialApp(
            home: PlaylistsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Headers
      expect(find.text('STUDIO PLAYLISTS'), findsOneWidget);
      expect(find.text('STUDIO COLLECTIONS'), findsOneWidget);
      expect(find.textContaining('DYNAMIC SMART PLAYLISTS'), findsOneWidget);

      // Verify Smart Playlist Item
      expect(find.text('Studio Master Series'), findsOneWidget);

      // Tap Smart Playlist to open detail sheet
      await tester.tap(find.text('Studio Master Series'));
      await tester.pumpAndSettle();

      // Verify Detail Sheet contains evaluated track
      expect(find.text('Autumn Leaves'), findsOneWidget);
      expect(find.text('Play All'), findsOneWidget);
      expect(find.text('Shuffle'), findsOneWidget);
    });

    testWidgets('CreateSmartPlaylistDialog opens, live evaluates count, and saves new playlist', (tester) async {
      final controller = UnifiedLibraryController(initialTracks: allTracks);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            unifiedLibraryProvider.overrideWith((ref) => controller),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => CreateSmartPlaylistDialog.show(context),
                  child: const Text('OPEN DIALOG'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.text('OPEN DIALOG'));
      await tester.pumpAndSettle();

      // Verify Dialog header
      expect(find.text('NEW SMART PLAYLIST'), findsOneWidget);
      expect(find.text('MATCH LOGIC'), findsOneWidget);
      expect(find.textContaining('Matched'), findsOneWidget);

      // Enter Playlist Name
      final nameField = find.widgetWithText(TextField, 'Playlist Name');
      expect(nameField, findsOneWidget);
      await tester.enterText(nameField, 'Acoustic Legends');
      await tester.pumpAndSettle();

      // Save Smart Playlist
      final saveButton = find.text('Save Smart Playlist');
      expect(saveButton, findsOneWidget);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Verify newly created smart playlist is in state
      expect(
        controller.state.smartPlaylists.any((p) => p.name == 'Acoustic Legends'),
        isTrue,
      );
    });
  });
}
