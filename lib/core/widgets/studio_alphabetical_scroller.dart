import 'package:flutter/material.dart';
import '../../app/theme/app_haptics.dart';

/// Studio Alphabetical Fast-Scroller & Context-Aware Scrollbar
///
/// Features:
/// 1. Alphabetical Mode (`isAlphabetical == true`):
///    - Displays an interactive A-Z and # rail along the right edge.
///    - Tap or drag smoothly jumps to corresponding items with haptic feedback.
///    - Displays a floating studio letter indicator bubble during drag.
///    - Syncs visible letter highlighting with normal scroll events.
/// 2. Standard Scrollbar Mode (`isAlphabetical == false`):
///    - Displays a sleek Studio Material 3 scrollbar with rounded pill thumb.
class StudioAlphabeticalScroller extends StatefulWidget {
  final ScrollController scrollController;
  final int itemCount;
  final double itemHeight;
  final bool isAlphabetical;
  final String Function(int index) letterSelector;
  final Widget child;
  final EdgeInsets padding;

  const StudioAlphabeticalScroller({
    super.key,
    required this.scrollController,
    required this.itemCount,
    this.itemHeight = 72.0,
    required this.isAlphabetical,
    required this.letterSelector,
    required this.child,
    this.padding = EdgeInsets.zero,
  });

  static const List<String> defaultAlphabet = [
    '#',
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J',
    'K',
    'L',
    'M',
    'N',
    'O',
    'P',
    'Q',
    'R',
    'S',
    'T',
    'U',
    'V',
    'W',
    'X',
    'Y',
    'Z',
  ];

  static String extractLeadingLetter(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return '#';
    final first = trimmed[0].toUpperCase();
    if (RegExp(r'^[A-Z]$').hasMatch(first)) {
      return first;
    }
    return '#';
  }

  @override
  State<StudioAlphabeticalScroller> createState() => _StudioAlphabeticalScrollerState();
}

class _StudioAlphabeticalScrollerState extends State<StudioAlphabeticalScroller> {
  final GlobalKey _railKey = GlobalKey();
  bool _isDragging = false;
  String? _activeLetter;
  final Map<String, int> _letterMap = {};

  @override
  void initState() {
    super.initState();
    _rebuildLetterMap();
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant StudioAlphabeticalScroller oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController.removeListener(_onScroll);
      widget.scrollController.addListener(_onScroll);
    }
    if (oldWidget.itemCount != widget.itemCount ||
        oldWidget.isAlphabetical != widget.isAlphabetical) {
      _rebuildLetterMap();
    }
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _rebuildLetterMap() {
    _letterMap.clear();
    if (!widget.isAlphabetical || widget.itemCount == 0) return;

    for (int i = 0; i < widget.itemCount; i++) {
      final letter = StudioAlphabeticalScroller.extractLeadingLetter(
        widget.letterSelector(i),
      );
      if (!_letterMap.containsKey(letter)) {
        _letterMap[letter] = i;
      }
    }
  }

  void _onScroll() {
    if (_isDragging || !widget.isAlphabetical || widget.itemCount == 0) return;
    if (!widget.scrollController.hasClients) return;

    final offset = widget.scrollController.offset;
    final index = (offset / widget.itemHeight).floor().clamp(0, widget.itemCount - 1);
    final letter = StudioAlphabeticalScroller.extractLeadingLetter(
      widget.letterSelector(index),
    );

    if (_activeLetter != letter) {
      setState(() {
        _activeLetter = letter;
      });
    }
  }

  void _handleRailTouch(Offset localPosition) {
    final railBox = _railKey.currentContext?.findRenderObject() as RenderBox?;
    final totalHeight = railBox?.size.height ?? 0;
    if (totalHeight <= 0 || widget.itemCount == 0) return;

    final alphabet = StudioAlphabeticalScroller.defaultAlphabet;
    final ratio = (localPosition.dy / totalHeight).clamp(0.0, 0.9999);
    final letterIndex = (ratio * alphabet.length).floor().clamp(0, alphabet.length - 1);
    final letter = alphabet[letterIndex];

    if (_activeLetter != letter) {
      AppHaptics.selectionClick();
      setState(() {
        _activeLetter = letter;
      });
      _scrollToLetter(letter);
    }
  }

  void _scrollToLetter(String letter) {
    if (!widget.scrollController.hasClients || widget.itemCount == 0) return;

    int? targetIndex = _letterMap[letter];

    // If letter has no direct match, find nearest available letter
    if (targetIndex == null) {
      final alphabet = StudioAlphabeticalScroller.defaultAlphabet;
      final targetAlphabetIdx = alphabet.indexOf(letter);

      int minDistance = 999;
      for (final entry in _letterMap.entries) {
        final entryIdx = alphabet.indexOf(entry.key);
        if (entryIdx != -1) {
          final dist = (entryIdx - targetAlphabetIdx).abs();
          if (dist < minDistance) {
            minDistance = dist;
            targetIndex = entry.value;
          }
        }
      }
    }

    if (targetIndex != null) {
      final maxScroll = widget.scrollController.position.maxScrollExtent;
      final targetOffset = (targetIndex * widget.itemHeight).clamp(0.0, maxScroll);
      widget.scrollController.jumpTo(targetOffset);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    if (!widget.isAlphabetical) {
      return Theme(
        data: theme.copyWith(
          scrollbarTheme: ScrollbarThemeData(
            thumbColor: WidgetStatePropertyAll(primary.withValues(alpha: 0.5)),
            trackColor: WidgetStatePropertyAll(Colors.white.withValues(alpha: 0.04)),
            trackBorderColor: const WidgetStatePropertyAll(Colors.transparent),
            radius: const Radius.circular(8),
            thickness: const WidgetStatePropertyAll(4.5),
            minThumbLength: 36,
          ),
        ),
        child: Scrollbar(
          controller: widget.scrollController,
          thumbVisibility: true,
          interactive: true,
          child: widget.child,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // ─── 1. MAIN SCROLLABLE CONTENT ─────────────────────────────────
            widget.child,

            // ─── 2. ALPHABET RAIL (RIGHT EDGE) ──────────────────────────────
            Positioned(
              right: 2,
              top: widget.padding.top + 8,
              bottom: widget.padding.bottom + 8,
              width: 22,
              child: GestureDetector(
                key: _railKey,
                behavior: HitTestBehavior.opaque,
                onVerticalDragStart: (details) {
                  setState(() => _isDragging = true);
                  _handleRailTouch(details.localPosition);
                },
                onVerticalDragUpdate: (details) {
                  _handleRailTouch(details.localPosition);
                },
                onVerticalDragEnd: (_) {
                  setState(() => _isDragging = false);
                },
                onVerticalDragCancel: () {
                  setState(() => _isDragging = false);
                },
                onTapDown: (details) {
                  setState(() => _isDragging = true);
                  _handleRailTouch(details.localPosition);
                },
                onTapUp: (_) {
                  Future.delayed(const Duration(milliseconds: 300), () {
                    if (mounted) setState(() => _isDragging = false);
                  });
                },
                onTapCancel: () {
                  setState(() => _isDragging = false);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainer.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: StudioAlphabeticalScroller.defaultAlphabet.map((letter) {
                      final hasTracks = _letterMap.containsKey(letter);
                      final isSelected = _activeLetter == letter;

                      return Expanded(
                        child: Center(
                          child: Text(
                            letter,
                            style: TextStyle(
                              fontSize: 9.0,
                              fontWeight: isSelected
                                  ? FontWeight.w900
                                  : (hasTracks ? FontWeight.w700 : FontWeight.w500),
                              color: isSelected
                                  ? primary
                                  : (hasTracks
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF475569).withValues(alpha: 0.5)),
                              height: 1.0,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),

            // ─── 3. FLOATING STUDIO LETTER BUBBLE INDICATOR ─────────────────
            if (_isDragging && _activeLetter != null)
              Positioned(
                right: 38,
                top: (constraints.maxHeight / 2) - 30,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.6),
                        blurRadius: 18,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _activeLetter!,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: primary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
