import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import '../../features/player/presentation/controllers/player_controller.dart';
import '../../features/player/presentation/widgets/now_playing_queue_sheet.dart';
import '../../features/pro_q_studio/presentation/pro_q_studio_screen.dart';
import 'desktop_lyrics_dialog.dart';
import 'desktop_window_service.dart';

/// Widget pembungkus tingkat atas untuk menangkap pintasan keyboard studio pada platform Desktop.
/// Terisolasi aman: hanya memproses event tombol fisik dan mengabaikan saat pengguna mengetik di input text field.
class DesktopShortcutsDispatcher extends ConsumerStatefulWidget {
  final Widget child;
  final VoidCallback? onSearchRequested;

  const DesktopShortcutsDispatcher({
    super.key,
    required this.child,
    this.onSearchRequested,
  });

  @override
  ConsumerState<DesktopShortcutsDispatcher> createState() => _DesktopShortcutsDispatcherState();
}

class _DesktopShortcutsDispatcherState extends ConsumerState<DesktopShortcutsDispatcher> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  bool _isTyping(BuildContext context) {
    final focused = FocusManager.instance.primaryFocus;
    if (focused == null) return false;
    final focusedContext = focused.context;
    if (focusedContext == null) return false;

    // 1. Direct widget type inspection
    final widget = focusedContext.widget;
    if (widget is EditableText || widget is TextField || widget is TextFormField) {
      return true;
    }

    // 2. Ancestor state & widget inspection
    if (focusedContext.findAncestorStateOfType<EditableTextState>() != null) {
      return true;
    }
    if (focusedContext.findAncestorWidgetOfExactType<EditableText>() != null ||
        focusedContext.findAncestorWidgetOfExactType<TextField>() != null ||
        focusedContext.findAncestorWidgetOfExactType<TextFormField>() != null) {
      return true;
    }

    // 3. FocusNode debug label inspection
    final debugLabel = focused.debugLabel?.toLowerCase() ?? '';
    if (debugLabel.contains('editabletext') ||
        debugLabel.contains('textfield') ||
        debugLabel.contains('textformfield')) {
      return true;
    }

    return false;
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (kIsWeb || (!Platform.isLinux && !Platform.isWindows && !Platform.isMacOS)) {
      return KeyEventResult.ignored;
    }

    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    // Jika sedang fokus pada text field input, biarkan ketikan normal
    if (_isTyping(context)) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;
    final isCtrl = HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;
    final isShift = HardwareKeyboard.instance.isShiftPressed;

    final playerCtrl = ref.read(playerControllerProvider.notifier);
    final playback = ref.read(playerControllerProvider);

    // 1. SPACE: Toggle Play / Pause
    if (key == LogicalKeyboardKey.space) {
      playerCtrl.togglePlayPause();
      return KeyEventResult.handled;
    }

    // 2. CTRL + LEFT: Previous Track
    if (isCtrl && key == LogicalKeyboardKey.arrowLeft) {
      playerCtrl.skipPrevious();
      return KeyEventResult.handled;
    }

    // 3. CTRL + RIGHT: Next Track
    if (isCtrl && key == LogicalKeyboardKey.arrowRight) {
      playerCtrl.skipNext();
      return KeyEventResult.handled;
    }

    // 4. ARROW LEFT: Seek Backward (5s / 15s with Shift)
    if (key == LogicalKeyboardKey.arrowLeft && !isCtrl) {
      final delta = isShift ? 15 : 5;
      final target = playback.position - Duration(seconds: delta);
      playerCtrl.seek(target < Duration.zero ? Duration.zero : target);
      return KeyEventResult.handled;
    }

    // 5. ARROW RIGHT: Seek Forward (5s / 15s with Shift)
    if (key == LogicalKeyboardKey.arrowRight && !isCtrl) {
      final delta = isShift ? 15 : 5;
      final target = playback.position + Duration(seconds: delta);
      final max = playback.duration;
      playerCtrl.seek(target > max ? max : target);
      return KeyEventResult.handled;
    }

    // 6. ARROW UP: Volume Up (+5%)
    if (key == LogicalKeyboardKey.arrowUp) {
      final cur = playback.volume;
      playerCtrl.setVolume((cur + 0.05).clamp(0.0, 1.0));
      return KeyEventResult.handled;
    }

    // 7. ARROW DOWN: Volume Down (-5%)
    if (key == LogicalKeyboardKey.arrowDown) {
      final cur = playback.volume;
      playerCtrl.setVolume((cur - 0.05).clamp(0.0, 1.0));
      return KeyEventResult.handled;
    }

    // 8. KEY M: Toggle Mute
    if (key == LogicalKeyboardKey.keyM) {
      if (playback.volume > 0.0) {
        playerCtrl.setVolume(0.0);
      } else {
        playerCtrl.setVolume(1.0);
      }
      return KeyEventResult.handled;
    }

    // 9. KEY L: Toggle Synchronized Lyrics Modal
    if (key == LogicalKeyboardKey.keyL) {
      DesktopLyricsDialog.show(context, playback.currentTrack);
      return KeyEventResult.handled;
    }

    // 10. KEY Q: Toggle Up Next Queue Modal
    if (key == LogicalKeyboardKey.keyQ) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const NowPlayingQueueSheet(),
      );
      return KeyEventResult.handled;
    }

    // 11. KEY E: Open Pro-Q Studio Screen
    if (key == LogicalKeyboardKey.keyE) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ProQStudioScreen()),
      );
      return KeyEventResult.handled;
    }

    // 12. CTRL + F / SLASH: Search Focus
    if ((isCtrl && key == LogicalKeyboardKey.keyF) || key == LogicalKeyboardKey.slash) {
      widget.onSearchRequested?.call();
      return KeyEventResult.handled;
    }

    // 13. F11: Toggle Fullscreen
    if (key == LogicalKeyboardKey.f11) {
      DesktopWindowService.instance.toggleFullScreen();
      return KeyEventResult.handled;
    }

    // 14. QUESTION MARK / CTRL + SLASH: Cheatsheet Dialog
    if (key == LogicalKeyboardKey.question || (isCtrl && key == LogicalKeyboardKey.slash)) {
      showDesktopShortcutsCheatsheet(context);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: widget.child,
    );
  }
}

/// Menampilkan Modal Cheatsheet Pintasan Keyboard Studio M3 Expressive
void showDesktopShortcutsCheatsheet(BuildContext context) {
  final theme = Theme.of(context);

  final shortcuts = [
    {'keys': 'Space', 'desc': 'Toggle Play / Pause'},
    {'keys': '← / →', 'desc': 'Seek -5s / +5s (Shift for 15s)'},
    {'keys': 'Ctrl + ← / →', 'desc': 'Previous / Next Track'},
    {'keys': '↑ / ↓', 'desc': 'Volume Up / Down (+5% / -5%)'},
    {'keys': 'M', 'desc': 'Mute / Unmute Audio'},
    {'keys': 'L', 'desc': 'Open Synchronized Lyrics Modal'},
    {'keys': 'Q', 'desc': 'Open Up Next Queue Modal'},
    {'keys': 'E', 'desc': 'Open Pro-Q Studio & DSP Rack'},
    {'keys': 'Ctrl + F / /', 'desc': 'Focus Library Search Bar'},
    {'keys': 'F11', 'desc': 'Toggle Fullscreen Mode'},
    {'keys': 'Esc', 'desc': 'Close Dialogs / Exit Fullscreen'},
  ];

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: theme.colorScheme.surface,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedKeyboard,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Studio Keyboard Shortcuts',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: shortcuts.map((s) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.25),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      s['keys']!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      s['desc']!,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          ),
        ),
      ),
      actions: [
        M3EButton(
          label: const Text('Got it'),
          style: M3EButtonStyle.tonal,
          onPressed: () => Navigator.of(ctx).pop(),
        ),
      ],
    ),
  );
}
