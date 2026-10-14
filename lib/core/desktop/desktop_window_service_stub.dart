import 'package:flutter/foundation.dart';

/// Web/Stub implementation of DesktopWindowService with zero native dependencies.
class DesktopWindowService {
  static DesktopWindowService? _instance;
  static DesktopWindowService get instance => _instance ??= DesktopWindowService._();

  DesktopWindowService._();

  bool get isInitialized => false;

  final ValueNotifier<bool> isMaximizedNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isFullScreenNotifier = ValueNotifier<bool>(false);

  Future<void> init() async {}

  Future<void> minimize() async {}

  Future<void> toggleMaximize() async {}

  Future<void> close() async {}

  Future<void> toggleFullScreen() async {}
}
