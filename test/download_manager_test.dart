import 'package:flutter_test/flutter_test.dart';
import 'package:baydev_hifi/features/download_manager/domain/download_task.dart';
import 'package:baydev_hifi/features/download_manager/presentation/controllers/download_controller.dart';
import 'package:baydev_hifi/features/library/presentation/controllers/library_controller.dart';
import 'package:baydev_hifi/features/player/domain/track.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const dummyTrack1 = Track(
    id: 'track_1',
    title: 'Get Lucky',
    artist: 'Daft Punk',
    album: 'Random Access Memories',
    duration: Duration(minutes: 4, seconds: 8),
    remoteUrl: 'https://youtube.com/watch?v=5NV6Rdv1a3I',
  );

  const dummyTrack2 = Track(
    id: 'track_2',
    title: 'Starboy',
    artist: 'The Weeknd',
    album: 'Starboy',
    duration: Duration(minutes: 3, seconds: 50),
    remoteUrl: 'https://youtube.com/watch?v=34Na4j8AVgA',
  );

  group('DownloadTask Domain Tests', () {
    test('DownloadProgress formatters calculate speeds and sizes correctly', () {
      const progress = DownloadProgress(
        downloadedBytes: 3145728, // 3.0 MB
        totalBytes: 7340032, // 7.0 MB
        speedBytesPerSec: 1572864, // 1.5 MB/s
        fraction: 0.428,
        statusText: 'Downloading stream: 43%',
      );

      expect(progress.speedFormatted, equals('1.5 MB/s'));
      expect(progress.sizeFormatted, equals('3.0 MB / 7.0 MB'));
    });

    test('DownloadTask JSON serialization round-trip', () {
      final task = DownloadTask(
        id: 'task_123',
        track: dummyTrack1,
        status: DownloadStatus.downloading,
        createdAt: DateTime(2026, 1, 1, 12, 0),
        matchedVideoId: '5NV6Rdv1a3I',
      );

      final json = task.toJson();
      final restored = DownloadTask.fromJson(json);

      expect(restored.id, equals('task_123'));
      expect(restored.track.id, equals(dummyTrack1.id));
      expect(restored.track.title, equals('Get Lucky'));
      expect(restored.status, equals(DownloadStatus.downloading));
      expect(restored.matchedVideoId, equals('5NV6Rdv1a3I'));
    });
  });

  group('DownloadController Queue & State Management Tests', () {
    test('Enqueuing a track adds it to queue and advances state', () {
      final controller = DownloadController();

      controller.enqueueTrack(dummyTrack1);

      expect(
        controller.state.queue.length + controller.state.active.length,
        equals(1),
      );
      expect(controller.state.hasActiveDownloads, isTrue);

      // Prevent duplicate enqueuing
      controller.enqueueTrack(dummyTrack1);
      expect(
        controller.state.queue.length + controller.state.active.length,
        equals(1),
      );
    });

    test('Enqueuing multiple tracks adds all non-duplicates', () {
      final controller = DownloadController();

      controller.enqueueTracks([dummyTrack1, dummyTrack2]);

      expect(
        controller.state.queue.length + controller.state.active.length,
        equals(2),
      );
    });

    test('Cancelling task removes it from queue/active list', () {
      final controller = DownloadController();
      controller.enqueueTrack(dummyTrack1);

      final taskId = controller.state.queue.isNotEmpty
          ? controller.state.queue.first.id
          : controller.state.active.first.id;

      controller.cancelTask(taskId);

      expect(controller.state.queue.isEmpty, isTrue);
      expect(controller.state.active.isEmpty, isTrue);
    });

    test('Clear completed clears the finished history', () {
      final controller = DownloadController();
      controller.state = controller.state.copyWith(
        completed: [
          DownloadTask(
            id: 'comp_1',
            track: dummyTrack1,
            status: DownloadStatus.completed,
            createdAt: DateTime.now(),
          ),
        ],
      );

      expect(controller.state.completed.length, equals(1));
      controller.clearCompleted();
      expect(controller.state.completed.isEmpty, isTrue);
    });
  });

  group('Track Persistence & Folder Categorization Tests', () {
    test('UnifiedLibraryState.folders categorizes local and cloud tracks accurately', () {
      const localTrack1 = Track(
        id: 'local_1',
        title: 'Song A',
        artist: 'Artist A',
        album: 'Album A',
        duration: Duration(minutes: 3),
        filePath: '/home/user/Music/BaydevHiFi/Artist A - Song A.opus',
      );

      const localTrack2 = Track(
        id: 'local_2',
        title: 'Song B',
        artist: 'Artist B',
        album: 'Album B',
        duration: Duration(minutes: 3),
        filePath: '/home/user/Music/Rock/Artist B - Song B.flac',
      );

      const spotifyTrack = Track(
        id: 'spotify_123',
        title: 'Song C',
        artist: 'Artist C',
        album: 'Album C',
        duration: Duration(minutes: 3),
        remoteUrl: 'spotify://track/123',
      );

      const navidromeTrack = Track(
        id: 'nav_123',
        title: 'Song D',
        artist: 'Artist D',
        album: 'Album D',
        duration: Duration(minutes: 3),
        remoteUrl: 'http://subsonic.local/rest/stream?id=123',
      );

      const state = UnifiedLibraryState(
        tracks: [localTrack1, localTrack2, spotifyTrack, navidromeTrack],
      );

      final folders = state.folders;
      expect(folders.length, equals(4));

      final folderNames = folders.map((f) => f.name).toSet();
      expect(folderNames.contains('BaydevHiFi'), isTrue);
      expect(folderNames.contains('Rock'), isTrue);
      expect(folderNames.contains('Spotify Cloud Library'), isTrue);
      expect(folderNames.contains('Navidrome Cloud Library'), isTrue);

      final bayHifiFolder = folders.firstWhere((f) => f.name == 'BaydevHiFi');
      expect(bayHifiFolder.path, equals('/home/user/Music/BaydevHiFi'));
      expect(bayHifiFolder.tracks.length, equals(1));
      expect(bayHifiFolder.tracks.first.id, equals('local_1'));
    });
  });
}
