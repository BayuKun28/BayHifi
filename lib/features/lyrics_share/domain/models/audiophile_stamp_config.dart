import 'package:flutter/foundation.dart';

/// Configuration for the Audiophile Signal Chain Telemetry Stamp on Lyric Cards
@immutable
class AudiophileStampConfig {
  final bool enabled;
  final bool showSignalChain;
  final bool showAutoEq;
  final bool showDspUnits;
  final bool showDacBridge;
  final bool showTimestamp;
  final String? customGearText;
  final String? autoEqProfileName;
  final String? dspProfileName;
  final String? dacDeviceName;
  final DateTime? timestamp;

  const AudiophileStampConfig({
    this.enabled = true,
    this.showSignalChain = true,
    this.showAutoEq = true,
    this.showDspUnits = true,
    this.showDacBridge = true,
    this.showTimestamp = true,
    this.customGearText,
    this.autoEqProfileName,
    this.dspProfileName,
    this.dacDeviceName,
    this.timestamp,
  });

  bool get showFormatRate => showSignalChain;
  bool get showAutoEqProfile => showAutoEq;
  bool get showVirtualDspChain => showDspUnits;
  bool get showHardwareDac => showDacBridge;

  String get effectiveAutoEqName => autoEqProfileName ?? 'Harman Target (Default)';
  String get effectiveDspChainName => dspProfileName ?? 'Tube + Limiter DSP';
  String get effectiveDacName => dacDeviceName ?? 'Bit-Perfect Direct Out';

  bool get hasAnyEnabled =>
      enabled &&
      (showSignalChain ||
          showAutoEq ||
          showDspUnits ||
          showDacBridge ||
          showTimestamp ||
          (customGearText != null && customGearText!.isNotEmpty));

  AudiophileStampConfig copyWith({
    bool? enabled,
    bool? showSignalChain,
    bool? showFormatRate,
    bool? showAutoEq,
    bool? showAutoEqProfile,
    bool? showDspUnits,
    bool? showVirtualDspChain,
    bool? showDacBridge,
    bool? showHardwareDac,
    bool? showTimestamp,
    String? customGearText,
    String? autoEqProfileName,
    String? customAutoEqName,
    String? dspProfileName,
    String? customDspChainName,
    String? dacDeviceName,
    String? customDacName,
    DateTime? timestamp,
  }) {
    return AudiophileStampConfig(
      enabled: enabled ?? this.enabled,
      showSignalChain: showFormatRate ?? showSignalChain ?? this.showSignalChain,
      showAutoEq: showAutoEqProfile ?? showAutoEq ?? this.showAutoEq,
      showDspUnits: showVirtualDspChain ?? showDspUnits ?? this.showDspUnits,
      showDacBridge: showHardwareDac ?? showDacBridge ?? this.showDacBridge,
      showTimestamp: showTimestamp ?? this.showTimestamp,
      customGearText: customGearText ?? this.customGearText,
      autoEqProfileName: customAutoEqName ?? autoEqProfileName ?? this.autoEqProfileName,
      dspProfileName: customDspChainName ?? dspProfileName ?? this.dspProfileName,
      dacDeviceName: customDacName ?? dacDeviceName ?? this.dacDeviceName,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AudiophileStampConfig &&
          runtimeType == other.runtimeType &&
          enabled == other.enabled &&
          showSignalChain == other.showSignalChain &&
          showAutoEq == other.showAutoEq &&
          showDspUnits == other.showDspUnits &&
          showDacBridge == other.showDacBridge &&
          showTimestamp == other.showTimestamp &&
          customGearText == other.customGearText &&
          autoEqProfileName == other.autoEqProfileName &&
          dspProfileName == other.dspProfileName &&
          dacDeviceName == other.dacDeviceName &&
          timestamp == other.timestamp;

  @override
  int get hashCode =>
      enabled.hashCode ^
      showSignalChain.hashCode ^
      showAutoEq.hashCode ^
      showDspUnits.hashCode ^
      showDacBridge.hashCode ^
      showTimestamp.hashCode ^
      (customGearText?.hashCode ?? 0) ^
      (autoEqProfileName?.hashCode ?? 0) ^
      (dspProfileName?.hashCode ?? 0) ^
      (dacDeviceName?.hashCode ?? 0) ^
      (timestamp?.hashCode ?? 0);
}
