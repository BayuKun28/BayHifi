import '../../domain/models/dac_band_config.dart';
import '../../domain/models/dac_device.dart';
import '../../domain/models/dac_peq_profile.dart';
import '../protocols/dac_packet_decoder.dart';
import '../protocols/dac_packet_encoder.dart';
import '../transports/dac_transport.dart';
import 'dac_driver.dart';

/// Driver for CB-Series DSP DACs (CB-5000X 6-band, CB-3000S 4-band).
class CbDacDriver implements DacDriver {
  CbDacDriver({
    required this.transport,
    this.chipset = DacChipset.cb5000x,
    this.reportId = 0x81, // 129
    this.encoder = const DacPacketEncoder(),
    this.decoder = const DacPacketDecoder(),
  });

  @override
  final DacTransport transport;

  @override
  final DacChipset chipset;

  final int reportId;
  final DacPacketEncoder encoder;
  final DacPacketDecoder decoder;

  List<DacBandConfig> _cachedBands = DacBandConfig.defaultStandard5Bands;
  bool _cachedEqEnabled = true;

  @override
  bool get isConnected => transport.isConnected;

  DacChipset get supportedChipset => chipset;

  @override
  Future<bool> initialize() async {
    if (!isConnected) return false;
    try {
      await readAllBands();
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> getEqEnabled() async => _cachedEqEnabled;

  @override
  Future<bool> setEqEnabled(bool enabled) async {
    _cachedEqEnabled = enabled;
    return true;
  }

  @override
  Future<List<DacBandConfig>> readAllBands() async => _cachedBands;

  @override
  Future<bool> writeBand(DacBandConfig band) async {
    final regAddr = 0x20 + band.bandIndex; // 32 + band
    final packet = encoder.encodeCbWriteBand(
      registerAddress: regAddr,
      frequencyHz: band.clampedFrequency,
      gainDb: band.isBypassed ? 0.0 : band.clampedGainDb,
      qFactor: band.clampedQFactor,
    );
    await transport.sendOutputReport(reportId, packet);
    return true;
  }

  @override
  Future<bool> writeAllBands(List<DacBandConfig> bands) async {
    for (final band in bands) {
      await writeBand(band);
    }
    _cachedBands = bands;
    return true;
  }

  @override
  Future<bool> applyProfile(DacPeqProfile profile) async {
    return await writeAllBands(profile.bands);
  }

  @override
  Future<bool> saveToFlash() async {
    final packet = encoder.encodeCbSaveFlash();
    await transport.sendOutputReport(reportId, packet);
    return true;
  }

  @override
  Future<bool> clearFlash() async {
    _cachedBands = DacBandConfig.defaultStandard5Bands;
    return true;
  }

  @override
  Future<double?> readGlobalGain() async => null;

  @override
  Future<bool> writeGlobalGain(double gainDb) async => false;

  @override
  Future<void> dispose() async {
    await transport.disconnect();
  }
}
