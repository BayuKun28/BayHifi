import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/theme_mode_controller.dart';
import '../../../../audio_engine/virtual_dsp_service.dart';
import '../../../../core/database/local_persistence_service.dart';
import '../../../analytics/data/playback_analytics_service.dart';
import '../../../dsp_rack/presentation/controllers/dsp_rack_controller.dart';
import '../../../hardware_dac/presentation/controllers/dac_bridge_controller.dart';
import '../../../library/presentation/controllers/library_controller.dart';
import '../../../pro_q_studio/presentation/controllers/eq_controller.dart';
import '../../../settings/presentation/controllers/player_customization_controller.dart';
import '../../data/cloud_sync_service.dart';
import '../../domain/cloud_auth_state.dart';

final cloudSyncServiceProvider = Provider<CloudSyncService>((ref) {
  return CloudSyncService();
});

final cloudAuthControllerProvider =
    StateNotifierProvider<CloudAuthController, CloudAuthState>((ref) {
  final service = ref.watch(cloudSyncServiceProvider);
  return CloudAuthController(service, null, ref);
});

class CloudAuthController extends StateNotifier<CloudAuthState> {
  final CloudSyncService _service;
  final Ref? ref;

  CloudAuthController(this._service, [CloudAuthState? initialState, this.ref])
      : super(initialState ?? const CloudAuthState()) {
    if (initialState == null) {
      _hydrateSession();
    }
  }

  void _autoApplyUserConfiguration() {
    final r = ref;
    if (r == null) return;
    try {
      r.read(themeControllerProvider.notifier).hydrateFromStorage();
    } catch (e) {
      debugPrint('[CloudAuthController] Theme hydration notice: $e');
    }
    try {
      r.read(playerCustomizationProvider.notifier).hydrateFromStorage();
    } catch (e) {
      debugPrint('[CloudAuthController] Player customization hydration notice: $e');
    }
    try {
      r.read(eqControllerProvider.notifier).hydrateFromStorage();
    } catch (e) {
      debugPrint('[CloudAuthController] EQ hydration notice: $e');
    }
    try {
      r.read(dspRackControllerProvider.notifier).hydrateFromStorage();
    } catch (e) {
      debugPrint('[CloudAuthController] DSP rack hydration notice: $e');
    }
    try {
      r.read(dacBridgeControllerProvider.notifier).hydrateFromStorage();
    } catch (e) {
      debugPrint('[CloudAuthController] DAC bridge hydration notice: $e');
    }
    try {
      r.read(unifiedLibraryProvider.notifier).reloadFromPersistence();
    } catch (e) {
      debugPrint('[CloudAuthController] Library hydration notice: $e');
    }
    try {
      r.read(analyticsRevisionProvider.notifier).state++;
    } catch (e) {
      debugPrint('[CloudAuthController] Analytics revision notice: $e');
    }
  }

  Future<void> _hydrateSession() async {
    final session = await _service.getSavedSession();
    final defaultUrl = kIsWeb ? Uri.base.origin : 'http://localhost:8111';
    final serverUrl = session['serverUrl'] as String? ?? defaultUrl;
    final token = session['token'] as String?;
    final user = session['user'];
    final lastSyncedAt = session['lastSyncedAt'] as DateTime?;

    if (token != null && token.isNotEmpty && user != null) {
      final userId = user.id.toString();
      await LocalPersistenceService.instance.switchUser(userId);
      state = state.copyWith(
        status: CloudAuthStatus.authenticated,
        token: token,
        user: user,
        serverUrl: serverUrl,
        lastSyncedAt: lastSyncedAt,
      );
      _autoApplyUserConfiguration();
      // Auto-sync in background after session restored
      Future.delayed(const Duration(seconds: 2), () {
        if (state.isAuthenticated) {
          syncNow();
        }
      });
    } else {
      await LocalPersistenceService.instance.switchUser('guest');
      state = state.copyWith(
        status: CloudAuthStatus.guest,
        serverUrl: serverUrl,
      );
    }
  }

  /// Login ke akun BayHifi Cloud
  Future<bool> login({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    state = state.copyWith(status: CloudAuthStatus.loading, clearError: true);
    final res = await _service.login(
      serverUrl: serverUrl,
      username: username,
      password: password,
    );

    if (res['success'] == true) {
      final user = res['user'];
      final userId = user?.id?.toString() ?? user?['id']?.toString() ?? '';
      if (userId.isNotEmpty) {
        await LocalPersistenceService.instance.switchUser(userId);
      }
      state = state.copyWith(
        status: CloudAuthStatus.authenticated,
        token: res['token'] as String?,
        user: res['user'],
        serverUrl: _service.sanitizeUrl(serverUrl),
        clearError: true,
      );

      // Pull remote user settings, playback history logs & DSP profile if available
      try {
        if (state.token != null) {
          final remoteSettings = await _service.fetchUserSettings(
            serverUrl: state.serverUrl,
            token: state.token!,
          );
          if (remoteSettings != null && remoteSettings.isNotEmpty) {
            await LocalPersistenceService.instance.importCurrentUserSettings(remoteSettings, overwrite: true);
          }
          final remoteLogs = await _service.fetchPlaybackLogs(
            serverUrl: state.serverUrl,
            token: state.token!,
          );
          if (remoteLogs.isNotEmpty) {
            await LocalPersistenceService.instance.importPlaybackLogs(remoteLogs);
          }
          final remoteDsp = await _service.fetchDspProfile(
            serverUrl: state.serverUrl,
            token: state.token!,
          );
          if (remoteDsp != null) {
            _importRemoteDspProfile(remoteDsp);
          }
        }
      } catch (e) {
        debugPrint('[CloudAuthController] Remote hydration error: $e');
      }

      // Auto-apply user configuration dynamically into UI and audio engine
      _autoApplyUserConfiguration();

      // Immediate bidirectional sync on successful login (push & finalize)
      await syncNow();
      return true;
    } else {
      state = state.copyWith(
        status: CloudAuthStatus.error,
        errorMessage: res['message'] as String? ?? 'Login failed',
      );
      return false;
    }
  }

  /// Registrasi akun baru
  Future<bool> register({
    required String serverUrl,
    required String username,
    required String password,
    String? email,
  }) async {
    state = state.copyWith(status: CloudAuthStatus.loading, clearError: true);
    final res = await _service.register(
      serverUrl: serverUrl,
      username: username,
      password: password,
      email: email,
    );

    if (res['success'] == true) {
      final user = res['user'];
      final userId = user?.id?.toString() ?? user?['id']?.toString() ?? '';
      if (userId.isNotEmpty) {
        await LocalPersistenceService.instance.switchUser(userId);
      }
      state = state.copyWith(
        status: CloudAuthStatus.authenticated,
        token: res['token'] as String?,
        user: res['user'],
        serverUrl: _service.sanitizeUrl(serverUrl),
        clearError: true,
      );

      _autoApplyUserConfiguration();
      await syncNow();
      return true;
    } else {
      state = state.copyWith(
        status: CloudAuthStatus.error,
        errorMessage: res['message'] as String? ?? 'Registration failed',
      );
      return false;
    }
  }

  /// Logout akun cloud (kembali ke Guest / Offline mode)
  Future<void> logout() async {
    await LocalPersistenceService.instance.switchUser('guest');
    await _service.clearSession();
    state = state.copyWith(
      clearAuth: true,
      status: CloudAuthStatus.guest,
      clearError: true,
    );
    _autoApplyUserConfiguration();
  }

  /// Mengubah password akun
  Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    if (!state.isAuthenticated || state.token == null) {
      return {'success': false, 'message': 'Not authenticated'};
    }
    return await _service.changePassword(
      serverUrl: state.serverUrl,
      token: state.token!,
      oldPassword: oldPassword,
      newPassword: newPassword,
    );
  }

  /// Import and apply remote DSP & AutoEQ profile into local persistence & VirtualDspService
  void _importRemoteDspProfile(Map<String, dynamic> remoteDsp) {
    try {
      final rawBands = remoteDsp['bands'];
      List<Map<String, dynamic>> bands = [];
      if (rawBands is List) {
        bands = rawBands.map((b) => Map<String, dynamic>.from(b as Map)).toList();
      } else if (rawBands is String && rawBands.isNotEmpty) {
        final decoded = jsonDecode(rawBands);
        if (decoded is List) {
          bands = decoded.map((b) => Map<String, dynamic>.from(b as Map)).toList();
        }
      }

      if (bands.isNotEmpty) {
        LocalPersistenceService.instance.saveActiveEqState(
          bands: bands,
          preampDb: (remoteDsp['safePreampDb'] as num?)?.toDouble() ?? 0.0,
          activePresetName: remoteDsp['activePresetName'] as String? ?? 'Cloud Reference',
          lastDriverName: remoteDsp['driverName'] as String?,
          lastTargetName: remoteDsp['targetName'] as String?,
          isAutoEqActive: remoteDsp['isAutoEqActive'] as bool? ?? false,
          isEnabled: true,
          preserveCurvesIfNull: true,
        );
      }

      dynamic toggles = remoteDsp['dspToggles'];
      if (toggles is String && toggles.isNotEmpty) {
        try {
          toggles = jsonDecode(toggles);
        } catch (_) {}
      }
      if (toggles is Map) {
        final dsp = VirtualDspService.instance;
        if (toggles['tubeEnabled'] != null) dsp.toggleTubeExciter(toggles['tubeEnabled'] == true);
        if (toggles['limiterEnabled'] != null) dsp.toggleLimiter(toggles['limiterEnabled'] == true);
        if (toggles['reverbEnabled'] != null) dsp.toggleReverb(toggles['reverbEnabled'] == true);
        if (toggles['crossfeedEnabled'] != null) dsp.toggleCrossfeed(toggles['crossfeedEnabled'] == true);
        if (toggles['bassBoostEnabled'] != null) dsp.toggleBassBoost(toggles['bassBoostEnabled'] == true);
        if (toggles['stereoWidthEnabled'] != null) dsp.toggleStereoWidth(toggles['stereoWidthEnabled'] == true);
      }
    } catch (e) {
      debugPrint('[CloudAuthController] Remote DSP import error: $e');
    }
  }

  /// Sinkronisasi log pemutaran (Studio Wrapped), AutoEQ / DSP profil, dan pengaturan pengguna
  /// Melakukan sinkronisasi dua arah (GET data remote terlebih dahulu, lalu PUSH pembaruan lokal)
  /// Mengembalikan true jika sinkronisasi berhasil, false jika gagal.
  Future<bool> syncNow() async {
    // ATURAN KETAT: Jika tidak login, sama sekali tidak melakukan koneksi/sync!
    if (!state.isAuthenticated || state.token == null) {
      return false;
    }

    if (state.isSyncing) {
      return false;
    }

    state = state.copyWith(isSyncing: true, clearError: true);

    try {
      // 1. GET / PULL: Ambil data remote terbaru jika ada
      try {
        final remoteSettings = await _service.fetchUserSettings(
          serverUrl: state.serverUrl,
          token: state.token!,
        );
        if (remoteSettings != null && remoteSettings.isNotEmpty) {
          await LocalPersistenceService.instance.importCurrentUserSettings(remoteSettings, overwrite: false);
        }

        final remoteLogs = await _service.fetchPlaybackLogs(
          serverUrl: state.serverUrl,
          token: state.token!,
        );
        if (remoteLogs.isNotEmpty) {
          await LocalPersistenceService.instance.importPlaybackLogs(remoteLogs);
        }

        final remoteDsp = await _service.fetchDspProfile(
          serverUrl: state.serverUrl,
          token: state.token!,
        );
        if (remoteDsp != null) {
          _importRemoteDspProfile(remoteDsp);
        }
      } catch (e) {
        debugPrint('[CloudAuthController] Sync pull error: $e');
      }

      // 2. PUSH: Ambil log pemutaran lokal dan kirim ke cloud
      final rawLogs = LocalPersistenceService.instance.getPlaybackHistoryLogs();
      if (rawLogs.isNotEmpty) {
        await _service.syncPlaybackLogs(
          serverUrl: state.serverUrl,
          token: state.token!,
          logs: rawLogs,
        );
      }

      // 3. PUSH: Ambil profil AutoEQ & DSP aktif dan kirim ke cloud
      final eqData = LocalPersistenceService.instance.getActiveEqState();
      final dspService = VirtualDspService.instance;
      final dspPayload = {
        'activePresetName': eqData?['activePresetName'] ?? 'Flat Reference',
        'driverName': eqData?['lastDriverName'] ?? '',
        'targetName': eqData?['lastTargetName'] ?? '',
        'isAutoEqActive': eqData?['isAutoEqActive'] ?? false,
        'safePreampDb': dspService.preampGain,
        'bands': eqData?['bands'] ?? [],
        'dspToggles': {
          'tubeEnabled': dspService.tubeEnabled,
          'limiterEnabled': dspService.limiterEnabled,
          'reverbEnabled': dspService.reverbEnabled,
          'crossfeedEnabled': dspService.crossfeedEnabled,
          'bassBoostEnabled': dspService.bassBoostEnabled,
          'stereoWidthEnabled': dspService.stereoWidthEnabled,
        },
      };

      final dspSynced = await _service.syncDspProfile(
        serverUrl: state.serverUrl,
        token: state.token!,
        dspData: dspPayload,
      );

      // 4. PUSH: Sinkronkan seluruh bundel pengaturan pengguna ke cloud
      final settingsBundle = LocalPersistenceService.instance.exportCurrentUserSettings();
      bool settingsSynced = true;
      if (settingsBundle.isNotEmpty) {
        settingsSynced = await _service.saveUserSettings(
          serverUrl: state.serverUrl,
          token: state.token!,
          settings: settingsBundle,
        );
      }

      final isSuccess = dspSynced && settingsSynced;

      if (isSuccess) {
        state = state.copyWith(
          isSyncing: false,
          lastSyncedAt: DateTime.now(),
          pendingSyncCount: 0,
        );

        // 5. Terapkan konfigurasi ke UI & audio engine
        _autoApplyUserConfiguration();
        return true;
      } else {
        state = state.copyWith(
          isSyncing: false,
          errorMessage: 'Server synchronization failed or timed out',
        );
        return false;
      }
    } catch (e) {
      debugPrint('[CloudAuthController] Sync failed: $e');
      state = state.copyWith(
        isSyncing: false,
        errorMessage: 'Sync failed: $e',
      );
      return false;
    }
  }
}
