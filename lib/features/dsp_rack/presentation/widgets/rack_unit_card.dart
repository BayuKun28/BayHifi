import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../app/theme/studio_surface_theme.dart';

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
    HapticFeedback.selectionClick();
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSolid = ref.isSolidStyle;
    final color = widget.accentColor ?? theme.colorScheme.primary;

    final chassisBg = StudioSurfaceTheme.surface(context, isSolid: isSolid);
    final borderColor = widget.isActive
        ? (isSolid ? color : color.withValues(alpha: 0.5))
        : StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: chassisBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: widget.isActive ? 1.2 : 1.0),
        boxShadow: isSolid
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
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
                color: StudioSurfaceTheme.surfaceContainer(context, isSolid: isSolid),
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(15),
                  bottom: _isExpanded ? Radius.zero : const Radius.circular(15),
                ),
                border: _isExpanded
                    ? Border(
                        bottom: BorderSide(
                          color: StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid),
                          width: 0.8,
                        ),
                      )
                    : null,
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
                          ? StudioSurfaceTheme.tintedContainer(
                              context,
                              color,
                              isSolid: isSolid,
                              translucentAlpha: 0.2,
                              solidBlendAlpha: 0.2,
                            )
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: widget.isActive
                            ? color
                            : StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      widget.unitNumber,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: widget.isActive ? color : (isDark ? Colors.white54 : Colors.black54),
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
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          widget.subtitle,
                          style: TextStyle(
                            fontSize: 10,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
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
                            ? StudioSurfaceTheme.tintedContainer(
                                context,
                                color,
                                isSolid: isSolid,
                                translucentAlpha: 0.15,
                                solidBlendAlpha: 0.2,
                              )
                            : StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: widget.isActive
                              ? (isSolid ? theme.colorScheme.outline : color)
                              : StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // LED Light
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: widget.isActive ? color : (isDark ? Colors.white24 : Colors.black26),
                              boxShadow: widget.isActive
                                  ? [
                                      BoxShadow(
                                        color: color.withValues(alpha: 0.8),
                                        blurRadius: 6,
                                        spreadRadius: 1,
                                      )
                                    ]
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            widget.isActive ? 'ON' : 'BYPASS',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              color: widget.isActive ? color : (isDark ? Colors.white54 : Colors.black54),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 6),

                  // Expand / Collapse Chevron Indicator
                  HugeIcon(
                    icon: _isExpanded
                        ? HugeIcons.strokeRoundedArrowUp01
                        : HugeIcons.strokeRoundedArrowDown01,
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
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
          width: 0.8,
        ),
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
