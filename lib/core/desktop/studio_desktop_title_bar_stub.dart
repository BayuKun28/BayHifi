import 'package:flutter/material.dart';

/// Web/Stub implementation of StudioDesktopTitleBar.
class StudioDesktopTitleBar extends StatelessWidget implements PreferredSizeWidget {
  final double height;

  const StudioDesktopTitleBar({
    super.key,
    this.height = 38.0,
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
