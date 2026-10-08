import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/theme_mode_controller.dart';

/// Studio Wallpaper Backdrop Widget
/// Renders a GPU-cached, high-performance blurred and dimmed background layer
/// behind app content when custom wallpaper is enabled.
class StudioWallpaperBackdrop extends ConsumerWidget {
  final Widget child;

  const StudioWallpaperBackdrop({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallpaper = ref.watch(themeControllerProvider.select((s) => s.wallpaperSettings));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final hasValidWallpaper = wallpaper.enabled &&
        wallpaper.imagePath != null &&
        wallpaper.imagePath!.isNotEmpty &&
        (wallpaper.isAsset || File(wallpaper.imagePath!).existsSync());

    return Stack(
      fit: StackFit.expand,
      children: [
        // Layer 0: Isolated RepaintBoundary for Background Wallpaper
        if (hasValidWallpaper)
          RepaintBoundary(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: _buildWallpaperLayer(wallpaper, isDark),
            ),
          ),

        // Layer 1: App Content & Interactive UI
        child,
      ],
    );
  }

  Widget _buildWallpaperLayer(WallpaperSettings wallpaper, bool isDark) {
    final blur = wallpaper.blurRadius;
    final dim = wallpaper.dimOpacity.clamp(0.0, 0.95);

    Widget imageWidget = wallpaper.isAsset
        ? Image.asset(
            wallpaper.imagePath!,
            key: ValueKey(wallpaper.imagePath),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            gaplessPlayback: true,
            errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
          )
        : Image.file(
            File(wallpaper.imagePath!),
            key: ValueKey(wallpaper.imagePath),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            gaplessPlayback: true,
            errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
          );

    if (blur > 0.5) {
      imageWidget = ImageFiltered(
        imageFilter: ImageFilter.blur(
          sigmaX: blur,
          sigmaY: blur,
          tileMode: TileMode.mirror,
        ),
        child: imageWidget,
      );
    }

    return Stack(
      key: ValueKey('${wallpaper.imagePath}_${blur}_$dim'),
      fit: StackFit.expand,
      children: [
        imageWidget,
        ColoredBox(
          color: (isDark ? Colors.black : Colors.white).withValues(alpha: dim),
        ),
      ],
    );
  }
}
