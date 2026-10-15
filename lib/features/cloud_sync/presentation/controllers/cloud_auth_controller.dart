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

      // Pull remote user settings & playback history logs if available
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
        }
      } catch (e) {
        debugPrint('[CloudAuthController] Remote hydration error: $e');
      }

      // Auto-apply user configuration dynamically into UI and audio engine
      _autoApplyUserConfiguration();

      // Immediate sync on successful login
      syncNow();
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
      syncNow();
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

  /// Sinkronisasi log pemutaran (Studio Wrapped), AutoEQ / DSP profil, dan pengaturan pengguna
  Future<void> syncNow() async {
    // ATURAN KETAT: Jika tidak login, sama sekali tidak melakukan koneksi/sync!
    if (!state.isAuthenticated || state.token == null) {
      return;
    }

    try {
      // 1. Ambil log pemutaran lokal
      final rawLogs = LocalPersistenceService.instance.getPlaybackHistoryLogs();
      if (rawLogs.isNotEmpty) {
        await _service.syncPlaybackLogs(
          serverUrl: state.serverUrl,
          token: state.token!,
          logs: rawLogs,
        );
      }

      // 2. Ambil profil AutoEQ & DSP aktif
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

      await _service.syncDspProfile(
        serverUrl: state.serverUrl,
        token: state.token!,
        dspData: dspPayload,
      );

      // 3. Sinkronkan seluruh bundel pengaturan pengguna
      final settingsBundle = LocalPersistenceService.instance.exportCurrentUserSettings();
      if (settingsBundle.isNotEmpty) {
        await _service.saveUserSettings(
          serverUrl: state.serverUrl,
          token: state.token!,
          settings: settingsBundle,
        );
      }

      state = state.copyWith(
        lastSyncedAt: DateTime.now(),
        pendingSyncCount: 0,
      );
    } catch (e) {
      debugPrint('[CloudAuthController] Sync failed: $e');
    }
  }
}
