import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../pro_q_studio/domain/eq_band.dart';
import '../../data/drivers/dac_driver.dart';
import '../../data/drivers/kiwi_ears_kt_driver.dart';
import '../../data/transports/android_usb_hid_transport.dart';
import '../../data/transports/dac_transport.dart';
import '../../data/transports/linux_hidraw_transport.dart';
import '../../data/transports/mock_dac_transport.dart';
import '../../domain/models/dac_band_config.dart';
import '../../domain/models/dac_device.dart';
import '../../domain/models/dac_peq_profile.dart';
import '../../domain/services/auto_eq_to_hardware_fitter.dart';
import 'dac_bridge_state.dart';

/// Riverpod provider for the hardware DAC transport layer.
final dacTransportProvider = Provider<DacTransport>((ref) {
  if (Platform.isLinux) {
    return LinuxHidRawTransport();
  } else if (Platform.isAndroid) {
    return AndroidUsbHidTransport();
  }
  return MockDacTransport(autoConnect: false);
});

/// Riverpod provider for the main Hardware DAC Bridge controller.
final dacBridgeControllerProvider =
    StateNotifierProvider<DacBridgeController, DacBridgeState>((ref) {
  final transport = ref.watch(dacTransportProvider);
  final driver = KiwiEarsKtDriver(transport: transport);
  const fitter = AutoEqToHardwareFitter();

  return DacBridgeController(
    driver: driver,
    fitter: fitter,
  );
});

/// Riverpod StateNotifier controlling hardware USB DAC connectivity, PEQ editing, and EEPROM flashing.
class DacBridgeController extends StateNotifier<DacBridgeState> {
  DacBridgeController({
    required this.driver,
    required this.fitter,
    bool enableHotplugWatcher = true,
  }) : super(DacBridgeState(availablePresets: DacPeqProfile.builtInPresets)) {
    driver.transport.setOnDisconnectListener(_handleTransportDisconnect);
    if (driver.transport is AndroidUsbHidTransport) {
      (driver.transport as AndroidUsbHidTransport).setOnDeviceAttachedListener(() {
        _lastAttemptedDeviceId = null;
        if (!state.isConnected && _activeConnectFuture == null) {
          scanAndConnect();
        }
      });
    }
    _initAutoConnect();
    final isTest = Platform.environment.containsKey('FLUTTER_TEST');
    if (enableHotplugWatcher && !isTest) {
      _startHotplugWatcher();
    }
  }

  final DacDriver driver;
  final AutoEqToHardwareFitter fitter;
  Timer? _hotplugTimer;
  Future<void>? _activeConnectFuture;
  String? _lastAttemptedDeviceId;

  void _handleTransportDisconnect() {
    _lastAttemptedDeviceId = null;
    if (state.isConnected || state.device != null) {
      state = state.copyWith(
        status: DacBridgeStatus.disconnected,
        device: () => null,
        statusBannerMessage: () => 'USB DAC disconnected.',
      );
    }
  }

  void _startHotplugWatcher() {
    _hotplugTimer?.cancel();
    _hotplugTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      _checkHotplugStatus();
    });
  }

  Future<void> _checkHotplugStatus() async {
    if (_activeConnectFuture != null) return;

    if (state.isConnected) {
      final currentDev = state.device;
      if (currentDev != null) {
        if (Platform.isLinux) {
          final file = File(currentDev.id);
          if (!file.existsSync() || !driver.transport.isConnected) {
            await driver.transport.disconnect();
            _handleTransportDisconnect();
          }
        } else if (Platform.isAndroid) {
          if (!driver.transport.isConnected) {
            await driver.transport.disconnect();
            _handleTransportDisconnect();
          }
        }
      }
    } else if (state.status != DacBridgeStatus.connecting &&
        state.status != DacBridgeStatus.reading &&
        state.status != DacBridgeStatus.writing &&
        state.status != DacBridgeStatus.flashing) {
      // Silently check if a DAC has been plugged in
      if (Platform.isLinux) {
        try {
          final devices = await LinuxHidRawTransport.enumerateDevices();
          if (devices.isEmpty) {
            _lastAttemptedDeviceId = null;
          } else {
            final target = devices.first;
            if (target.id != _lastAttemptedDeviceId) {
              _lastAttemptedDeviceId = target.id;
              await scanAndConnect(targetDevice: target);
            }
          }
        } catch (_) {}
      } else if (Platform.isAndroid) {
        try {
          final devices = await AndroidUsbHidTransport.enumerateDevices();
          if (devices.isEmpty) {
            _lastAttemptedDeviceId = null;
          } else {
            final target = devices.first;
            if (target.id != _lastAttemptedDeviceId) {
              _lastAttemptedDeviceId = target.id;
              await scanAndConnect(targetDevice: target);
            }
          }
        } catch (_) {}
      }
    }
  }

  Future<void> _initAutoConnect() async {
    await scanAndConnect();
  }

  /// Scans for connected USB DACs and establishes HID connection.
  Future<void> scanAndConnect({DacDevice? targetDevice, bool isManual = false}) async {
    if (_activeConnectFuture != null) {
      if (!isManual) {
        return _activeConnectFuture!;
      }
      try {
        await _activeConnectFuture;
      } catch (_) {}
    }

    final future = _performScanAndConnect(targetDevice: targetDevice, isManual: isManual);
    _activeConnectFuture = future;
    try {
      await future;
    } finally {
      if (_activeConnectFuture == future) {
        _activeConnectFuture = null;
      }
    }
  }

  Future<void> _performScanAndConnect({DacDevice? targetDevice, bool isManual = false}) async {
    if (isManual) {
      _lastAttemptedDeviceId = null;
    }
    state = state.copyWith(status: DacBridgeStatus.connecting);

    try {
      final device = await driver.transport.connect(specificDevice: targetDevice);
      if (device != null) {
        final initialized = await driver.initialize();
        if (initialized) {
          final bands = await driver.readAllBands();
          final isEqEnabled = await driver.getEqEnabled();
          final globalGain = await driver.readGlobalGain() ?? 0.0;

          final profile = DacPeqProfile(
            id: 'active_dac_profile',
            name: '${device.productName} Active Tuning',
            bands: bands,
            preampGainDb: globalGain,
            targetChipset: device.chipset,
          );

          state = state.copyWith(
            status: DacBridgeStatus.connected,
            device: () => device,
            currentProfile: profile,
            isEqEnabled: isEqEnabled,
            globalGainDb: globalGain,
            hasUnsavedFlashChanges: false,
            errorMessage: () => null,
            statusBannerMessage: () => '${device.productName} connected & synced.',
          );
          return;
        }
      }

      state = state.copyWith(
        status: DacBridgeStatus.disconnected,
        device: () => null,
        statusBannerMessage: () => 'No supported USB DAC detected.',
      );
    } catch (e) {
      state = state.copyWith(
        status: DacBridgeStatus.error,
        errorMessage: () => 'Connection failed: $e',
      );
    }
  }

  /// Disconnects the active USB DAC session.
  Future<void> disconnect() async {
    _lastAttemptedDeviceId = null;
    await driver.transport.disconnect();
    state = state.copyWith(
      status: DacBridgeStatus.disconnected,
      device: () => null,
      statusBannerMessage: () => 'DAC disconnected.',
    );
  }

  /// Toggles hardware EQ active vs bypass in real-time.
  Future<bool> toggleHardwareEq(bool enabled) async {
    if (!state.isConnected) return false;
    final success = await driver.setEqEnabled(enabled);
    if (success) {
      state = state.copyWith(
        isEqEnabled: enabled,
        hasUnsavedFlashChanges: true,
      );
    }
    return success;
  }

  /// Updates a single band's frequency, gain, Q-factor, or filter type.
  Future<bool> updateBand(
    int bandIndex, {
    double? frequency,
    double? gainDb,
    double? qFactor,
    DacFilterType? filterType,
    bool? isBypassed,
  }) async {
    if (!state.isConnected) return false;
    if (bandIndex < 0 || bandIndex >= state.bands.length) return false;

    final currentBand = state.bands[bandIndex];
    final updatedBand = currentBand.copyWith(
      frequency: frequency,
      gainDb: gainDb,
      qFactor: qFactor,
      filterType: filterType,
      isBypassed: isBypassed,
    );

    final updatedBands = List<DacBandConfig>.from(state.bands);
    updatedBands[bandIndex] = updatedBand;

    // Realtime write to hardware RAM register
    final success = await driver.writeBand(updatedBand);
    if (success) {
      state = state.copyWith(
        currentProfile: state.currentProfile.copyWith(bands: updatedBands),
        hasUnsavedFlashChanges: true,
      );
    }
    return success;
  }

  /// Applies a full DacPeqProfile in real-time.
  Future<bool> applyProfile(DacPeqProfile profile) async {
    if (!state.isConnected) return false;
    state = state.copyWith(status: DacBridgeStatus.writing);

    final success = await driver.applyProfile(profile);
    if (success) {
      state = state.copyWith(
        status: DacBridgeStatus.connected,
        currentProfile: profile,
        globalGainDb: profile.preampGainDb,
        hasUnsavedFlashChanges: true,
        statusBannerMessage: () => 'Profile "${profile.name}" applied to RAM.',
      );
    } else {
      state = state.copyWith(
        status: DacBridgeStatus.connected,
        errorMessage: () => 'Failed to apply profile to hardware.',
      );
    }
    return success;
  }

  /// Converts a multi-band Pro-Q Studio or AutoEQ curve and applies it to the hardware DAC.
  Future<bool> importFromAutoEq(List<EqBand> eqBands, {String name = 'AutoEQ Import'}) async {
    final fittedProfile = fitter.fitFromEqBands(
      eqBands,
      name: name,
      targetChipset: state.device?.chipset ?? DacChipset.kt0211l,
      targetBandCount: state.device?.maxBands ?? 5,
    );
    return await applyProfile(fittedProfile);
  }

  /// Flashes/Burns active RAM registers into non-volatile EEPROM memory.
  Future<bool> burnToFlash() async {
    if (!state.isConnected) return false;
    state = state.copyWith(status: DacBridgeStatus.flashing);

    final success = await driver.saveToFlash();
    if (success) {
      state = state.copyWith(
        status: DacBridgeStatus.connected,
        hasUnsavedFlashChanges: false,
        statusBannerMessage: () => 'Flashing successful! EQ saved to hardware memory.',
      );
    } else {
      state = state.copyWith(
        status: DacBridgeStatus.connected,
        errorMessage: () => 'Failed to burn settings to EEPROM Flash.',
      );
    }
    return success;
  }

  /// Resets hardware registers to factory default flat EQ and clears flash.
  Future<bool> clearFlash() async {
    if (!state.isConnected) return false;
    state = state.copyWith(status: DacBridgeStatus.flashing);

    final isSuccess = await driver.clearFlash();
    if (isSuccess) {
      final flatProfile = DacPeqProfile.flatDefault;

      state = state.copyWith(
        status: DacBridgeStatus.connected,
        currentProfile: flatProfile,
        isEqEnabled: true,
        globalGainDb: 0.0,
        hasUnsavedFlashChanges: false,
        statusBannerMessage: () => 'DAC restored to factory defaults.',
      );
    } else {
      state = state.copyWith(
        status: DacBridgeStatus.connected,
        errorMessage: () => 'Factory reset failed.',
      );
    }
    return isSuccess;
  }

  /// Sets global hardware analog gain / preamp volume.
  Future<bool> setGlobalGain(double gainDb) async {
    if (!state.isConnected) return false;
    final success = await driver.writeGlobalGain(gainDb);
    if (success) {
      state = state.copyWith(
        globalGainDb: gainDb,
        hasUnsavedFlashChanges: true,
      );
    }
    return success;
  }

  /// Refreshes and re-reads all hardware registers directly from the physical device.
  Future<void> refreshFromHardware() async {
    if (!state.isConnected) return;
    state = state.copyWith(status: DacBridgeStatus.reading);

    try {
      final bands = await driver.readAllBands();
      final isEqEnabled = await driver.getEqEnabled();
      final globalGain = await driver.readGlobalGain() ?? 0.0;

      final profile = state.currentProfile.copyWith(
        bands: bands,
        preampGainDb: globalGain,
      );

      state = state.copyWith(
        status: DacBridgeStatus.connected,
        currentProfile: profile,
        isEqEnabled: isEqEnabled,
        globalGainDb: globalGain,
        hasUnsavedFlashChanges: false,
        statusBannerMessage: () => 'Synced with hardware registers.',
      );
    } catch (e) {
      state = state.copyWith(
        status: DacBridgeStatus.connected,
        errorMessage: () => 'Failed to read from hardware: $e',
      );
    }
  }

  @override
  void dispose() {
    _hotplugTimer?.cancel();
    super.dispose();
  }
}
