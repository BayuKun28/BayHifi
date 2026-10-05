import 'package:flutter/foundation.dart';

/// Identifies the DSP chipset family powering the USB DAC hardware.
enum DacChipset {
  /// KTmicro KT02H20 / KT0211L (Kiwi Ears AD1, Allegro Mini, FiiO JA11, JCALLY JM12)
  kt0211l(
    displayName: 'KTmicro KT02H20',
    defaultBands: 5,
    maxSampleRate: 384000,
    bitDepth: 32,
    hasGlobalGain: true,
  ),

  /// KTmicro KT1132L (Kiwi Ears S-Link DSP cable variant)
  kt1132l(
    displayName: 'KTmicro KT1132L',
    defaultBands: 5,
    maxSampleRate: 384000,
    bitDepth: 32,
    hasGlobalGain: false,
  ),

  /// KTmicro KT3016L (Kiwi Ears 3016 Series)
  kt3016l(
    displayName: 'KTmicro KT3016L',
    defaultBands: 5,
    maxSampleRate: 384000,
    bitDepth: 32,
    hasGlobalGain: false,
  ),

  /// CB Series 6-Band Flagship DAC (CB-5000X)
  cb5000x(
    displayName: 'CB-5000X DSP',
    defaultBands: 6,
    maxSampleRate: 768000,
    bitDepth: 32,
    hasGlobalGain: true,
  ),

  /// CB Series 4-Band Standard DAC (CB-3000S)
  cb3000s(
    displayName: 'CB-3000S DSP',
    defaultBands: 4,
    maxSampleRate: 384000,
    bitDepth: 32,
    hasGlobalGain: false,
  ),

  /// Unknown / generic USB audio device
  unknown(
    displayName: 'Generic USB Audio',
    defaultBands: 5,
    maxSampleRate: 192000,
    bitDepth: 24,
    hasGlobalGain: false,
  );

  const DacChipset({
    required this.displayName,
    required this.defaultBands,
    required this.maxSampleRate,
    required this.bitDepth,
    required this.hasGlobalGain,
  });

  final String displayName;
  final int defaultBands;
  final int maxSampleRate;
  final int bitDepth;
  final bool hasGlobalGain;

  bool get isKtFamily =>
      this == DacChipset.kt0211l ||
      this == DacChipset.kt1132l ||
      this == DacChipset.kt3016l;

  bool get isCbFamily =>
      this == DacChipset.cb5000x || this == DacChipset.cb3000s;
}

/// Represents a physical or simulated USB DAC device connected to the host system.
@immutable
class DacDevice {
  const DacDevice({
    required this.id,
    required this.vendorId,
    required this.productId,
    required this.productName,
    required this.chipset,
    this.maxBands = 5,
    this.isConnected = true,
    this.isEqEnabled = true,
    this.globalGainDb = 0.0,
    this.firmwareVersion,
    this.serialNumber,
  });

  /// Unique identifier or USB device node path.
  final String id;

  /// USB Vendor ID (e.g. 0x31B2 for Kiwi Ears, 0x3302 for Savitech/FiiO).
  final int vendorId;

  /// USB Product ID (e.g. 0x0111 for AD1, 0x2017 for Allegro Mini).
  final int productId;

  /// Human-readable product name.
  final String productName;

  /// Detected hardware DSP chipset.
  final DacChipset chipset;

  /// Maximum number of parametric equalizer bands supported by the hardware.
  final int maxBands;

  /// Whether the device is actively connected and ready for HID communication.
  final bool isConnected;

  /// Whether the hardware DSP EQ processing is active (not bypassed).
  final bool isEqEnabled;

  /// Hardware pre-amp / global analog gain in dB (-18.0 dB .. +3.0 dB).
  final double globalGainDb;

  /// Optional firmware version string.
  final String? firmwareVersion;

  /// Optional hardware serial number.
  final String? serialNumber;

  /// Hex representation of Vendor ID (e.g. "0x31B2").
  String get vendorIdHex =>
      '0x${vendorId.toRadixString(16).toUpperCase().padLeft(4, '0')}';

  /// Hex representation of Product ID (e.g. "0x0111").
  String get productIdHex =>
      '0x${productId.toRadixString(16).toUpperCase().padLeft(4, '0')}';

  /// Returns a friendly model title.
  String get formattedTitle {
    if (productName.isNotEmpty && productName != 'USB Audio') {
      return productName;
    }
    return chipset.displayName;
  }

  /// Formatted audio capability string.
  String get audioCapabilityString =>
      '${chipset.bitDepth}-bit / ${(chipset.maxSampleRate / 1000).round()}kHz';

  DacDevice copyWith({
    String? id,
    int? vendorId,
    int? productId,
    String? productName,
    DacChipset? chipset,
    int? maxBands,
    bool? isConnected,
    bool? isEqEnabled,
    double? globalGainDb,
    String? firmwareVersion,
    String? serialNumber,
  }) {
    return DacDevice(
      id: id ?? this.id,
      vendorId: vendorId ?? this.vendorId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      chipset: chipset ?? this.chipset,
      maxBands: maxBands ?? this.maxBands,
      isConnected: isConnected ?? this.isConnected,
      isEqEnabled: isEqEnabled ?? this.isEqEnabled,
      globalGainDb: globalGainDb ?? this.globalGainDb,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      serialNumber: serialNumber ?? this.serialNumber,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DacDevice &&
        other.id == id &&
        other.vendorId == vendorId &&
        other.productId == productId &&
        other.productName == productName &&
        other.chipset == chipset &&
        other.maxBands == maxBands &&
        other.isConnected == isConnected &&
        other.isEqEnabled == isEqEnabled &&
        other.globalGainDb == globalGainDb &&
        other.firmwareVersion == firmwareVersion &&
        other.serialNumber == serialNumber;
  }

  @override
  int get hashCode => Object.hash(
        id,
        vendorId,
        productId,
        productName,
        chipset,
        maxBands,
        isConnected,
        isEqEnabled,
        globalGainDb,
        firmwareVersion,
        serialNumber,
      );

  @override
  String toString() =>
      'DacDevice($formattedTitle, $vendorIdHex:$productIdHex, ${chipset.displayName}, connected: $isConnected, eq: $isEqEnabled)';
}
