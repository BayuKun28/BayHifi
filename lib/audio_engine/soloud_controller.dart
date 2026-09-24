import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

/// Wrapper Singleton untuk SoLoud Engine — Mengontrol pemutaran, buffer, FFT stream, dan DSP filter.
class SoLoudController {
  SoLoudController._internal();
  static final SoLoudController instance = SoLoudController._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  SoundHandle? _currentHandle;
  AudioSource? _currentSource;
  Timer? _positionTimer;

  final _positionController = StreamController<Duration>.broadcast();
  Stream<Duration> get positionStream => _positionController.stream;

  double _volume = 1.0;
  double _preampDb = 0.0;

  SoundHandle? get currentHandle => _currentHandle;
  AudioSource? get currentSource => _currentSource;
  double get volume => _volume;
  double get preampDb => _preampDb;

  /// Inisialisasi engine audio SoLoud native dengan sample rate audiophile
  Future<void> init({
    int sampleRate = 48000,
    int bufferSize = 2048,
    Channels channels = Channels.stereo,
  }) async {
    if (_isInitialized) return;

    try {
      await SoLoud.instance.init(
        sampleRate: sampleRate,
        bufferSize: bufferSize,
        channels: channels,
        lowLatency: true,
        automaticCleanup: true,
      );

      // Aktifkan stream FFT & Waveform secara default untuk RTA Visualizer
      SoLoud.instance.setVisualizationEnabled(
        true,
        windowSize: 512,
        kind: VisualizationKind.waveAndFft,
        channel: VisualizationChannel.merged,
      );
      SoLoud.instance.setFftSmoothing(0.75);

      _isInitialized = true;
      _startPositionTracking();
      debugPrint('[SoLoudController] Audio engine initialized @ $sampleRate Hz');
    } catch (e, stack) {
      debugPrint('[SoLoudController] Initialization error: $e\n$stack');
      rethrow;
    }
  }

  /// Memulai pemutaran audio dari path file lokal
  Future<SoundHandle> playFile(String filePath) async {
    if (!_isInitialized) await init();

    await stop();

    try {
      final source = await SoLoud.instance.loadFile(
        filePath,
        mode: LoadMode.disk,
      );
      _currentSource = source;

      final handle = SoLoud.instance.play(
        source,
        volume: _effectiveVolume,
      );
      _currentHandle = handle;

      return handle;
    } catch (e, stack) {
      debugPrint('[SoLoudController] Failed to play file: $filePath -> $e\n$stack');
      rethrow;
    }
  }

  /// Memutar audio dari URL streaming (Navidrome / remote)
  Future<SoundHandle> playUrl(String url) async {
    if (!_isInitialized) await init();

    await stop();

    try {
      final source = await SoLoud.instance.loadUrl(
        url,
        mode: LoadMode.disk,
      );
      _currentSource = source;

      final handle = SoLoud.instance.play(
        source,
        volume: _effectiveVolume,
      );
      _currentHandle = handle;

      return handle;
    } catch (e, stack) {
      debugPrint('[SoLoudController] Failed to play URL: $url -> $e\n$stack');
      rethrow;
    }
  }

  /// Pause / Resume toggle
  void pauseSwitch() {
    final handle = _currentHandle;
    if (handle != null && SoLoud.instance.getIsValidVoiceHandle(handle)) {
      SoLoud.instance.pauseSwitch(handle);
    }
  }

  /// Pause pemutaran
  void pause() {
    final handle = _currentHandle;
    if (handle != null && SoLoud.instance.getIsValidVoiceHandle(handle)) {
      if (!SoLoud.instance.getPause(handle)) {
        SoLoud.instance.pauseSwitch(handle);
      }
    }
  }

  /// Resume pemutaran
  void resume() {
    final handle = _currentHandle;
    if (handle != null && SoLoud.instance.getIsValidVoiceHandle(handle)) {
      if (SoLoud.instance.getPause(handle)) {
        SoLoud.instance.pauseSwitch(handle);
      }
    }
  }

  /// Stop pemutaran dan dispose source
  Future<void> stop() async {
    final handle = _currentHandle;
    if (handle != null && SoLoud.instance.getIsValidVoiceHandle(handle)) {
      SoLoud.instance.stop(handle);
      _currentHandle = null;
    }

    final source = _currentSource;
    if (source != null) {
      await SoLoud.instance.disposeSource(source);
      _currentSource = null;
    }
  }

  /// Lompat ke posisi tertentu
  void seek(Duration position) {
    final handle = _currentHandle;
    if (handle != null && SoLoud.instance.getIsValidVoiceHandle(handle)) {
      SoLoud.instance.seek(handle, position);
    }
  }

  /// Mengatur volume utama (0.0 s/d 1.0)
  void setVolume(double vol) {
    _volume = vol.clamp(0.0, 1.0);
    _applyEffectiveVolume();
  }

  /// Mengatur gain pre-amp dalam dB (-24 dB s/d +12 dB)
  void setPreamp(double preampDb) {
    _preampDb = preampDb;
    _applyEffectiveVolume();
  }

  double get _effectiveVolume {
    // linear = 10^(dB / 20) * master_volume
    final linearPreamp = math.pow(10.0, _preampDb / 20.0).toDouble();
    return (_volume * linearPreamp).clamp(0.0, 2.0);
  }

  void _applyEffectiveVolume() {
    final handle = _currentHandle;
    if (handle != null && SoLoud.instance.getIsValidVoiceHandle(handle)) {
      SoLoud.instance.setVolume(handle, _effectiveVolume);
    }
  }

  /// Mendapatkan durasi audio saat ini
  Duration get duration {
    final source = _currentSource;
    if (source == null) return Duration.zero;
    return SoLoud.instance.getLength(source);
  }

  /// Mendapatkan posisi audio saat ini
  Duration get position {
    final handle = _currentHandle;
    if (handle == null || !SoLoud.instance.getIsValidVoiceHandle(handle)) {
      return Duration.zero;
    }
    return SoLoud.instance.getPosition(handle);
  }

  /// Status apakah suara sedang aktif berputar
  bool get isPlaying {
    final handle = _currentHandle;
    if (handle == null || !SoLoud.instance.getIsValidVoiceHandle(handle)) {
      return false;
    }
    return !SoLoud.instance.getPause(handle);
  }

  /// Stream visualisasi real-time (FFT & Waveform)
  Stream<AudioVisualizationData> get visualizationEvents =>
      SoLoud.instance.audioVisualizationEvents;

  void _startPositionTracking() {
    _positionTimer?.cancel();
    _positionTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (isPlaying) {
        _positionController.add(position);
      }
    });
  }

  /// Shutdown dan bersihkan resource audio
  Future<void> deinit() async {
    _positionTimer?.cancel();
    await stop();
    if (_isInitialized) {
      SoLoud.instance.deinit();
      _isInitialized = false;
    }
    await _positionController.close();
  }
}
