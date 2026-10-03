import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'virtual_dsp_service.dart';

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
  double _replayGainDb = 0.0;
  double _playbackSpeed = 1.0;
  int _playRequestId = 0;

  SoundHandle? get currentHandle => _currentHandle;
  AudioSource? get currentSource => _currentSource;
  double get volume => _volume;
  double get preampDb => _preampDb;
  double get replayGainDb => _replayGainDb;
  double get playbackSpeed => _playbackSpeed;

  /// Inisialisasi engine audio SoLoud native dengan sample rate audiophile
  Future<void> init({
    int sampleRate = 44100,
    int bufferSize = 2048,
    Channels channels = Channels.stereo,
  }) async {
    if (_isInitialized) return;

    try {
      await SoLoud.instance.init(
        sampleRate: sampleRate,
        bufferSize: bufferSize,
        channels: channels,
        lowLatency: false,
        automaticCleanup: true,
      );

      // Pastikan master volume engine pada level 1.0 penuh
      SoLoud.instance.setGlobalVolume(1.0);

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

      // Inisialisasi rantai DSP tunggal
      VirtualDspService.instance.init();

      debugPrint('[SoLoudController] Audio engine initialized @ $sampleRate Hz');
    } catch (e, stack) {
      debugPrint('[SoLoudController] Initialization error: $e\n$stack');
      rethrow;
    }
  }

  /// Memulai pemutaran audio dari path file lokal
  Future<SoundHandle?> playFile(
    String filePath, {
    bool fadeIn = false,
    Duration fadeDuration = const Duration(milliseconds: 300),
  }) async {
    final int requestId = ++_playRequestId;
    if (!_isInitialized) await init();
    if (requestId != _playRequestId) return null;

    await _stopCurrentAudio();
    if (requestId != _playRequestId) return null;

    try {
      final file = File(filePath);
      AudioSource? source;

      // 1. Coba load via loadFile(mode: LoadMode.memory) untuk kecepatan decode & seek optimal
      try {
        source = await SoLoud.instance.loadFile(
          filePath,
          mode: LoadMode.memory,
        );
      } catch (loadErr) {
        debugPrint('[SoLoudController] loadFile(memory) failed ($loadErr). Attempting readAsBytes + loadMem fallback...');
      }

      // 2. Fallback jika C++ fopen terhalang Android Scoped Storage permissions
      if (source == null && await file.exists()) {
        try {
          final bytes = await file.readAsBytes();
          source = await SoLoud.instance.loadMem(
            filePath,
            bytes,
            mode: LoadMode.memory,
          );
        } catch (memErr) {
          debugPrint('[SoLoudController] loadMem fallback failed: $memErr');
        }
      }

      // 3. Fallback terakhir ke loadFile(mode: LoadMode.disk)
      source ??= await SoLoud.instance.loadFile(
        filePath,
        mode: LoadMode.disk,
      );

      if (requestId != _playRequestId) {
        await SoLoud.instance.disposeSource(source);
        return null;
      }
      _currentSource = source;

      final targetVolume = effectiveVolume > 0.0 ? effectiveVolume : 1.0;
      final handle = SoLoud.instance.play(
        source,
        volume: targetVolume,
        scale: _playbackSpeed.clamp(0.05, 5.0),
      );
      _currentHandle = handle;
      SoLoud.instance.setVolume(handle, targetVolume);

      _startPositionTracking();

      return handle;
    } catch (e, stack) {
      debugPrint('[SoLoudController] Failed to play file: $filePath -> $e\n$stack');
      rethrow;
    }
  }

  /// Memutar audio dari URL streaming (Navidrome / remote)
  Future<SoundHandle?> playUrl(
    String url, {
    bool fadeIn = false,
    Duration fadeDuration = const Duration(milliseconds: 300),
  }) async {
    final int requestId = ++_playRequestId;
    if (!_isInitialized) await init();
    if (requestId != _playRequestId) return null;

    await _stopCurrentAudio();
    if (requestId != _playRequestId) return null;

    try {
      final source = await SoLoud.instance.loadUrl(
        url,
        mode: LoadMode.memory,
      );
      if (requestId != _playRequestId) {
        await SoLoud.instance.disposeSource(source);
        return null;
      }
      _currentSource = source;

      final targetVolume = effectiveVolume > 0.0 ? effectiveVolume : 1.0;
      final handle = SoLoud.instance.play(
        source,
        volume: targetVolume,
        scale: _playbackSpeed.clamp(0.05, 5.0),
      );
      _currentHandle = handle;
      SoLoud.instance.setVolume(handle, targetVolume);

      _startPositionTracking();

      return handle;
    } catch (e, stack) {
      debugPrint('[SoLoudController] Failed to play URL: $url -> $e\n$stack');
      rethrow;
    }
  }

  /// Memutar audio dari AudioSource kustom (misal Push/Buffer Stream)
  Future<SoundHandle?> playAudioSource(
    AudioSource source, {
    bool fadeIn = false,
    Duration fadeDuration = const Duration(milliseconds: 300),
  }) async {
    final int requestId = ++_playRequestId;
    if (!_isInitialized) await init();
    if (requestId != _playRequestId) return null;

    await _stopCurrentAudio();
    if (requestId != _playRequestId) return null;

    try {
      _currentSource = source;
      final targetVolume = effectiveVolume > 0.0 ? effectiveVolume : 1.0;
      final handle = SoLoud.instance.play(
        source,
        volume: targetVolume,
        scale: _playbackSpeed.clamp(0.05, 5.0),
      );
      _currentHandle = handle;
      SoLoud.instance.setVolume(handle, targetVolume);

      _startPositionTracking();
      return handle;
    } catch (e, stack) {
      debugPrint('[SoLoudController] Failed to play AudioSource -> $e\n$stack');
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

  /// Pause pemutaran (langsung tanpa fade)
  void pause() {
    final handle = _currentHandle;
    if (handle != null && SoLoud.instance.getIsValidVoiceHandle(handle)) {
      if (!SoLoud.instance.getPause(handle)) {
        SoLoud.instance.pauseSwitch(handle);
      }
    }
  }

  /// Pause pemutaran dengan smooth fade-out (Namida Flow)
  Future<void> pauseWithFade({Duration duration = const Duration(milliseconds: 300)}) async {
    final handle = _currentHandle;
    if (handle != null && SoLoud.instance.getIsValidVoiceHandle(handle)) {
      if (!SoLoud.instance.getPause(handle)) {
        if (duration <= Duration.zero) {
          pause();
          return;
        }
        try {
          SoLoud.instance.fadeVolume(handle, 0.001, duration);
          SoLoud.instance.schedulePause(handle, duration);
          // Tunggu hingga fade selesai sebelum mereset target volume pada voice
          await Future<void>.delayed(duration);
        } catch (e) {
          debugPrint('[SoLoudController] pauseWithFade error: $e');
          pause();
        }
      }
    }
  }

  /// Resume pemutaran (langsung tanpa fade)
  void resume() {
    final handle = _currentHandle;
    if (handle != null && SoLoud.instance.getIsValidVoiceHandle(handle)) {
      if (SoLoud.instance.getPause(handle)) {
        SoLoud.instance.pauseSwitch(handle);
        updateEffectiveVolume();
      }
    }
  }

  /// Resume pemutaran dengan smooth fade-in (Namida Flow)
  void resumeWithFade({Duration duration = const Duration(milliseconds: 300)}) {
    final handle = _currentHandle;
    if (handle != null && SoLoud.instance.getIsValidVoiceHandle(handle)) {
      if (SoLoud.instance.getPause(handle)) {
        if (duration <= Duration.zero) {
          resume();
          return;
        }
        try {
          SoLoud.instance.setVolume(handle, 0.001);
          SoLoud.instance.pauseSwitch(handle); // unpause
          SoLoud.instance.fadeVolume(handle, effectiveVolume, duration);
        } catch (e) {
          debugPrint('[SoLoudController] resumeWithFade error: $e');
          resume();
        }
      }
    }
  }

  /// Menghentikan audio yang aktif dan membersihkan voice/source tanpa membatalkan requestId aktif
  Future<void> _stopCurrentAudio() async {
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

  /// Stop pemutaran dan dispose source (eksternal stop membatalkan pemutaran yang sedang berlangsung)
  Future<void> stop() async {
    _playRequestId++;
    await _stopCurrentAudio();
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
    updateEffectiveVolume();
  }

  /// Mengatur gain pre-amp dalam dB (-24 dB s/d +12 dB)
  void setPreamp(double preampDb) {
    _preampDb = preampDb;
    VirtualDspService.instance.setPreampGain(preampDb);
    updateEffectiveVolume();
  }

  /// Mengatur penyesuaian ReplayGain dalam dB (Fase 16)
  void setReplayGainDb(double gainDb) {
    _replayGainDb = gainDb;
    updateEffectiveVolume();
  }

  /// Mengatur kecepatan playback (0.05x s/d 5.0x) (Fase 16)
  void setPlaybackSpeed(double speed) {
    _playbackSpeed = speed.clamp(0.05, 5.0);
    final handle = _currentHandle;
    if (handle != null && SoLoud.instance.getIsValidVoiceHandle(handle)) {
      try {
        SoLoud.instance.setRelativePlaySpeed(handle, _playbackSpeed);
      } catch (e) {
        debugPrint('[SoLoudController] Playback speed error: $e');
      }
    }
  }

  /// Perhitungan volume efektif aman (RYNLABS_HIFI & Namida Flow)
  double get effectiveVolume {
    final dsp = VirtualDspService.instance;
    final activePreamp = dsp.preampGain;
    final reverbComp = dsp.reverbVolumeCompensationDb;
    final totalDb = activePreamp + reverbComp + _replayGainDb;
    final totalLinear = math.pow(10.0, totalDb / 20.0).toDouble();
    // Clamp maksimal 1.5 untuk menghindari software mixer overflow
    return (_volume * totalLinear).clamp(0.0, 1.5);
  }

  /// Memperbarui volume pada handle aktif secara real-time
  void updateEffectiveVolume() {
    final handle = _currentHandle;
    if (handle != null && SoLoud.instance.getIsValidVoiceHandle(handle)) {
      try {
        SoLoud.instance.setVolume(handle, effectiveVolume);
      } catch (e) {
        debugPrint('[SoLoudController] Volume update error: $e');
      }
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
    _positionTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
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
