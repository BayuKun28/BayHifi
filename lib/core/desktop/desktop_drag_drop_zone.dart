import 'dart:io';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../features/library/data/local_audio_scanner.dart';
import '../../features/player/domain/track.dart';
import '../../features/player/presentation/controllers/player_controller.dart';

/// Handler Desktop Drag-and-Drop untuk mengimpor file audio atau folder musik
/// langsung dari File Manager Linux/Desktop ke pemutar musik Baydev HiFi.
class DesktopDragDropZone extends ConsumerStatefulWidget {
  final Widget child;

  const DesktopDragDropZone({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<DesktopDragDropZone> createState() => _DesktopDragDropZoneState();
}

class _DesktopDragDropZoneState extends ConsumerState<DesktopDragDropZone> {
  bool _isDragging = false;
  final LocalAudioScanner _scanner = const LocalAudioScanner();

  bool _isSupportedAudio(String path) {
    final dotIdx = path.lastIndexOf('.');
    if (dotIdx == -1 || dotIdx >= path.length - 1) return false;
    final ext = path.substring(dotIdx + 1).toLowerCase();
    return LocalAudioScanner.supportedExtensions.contains(ext);
  }

  Future<void> _handleDroppedFiles(List<String> paths) async {
    final List<File> audioFiles = [];

    for (final p in paths) {
      final type = FileSystemEntity.typeSync(p);
      if (type == FileSystemEntityType.file) {
        if (_isSupportedAudio(p)) {
          audioFiles.add(File(p));
        }
      } else if (type == FileSystemEntityType.directory) {
        final dir = Directory(p);
        try {
          final entities = dir.listSync(recursive: true);
          for (final entity in entities) {
            if (entity is File && _isSupportedAudio(entity.path)) {
              audioFiles.add(entity);
            }
          }
        } catch (e) {
          debugPrint('[DesktopDragDropZone] Error scanning dropped directory: $e');
        }
      }
    }

    if (audioFiles.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No supported audio files found in dropped items.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    // Bangun list Track
    final List<Track> tracks = [];
    for (final file in audioFiles) {
      try {
        final parsed = await _scanner.parseFile(file);
        if (parsed != null) {
          tracks.add(parsed);
        } else {
          final fileName = file.uri.pathSegments.last;
          tracks.add(
            Track(
              id: file.path,
              title: fileName.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), ''),
              artist: 'Local File',
              album: 'Dropped Items',
              filePath: file.path,
              duration: Duration.zero,
            ),
          );
        }
      } catch (_) {
        final fileName = file.uri.pathSegments.last;
        tracks.add(
          Track(
            id: file.path,
            title: fileName.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), ''),
            artist: 'Local File',
            album: 'Dropped Items',
            filePath: file.path,
            duration: Duration.zero,
          ),
        );
      }
    }

    if (tracks.isNotEmpty && mounted) {
      final messenger = ScaffoldMessenger.of(context);
      final playerCtrl = ref.read(playerControllerProvider.notifier);
      // Mainkan lagu pertama dan tambahkan sisanya ke antrean
      await playerCtrl.setQueue(tracks, initialIndex: 0);
      await playerCtrl.playTrack(tracks.first);

      messenger.showSnackBar(
        SnackBar(
          content: Text('Loaded ${tracks.length} track${tracks.length > 1 ? 's' : ''} to queue.'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || (!Platform.isLinux && !Platform.isWindows && !Platform.isMacOS)) {
      return widget.child;
    }

    final theme = Theme.of(context);

    return DropTarget(
      onDragEntered: (_) => setState(() => _isDragging = true),
      onDragExited: (_) => setState(() => _isDragging = false),
      onDragDone: (details) async {
        setState(() => _isDragging = false);
        final paths = details.files.map((f) => f.path).toList();
        await _handleDroppedFiles(paths);
      },
      child: Stack(
        children: [
          widget.child,
          if (_isDragging)
            Positioned.fill(
              child: Container(
                color: theme.colorScheme.surface.withValues(alpha: 0.88),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 28),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: theme.colorScheme.primary,
                        width: 2.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(alpha: 0.25),
                          blurRadius: 30,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              LucideIcons.upload,
                              color: theme.colorScheme.primary,
                              size: 32,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Drop Audio Files or Folders Here',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Supported: FLAC, WAV, MP3, OGG, OPUS, M4A, DSD',
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
