import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:baydev_hifi/features/cloud_sync/data/cloud_sync_service.dart';
import 'package:baydev_hifi/features/cloud_sync/domain/user_profile.dart';
import 'package:baydev_hifi/features/cloud_sync/domain/cloud_auth_state.dart';
import 'package:baydev_hifi/features/cloud_sync/presentation/controllers/cloud_auth_controller.dart';
import 'package:baydev_hifi/features/cloud_sync/presentation/widgets/dashboard_profile_button.dart';
import 'package:baydev_hifi/features/cloud_sync/presentation/widgets/settings_account_card.dart';
import 'package:baydev_hifi/features/cloud_sync/presentation/widgets/cloud_auth_dialog.dart';
import 'package:baydev_hifi/features/cloud_sync/presentation/widgets/user_profile_sheet.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Cloud Sync Domain Models Test', () {
    test('UserProfile serialization and deserialization', () {
      final now = DateTime.now();
      final user = UserProfile(
        id: 'usr_123',
        username: 'bayu_audiophile',
        email: 'bayu@example.com',
        createdAt: now,
      );

      final map = user.toMap();
      expect(map['id'], 'usr_123');
      expect(map['username'], 'bayu_audiophile');
      expect(map['email'], 'bayu@example.com');

      final fromMap = UserProfile.fromMap(map);
      expect(fromMap.id, 'usr_123');
      expect(fromMap.username, 'bayu_audiophile');
      expect(fromMap.email, 'bayu@example.com');
    });

    test('CloudAuthState default state is guest and not authenticated', () {
      const state = CloudAuthState();
      expect(state.status, CloudAuthStatus.guest);
      expect(state.isGuest, isTrue);
      expect(state.isAuthenticated, isFalse);
      expect(state.serverUrl, 'http://localhost:8111');
      expect(state.user, isNull);
      expect(state.token, isNull);
    });

    test('CloudAuthState transitions to authenticated correctly', () {
      final user = UserProfile(
        id: 'usr_456',
        username: 'studio_master',
        createdAt: DateTime.now(),
      );

      var state = const CloudAuthState();
      state = state.copyWith(
        status: CloudAuthStatus.authenticated,
        token: 'jwt_mock_token_123',
        user: user,
      );

      expect(state.status, CloudAuthStatus.authenticated);
      expect(state.isAuthenticated, isTrue);
      expect(state.isGuest, isFalse);
      expect(state.user?.username, 'studio_master');
      expect(state.token, 'jwt_mock_token_123');

      // Test logout/clearAuth
      state = state.copyWith(clearAuth: true);
      expect(state.status, CloudAuthStatus.guest);
      expect(state.isAuthenticated, isFalse);
      expect(state.user, isNull);
      expect(state.token, isNull);
    });
  });

  group('DashboardProfileButton Widget Test', () {
    testWidgets('Renders Guest state when unauthenticated', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DashboardProfileButton(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Guest'), findsOneWidget);
    });

    testWidgets('Renders Username and initial when authenticated', (tester) async {
      final user = UserProfile(
        id: 'usr_999',
        username: 'BayuDev',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cloudAuthControllerProvider.overrideWith(
              (ref) => CloudAuthController(
                ref.read(cloudSyncServiceProvider),
                CloudAuthState(
                  status: CloudAuthStatus.authenticated,
                  user: user,
                  token: 'valid_mock_token',
                ),
              ),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: DashboardProfileButton(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('BayuDev'), findsOneWidget);
      expect(find.text('B'), findsOneWidget); // Initial avatar
    });
  });

  group('SettingsAccountCard Widget Test', () {
    testWidgets('Renders offline invite banner when guest', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: SettingsAccountCard(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('BAYHIFI CLOUD ACCOUNT'), findsOneWidget);
      expect(find.text('Offline Mode (Local Storage Only)'), findsOneWidget);
      expect(find.text('CONNECT & SIGN IN'), findsOneWidget);
    });

    testWidgets('Renders user details and sync button when authenticated', (tester) async {
      final user = UserProfile(
        id: 'usr_888',
        username: 'StudioUser',
        email: 'studio@bayhifi.app',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cloudAuthControllerProvider.overrideWith(
              (ref) => CloudAuthController(
                ref.read(cloudSyncServiceProvider),
                CloudAuthState(
                  status: CloudAuthStatus.authenticated,
                  user: user,
                  token: 'valid_mock_token',
                  lastSyncedAt: DateTime(2026, 10, 14, 11, 0),
                ),
              ),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: SettingsAccountCard(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('StudioUser'), findsOneWidget);
      expect(find.text('studio@bayhifi.app'), findsOneWidget);
      expect(find.text('SYNC NOW'), findsOneWidget);
      expect(find.text('DETAILS'), findsOneWidget);
    });
  });

  group('CloudAuthDialog Widget Test', () {
    testWidgets('Renders dialog with mode switch and fields', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CloudAuthDialog(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('BAYHIFI CLOUD'), findsOneWidget);
      expect(find.text('SIGN IN'), findsOneWidget);
      expect(find.text('REGISTER'), findsOneWidget);
      expect(find.text('Server Host URL'), findsOneWidget);
      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);

      // Tap Register to reveal Email field
      await tester.tap(find.text('REGISTER'));
      await tester.pumpAndSettle();
      expect(find.text('Email (Optional)'), findsOneWidget);
      expect(find.text('CREATE ACCOUNT'), findsOneWidget);
    });

    testWidgets('Renders loading indicator when auth is loading', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cloudAuthControllerProvider.overrideWith(
              (ref) => CloudAuthController(
                ref.read(cloudSyncServiceProvider),
                const CloudAuthState(
                  status: CloudAuthStatus.loading,
                ),
              ),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CloudAuthDialog(),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Renders error banner when errorMessage is present', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cloudAuthControllerProvider.overrideWith(
              (ref) => CloudAuthController(
                ref.read(cloudSyncServiceProvider),
                const CloudAuthState(
                  status: CloudAuthStatus.guest,
                  errorMessage: 'Invalid username or password',
                ),
              ),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CloudAuthDialog(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Invalid username or password'), findsOneWidget);
    });
  });

  group('UserProfileSheet Widget Tests', () {
    testWidgets('Renders user profile details and SYNC NOW button', (tester) async {
      final user = UserProfile(
        id: 'usr_matt',
        username: 'Matt',
        email: 'matt@baydev.studio',
        createdAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cloudAuthControllerProvider.overrideWith(
              (ref) => CloudAuthController(
                FakeSyncService(),
                CloudAuthState(
                  status: CloudAuthStatus.authenticated,
                  user: user,
                  token: 'valid_token',
                  lastSyncedAt: DateTime(2026, 10, 15, 12, 30),
                ),
              ),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: UserProfileSheet(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Matt'), findsOneWidget);
      expect(find.text('matt@baydev.studio'), findsOneWidget);
      expect(find.text('SYNC NOW'), findsOneWidget);
      expect(find.text('LOG OUT'), findsOneWidget);
      expect(find.text('CHANGE PASSWORD'), findsOneWidget);
    });

    testWidgets('Renders loading spinner and SYNCING... label when isSyncing is true', (tester) async {
      final user = UserProfile(
        id: 'usr_matt',
        username: 'Matt',
        createdAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cloudAuthControllerProvider.overrideWith(
              (ref) => CloudAuthController(
                FakeSyncService(),
                CloudAuthState(
                  status: CloudAuthStatus.authenticated,
                  user: user,
                  token: 'valid_token',
                  isSyncing: true,
                ),
              ),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: UserProfileSheet(),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('SYNCING...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Triggers syncNow and shows success banner and toast on successful sync', (tester) async {
      final fakeService = FakeSyncService()..returnSuccess = true;
      final user = UserProfile(
        id: 'usr_matt',
        username: 'Matt',
        createdAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cloudAuthControllerProvider.overrideWith(
              (ref) => CloudAuthController(
                fakeService,
                CloudAuthState(
                  status: CloudAuthStatus.authenticated,
                  user: user,
                  token: 'valid_token',
                ),
              ),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: UserProfileSheet(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('SYNC NOW'), findsOneWidget);

      await tester.tap(find.text('SYNC NOW'));
      await tester.pumpAndSettle();

      expect(find.text('Studio Cloud synchronization completed successfully.'), findsOneWidget);
      expect(find.text('Studio Cloud sync completed. All profiles & telemetry updated.'), findsOneWidget);
      expect(find.byIcon(LucideIcons.checkCircle2), findsWidgets);
    });

    testWidgets('Triggers syncNow and shows error banner and toast on failed sync', (tester) async {
      final fakeService = FakeSyncService()..returnSuccess = false;
      final user = UserProfile(
        id: 'usr_matt',
        username: 'Matt',
        createdAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cloudAuthControllerProvider.overrideWith(
              (ref) => CloudAuthController(
                fakeService,
                CloudAuthState(
                  status: CloudAuthStatus.authenticated,
                  user: user,
                  token: 'valid_token',
                ),
              ),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: UserProfileSheet(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('SYNC NOW'), findsOneWidget);

      await tester.tap(find.text('SYNC NOW'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Sync failed'), findsWidgets);
      expect(find.byIcon(LucideIcons.alertCircle), findsWidgets);
    });

    testWidgets('Renders SYNCING... and CircularProgressIndicator in SettingsAccountCard when isSyncing is true', (tester) async {
      final user = UserProfile(
        id: 'usr_888',
        username: 'StudioUser',
        email: 'studio@bayhifi.app',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cloudAuthControllerProvider.overrideWith(
              (ref) => CloudAuthController(
                FakeSyncService(),
                CloudAuthState(
                  status: CloudAuthStatus.authenticated,
                  user: user,
                  token: 'valid_mock_token',
                  isSyncing: true,
                ),
              ),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: SettingsAccountCard(),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('SYNCING...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}

class FakeSyncService extends CloudSyncService {
  bool returnSuccess = true;

  @override
  Future<Map<String, dynamic>?> fetchUserSettings({
    required String serverUrl,
    required String token,
  }) async {
    return {};
  }

  @override
  Future<List<Map<String, dynamic>>> fetchPlaybackLogs({
    required String serverUrl,
    required String token,
    int limit = 500,
  }) async {
    return [];
  }

  @override
  Future<Map<String, dynamic>?> fetchDspProfile({
    required String serverUrl,
    required String token,
  }) async {
    return null;
  }

  @override
  Future<int> syncPlaybackLogs({
    required String serverUrl,
    required String token,
    required List<Map<String, dynamic>> logs,
  }) async {
    return returnSuccess ? logs.length : 0;
  }

  @override
  Future<bool> syncDspProfile({
    required String serverUrl,
    required String token,
    required Map<String, dynamic> dspData,
  }) async {
    return returnSuccess;
  }

  @override
  Future<bool> saveUserSettings({
    required String serverUrl,
    required String token,
    required Map<String, dynamic> settings,
  }) async {
    return returnSuccess;
  }
}
