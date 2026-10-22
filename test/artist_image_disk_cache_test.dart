import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:baydev_hifi/core/database/local_persistence_service.dart';
import 'package:baydev_hifi/features/library/data/artist_metadata_service.dart';
import 'package:baydev_hifi/features/library/data/storage_cache_manager.dart';
import 'package:baydev_hifi/features/library/presentation/widgets/artist_avatar_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory testDir;

  final validPngBytes = Uint8List.fromList(const [
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
    0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
    0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
  ]);

  setUpAll(() async {
    testDir = Directory.systemTemp.createTempSync('bayhifi_artist_cache_test_');

    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return testDir.path;
    });

    SharedPreferences.setMockInitialValues({});
    await LocalPersistenceService.instance.init();
  });

  setUp(() {
    ArtistMetadataService.instance.clearMemoryCache();
    ArtistMetadataService.instance.testCoversDirectory = Directory('${testDir.path}/artist_covers');
  });

  tearDownAll(() {
    try {
      if (testDir.existsSync()) {
        testDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  group('ArtistMetadataService Disk Caching Tests', () {
    test('saveArtistCoverBytes persists file to disk and supports synchronous instant lookup', () async {
      final savedPath = await ArtistMetadataService.instance.saveArtistCoverBytes('Matt Bellamy', validPngBytes);

      expect(savedPath, isNotNull);
      expect(File(savedPath!).existsSync(), isTrue);

      // Synchronous Frame-1 lookup
      final syncPath = ArtistMetadataService.instance.getCachedArtistImagePathSync('Matt Bellamy');
      expect(syncPath, equals(savedPath));

      // Case-insensitive lookup
      final syncPathLower = ArtistMetadataService.instance.getCachedArtistImagePathSync('matt bellamy');
      expect(syncPathLower, equals(savedPath));
    });

    test('getCachedArtistImagePathSync returns null for non-cached or unknown artists', () {
      expect(ArtistMetadataService.instance.getCachedArtistImagePathSync('NonExistentArtistXYZ'), isNull);
      expect(ArtistMetadataService.instance.getCachedArtistImagePathSync('Unknown Artist'), isNull);
      expect(ArtistMetadataService.instance.getCachedArtistImagePathSync(''), isNull);
    });

    test('getArtistImageUrl returns cached local file path without network request', () async {
      final savedPath = await ArtistMetadataService.instance.saveArtistCoverBytes('Coldplay', validPngBytes);
      expect(savedPath, isNotNull);

      // Async getter should return local file path directly
      final resolvedPath = await ArtistMetadataService.instance.getArtistImageUrl('Coldplay');
      expect(resolvedPath, equals(savedPath));
    });

    test('StorageCacheManager.clearArtworkCache removes artist_covers directory and clears memory cache', () async {
      await ArtistMetadataService.instance.saveArtistCoverBytes('Radiohead', validPngBytes);
      expect(ArtistMetadataService.instance.getCachedArtistImagePathSync('Radiohead'), isNotNull);

      final cacheManager = StorageCacheManager.instance;
      await cacheManager.clearArtworkCache();

      expect(ArtistMetadataService.instance.getCachedArtistImagePathSync('Radiohead'), isNull);
    });
  });

  group('ArtistAvatarWidget Instant 0ms Frame-1 Tests', () {
    testWidgets('Renders FileImage immediately on Frame 1 without spinner when artist is cached on disk', (tester) async {
      await ArtistMetadataService.instance.saveArtistCoverBytes('Daft Punk', validPngBytes);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ArtistAvatarWidget(
              artistName: 'Daft Punk',
              radius: 30,
            ),
          ),
        ),
      );

      // Frame 1 check: NO spinner should exist because local cache was resolved synchronously!
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(CircleAvatar), findsOneWidget);

      final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
      expect(avatar.backgroundImage, isA<FileImage>());
    });

    testWidgets('Renders MemoryImage immediately on Frame 1 without spinner when fallbackCoverBytes is provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ArtistAvatarWidget(
              artistName: 'Uncached Artist With Album Art',
              fallbackCoverBytes: validPngBytes,
              radius: 30,
            ),
          ),
        ),
      );

      // Frame 1 check: NO spinner should exist because fallback album art is displayed immediately!
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(CircleAvatar), findsOneWidget);

      final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
      expect(avatar.backgroundImage, isA<MemoryImage>());
    });
  });
}
