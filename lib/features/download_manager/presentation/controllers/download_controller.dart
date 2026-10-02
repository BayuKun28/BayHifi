import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:baydev_hifi/app/theme/app_haptics.dart';
import 'package:baydev_hifi/features/player/domain/track.dart';
import 'package:baydev_hifi/features/download_manager/data/native_download_service.dart';
import 'package:baydev_hifi/features/download_manager/domain/download_task.dart';
import 'package:baydev_hifi/features/download_manager/presentation/controllers/download_state.dart';
import 'package:baydev_hifi/features/library/presentation/controllers/library_controller.dart';

final downloadControllerProvider =
    StateNotifierProvider<DownloadController, DownloadState>((ref) {
  return DownloadController(ref: ref);
});

class DownloadController extends StateNotifier<DownloadState> {
  DownloadController({this.ref}) : super(const DownloadState());

  final Ref? ref;
  final NativeDownloadService _service = NativeDownloadService.instance;
  final Map<String, CancellationToken> _activeTokens = {};

  /// Enqueues a single track for download
  void enqueueTrack(Track track) {
    // Prevent duplicate enqueuing
    final existing = state.queue.any((t) => t.track.id == track.id) ||
        state.active.any((t) => t.track.id == track.id);
    if (existing) {
      debugPrint('[DownloadController] Track already in queue/active: ${track.title}');
      return;
    }

    final task = DownloadTask(
      id: 'task_${DateTime.now().millisecondsSinceEpoch}_${track.id}',
      track: track,
      status: DownloadStatus.pending,
      createdAt: DateTime.now(),
    );

    state = state.copyWith(queue: [...state.queue, task]);
    AppHaptics.selectionClick();
    _processNext();
  }

  /// Enqueues multiple tracks (e.g., from an imported playlist or album)
  void enqueueTracks(List<Track> tracks) {
    final newTasks = <DownloadTask>[];
    for (final track in tracks) {
      final existing = state.queue.any((t) => t.track.id == track.id) ||
          state.active.any((t) => t.track.id == track.id);
      if (!existing) {
        newTasks.add(
          DownloadTask(
            id: 'task_${DateTime.now().microsecondsSinceEpoch}_${track.id}',
            track: track,
            status: DownloadStatus.pending,
            createdAt: DateTime.now(),
          ),
        );
      }
    }

    if (newTasks.isNotEmpty) {
      state = state.copyWith(queue: [...state.queue, ...newTasks]);
      AppHaptics.lightImpact();
      _processNext();
    }
  }

  /// Cancels an active or queued download task
  void cancelTask(String taskId) {
    _activeTokens[taskId]?.cancel();
    _activeTokens.remove(taskId);

    final updatedQueue = state.queue.where((t) => t.id != taskId).toList();
    final updatedActive = state.active.where((t) => t.id != taskId).toList();

    state = state.copyWith(
      queue: updatedQueue,
      active: updatedActive,
    );
    AppHaptics.selectionClick();
    _processNext();
  }

  /// Retries a failed download task
  void retryTask(String taskId) {
    final failedTask = state.failed.firstWhere((t) => t.id == taskId);
    final updatedFailed = state.failed.where((t) => t.id != taskId).toList();

    final resetTask = failedTask.copyWith(
      status: DownloadStatus.pending,
      progress: const DownloadProgress(),
      errorMessage: null,
    );

    state = state.copyWith(
      failed: updatedFailed,
      queue: [...state.queue, resetTask],
    );
    _processNext();
  }

  /// Clears completed download history
  void clearCompleted() {
    state = state.copyWith(completed: const []);
    AppHaptics.selectionClick();
  }

  /// Drains and processes queued tasks concurrently up to maxConcurrent limit
  Future<void> _processNext() async {
    if (state.active.length >= state.maxConcurrent || state.queue.isEmpty) {
      return;
    }

    final taskToStart = state.queue.first;
    final remainingQueue = state.queue.sublist(1);

    final activeTask = taskToStart.copyWith(status: DownloadStatus.downloading);
    final token = CancellationToken();
    _activeTokens[taskToStart.id] = token;

    state = state.copyWith(
      queue: remainingQueue,
      active: [...state.active, activeTask],
    );

    _executeDownload(activeTask, token);
    _processNext(); // Check if another concurrent slot is available
  }

  Future<void> _executeDownload(DownloadTask task, CancellationToken token) async {
    try {
      final downloadedTrack = await _service.downloadTrack(
        track: task.track,
        cancellationToken: token,
        onProgress: (prog) {
          if (!mounted) return;
          final updatedActive = state.active.map((t) {
            if (t.id == task.id) {
              return t.copyWith(
                status: DownloadStatus.downloading,
                progress: prog,
              );
            }
            return t;
          }).toList();
          state = state.copyWith(active: updatedActive);
        },
      );

      _activeTokens.remove(task.id);
      final completedTask = task.copyWith(
        track: downloadedTrack,
        status: DownloadStatus.completed,
        destinationPath: downloadedTrack.filePath,
        fileSize: downloadedTrack.fileSize,
        completedAt: DateTime.now(),
        progress: const DownloadProgress(fraction: 1.0, statusText: 'Completed'),
      );

      try {
        ref?.read(unifiedLibraryProvider.notifier).updateTrack(downloadedTrack);
      } catch (e) {
        debugPrint('[DownloadController] Update library notice: $e');
      }

      final updatedActive = state.active.where((t) => t.id != task.id).toList();
      state = state.copyWith(
        active: updatedActive,
        completed: [completedTask, ...state.completed],
      );

      AppHaptics.lightImpact();
    } catch (e) {
      _activeTokens.remove(task.id);
      final failedTask = task.copyWith(
        status: DownloadStatus.failed,
        errorMessage: e.toString(),
      );

      final updatedActive = state.active.where((t) => t.id != task.id).toList();
      state = state.copyWith(
        active: updatedActive,
        failed: [failedTask, ...state.failed],
      );
    } finally {
      _processNext();
    }
  }
}
