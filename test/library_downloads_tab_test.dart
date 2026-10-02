import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baydev_hifi/features/download_manager/domain/download_task.dart';
import 'package:baydev_hifi/features/download_manager/presentation/controllers/download_controller.dart';
import 'package:baydev_hifi/features/download_manager/presentation/controllers/download_state.dart';
import 'package:baydev_hifi/features/download_manager/presentation/tabs/library_downloads_tab.dart';
import 'package:baydev_hifi/features/player/domain/track.dart';

void main() {
  const dummyTrack = Track(
    id: 'track_1',
    title: 'Midnight City',
    artist: 'M83',
    album: 'Hurry Up, We\'re Dreaming',
    duration: Duration(minutes: 4, seconds: 3),
  );

  testWidgets('LibraryDownloadsTab renders empty state when no downloads', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: LibraryDownloadsTab(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('NO DOWNLOADS IN QUEUE'), findsOneWidget);
    expect(find.text('Import from Link'), findsOneWidget);
  });

  testWidgets('LibraryDownloadsTab renders active downloading task', (tester) async {
    final activeTask = DownloadTask(
      id: 'task_1',
      track: dummyTrack,
      status: DownloadStatus.downloading,
      progress: const DownloadProgress(
        downloadedBytes: 2097152,
        totalBytes: 5242880,
        speedBytesPerSec: 1048576,
        fraction: 0.4,
        statusText: 'Downloading stream: 40%',
      ),
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          downloadControllerProvider.overrideWith(
            (ref) => DownloadController()..state = DownloadState(active: [activeTask]),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: LibraryDownloadsTab(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('DOWNLOADING (1)'), findsOneWidget);
    expect(find.text('Midnight City'), findsOneWidget);
    expect(find.text('M83'), findsOneWidget);
    expect(find.text('Downloading stream: 40%'), findsOneWidget);
  });

  testWidgets('LibraryDownloadsTab renders completed task with OFFLINE badge and local path', (tester) async {
    final completedTask = DownloadTask(
      id: 'task_comp_1',
      track: dummyTrack,
      status: DownloadStatus.completed,
      destinationPath: '/home/user/Music/BaydevHiFi/M83 - Midnight City.opus',
      progress: const DownloadProgress(fraction: 1.0, statusText: 'Completed'),
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          downloadControllerProvider.overrideWith(
            (ref) => DownloadController()..state = DownloadState(completed: [completedTask]),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: LibraryDownloadsTab(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('COMPLETED (1)'), findsOneWidget);
    expect(find.text('OFFLINE'), findsOneWidget);
    expect(find.text('Midnight City'), findsOneWidget);
    expect(find.byTooltip('Play Now'), findsOneWidget);
  });
}
