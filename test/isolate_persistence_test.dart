import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:baydev_hifi/core/database/local_persistence_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('bayhifi_isolate_test_');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('LocalPersistenceService encodes and decodes large track libraries via background isolate compute', () async {
    final dbFile = '${tempDir.path}/large_storage.json';
    final service = LocalPersistenceService.instance;
    await service.init(customPath: dbFile);

    // Generate 120 tracks to exceed the 50-track threshold and trigger compute isolate
    final List<Map<String, dynamic>> mockTracks = List.generate(120, (i) => {
      'id': 'track_id_$i',
      'title': 'Audiophile Master Recording Title $i',
      'artist': 'High-Resolution Acoustic Studio Artist $i',
      'album': 'DSD & FLAC Reference Master Collection $i',
      'duration': 240000 + i * 1000,
      'filePath': '/storage/emulated/0/Music/Album_$i/track_$i.flac',
      'format': 'flac',
      'bitDepth': 24,
      'sampleRate': 96000,
      'fileSizeBytes': 45000000 + i * 10000,
    });

    await service.saveLibraryTracks(mockTracks);
    await service.flush();

    final savedFile = File(dbFile);
    expect(savedFile.existsSync(), isTrue);
    final fileContent = savedFile.readAsStringSync();
    expect(fileContent.length, greaterThan(20000));

    // Re-initialize from the large JSON file on disk to test compute decoding
    await service.init(customPath: dbFile);
    final reloadedTracks = service.getSavedLibraryTracks();

    expect(reloadedTracks.length, 120);
    expect(reloadedTracks.first['title'], 'Audiophile Master Recording Title 0');
    expect(reloadedTracks.last['title'], 'Audiophile Master Recording Title 119');
  });
}
