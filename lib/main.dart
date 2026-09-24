import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'audio_engine/soloud_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi engine audio SoLoud native dengan sample rate 48000 Hz
  try {
    await SoLoudController.instance.init(
      sampleRate: 48000,
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
