// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:tray_manager/legacy.dart';
import 'package:window_manager/window_manager.dart';
import '../database/local_persistence_service.dart';
import '../../features/player/domain/track.dart';

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
      trayManager.addListener(this);

      // Icon tray default (menggunakan asset yang terdaftar)
      await _applyTrayIcon();

      final isTooltipEnabled = LocalPersistenceService.instance.getSetting<bool>(
        'desktop_tray_tooltip_enabled',
        true,
      ) ?? true;

      if (isTooltipEnabled) {
        await trayManager.setToolTip('Baydev HiFi — Studio Audiophile Player');
      }

      await updateTrayMenu();

      _isInitialized = true;
      debugPrint('[DesktopTrayService] Initialized successfully');
    } catch (e) {
      debugPrint('[DesktopTrayService] Initialization bypassed or failed: $e');
    }
  }

  Future<void> _applyTrayIcon() async {
    try {
      // Pada Linux & desktop, icon asset dimuat dari bundle
      if (Platform.isLinux) {
        await trayManager.setIcon('assets/images/baydev_logo.png');
      } else if (Platform.isWindows) {
        await trayManager.setIcon('assets/images/baydev_logo.png');
      } else if (Platform.isMacOS) {
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
    _lastTrack = currentTrack;
    _lastIsPlaying = isPlaying;
    _lastVolume = volume;
    _lastIsMuted = isMuted;
    _lastDspPreset = dspPresetName;
    _lastAutoEqTarget = autoEqTarget;
    _lastIsDspActive = isDspActive;

    if (!_isInitialized) return;

    try {
      // Perbarui tooltip
      final isTooltipEnabled = LocalPersistenceService.instance.getSetting<bool>(
        'desktop_tray_tooltip_enabled',
        true,
      ) ?? true;

      if (isTooltipEnabled) {
        if (currentTrack != null) {
          final status = isPlaying ? 'Playing' : 'Paused';
          await trayManager.setToolTip(
            'Baydev HiFi ($status)\n${currentTrack.title} — ${currentTrack.artist}',
          );
        } else {
          await trayManager.setToolTip('Baydev HiFi — Studio Audiophile Player');
        }
      }

      await updateTrayMenu();
    } catch (e) {
      debugPrint('[DesktopTrayService] Error updating playback state: $e');
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

      final menu = Menu(items: items);
      await trayManager.setContextMenu(menu);
    } catch (e) {
      debugPrint('[DesktopTrayService] Error building context menu: $e');
    }
  }

  // ─── TrayListener Event Handlers ──────────────────────────────────────────

  @override
  void onTrayIconMouseDown() {
    // Klik kiri pada icon tray: Toggle visibilitas window
    toggleWindowVisibility();
  }

  @override
  void onTrayIconRightMouseDown() {
    // Klik kanan pada icon tray: Pop-up context menu instan
    try {
      trayManager.popUpContextMenu();
    } catch (e) {
      debugPrint('[DesktopTrayService] Error popping up context menu: $e');
    }
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'play_pause':
        onPlayPause?.call();
        break;
      case 'next_track':
        onNext?.call();
        break;
      case 'previous_track':
        onPrevious?.call();
        break;
      case 'toggle_mute':
        onToggleMute?.call();
        break;
      case 'dsp_status':
        onToggleDspRack?.call();
        break;
      case 'autoeq_status':
        onOpenAutoEq?.call();
        break;
      case 'toggle_window':
        toggleWindowVisibility();
        break;
      case 'quit_app':
        quitApplication();
        break;
    }
  }

  /// Toggle visibilitas window aplikasi
  Future<void> toggleWindowVisibility() async {
    if (kIsWeb || (!Platform.isLinux && !Platform.isWindows && !Platform.isMacOS)) return;
    try {
      final isVisible = await windowManager.isVisible();
      if (isVisible) {
        final isFocused = await windowManager.isFocused();
        if (isFocused) {
          await windowManager.hide();
        } else {
          await windowManager.focus();
        }
      } else {
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
      trayManager.removeListener(this);
      _isInitialized = false;
    } catch (e) {
      debugPrint('[DesktopTrayService] Error disposing tray service: $e');
    }
  }
}
