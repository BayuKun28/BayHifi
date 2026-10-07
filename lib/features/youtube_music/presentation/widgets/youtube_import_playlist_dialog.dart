import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../../../app/theme/app_haptics.dart';
import '../../../player/presentation/controllers/player_controller.dart';
import '../controllers/youtube_music_controller.dart';

/// Studio Material 3 dialog for importing and playing YouTube & YouTube Music playlists.
class YouTubeImportPlaylistDialog extends ConsumerStatefulWidget {
  const YouTubeImportPlaylistDialog({super.key});

  @override
  ConsumerState<YouTubeImportPlaylistDialog> createState() =>
      _YouTubeImportPlaylistDialogState();
}

class _YouTubeImportPlaylistDialogState
    extends ConsumerState<YouTubeImportPlaylistDialog> {
  final _urlController = TextEditingController();
  bool _isLoading = false;
  String? _statusText;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    AppHaptics.selectionClick();
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      setState(() {
        _urlController.text = data.text!.trim();
      });
    }
  }

  Future<void> _importPlaylist({required bool autoPlay}) async {
    final input = _urlController.text.trim();
    if (input.isEmpty) return;

    AppHaptics.lightImpact();
    setState(() {
      _isLoading = true;
      _statusText = 'Importing playlist tracks...';
    });

    final controller = ref.read(youtubeMusicControllerProvider.notifier);
    final tracks = await controller.importPlaylist(input);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (tracks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No tracks found or invalid playlist URL/ID.'),
        ),
      );
      return;
    }

    if (autoPlay) {
      await ref.read(playerControllerProvider.notifier).setQueue(tracks, initialIndex: 0);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imported and playing ${tracks.length} tracks.'),
          ),
        );
      }
    } else {
      for (final t in tracks) {
        ref.read(playerControllerProvider.notifier).addToQueue(t);
      }
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${tracks.length} tracks to queue.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Icon & Title
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedPlayList,
                      size: 22,
                      color: primary,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'IMPORT PLAYLIST',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'YouTube & YouTube Music',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Paste a YouTube or YouTube Music playlist link or ID to stream with Baydev HiFi DSP mastering.',
              style: TextStyle(
                fontSize: 12.5,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            // URL Input Field
            TextField(
              controller: _urlController,
              enabled: !_isLoading,
              decoration: InputDecoration(
                hintText: 'https://music.youtube.com/playlist?list=...',
                hintStyle: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_urlController.text.isNotEmpty)
                      M3EIconButton(
                        icon: const HugeIcon(
                          icon: HugeIcons.strokeRoundedCancel01,
                          size: 16,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _urlController.clear();
                          });
                        },
                      ),
                    M3EIconButton(
                      icon: HugeIcon(
                        icon: HugeIcons.strokeRoundedClipboard,
                        size: 18,
                        color: primary,
                      ),
                      tooltip: 'Paste from Clipboard',
                      onPressed: _pasteFromClipboard,
                    ),
                  ],
                ),
              ),
              style: const TextStyle(fontSize: 13),
              onChanged: (_) => setState(() {}),
            ),
            if (_isLoading) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: M3EProgressIndicator.circular(
                      strokeWidth: 2,
                      color: primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _statusText ?? 'Importing...',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            // Action Buttons
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                M3EButton.text(
                  onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                M3EButton.outlined(
                  onPressed: _isLoading || _urlController.text.trim().isEmpty
                      ? null
                      : () => _importPlaylist(autoPlay: false),
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedQueue01,
                    size: 16,
                    color: null,
                  ),
                  label: const Text('Add to Queue'),
                ),
                M3EButton.filled(
                  onPressed: _isLoading || _urlController.text.trim().isEmpty
                      ? null
                      : () => _importPlaylist(autoPlay: true),
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedPlay,
                    size: 16,
                    color: null,
                  ),
                  label: const Text('Play All'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
