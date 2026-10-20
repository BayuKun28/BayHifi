import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Layout mode selection on Desktop (Responsive Shortcut Switcher)
enum DesktopLayoutMode {
  auto('Auto Layout', 'Responsive to desktop window width', LucideIcons.layers),
  mobile('Mobile Phone', 'Single-column with bottom dock (430px)', LucideIcons.smartphone),
  tablet('Tablet Mode', 'Dual-pane with compact studio rail (950px)', LucideIcons.tablet),
  desktop('Desktop Studio', 'Full-width master layout with transport deck (1280px)', LucideIcons.monitor);

  final String label;
  final String description;
  final IconData icon;
  const DesktopLayoutMode(this.label, this.description, this.icon);
}

/// State notifier for Desktop layout override
class DesktopLayoutController extends StateNotifier<DesktopLayoutMode> {
  DesktopLayoutController() : super(DesktopLayoutMode.auto);

  void setLayoutMode(DesktopLayoutMode mode) {
    state = mode;
  }
}

final desktopLayoutModeProvider =
    StateNotifierProvider<DesktopLayoutController, DesktopLayoutMode>(
  (ref) => DesktopLayoutController(),
);
