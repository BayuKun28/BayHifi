import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:baydev_hifi/core/database/local_persistence_service.dart';
import 'package:baydev_hifi/core/storage/storage_permission_dialog.dart';
import 'package:baydev_hifi/core/storage/storage_permission_service.dart';
import 'package:baydev_hifi/features/library/data/metadata_tagger_service.dart';
import 'package:baydev_hifi/features/library/presentation/widgets/metadata_tag_editor_sheet.dart';
import 'package:baydev_hifi/features/player/domain/track.dart';
import 'package:baydev_hifi/features/settings/data/backup_restore_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() {
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return '/tmp/bayhifi_storage_persistence_test';
    });
  });

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('bayhifi_test_');
    final dbFile = '${tempDir.path}/storage.json';
    await LocalPersistenceService.instance.init(customPath: dbFile);
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('StoragePermissionService Tests', () {
    test('getPublicMusicDirectory returns valid non-empty directory path', () async {
      final service = StoragePermissionService.instance;
      final dir = await service.getPublicMusicDirectory();
      expect(dir.path, isNotEmpty);
      expect(dir.path.contains('Music') || dir.path.contains('BaydevHiFi'), isTrue);
    });

    test('getPublicBackupFile returns json file within public music path', () async {
      final service = StoragePermissionService.instance;
      final file = await service.getPublicBackupFile();
      expect(file.path.endsWith('baydev_hifi_backup.json'), isTrue);
    });

    test('canWriteToPath returns true for writable directory and files', () async {
      final service = StoragePermissionService.instance;
      final canWriteDir = await service.canWriteToPath(tempDir.path);
      expect(canWriteDir, isTrue);

      final testFile = File('${tempDir.path}/test_write.txt');
      await testFile.writeAsString('hello');
      final canWriteFile = await service.canWriteToPath(testFile.path);
      expect(canWriteFile, isTrue);
    });

    test('hasManageExternalStoragePermission defaults safely in test/desktop environment', () async {
      final service = StoragePermissionService.instance;
      final hasPerm = await service.hasManageExternalStoragePermission();
      expect(hasPerm, isA<bool>());
    });
  });

  group('StoragePermissionDialog Widget Tests', () {
    testWidgets('renders M3E dialog with rationale, shield icon, and action buttons', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: StoragePermissionDialog(
                featureName: 'Direct Physical Audio Tagging',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Storage Permission'), findsOneWidget);
      expect(find.text('Direct Physical Audio Tagging'), findsOneWidget);
      expect(find.textContaining('MANAGE_EXTERNAL_STORAGE'), findsOneWidget);
      expect(find.byType(M3EButton), findsNWidgets(2));
    });
  });

  group('MetadataTaggerService Result & Status Tests', () {
    test('PhysicalTagWriteResult correctly reports success and failure states', () {
      const successRes = PhysicalTagWriteResult(status: PhysicalTagWriteStatus.success);
      expect(successRes.isSuccess, isTrue);
      expect(successRes.isPhysicalSuccess, isTrue);
      expect(successRes.isPermissionDenied, isFalse);

      const permRes = PhysicalTagWriteResult(
        status: PhysicalTagWriteStatus.permissionDenied,
        errorMessage: 'EACCES Permission Denied',
      );
      expect(permRes.isSuccess, isFalse);
      expect(permRes.isPhysicalSuccess, isFalse);
      expect(permRes.isPermissionDenied, isTrue);

      const virtualRes = PhysicalTagWriteResult(status: PhysicalTagWriteStatus.virtualTrack);
      expect(virtualRes.isSuccess, isTrue);
      expect(virtualRes.isPhysicalSuccess, isFalse);
    });

    test('writePhysicalTags returns fileNotFound for non-existent file', () async {
      const tagger = MetadataTaggerService();
      const tagData = AudioTagData(title: 'Test Song', artist: 'Test Artist');
      final result = await tagger.writePhysicalTags('/non/existent/path.mp3', tagData);
      expect(result.status, PhysicalTagWriteStatus.fileNotFound);
      expect(result.isSuccess, isFalse);
    });
  });

  group('BackupRestoreService Auto-Sync & Empty Database Recovery Tests', () {
    test('createBackupJson includes DSP states, EQ presets, and AutoEQ driver curves', () async {
      final storage = LocalPersistenceService.instance;
      await storage.saveCustomPlaylists([
        {'id': 'p1', 'name': 'Rock Mix', 'tracks': []}
      ]);
      await storage.saveFavoriteTrackIds({'track_1', 'track_2'});
      await storage.saveDspGenreMappings({'Rock': 'genre_rock'});
      await storage.saveDspTrackOverride({'trackId': 'track_1', 'presetId': 'genre_rock', 'isPinned': true});
      await storage.saveActiveEqState(
        bands: [{'freq': 1000.0, 'gain': 2.5, 'q': 1.0}],
        preampDb: -2.5,
        activePresetName: 'Studio Warmth',
        lastDriverName: 'KZ Castor',
        lastTargetName: 'Harman 2019',
      );

      final service = BackupRestoreService.instance;
      final jsonStr = service.createBackupJson();
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;

      expect(map['version'], 1);
      expect(map['dsp_genre_mappings'], isNotNull);
      expect(map['dsp_track_overrides'], isNotNull);
      expect(map['active_eq_state'], isNotNull);
      expect(map['active_eq_state']['lastDriverName'], 'KZ Castor');
    });

    test('restoreFromBackupJson restores DSP overrides, genre mappings, and EQ state accurately', () async {
      final service = BackupRestoreService.instance;
      final testBackup = {
        'app': 'Baydev HiFi',
        'version': 2,
        'createdAt': DateTime.now().toIso8601String(),
        'theme_settings': {'palette_id': 'amber_tube', 'theme_mode': 1},
        'custom_playlists': [
          {'id': 'pl_recovered', 'name': 'Recovered', 'tracks': []}
        ],
        'smart_playlists': [],
        'favorite_track_ids': ['fav_100'],
        'saved_music_folders': ['/storage/emulated/0/Music'],
        'dsp_genre_mappings': {'Jazz': 'genre_jazz'},
        'dsp_track_overrides': {
          't_jazz_1': {'presetId': 'genre_jazz', 'isPinned': true}
        },
        'active_eq_state': {
          'bands': [],
          'preampDb': -1.2,
          'activePresetName': 'Jazz Reference',
          'lastDriverName': 'Moondrop Aria',
          'lastTargetName': 'HBB Target',
        },
      };

      final res = await service.restoreFromBackupJson(jsonEncode(testBackup));
      expect(res.success, isTrue);

      final storage = LocalPersistenceService.instance;
      expect(storage.getCustomPlaylists().length, 1);
      expect(storage.getFavoriteTrackIds(), contains('fav_100'));
      expect(storage.getDspGenreMappings()['Jazz'], 'genre_jazz');
      expect(storage.getDspTrackOverrides()['t_jazz_1']?['presetId'], 'genre_jazz');
      expect(storage.getActiveEqState()?['lastDriverName'], 'Moondrop Aria');
    });

    test('LocalPersistenceService.isEmpty accurately reports true when empty and false when populated', () async {
      final storage = LocalPersistenceService.instance;
      expect(storage.isEmpty, isTrue);

      await storage.saveFavoriteTrackIds({'t1'});
      expect(storage.isEmpty, isFalse);
    });
  });

  group('MetadataTagEditorSheet Widget & UI Status Tests', () {
    testWidgets('renders status pill and fields for physical track', (tester) async {
      const track = Track(
        id: 'phys_1',
        title: 'Physical Audio Track',
        artist: 'Studio Master',
        album: 'Audiophile Album',
        duration: Duration(minutes: 3),
        filePath: '/tmp/test_song.flac',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => MetadataTagEditorSheet.show(context, track),
                  child: const Text('Open Sheet'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('STUDIO TAG EDITOR'), findsOneWidget);
      expect(find.text('Physical Audio Track'), findsOneWidget);
      expect(find.text('Physical Tagging Active — Tags will be written permanently to disk'), findsOneWidget);
    });
  });
}
