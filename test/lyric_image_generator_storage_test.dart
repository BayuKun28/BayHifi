import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baydev_hifi/features/lyrics_share/presentation/services/lyric_image_generator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory testTempDir;

  setUpAll(() {
    testTempDir = Directory.systemTemp.createTempSync('bayhifi_lyric_test_');
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return testTempDir.path;
    });
  });

  tearDownAll(() {
    if (testTempDir.existsSync()) {
      testTempDir.deleteSync(recursive: true);
    }
  });

  group('LyricImageGenerator Storage & Pruning Tests', () {
    test('saveBytesToTempCache creates a file and returns valid File handle', () async {
      final sampleBytes = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
      final file = await LyricImageGenerator.saveBytesToTempCache(
        sampleBytes,
        prefix: 'baydev_hifi_lyric_test',
      );

      expect(file, isNotNull);
      expect(file!.existsSync(), isTrue);
      expect(file.path, contains('baydev_hifi_lyric_test'));
      expect(file.readAsBytesSync(), equals(sampleBytes));

      // Cleanup
      if (file.existsSync()) {
        file.deleteSync();
      }
    });

    test('pruneOrphanedCaches deletes files older than maxAge', () async {
      final sampleBytes = Uint8List.fromList([1, 2, 3, 4]);
      final file = await LyricImageGenerator.saveBytesToTempCache(
        sampleBytes,
        prefix: 'baydev_hifi_lyric_old',
      );
      expect(file, isNotNull);
      expect(file!.existsSync(), isTrue);

      // Artificially modify file's modified time to 3 days ago
      final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
      file.setLastModifiedSync(threeDaysAgo);

      // Run pruning with 48 hours maxAge
      final pruned = await LyricImageGenerator.pruneOrphanedCaches(
        maxAge: const Duration(hours: 48),
      );

      expect(pruned, greaterThanOrEqualTo(1));
      expect(file.existsSync(), isFalse);
    });

    test('saveBytesToPublicGallery saves image successfully to gallery/downloads/docs directory', () async {
      final sampleBytes = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
      final file = await LyricImageGenerator.saveBytesToPublicGallery(
        sampleBytes,
        prefix: 'baydev_hifi_lyric_public',
      );

      expect(file, isNotNull);
      expect(file!.existsSync(), isTrue);

      // Cleanup
      if (file.existsSync()) {
        file.deleteSync();
      }
    });
  });
}
