import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_haptics.dart';

/// Reusable Studio Rackmount Unit Frame with collapsible minimization
class RackUnitCard extends ConsumerStatefulWidget {
  const RackUnitCard({
    super.key,
    required this.unitNumber,
    required this.title,
    required this.subtitle,
    required this.isActive,
    required this.onToggle,
    required this.content,
    this.accentColor,
    this.headerTrailing,
    this.initiallyExpanded,
  });

  final String unitNumber;
  final String title;
  final String subtitle;
  final bool isActive;
  final VoidCallback onToggle;
  final Widget content;
  final Color? accentColor;
  final Widget? headerTrailing;
  final bool? initiallyExpanded;

  @override
  ConsumerState<RackUnitCard> createState() => _RackUnitCardState();
}

class _RackUnitCardState extends ConsumerState<RackUnitCard> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded ?? widget.isActive;
  }

  @override
  void didUpdateWidget(covariant RackUnitCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _isExpanded = true;
    }
  }

  void _toggleExpanded() {
    AppHaptics.selectionClick();
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = widget.accentColor ?? theme.colorScheme.primary;

    final chassisBg = const Color(0xFF16181F);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: chassisBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF262936),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Rack Mount Header Strip (Tap to Expand/Collapse)
          InkWell(
            onTap: _toggleExpanded,
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(15),
              bottom: _isExpanded ? Radius.zero : const Radius.circular(15),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1E212B),
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(15),
                  bottom: _isExpanded ? Radius.zero : const Radius.circular(15),
                ),
              ),
              child: Row(
                children: [
                  // Faux Rack Screw
                  _buildScrew(isDark),
                  const SizedBox(width: 10),

                  // Unit Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: widget.isActive
                          ? const Color(0xFF252834)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                      border: widget.isActive
                          ? Border.all(
                              color: const Color(0xFF383D50),
                              width: 0.8,
                            )
                          : null,
                    ),
                    child: Text(
                      widget.unitNumber,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: widget.isActive ? Colors.white : (isDark ? Colors.white54 : Colors.black54),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Unit Titles
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.title.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: widget.isActive
                                ? Colors.white
                                : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          widget.subtitle,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF94A3B8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  if (widget.headerTrailing != null) ...[
                    widget.headerTrailing!,
                    const SizedBox(width: 6),
                  ],

                  // Studio Power Toggle with LED
                  InkWell(
                    onTap: widget.onToggle,
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.isActive
                            ? const Color(0xFF252834)
                            : const Color(0xFF16181F),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: widget.isActive
                              ? const Color(0xFF383D50)
                              : const Color(0xFF262936),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // LED Light (Solid dot, zero neon halo blur)
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: widget.isActive ? color : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            widget.isActive ? 'ON' : 'BYPASS',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              color: widget.isActive ? Colors.white : const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 6),

                  // Expand / Collapse Chevron Indicator
                  Icon(
                    _isExpanded
                        ? LucideIcons.chevronUp
                        : LucideIcons.chevronDown,
                    size: 14,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),

                  const SizedBox(width: 8),
                  // Faux Rack Screw
                  _buildScrew(isDark),
                ],
              ),
            ),
          ),

          // Collapsible Rack Unit Body
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            child: _isExpanded
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: widget.isActive ? 1.0 : 0.6,
                      child: widget.content,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildScrew(bool isDark) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? const Color(0xFF2C3240) : const Color(0xFFCFD5E1),
      ),
      child: Center(
        child: Container(
          width: 6,
          height: 1.2,
          color: isDark ? Colors.white30 : Colors.black38,
        ),
      ),
    );
  }
}
