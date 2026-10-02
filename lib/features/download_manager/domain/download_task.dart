import 'package:flutter/foundation.dart';
import '../../player/domain/track.dart';

enum DownloadStatus {
  pending('Pending'),
  matching('Matching Audio Source'),
  downloading('Downloading Stream'),
  tagging('Embedding Studio Tags'),
  completed('Completed'),
  failed('Failed'),
  paused('Paused'),
  cancelled('Cancelled');

  final String label;
  const DownloadStatus(this.label);

  bool get isActive =>
      this == DownloadStatus.pending ||
      this == DownloadStatus.matching ||
      this == DownloadStatus.downloading ||
      this == DownloadStatus.tagging;

  bool get isFinished =>
      this == DownloadStatus.completed ||
      this == DownloadStatus.failed ||
      this == DownloadStatus.cancelled;
}

@immutable
class DownloadProgress {
  final int downloadedBytes;
  final int totalBytes;
  final double speedBytesPerSec;
  final double fraction; // 0.0 to 1.0
  final String statusText;

  const DownloadProgress({
    this.downloadedBytes = 0,
    this.totalBytes = 0,
    this.speedBytesPerSec = 0.0,
    this.fraction = 0.0,
    this.statusText = '',
  });

  String get speedFormatted {
    if (speedBytesPerSec <= 0) return '';
    if (speedBytesPerSec >= 1024 * 1024) {
      return '${(speedBytesPerSec / (1024 * 1024)).toStringAsFixed(1)} MB/s';
    }
    return '${(speedBytesPerSec / 1024).toStringAsFixed(0)} KB/s';
  }

  String get sizeFormatted {
    if (totalBytes <= 0) return '';
    final downMb = (downloadedBytes / (1024 * 1024)).toStringAsFixed(1);
    final totalMb = (totalBytes / (1024 * 1024)).toStringAsFixed(1);
    return '$downMb MB / $totalMb MB';
  }
}

@immutable
class DownloadTask {
  final String id;
  final Track track;
  final DownloadStatus status;
  final DownloadProgress progress;
  final String? destinationPath;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime? completedAt;
  final int? fileSize;
  final String? matchedVideoId;

  const DownloadTask({
    required this.id,
    required this.track,
    this.status = DownloadStatus.pending,
    this.progress = const DownloadProgress(),
    this.destinationPath,
    this.errorMessage,
    required this.createdAt,
    this.completedAt,
    this.fileSize,
    this.matchedVideoId,
  });

  DownloadTask copyWith({
    Track? track,
    DownloadStatus? status,
    DownloadProgress? progress,
    String? destinationPath,
    String? errorMessage,
    DateTime? completedAt,
    int? fileSize,
    String? matchedVideoId,
  }) {
    return DownloadTask(
      id: id,
      track: track ?? this.track,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      destinationPath: destinationPath ?? this.destinationPath,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
      fileSize: fileSize ?? this.fileSize,
      matchedVideoId: matchedVideoId ?? this.matchedVideoId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'track': track.toMap(),
      'status': status.name,
      'destinationPath': destinationPath,
      'errorMessage': errorMessage,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'fileSize': fileSize,
      'matchedVideoId': matchedVideoId,
    };
  }

  factory DownloadTask.fromJson(Map<String, dynamic> json) {
    return DownloadTask(
      id: json['id'] as String,
      track: Track.fromMap(Map<String, dynamic>.from(json['track'] as Map)),
      status: DownloadStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => DownloadStatus.completed,
      ),
      destinationPath: json['destinationPath'] as String?,
      errorMessage: json['errorMessage'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'] as String)
          : null,
      fileSize: json['fileSize'] as int?,
      matchedVideoId: json['matchedVideoId'] as String?,
    );
  }
}
