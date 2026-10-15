import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:baydev_hifi/features/cloud_sync/data/cloud_sync_service.dart';
import 'package:baydev_hifi/features/cloud_sync/domain/cloud_auth_state.dart';
import 'package:baydev_hifi/features/cloud_sync/domain/user_profile.dart';
import 'package:baydev_hifi/features/cloud_sync/presentation/controllers/cloud_auth_controller.dart';
import 'package:baydev_hifi/features/cloud_sync/presentation/widgets/change_password_dialog.dart';

class MockCloudSyncService extends CloudSyncService {
  bool changePasswordSuccess = true;
  String? lastOldPassword;
  String? lastNewPassword;

  @override
  Future<Map<String, dynamic>> changePassword({
    required String serverUrl,
    required String token,
    required String oldPassword,
    required String newPassword,
  }) async {
    lastOldPassword = oldPassword;
    lastNewPassword = newPassword;
    if (changePasswordSuccess) {
      return {'success': true, 'message': 'Password updated successfully'};
    } else {
      return {'success': false, 'message': 'Current password is incorrect'};
    }
  }
}

void main() {
  group('Change Password Controller & Dialog Tests', () {
    late MockCloudSyncService mockService;

    setUp(() {
      mockService = MockCloudSyncService();
    });

    test('CloudAuthController.changePassword returns error if not authenticated', () async {
      final controller = CloudAuthController(
        mockService,
        const CloudAuthState(status: CloudAuthStatus.guest),
      );

      final res = await controller.changePassword(
        oldPassword: 'oldSecret123',
        newPassword: 'newSecret456',
      );

      expect(res['success'], isFalse);
      expect(res['message'], contains('Not authenticated'));
    });

    test('CloudAuthController.changePassword calls service when authenticated', () async {
      final controller = CloudAuthController(
        mockService,
        CloudAuthState(
          status: CloudAuthStatus.authenticated,
          token: 'mock_jwt_token',
          serverUrl: 'http://localhost:8111',
          user: UserProfile(
            id: 'usr_1',
            username: 'audiophile',
            createdAt: DateTime(2026, 1, 1),
          ),
        ),
      );

      final res = await controller.changePassword(
        oldPassword: 'oldSecret123',
        newPassword: 'newSecret456',
      );

      expect(res['success'], isTrue);
      expect(mockService.lastOldPassword, 'oldSecret123');
      expect(mockService.lastNewPassword, 'newSecret456');
    });

    testWidgets('ChangePasswordDialog renders input fields and validates matching passwords',
        (tester) async {
      final authenticatedState = CloudAuthState(
        status: CloudAuthStatus.authenticated,
        token: 'mock_jwt_token',
        serverUrl: 'http://localhost:8111',
        user: UserProfile(
          id: 'usr_1',
          username: 'audiophile',
          createdAt: DateTime(2026, 1, 1),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cloudAuthControllerProvider.overrideWith(
              (ref) => CloudAuthController(mockService, authenticatedState),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ChangePasswordDialog(),
            ),
          ),
        ),
      );

      expect(find.text('Change Password'), findsOneWidget);
      expect(find.text('Current Password'), findsOneWidget);
      expect(find.text('New Password'), findsOneWidget);
      expect(find.text('Confirm New Password'), findsOneWidget);

      // Tap UPDATE without filling inputs
      await tester.ensureVisible(find.byType(M3EButton).last);
      await tester.tap(find.byType(M3EButton).last);
      await tester.pumpAndSettle();

      expect(find.text('Please enter your current password'), findsOneWidget);

      // Enter mismatched passwords
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'oldPassword');
      await tester.enterText(textFields.at(1), 'newPassword1');
      await tester.enterText(textFields.at(2), 'newPassword2');

      await tester.ensureVisible(find.byType(M3EButton).last);
      await tester.tap(find.byType(M3EButton).last);
      await tester.pumpAndSettle();

      expect(find.text('New passwords do not match'), findsOneWidget);
    });

    testWidgets('ChangePasswordDialog displays error banner on backend failure',
        (tester) async {
      mockService.changePasswordSuccess = false;
      final authenticatedState = CloudAuthState(
        status: CloudAuthStatus.authenticated,
        token: 'mock_jwt_token',
        serverUrl: 'http://localhost:8111',
        user: UserProfile(
          id: 'usr_1',
          username: 'audiophile',
          createdAt: DateTime(2026, 1, 1),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cloudAuthControllerProvider.overrideWith(
              (ref) => CloudAuthController(mockService, authenticatedState),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ChangePasswordDialog(),
            ),
          ),
        ),
      );

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'wrongPassword');
      await tester.enterText(textFields.at(1), 'newPassword123');
      await tester.enterText(textFields.at(2), 'newPassword123');

      await tester.ensureVisible(find.byType(M3EButton).last);
      await tester.tap(find.byType(M3EButton).last);
      await tester.pumpAndSettle();

      expect(find.text('Current password is incorrect'), findsWidgets);
    });
  });
}
