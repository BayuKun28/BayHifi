import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

/// Layout mode selection on Desktop (Responsive Shortcut Switcher)
enum DesktopLayoutMode {
  auto('Auto Layout', 'Responsive to desktop window width', HugeIcons.strokeRoundedLayers01),
  mobile('Mobile Phone', 'Single-column with bottom dock (430px)', HugeIcons.strokeRoundedSmartPhone01),
  tablet('Tablet Mode', 'Dual-pane with compact studio rail (780px)', HugeIcons.strokeRoundedTablet01),
  desktop('Desktop Studio', 'Full-width master layout with transport deck (1280px)', HugeIcons.strokeRoundedComputer);

  final String label;
  final String description;
  final dynamic icon;
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
