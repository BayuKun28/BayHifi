import 'package:flutter/material.dart';
import '../../app/theme/simple_as_f_theme.dart';

/// Small uppercase tracking label for metadata, category tags, and section kickers.
/// Reference: Dribbble 27089924 ("WELCOME, MATT", "RECENTLY PLAYED", "DOWNLOAD", "2 FOLLOWERS").
class MetaTrackingLabel extends StatelessWidget {
  final String text;
  final double fontSize;
  final double letterSpacing;
  final Color? color;
  final FontWeight fontWeight;
  final TextAlign textAlign;
  final int? maxLines;
  final TextOverflow overflow;

  const MetaTrackingLabel(
    this.text, {
    super.key,
    this.fontSize = 11.0,
    this.letterSpacing = 1.8,
    this.color,
    this.fontWeight = FontWeight.w700,
    this.textAlign = TextAlign.start,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      text.toUpperCase(),
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
        color: color ?? (isDark ? SimpleAsFTheme.sageSlate : const Color(0xFF64748B)),
      ),
    );
  }
}
