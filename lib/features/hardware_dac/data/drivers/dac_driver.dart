import '../../domain/models/dac_band_config.dart';
import '../../domain/models/dac_device.dart';
import '../../domain/models/dac_peq_profile.dart';
import '../transports/dac_transport.dart';

/// Abstract hardware driver defining standard operations across all DAC chipsets.
abstract class DacDriver {
  /// The transport layer used for communicating with the physical/mock USB DAC.
  DacTransport get transport;

  /// The chipset model supported by this driver.
  DacChipset get chipset;

  /// Returns true if the DAC hardware is currently connected.
  bool get isConnected;

  /// Initializes the driver and synchronizes initial hardware states.
  Future<bool> initialize();

  /// Reads whether the hardware PEQ is currently active (true) or bypassed (false).
  Future<bool> getEqEnabled();

  /// Sets the hardware PEQ active or bypassed.
  Future<bool> setEqEnabled(bool enabled);

  /// Reads all active PEQ band configurations from hardware RAM registers.
  Future<List<DacBandConfig>> readAllBands();

  /// Writes a single band configuration into hardware RAM registers in real-time.
  Future<bool> writeBand(DacBandConfig band);

  /// Writes all band configurations into hardware RAM registers.
  Future<bool> writeAllBands(List<DacBandConfig> bands);

  /// Writes an entire profile (bands + preamp) to hardware.
  Future<bool> applyProfile(DacPeqProfile profile);

  /// Burns active RAM registers into non-volatile EEPROM/Flash.
  Future<bool> saveToFlash();

  /// Resets hardware registers and EEPROM to factory defaults.
  Future<bool> clearFlash();

  /// Reads the global hardware volume / gain in dB (if supported).
  Future<double?> readGlobalGain();

  /// Writes the global hardware volume / gain in dB (if supported).
  Future<bool> writeGlobalGain(double gainDb);

  /// Disposes driver resources and disconnects transport.
  Future<void> dispose();
}
