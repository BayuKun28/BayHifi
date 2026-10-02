import 'package:flutter/foundation.dart';
import '../../domain/download_task.dart';

@immutable
class DownloadState {
  final List<DownloadTask> queue;
  final List<DownloadTask> active;
  final List<DownloadTask> completed;
  final List<DownloadTask> failed;
  final bool isProcessing;
  final int maxConcurrent;

  const DownloadState({
    this.queue = const [],
    this.active = const [],
    this.completed = const [],
    this.failed = const [],
    this.isProcessing = false,
    this.maxConcurrent = 2,
  });

  int get totalActiveCount => queue.length + active.length;
  bool get hasActiveDownloads => totalActiveCount > 0;

  double get overallProgress {
    if (active.isEmpty) return 0.0;
    final totalFractions = active.fold<double>(0.0, (sum, t) => sum + t.progress.fraction);
    return (totalFractions / active.length).clamp(0.0, 1.0);
  }

  DownloadState copyWith({
    List<DownloadTask>? queue,
    List<DownloadTask>? active,
    List<DownloadTask>? completed,
    List<DownloadTask>? failed,
    bool? isProcessing,
    int? maxConcurrent,
  }) {
    return DownloadState(
      queue: queue ?? this.queue,
      active: active ?? this.active,
      completed: completed ?? this.completed,
      failed: failed ?? this.failed,
      isProcessing: isProcessing ?? this.isProcessing,
      maxConcurrent: maxConcurrent ?? this.maxConcurrent,
    );
  }
}
