import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'player_controller.dart';

@immutable
class SleepTimerState {
  final bool isActive;
  final Duration remainingTime;
  final int totalMinutes;
  final bool stopAtEndOfTrack;
  final bool enableFadeOut;
  final bool isFadingOut;

  const SleepTimerState({
    this.isActive = false,
    this.remainingTime = Duration.zero,
    this.totalMinutes = 0,
    this.stopAtEndOfTrack = false,
    this.enableFadeOut = true,
    this.isFadingOut = false,
  });

  String get formattedRemaining {
    final mins = remainingTime.inMinutes;
    final secs = remainingTime.inSeconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  SleepTimerState copyWith({
    bool? isActive,
    Duration? remainingTime,
    int? totalMinutes,
    bool? stopAtEndOfTrack,
    bool? enableFadeOut,
    bool? isFadingOut,
  }) {
    return SleepTimerState(
      isActive: isActive ?? this.isActive,
      remainingTime: remainingTime ?? this.remainingTime,
      totalMinutes: totalMinutes ?? this.totalMinutes,
      stopAtEndOfTrack: stopAtEndOfTrack ?? this.stopAtEndOfTrack,
      enableFadeOut: enableFadeOut ?? this.enableFadeOut,
      isFadingOut: isFadingOut ?? this.isFadingOut,
    );
  }
}

final sleepTimerControllerProvider =
    StateNotifierProvider<SleepTimerController, SleepTimerState>((ref) {
  final playerCtrl = ref.read(playerControllerProvider.notifier);
  return SleepTimerController(playerCtrl, ref);
});

class SleepTimerController extends StateNotifier<SleepTimerState> {
  final PlayerController _playerController;
  final Ref _ref;
  Timer? _ticker;
  double? _initialVolume;

  SleepTimerController(this._playerController, this._ref)
      : super(const SleepTimerState());

  /// Starts the sleep timer with duration in minutes
  void startTimer(
    int minutes, {
    bool stopAtEndOfTrack = false,
    bool enableFadeOut = true,
  }) {
    cancelTimer();

    _initialVolume = _ref.read(playerControllerProvider).volume;

    state = SleepTimerState(
      isActive: true,
      totalMinutes: minutes,
      remainingTime: Duration(minutes: minutes),
      stopAtEndOfTrack: stopAtEndOfTrack,
      enableFadeOut: enableFadeOut,
      isFadingOut: false,
    );

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (!state.isActive) return;

    if (state.remainingTime.inSeconds <= 1) {
      _onTimerCompleted();
      return;
    }

    final newRemaining = state.remainingTime - const Duration(seconds: 1);
    bool fading = state.isFadingOut;

    // Handle 15-second gradual volume fade-out
    if (state.enableFadeOut && newRemaining.inSeconds <= 15) {
      fading = true;
      if (_initialVolume != null) {
        final scale = (newRemaining.inSeconds / 15.0).clamp(0.0, 1.0);
        _playerController.setVolume(_initialVolume! * scale);
      }
    }

    state = state.copyWith(
      remainingTime: newRemaining,
      isFadingOut: fading,
    );
  }

  void _onTimerCompleted() {
    _ticker?.cancel();

    if (state.stopAtEndOfTrack) {
      // Keep active waiting for track to complete naturally
      state = state.copyWith(
        remainingTime: Duration.zero,
        isActive: false,
        isFadingOut: false,
      );
    } else {
      _playerController.pause();
      if (_initialVolume != null) {
        _playerController.setVolume(_initialVolume!);
      }
      state = const SleepTimerState();
    }
  }

  /// Extends active timer by [minutes]
  void extendTimer(int minutes) {
    if (!state.isActive) {
      startTimer(minutes);
      return;
    }

    if (_initialVolume != null && state.isFadingOut) {
      _playerController.setVolume(_initialVolume!);
    }

    final extended = state.remainingTime + Duration(minutes: minutes);
    state = state.copyWith(
      remainingTime: extended,
      totalMinutes: state.totalMinutes + minutes,
      isFadingOut: false,
    );
  }

  /// Cancels active sleep timer and restores original volume
  void cancelTimer() {
    _ticker?.cancel();
    _ticker = null;

    if (_initialVolume != null) {
      _playerController.setVolume(_initialVolume!);
      _initialVolume = null;
    }

    state = const SleepTimerState();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
