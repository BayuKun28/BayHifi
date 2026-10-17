import 'package:flutter/foundation.dart';
import 'user_profile.dart';

enum CloudAuthStatus { guest, loading, authenticated, error }

/// State reaktif untuk status autentikasi dan sinkronisasi BayHifi Cloud
@immutable
class CloudAuthState {
  final CloudAuthStatus status;
  final UserProfile? user;
  final String? token;
  final String serverUrl;
  final DateTime? lastSyncedAt;
  final int pendingSyncCount;
  final String? errorMessage;
  final bool isSyncing;

  const CloudAuthState({
    this.status = CloudAuthStatus.guest,
    this.user,
    this.token,
    this.serverUrl = 'http://localhost:8111',
    this.lastSyncedAt,
    this.pendingSyncCount = 0,
    this.errorMessage,
    this.isSyncing = false,
  });

  bool get isAuthenticated => status == CloudAuthStatus.authenticated && token != null && token!.isNotEmpty;
  bool get isGuest => !isAuthenticated;

  CloudAuthState copyWith({
    CloudAuthStatus? status,
    UserProfile? user,
    String? token,
    String? serverUrl,
    DateTime? lastSyncedAt,
    int? pendingSyncCount,
    String? errorMessage,
    bool? isSyncing,
    bool clearError = false,
    bool clearAuth = false,
  }) {
    return CloudAuthState(
      status: clearAuth ? CloudAuthStatus.guest : (status ?? this.status),
      user: clearAuth ? null : (user ?? this.user),
      token: clearAuth ? null : (token ?? this.token),
      serverUrl: serverUrl ?? this.serverUrl,
      lastSyncedAt: clearAuth ? null : (lastSyncedAt ?? this.lastSyncedAt),
      pendingSyncCount: pendingSyncCount ?? this.pendingSyncCount,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isSyncing: clearAuth ? false : (isSyncing ?? this.isSyncing),
    );
  }
}
