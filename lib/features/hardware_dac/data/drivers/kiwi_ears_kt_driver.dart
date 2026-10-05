import '../../domain/models/dac_band_config.dart';
import '../../domain/models/dac_device.dart';
import '../../domain/models/dac_peq_profile.dart';
import '../protocols/dac_packet_decoder.dart';
import '../protocols/dac_packet_encoder.dart';
import '../transports/dac_transport.dart';
import 'dac_driver.dart';

/// Driver for KTmicro chipsets: KT0211L, KT1132L, KT3016L (Kiwi Ears AD1, S-Link, Allegro Mini).
class KiwiEarsKtDriver implements DacDriver {
  KiwiEarsKtDriver({
    required this.transport,
    this.chipset = DacChipset.kt0211l,
    this.reportId = 0x4B, // 75 ('K')
    this.encoder = const DacPacketEncoder(),
    this.decoder = const DacPacketDecoder(),
  });

  @override
  final DacTransport transport;

  @override
  final DacChipset chipset;

  /// USB HID report ID (typically 0x4B / 75).
  final int reportId;

  final DacPacketEncoder encoder;
  final DacPacketDecoder decoder;

  List<DacBandConfig> _cachedBands = DacBandConfig.defaultKiwiEars5Bands;
  bool _cachedEqEnabled = true;
  double _cachedGlobalGain = 0.0;

  @override
  bool get isConnected => transport.isConnected;

  List<DacBandConfig> get cachedBands => List.unmodifiable(_cachedBands);
  bool get cachedEqEnabled => _cachedEqEnabled;
  double get cachedGlobalGain => _cachedGlobalGain;

  DacChipset get supportedChipset => chipset;

  @override
  Future<bool> initialize() async {
    if (!isConnected) return false;
    try {
      await readAllBands();
      await getEqEnabled();
      if (chipset.hasGlobalGain) {
        await readGlobalGain();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> getEqEnabled() async {
    final packet = encoder.encodeKtReadRegister(Kt0211Registers.allEnable);
    final response = await transport.sendCommandWithResponse(reportId, packet);
    final isEnabled = decoder.parseKtEnableResponse(response);
    if (isEnabled != null) {
      _cachedEqEnabled = isEnabled;
      return isEnabled;
    }
    return _cachedEqEnabled;
  }

  @override
  Future<bool> setEqEnabled(bool enabled) async {
    final packet = encoder.encodeKtWriteEnable(
      registerAddress: Kt0211Registers.allEnable,
      enabled: enabled,
    );
    final response = await transport.sendCommandWithResponse(
      reportId,
      packet,
      verifyFlag: true,
      expectedFlag: _expectedAckFlag,
    );
    final success = decoder.verifyKtSuccessFlag(response, expectedFlag: _expectedAckFlag);
    if (success) {
      _cachedEqEnabled = enabled;
    }
    return success;
  }

  @override
  Future<List<DacBandConfig>> readAllBands() async {
    final List<DacBandConfig> bands = [];
    final int bandCount = chipset.defaultBands;

    for (int i = 0; i < bandCount; i++) {
      final freqReg = Kt0211Registers.freqRegForBand(i);
      final qReg = Kt0211Registers.qRegForBand(i);

      // Read Frequency & Gain
      final freqPacket = encoder.encodeKtReadRegister(freqReg);
      final freqResp = await transport.sendCommandWithResponse(reportId, freqPacket);
      final parsedFreqGain = decoder.parseKtFrequencyGainResponse(freqResp);

      // Read Q
      final qPacket = encoder.encodeKtReadRegister(qReg);
      final qResp = await transport.sendCommandWithResponse(reportId, qPacket);
      final parsedQ = decoder.parseKtQResponse(qResp) ?? 0.707;

      final freq = parsedFreqGain?['frequency'] ?? _cachedBands[i].frequency;
      final gain = parsedFreqGain?['gainDb'] ?? _cachedBands[i].gainDb;

      bands.add(DacBandConfig(
        bandIndex: i,
        frequency: freq,
        gainDb: gain,
        qFactor: parsedQ,
        filterType: i == 0 ? DacFilterType.lowShelf : (i == bandCount - 1 ? DacFilterType.highShelf : DacFilterType.peaking),
      ));
    }

    _cachedBands = bands;
    return bands;
  }

  @override
  Future<bool> writeBand(DacBandConfig band) async {
    if (band.bandIndex < 0 || band.bandIndex >= chipset.defaultBands) {
      return false;
    }

    final freqReg = Kt0211Registers.freqRegForBand(band.bandIndex);
    final qReg = Kt0211Registers.qRegForBand(band.bandIndex);

    // 1. Write Frequency & Gain
    final freqPacket = encoder.encodeKtWriteFreqGain(
      registerAddress: freqReg,
      frequencyHz: band.clampedFrequency,
      gainDb: band.isBypassed ? 0.0 : band.clampedGainDb,
    );
    final freqResp = await transport.sendCommandWithResponse(
      reportId,
      freqPacket,
      verifyFlag: true,
      expectedFlag: _expectedAckFlag,
    );
    final freqOk = decoder.verifyKtSuccessFlag(freqResp, expectedFlag: _expectedAckFlag);

    // 2. Write Q-Factor
    final qPacket = encoder.encodeKtWriteQ(
      registerAddress: qReg,
      qFactor: band.clampedQFactor,
    );
    final qResp = await transport.sendCommandWithResponse(
      reportId,
      qPacket,
      verifyFlag: true,
      expectedFlag: _expectedAckFlag,
    );
    final qOk = decoder.verifyKtSuccessFlag(qResp, expectedFlag: _expectedAckFlag);

    if (freqOk && qOk) {
      final updated = List<DacBandConfig>.from(_cachedBands);
      updated[band.bandIndex] = band;
      _cachedBands = updated;
      return true;
    }
    return false;
  }

  @override
  Future<bool> writeAllBands(List<DacBandConfig> bands) async {
    bool allSuccess = true;
    for (final band in bands) {
      final success = await writeBand(band);
      if (!success) allSuccess = false;
    }
    return allSuccess;
  }

  @override
  Future<bool> applyProfile(DacPeqProfile profile) async {
    final success = await writeAllBands(profile.bands);
    if (success && chipset.hasGlobalGain && profile.preampGainDb != 0.0) {
      await writeGlobalGain(profile.preampGainDb);
    }
    return success;
  }

  @override
  Future<bool> saveToFlash() async {
    final packet = encoder.encodeKtSaveFlash();
    final response = await transport.sendCommandWithResponse(
      reportId,
      packet,
      verifyFlag: true,
      expectedFlag: _expectedAckFlag,
    );
    return decoder.verifyKtSuccessFlag(response, expectedFlag: _expectedAckFlag);
  }

  @override
  Future<bool> clearFlash() async {
    final packet = encoder.encodeKtClearFlash();
    final response = await transport.sendCommandWithResponse(
      reportId,
      packet,
      verifyFlag: true,
      expectedFlag: _expectedAckFlag,
    );
    final success = decoder.verifyKtSuccessFlag(response, expectedFlag: _expectedAckFlag);
    if (success) {
      await readAllBands();
    }
    return success;
  }

  @override
  Future<double?> readGlobalGain() async {
    if (!chipset.hasGlobalGain) return null;
    final packet = encoder.encodeKtReadRegister(Kt0211Registers.dacVol);
    final response = await transport.sendCommandWithResponse(reportId, packet);
    final gain = decoder.parseKtGlobalGainResponse(response);
    if (gain != null) {
      _cachedGlobalGain = gain;
    }
    return gain;
  }

  @override
  Future<bool> writeGlobalGain(double gainDb) async {
    if (!chipset.hasGlobalGain) return false;
    final packet = encoder.encodeKtWriteGlobalGain(
      registerAddress: Kt0211Registers.dacVol,
      gainDb: gainDb,
    );
    final response = await transport.sendCommandWithResponse(
      reportId,
      packet,
      verifyFlag: true,
      expectedFlag: _expectedAckFlag,
    );
    final success = decoder.verifyKtSuccessFlag(response, expectedFlag: _expectedAckFlag);
    if (success) {
      _cachedGlobalGain = gainDb;
    }
    return success;
  }

  @override
  Future<void> dispose() async {
    await transport.disconnect();
  }

  int get _expectedAckFlag =>
      chipset == DacChipset.kt1132l ? KtCommands.flagOkKt1132 : KtCommands.flagOkKt0211;
}
