import 'package:flutter/material.dart';
import '../../app/theme/simple_as_f_theme.dart';

/// Two-Tone Bold Header Widget
/// Renders modern two-tone titles as seen in Dribbble 27089924:
/// First keyword in pure solid white, second keyword in vibrant emerald mint.
/// Example: "Liked Songs", "Recently Played", "Equalizer Studio".
class TwoToneHeader extends StatelessWidget {
  final String primaryText;
  final String accentText;
  final Color? primaryColor;
  final Color? accentColor;
  final double fontSize;
  final FontWeight fontWeight;
  final double letterSpacing;
  final Widget? trailing;
  final VoidCallback? onTap;
  final TextOverflow overflow;
  final int? maxLines;

  const TwoToneHeader({
    super.key,
    required this.primaryText,
    required this.accentText,
    this.primaryColor,
    this.accentColor,
    this.fontSize = 26.0,
    this.fontWeight = FontWeight.w800,
    this.letterSpacing = -0.5,
    this.trailing,
    this.onTap,
    this.overflow = TextOverflow.ellipsis,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final pColor = primaryColor ?? SimpleAsFTheme.textWhite;
    final aColor = accentColor ?? SimpleAsFTheme.accent(context);

    final headerText = Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$primaryText ',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: fontWeight,
              letterSpacing: letterSpacing,
              color: pColor,
            ),
          ),
          TextSpan(
            text: accentText,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: fontWeight,
              letterSpacing: letterSpacing,
              color: aColor,
            ),
          ),
        ],
      ),
      overflow: overflow,
      maxLines: maxLines,
    );

    if (trailing == null && onTap == null) {
      return headerText;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: headerText),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );
  }
}
