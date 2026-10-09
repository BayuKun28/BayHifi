// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:tray_manager/legacy.dart';
import 'package:window_manager/window_manager.dart';
import '../database/local_persistence_service.dart';
import '../../features/player/domain/track.dart';
import 'linux_tray_dbus_service.dart';

/// Service manajemen System Tray Quick Menu (StatusNotifierItem) untuk desktop (Linux/macOS/Windows).
/// Menyediakan menu kontrol cepat, telemetri trek, dan integrasi dengan window_manager.
/// Seluruh metode dilindungi dengan platform guards agar 100% aman dan no-op di Android/iOS.
class DesktopTrayService with TrayListener {
  static DesktopTrayService? _instance;
  static DesktopTrayService get instance => _instance ??= DesktopTrayService._();

  DesktopTrayService._();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // Callbacks yang dihubungkan ke PlayerController & App Lifecycle
  VoidCallback? onPlay;
  VoidCallback? onPause;
  VoidCallback? onPlayPause;
  VoidCallback? onNext;
  VoidCallback? onPrevious;
  VoidCallback? onToggleMute;
  void Function(double volume)? onSetVolume;
  VoidCallback? onToggleDspRack;
  VoidCallback? onOpenAutoEq;
  VoidCallback? onQuit;

  // Cached state untuk membangun context menu dinamis
  Track? _lastTrack;
  bool _lastIsPlaying = false;
  double _lastVolume = 1.0;
  bool _lastIsMuted = false;
  String? _lastDspPreset;
  String? _lastAutoEqTarget;
  bool _lastIsDspActive = false;

  /// Inisialisasi System Tray pada platform Desktop
  Future<void> init() async {
    if (kIsWeb) return;
    if (!Platform.isLinux && !Platform.isWindows && !Platform.isMacOS) return;
    if (_isInitialized) return;

    try {
      if (Platform.isLinux) {
        // Pada Linux, gunakan pure D-Bus StatusNotifierItem & DBusMenu implementation
        await LinuxTrayDbusService.instance.init(trayService: this);
      } else {
        trayManager.addListener(this);
        await _applyTrayIcon();

        final isTooltipEnabled = LocalPersistenceService.instance.getSetting<bool>(
          'desktop_tray_tooltip_enabled',
          true,
        ) ?? true;

        if (isTooltipEnabled) {
          await trayManager.setToolTip('Baydev HiFi — Studio Audiophile Player');
        }
      }

      _isInitialized = true;
      await updateTrayMenu();
      debugPrint('[DesktopTrayService] Initialized successfully (Platform: ${Platform.operatingSystem})');
    } catch (e) {
      debugPrint('[DesktopTrayService] Initialization bypassed or failed: $e');
    }
  }

  Future<void> _applyTrayIcon() async {
    try {
      if (Platform.isWindows || Platform.isMacOS) {
        await trayManager.setIcon('assets/images/baydev_logo.png');
      }
    } catch (e) {
      debugPrint('[DesktopTrayService] Error setting tray icon: $e');
    }
  }

  /// Memperbarui state dan merefresh menu tray secara reaktif
  Future<void> updatePlaybackState({
    Track? currentTrack,
    required bool isPlaying,
    required double volume,
    bool isMuted = false,
    String? dspPresetName,
    String? autoEqTarget,
    bool isDspActive = false,
  }) async {
    final trackChanged = _lastTrack?.id != currentTrack?.id;
    final playStateChanged = _lastIsPlaying != isPlaying;
    final muteChanged = _lastIsMuted != isMuted;
    final dspChanged = _lastDspPreset != dspPresetName || _lastIsDspActive != isDspActive;
    final autoEqChanged = _lastAutoEqTarget != autoEqTarget;
    final volumeChanged = (_lastVolume - volume).abs() > 0.05;

    _lastTrack = currentTrack;
    _lastIsPlaying = isPlaying;
    _lastVolume = volume;
    _lastIsMuted = isMuted;
    _lastDspPreset = dspPresetName;
    _lastAutoEqTarget = autoEqTarget;
    _lastIsDspActive = isDspActive;

    if (!_isInitialized) return;

    final needsMenuRebuild = trackChanged || playStateChanged || muteChanged || dspChanged || autoEqChanged || volumeChanged;

    if (needsMenuRebuild) {
      try {
        final isTooltipEnabled = LocalPersistenceService.instance.getSetting<bool>(
          'desktop_tray_tooltip_enabled',
          true,
        ) ?? true;

        if (isTooltipEnabled) {
          final status = isPlaying ? 'Playing' : 'Paused';
          final trackLine = currentTrack != null ? '${currentTrack.title} — ${currentTrack.artist}' : 'Studio Audiophile Player';

          if (Platform.isLinux) {
            LinuxTrayDbusService.instance.updateTooltip(
              title: 'Baydev HiFi ($status)',
              body: trackLine,
            );
          } else {
            await trayManager.setToolTip('Baydev HiFi ($status)\n$trackLine');
          }
        }

        await updateTrayMenu();
      } catch (e) {
        debugPrint('[DesktopTrayService] Error updating playback state: $e');
      }
    }
  }

  /// Membangun struktur Menu Konteks Quick Action Tray
  Future<void> updateTrayMenu() async {
    if (!_isInitialized) return;

    try {
      final items = <MenuItem>[];

      // 1. Header & Title
      items.add(
        MenuItem(
          key: 'header_title',
          label: 'Baydev HiFi Studio',
          disabled: true,
        ),
      );

      // 2. Track & Specs Telemetry
      if (_lastTrack != null) {
        items.add(
          MenuItem(
            key: 'track_info',
            label: '${_lastTrack!.title} • ${_lastTrack!.artist}',
            disabled: true,
          ),
        );

        final format = _lastTrack!.format.name.toUpperCase();
        final rate = _lastTrack!.sampleRate != null ? '${(_lastTrack!.sampleRate! / 1000).toStringAsFixed(1)}kHz' : '';
        final bit = _lastTrack!.bitDepth != null ? '${_lastTrack!.bitDepth}-bit' : '';
        final specs = [format, if (rate.isNotEmpty) rate, if (bit.isNotEmpty) bit].join(' • ');

        if (specs.isNotEmpty) {
          items.add(
            MenuItem(
              key: 'specs_info',
              label: specs,
              disabled: true,
            ),
          );
        }
      } else {
        items.add(
          MenuItem(
            key: 'track_info_empty',
            label: 'No Track Playing',
            disabled: true,
          ),
        );
      }

      items.add(MenuItem.separator());

      // 3. Transport Controls
      items.add(
        MenuItem(
          key: 'play_pause',
          label: _lastIsPlaying ? 'Pause Playback' : 'Play Audio',
        ),
      );
      items.add(
        MenuItem(
          key: 'next_track',
          label: 'Next Track',
        ),
      );
      items.add(
        MenuItem(
          key: 'previous_track',
          label: 'Previous Track',
        ),
      );

      items.add(MenuItem.separator());

      // 4. Volume & Audio Quick Action
      final volPercent = (_lastVolume * 100).round();
      items.add(
        MenuItem(
          key: 'toggle_mute',
          label: _lastIsMuted ? 'Unmute Audio (Muted)' : 'Mute Audio (Vol: $volPercent%)',
        ),
      );

      // 5. Studio DSP & AutoEQ Status (Quick Launchers)
      if (_lastDspPreset != null || _lastIsDspActive) {
        items.add(
          MenuItem(
            key: 'dsp_status',
            label: 'DSP Rack: ${_lastIsDspActive ? (_lastDspPreset ?? "Active") : "Bypassed"}',
          ),
        );
      }

      if (_lastAutoEqTarget != null && _lastAutoEqTarget!.isNotEmpty) {
        items.add(
          MenuItem(
            key: 'autoeq_status',
            label: 'AutoEQ: $_lastAutoEqTarget',
          ),
        );
      }

      items.add(MenuItem.separator());

      // 6. Window Visibility & Lifecycle
      items.add(
        MenuItem(
          key: 'toggle_window',
          label: 'Show / Hide Window',
        ),
      );
      items.add(
        MenuItem(
          key: 'quit_app',
          label: 'Quit Baydev HiFi',
        ),
      );

      if (Platform.isLinux) {
        await LinuxTrayDbusService.instance.updateMenu(items);
      } else {
        final menu = Menu(items: items);
        await trayManager.setContextMenu(menu);
      }
      debugPrint('[DesktopTrayService] Context menu registered (${items.length} items)');
    } catch (e) {
      debugPrint('[DesktopTrayService] Error building context menu: $e');
    }
  }

  // ─── TrayListener Event Handlers ──────────────────────────────────────────

  @override
  void onTrayIconMouseDown() {
    debugPrint('[DesktopTrayService] >>> EVENT: onTrayIconMouseDown (Left-Click Detected) <<<');
    toggleWindowVisibility();
  }

  @override
  void onTrayIconMouseUp() {
    debugPrint('[DesktopTrayService] >>> EVENT: onTrayIconMouseUp <<<');
  }

  @override
  void onTrayIconRightMouseDown() {
    debugPrint('[DesktopTrayService] >>> EVENT: onTrayIconRightMouseDown (Right-Click Detected) <<<');
    if (!Platform.isLinux) {
      try {
        debugPrint('[DesktopTrayService] Calling trayManager.popUpContextMenu()...');
        trayManager.popUpContextMenu();
      } catch (e) {
        debugPrint('[DesktopTrayService] Error popping up context menu: $e');
      }
    }
  }

  @override
  void onTrayIconRightMouseUp() {
    debugPrint('[DesktopTrayService] >>> EVENT: onTrayIconRightMouseUp <<<');
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    debugPrint('[DesktopTrayService] >>> MENU ITEM CLICKED: "${menuItem.label}" (key: ${menuItem.key}) <<<');
    switch (menuItem.key) {
      case 'play_pause':
        debugPrint('[DesktopTrayService] Executing: Play/Pause');
        onPlayPause?.call();
        break;
      case 'next_track':
        debugPrint('[DesktopTrayService] Executing: Next Track');
        onNext?.call();
        break;
      case 'previous_track':
        debugPrint('[DesktopTrayService] Executing: Previous Track');
        onPrevious?.call();
        break;
      case 'toggle_mute':
        debugPrint('[DesktopTrayService] Executing: Toggle Mute');
        onToggleMute?.call();
        break;
      case 'dsp_status':
        debugPrint('[DesktopTrayService] Executing: Toggle DSP Rack');
        onToggleDspRack?.call();
        break;
      case 'autoeq_status':
        debugPrint('[DesktopTrayService] Executing: Open AutoEQ');
        onOpenAutoEq?.call();
        break;
      case 'toggle_window':
        debugPrint('[DesktopTrayService] Executing: Show/Hide Window');
        toggleWindowVisibility();
        break;
      case 'quit_app':
        debugPrint('[DesktopTrayService] Executing: Quit App');
        quitApplication();
        break;
      default:
        debugPrint('[DesktopTrayService] Unhandled menu key: ${menuItem.key}');
        break;
    }
  }

  /// Toggle visibilitas window aplikasi
  Future<void> toggleWindowVisibility() async {
    if (kIsWeb || (!Platform.isLinux && !Platform.isWindows && !Platform.isMacOS)) return;
    try {
      final isVisible = await windowManager.isVisible();
      debugPrint('[DesktopTrayService] toggleWindowVisibility: isVisible=$isVisible');
      if (isVisible) {
        final isMinimized = await windowManager.isMinimized();
        if (isMinimized) {
          debugPrint('[DesktopTrayService] Window is minimized -> Restoring & focusing');
          await windowManager.restore();
          await windowManager.show();
          await windowManager.focus();
        } else {
          final isFocused = await windowManager.isFocused();
          debugPrint('[DesktopTrayService] Window isVisible, isFocused=$isFocused');
          if (isFocused) {
            debugPrint('[DesktopTrayService] Window is focused -> Hiding window');
            await windowManager.hide();
          } else {
            debugPrint('[DesktopTrayService] Window is not focused -> Showing & focusing window');
            await windowManager.show();
            await windowManager.focus();
          }
        }
      } else {
        debugPrint('[DesktopTrayService] Window is hidden -> Showing & focusing');
        await windowManager.show();
        await windowManager.focus();
      }
    } catch (e) {
      debugPrint('[DesktopTrayService] Error toggling window visibility: $e');
    }
  }

  /// Keluar dari aplikasi secara bersih
  Future<void> quitApplication() async {
    if (onQuit != null) {
      onQuit!();
    }
    if (!kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
      try {
        await windowManager.destroy();
      } catch (e) {
        exit(0);
      }
    }
  }

  /// Dispose listeners saat aplikasi ditutup
  Future<void> dispose() async {
    if (!_isInitialized) return;
    try {
      if (Platform.isLinux) {
        await LinuxTrayDbusService.instance.dispose();
      } else {
        trayManager.removeListener(this);
      }
      _isInitialized = false;
    } catch (e) {
      debugPrint('[DesktopTrayService] Error disposing tray service: $e');
    }
  }
}
