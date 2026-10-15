import 'package:flutter/material.dart';
import '../../app/theme/simple_as_f_theme.dart';

/// SimpleAsFScaffold
/// Organic obsidian forest dark background with soft ambient radial emerald glows,
/// providing high breathability and subtle depth without heavy visual bloat.
/// Reference: Dribbble 27089924 (Music App by Murat Ak).
class SimpleAsFScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final bool extendBody;
  final bool extendBodyBehindAppBar;
  final Color? backgroundColor;
  final bool enableAmbientGlow;

  const SimpleAsFScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.backgroundColor,
    this.enableAmbientGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = backgroundColor ?? SimpleAsFTheme.forestCanvas;

    return Scaffold(
      backgroundColor: baseColor,
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ─── Ambient Radial Glows (Background Depth) ────────────────────────
          if (enableAmbientGlow) ...[
            // Soft top-left / center glow
            Positioned(
              top: -80,
              left: -40,
              width: 320,
              height: 320,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        SimpleAsFTheme.forestGlowAccent.withValues(alpha: 0.35),
                        SimpleAsFTheme.forestGlow.withValues(alpha: 0.15),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            // Soft bottom-right glow
            Positioned(
              bottom: 40,
              right: -60,
              width: 360,
              height: 360,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        SimpleAsFTheme.forestGlow.withValues(alpha: 0.25),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ],

          // ─── Foreground Body ────────────────────────────────────────────────
          body,
        ],
      ),
    );
  }
}
