import 'package:flutter_test/flutter_test.dart';
import 'package:baydev_hifi/features/hardware_dac/data/drivers/kiwi_ears_kt_driver.dart';
import 'package:baydev_hifi/features/hardware_dac/data/transports/mock_dac_transport.dart';
import 'package:baydev_hifi/features/hardware_dac/domain/models/dac_band_config.dart';
import 'package:baydev_hifi/features/hardware_dac/domain/models/dac_device.dart';
import 'package:baydev_hifi/features/hardware_dac/domain/models/dac_peq_profile.dart';

void main() {
  group('KiwiEarsKtDriver Unit Tests', () {
    late MockDacTransport transport;
    late KiwiEarsKtDriver driver;

    setUp(() {
      transport = MockDacTransport();
      driver = KiwiEarsKtDriver(transport: transport, chipset: DacChipset.kt0211l);
    });

    tearDown(() {
      transport.dispose();
    });

    test('Initializes driver and reads default factory bands', () async {
      final initialized = await driver.initialize();
      expect(initialized, isTrue);

      final bands = driver.cachedBands;
      expect(bands.length, equals(5));
      expect(bands[0].frequency, closeTo(28.0, 0.1));
      expect(bands[1].frequency, closeTo(84.0, 0.1));
      expect(bands[2].frequency, closeTo(680.0, 0.1));
      expect(bands[3].frequency, closeTo(4300.0, 0.1));
      expect(bands[4].frequency, closeTo(14500.0, 0.1));

      expect(driver.cachedEqEnabled, isTrue);
    });

    test('Toggles Hardware EQ Enable & Bypass', () async {
      await driver.initialize();

      final disabledSuccess = await driver.setEqEnabled(false);
      expect(disabledSuccess, isTrue);
      expect(driver.cachedEqEnabled, isFalse);

      final reEnabledSuccess = await driver.setEqEnabled(true);
      expect(reEnabledSuccess, isTrue);
      expect(driver.cachedEqEnabled, isTrue);
    });

    test('Writes single band and verifies updated state', () async {
      await driver.initialize();

      const newBand = DacBandConfig(
        bandIndex: 0,
        frequency: 65.0,
        gainDb: 3.5,
        qFactor: 0.85,
      );

      final writeOk = await driver.writeBand(newBand);
      expect(writeOk, isTrue);

      // Verify cached
      expect(driver.cachedBands[0].frequency, closeTo(65.0, 0.1));
      expect(driver.cachedBands[0].gainDb, closeTo(3.5, 0.1));
      expect(driver.cachedBands[0].qFactor, closeTo(0.85, 0.01));

      // Re-read directly from hardware RAM
      final readBands = await driver.readAllBands();
      expect(readBands[0].frequency, closeTo(65.0, 0.1));
      expect(readBands[0].gainDb, closeTo(3.5, 0.1));
      expect(readBands[0].qFactor, closeTo(0.85, 0.01));
    });

    test('Applies full DacPeqProfile and saves to Flash', () async {
      await driver.initialize();

      final profile = DacPeqProfile.harmanIemTarget;
      final applied = await driver.applyProfile(profile);
      expect(applied, isTrue);

      expect(driver.cachedBands[0].frequency, closeTo(50.0, 0.1));
      expect(driver.cachedBands[0].gainDb, closeTo(4.5, 0.1));
      expect(driver.cachedBands[2].frequency, closeTo(2800.0, 0.1));
      expect(driver.cachedBands[2].gainDb, closeTo(3.0, 0.1));

      final saveOk = await driver.saveToFlash();
      expect(saveOk, isTrue);
    });

    test('Clears Flash and resets to flat factory defaults', () async {
      await driver.initialize();

      // Modify band 0
      await driver.writeBand(const DacBandConfig(
        bandIndex: 0,
        frequency: 100.0,
        gainDb: 6.0,
        qFactor: 1.0,
      ));
      expect(driver.cachedBands[0].gainDb, closeTo(6.0, 0.1));

      // Clear flash
      final clearOk = await driver.clearFlash();
      expect(clearOk, isTrue);

      // Band 0 should be reset to 0dB gain
      expect(driver.cachedBands[0].gainDb, closeTo(0.0, 0.1));
    });

    test('Reads and writes Global Hardware Volume / Preamp', () async {
      await driver.initialize();

      final writeGainOk = await driver.writeGlobalGain(-3.5);
      expect(writeGainOk, isTrue);
      expect(driver.cachedGlobalGain, closeTo(-3.5, 0.1));

      final readGain = await driver.readGlobalGain();
      expect(readGain, isNotNull);
      expect(readGain!, closeTo(-3.5, 0.1));
    });
  });
}
