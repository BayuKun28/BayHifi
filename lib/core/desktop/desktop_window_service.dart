import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../database/local_persistence_service.dart';

/// Service manajemen window dan persistensi geometri desktop (Linux/macOS/Windows).
/// Seluruh metode dilindungi dengan platform guards agar tidak crash pada Android/iOS.
class DesktopWindowService with WindowListener {
  static DesktopWindowService? _instance;
  static DesktopWindowService get instance => _instance ??= DesktopWindowService._();

  DesktopWindowService._();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Inisialisasi Window Manager pada platform Desktop
  Future<void> init() async {
    if (kIsWeb) return;
    if (!Platform.isLinux && !Platform.isWindows && !Platform.isMacOS) return;

    try {
      await windowManager.ensureInitialized();
      windowManager.addListener(this);

      const minSize = Size(960, 640);
      const defaultSize = Size(1280, 820);

      final saved = LocalPersistenceService.instance.getWindowDimensions();
      Size targetSize = defaultSize;
      Offset? targetPos;
      bool wasMaximized = false;

      if (saved != null) {
        final w = (saved['width'] as num?)?.toDouble() ?? defaultSize.width;
        final h = (saved['height'] as num?)?.toDouble() ?? defaultSize.height;
        if (w >= minSize.width && h >= minSize.height) {
          targetSize = Size(w, h);
        }
        final x = (saved['x'] as num?)?.toDouble();
        final y = (saved['y'] as num?)?.toDouble();
        if (x != null && y != null && x >= 0 && y >= 0) {
          targetPos = Offset(x, y);
        }
        wasMaximized = saved['isMaximized'] == true;
      }

      final windowOptions = WindowOptions(
        size: targetSize,
        minimumSize: minSize,
        center: targetPos == null,
        backgroundColor: Colors.transparent,
        skipTaskbar: false,
        title: 'Baydev HiFi — Studio Audiophile Player',
        titleBarStyle: TitleBarStyle.normal,
      );

      await windowManager.waitUntilReadyToShow(windowOptions, () async {
        if (targetPos != null) {
          await windowManager.setPosition(targetPos);
        }
        if (wasMaximized) {
          await windowManager.maximize();
        }
        await windowManager.setPreventClose(true);
        await windowManager.show();
        await windowManager.focus();
      });

      _isInitialized = true;
      debugPrint('[DesktopWindowService] Initialized with size: $targetSize');
    } catch (e) {
      debugPrint('[DesktopWindowService] Initialization bypassed or failed: $e');
    }
  }

  @override
  void onWindowClose() async {
    if (!_isInitialized) return;
    try {
      final closeToTray = LocalPersistenceService.instance.getSetting<bool>(
        'desktop_close_to_tray',
        true,
      ) ?? true;

      if (closeToTray) {
        await windowManager.hide();
      } else {
        await windowManager.destroy();
      }
    } catch (e) {
      debugPrint('[DesktopWindowService] Error in onWindowClose: $e');
    }
  }

  @override
  void onWindowResized() {
    _saveCurrentGeometry();
  }

  @override
  void onWindowMoved() {
    _saveCurrentGeometry();
  }

  @override
  void onWindowMaximize() {
    _saveCurrentGeometry(maximized: true);
  }

  @override
  void onWindowUnmaximize() {
    _saveCurrentGeometry(maximized: false);
  }

  Future<void> _saveCurrentGeometry({bool? maximized}) async {
    if (!_isInitialized) return;
    try {
      final isMax = maximized ?? await windowManager.isMaximized();
      if (!isMax) {
        final size = await windowManager.getSize();
        final pos = await windowManager.getPosition();
        await LocalPersistenceService.instance.saveWindowDimensions(
          width: size.width,
          height: size.height,
          x: pos.dx,
          y: pos.dy,
          isMaximized: false,
        );
      } else {
        final saved = LocalPersistenceService.instance.getWindowDimensions();
        await LocalPersistenceService.instance.saveWindowDimensions(
          width: (saved?['width'] as num?)?.toDouble() ?? 1280,
          height: (saved?['height'] as num?)?.toDouble() ?? 820,
          x: (saved?['x'] as num?)?.toDouble(),
          y: (saved?['y'] as num?)?.toDouble(),
          isMaximized: true,
        );
      }
    } catch (e) {
      debugPrint('[DesktopWindowService] Error saving geometry: $e');
    }
  }

  /// Toggle Fullscreen Desktop Mode (e.g. for Studio Desk Docking)
  Future<void> toggleFullScreen() async {
    if (!Platform.isLinux && !Platform.isWindows && !Platform.isMacOS) return;
    try {
      final isFull = await windowManager.isFullScreen();
      await windowManager.setFullScreen(!isFull);
    } catch (e) {
      debugPrint('[DesktopWindowService] Error toggling fullscreen: $e');
    }
  }
}
