import 'package:flutter/material.dart';

/// Reusable Studio Rackmount Unit Frame (Terinspirasi rack hardware studio 19")
class RackUnitCard extends StatelessWidget {
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
  });

  final String unitNumber;
  final String title;
  final String subtitle;
  final bool isActive;
  final VoidCallback onToggle;
  final Widget content;
  final Color? accentColor;
  final Widget? headerTrailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = accentColor ?? theme.colorScheme.primary;

    final chassisBg = isDark
        ? const Color(0xFF14171E)
        : const Color(0xFFF1F3F7);
    final borderColor = isActive
        ? color.withValues(alpha: 0.4)
        : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: chassisBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: isActive ? 1.5 : 1.0),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Rack Mount Header Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF191D26)
                  : const Color(0xFFE5E9F0),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                ),
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
                    color: isActive ? color.withValues(alpha: 0.2) : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isActive ? color : (isDark ? Colors.white24 : Colors.black26),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    unitNumber,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isActive ? color : (isDark ? Colors.white54 : Colors.black54),
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
                        title.toUpperCase(),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                          color: isActive
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),

                if (headerTrailing != null) ...[
                  headerTrailing!,
                  const SizedBox(width: 8),
                ],

                // Studio Power Toggle with LED
                InkWell(
                  onTap: onToggle,
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isActive
                          ? color.withValues(alpha: 0.15)
                          : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive ? color : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // LED Light
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isActive ? color : (isDark ? Colors.white24 : Colors.black26),
                            boxShadow: isActive
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
                        const SizedBox(width: 6),
                        Text(
                          isActive ? 'ON' : 'BYPASS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color: isActive ? color : (isDark ? Colors.white54 : Colors.black54),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 10),
                // Faux Rack Screw
                _buildScrew(isDark),
              ],
            ),
          ),

          // Rack Unit Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isActive ? 1.0 : 0.45,
              child: content,
            ),
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
