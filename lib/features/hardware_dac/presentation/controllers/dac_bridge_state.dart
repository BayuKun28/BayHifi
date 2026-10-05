import 'package:flutter/foundation.dart';
import '../../domain/models/dac_band_config.dart';
import '../../domain/models/dac_device.dart';
import '../../domain/models/dac_peq_profile.dart';

/// Connection and communication status of the Hardware DAC Bridge.
enum DacBridgeStatus {
  disconnected,
  scanning,
  connecting,
  connected,
  reading,
  writing,
  flashing,
  error,
}

/// State container for the Hardware DAC Studio and USB Bridge.
@immutable
class DacBridgeState {
  const DacBridgeState({
    this.status = DacBridgeStatus.disconnected,
    this.device,
    this.currentProfile = const DacPeqProfile(
      id: 'active_dac_profile',
      name: 'Current Hardware Tuning',
      bands: [
        DacBandConfig(bandIndex: 0, frequency: 28.0, gainDb: 0.0, qFactor: 0.70),
        DacBandConfig(bandIndex: 1, frequency: 84.0, gainDb: 0.0, qFactor: 0.70),
        DacBandConfig(bandIndex: 2, frequency: 680.0, gainDb: 0.0, qFactor: 0.70),
        DacBandConfig(bandIndex: 3, frequency: 4300.0, gainDb: 0.0, qFactor: 0.70),
        DacBandConfig(bandIndex: 4, frequency: 14500.0, gainDb: 0.0, qFactor: 0.70),
      ],
      preampGainDb: 0.0,
    ),
    this.isEqEnabled = true,
    this.globalGainDb = 0.0,
    this.hasUnsavedFlashChanges = false,
    this.availablePresets = const [],
    this.errorMessage,
    this.statusBannerMessage,
  });

  final DacBridgeStatus status;
  final DacDevice? device;
  final DacPeqProfile currentProfile;
  final bool isEqEnabled;
  final double globalGainDb;
  final bool hasUnsavedFlashChanges;
  final List<DacPeqProfile> availablePresets;
  final String? errorMessage;
  final String? statusBannerMessage;

  bool get isConnected =>
      device != null &&
      device!.isConnected &&
      status != DacBridgeStatus.disconnected &&
      status != DacBridgeStatus.scanning &&
      status != DacBridgeStatus.connecting;

  bool get isBusy =>
      status == DacBridgeStatus.scanning ||
      status == DacBridgeStatus.connecting ||
      status == DacBridgeStatus.reading ||
      status == DacBridgeStatus.writing ||
      status == DacBridgeStatus.flashing;

  List<DacBandConfig> get bands => currentProfile.bands;

  DacBridgeState copyWith({
    DacBridgeStatus? status,
    DacDevice? Function()? device,
    DacPeqProfile? currentProfile,
    bool? isEqEnabled,
    double? globalGainDb,
    bool? hasUnsavedFlashChanges,
    List<DacPeqProfile>? availablePresets,
    String? Function()? errorMessage,
    String? Function()? statusBannerMessage,
  }) {
    return DacBridgeState(
      status: status ?? this.status,
      device: device != null ? device() : this.device,
      currentProfile: currentProfile ?? this.currentProfile,
      isEqEnabled: isEqEnabled ?? this.isEqEnabled,
      globalGainDb: globalGainDb ?? this.globalGainDb,
      hasUnsavedFlashChanges: hasUnsavedFlashChanges ?? this.hasUnsavedFlashChanges,
      availablePresets: availablePresets ?? this.availablePresets,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      statusBannerMessage: statusBannerMessage != null
          ? statusBannerMessage()
          : this.statusBannerMessage,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DacBridgeState &&
        other.status == status &&
        other.device == device &&
        other.currentProfile == currentProfile &&
        other.isEqEnabled == isEqEnabled &&
        other.globalGainDb == globalGainDb &&
        other.hasUnsavedFlashChanges == hasUnsavedFlashChanges &&
        listEquals(other.availablePresets, availablePresets) &&
        other.errorMessage == errorMessage &&
        other.statusBannerMessage == statusBannerMessage;
  }

  @override
  int get hashCode => Object.hash(
        status,
        device,
        currentProfile,
        isEqEnabled,
        globalGainDb,
        hasUnsavedFlashChanges,
        Object.hashAll(availablePresets),
        errorMessage,
        statusBannerMessage,
      );
}
