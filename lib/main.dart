import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'audio_engine/audio_cache_service.dart';
import 'audio_engine/soloud_controller.dart';
import 'core/audio_service/baydev_audio_handler.dart';
import 'core/database/local_persistence_service.dart';
import 'core/desktop/desktop_window_service.dart';
import 'core/desktop/linux_mpris_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi penyimpanan persisten lokal
  try {
    await LocalPersistenceService.instance.init();
  } catch (e) {
    debugPrint('Peringatan: Inisialisasi database lokal gagal: $e');
  }

  // Inisialisasi Window Manager pada platform Desktop (Linux/Windows/macOS)
  if (!kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
    try {
      await DesktopWindowService.instance.init();
    } catch (e) {
      debugPrint('Peringatan: Inisialisasi DesktopWindowService ditunda/mock: $e');
    }
  }

  // Inisialisasi Linux MPRIS v2 D-Bus Daemon (Linux Only)
  if (!kIsWeb && Platform.isLinux) {
    try {
      await LinuxMprisService.instance.init();
    } catch (e) {
      debugPrint('Peringatan: Inisialisasi LinuxMprisService ditunda/mock: $e');
    }
  }

  // Inisialisasi AudioCacheService untuk offline caching & prefetching
  try {
    await AudioCacheService.instance.init();
  } catch (e) {
    debugPrint('Peringatan: Inisialisasi AudioCacheService gagal: $e');
  }

  // Inisialisasi background AudioService untuk status bar notification
  try {
    await AudioService.init(
      builder: () => BaydevAudioHandler.instance,
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.baydev.baydev_hifi.channel.audio',
        androidNotificationChannelName: 'Baydev HiFi Playback',
        androidNotificationChannelDescription: 'Audiophile Lossless Music Playback Controls',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
        androidNotificationIcon: 'mipmap/ic_launcher',
      ),
    );
  } catch (e) {
    debugPrint('Peringatan: Inisialisasi background AudioService ditunda/mock: $e');
  }

  // Inisialisasi engine audio SoLoud native dengan sample rate 44100 Hz
  try {
    await SoLoudController.instance.init(
      sampleRate: 44100,
      bufferSize: 2048,
    );
  } catch (e) {
    debugPrint('Peringatan: Inisialisasi awal SoLoud ditunda sampai perangkat audio siap: $e');
  }

  runApp(
    const ProviderScope(
      child: BaydevHiFiApp(),
    ),
  );
}

