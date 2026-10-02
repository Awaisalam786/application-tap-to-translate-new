import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:german_lexicon_admin/features/auth/data/auth_repository.dart';
import 'package:german_lexicon_admin/features/auth/domain/admin_user_model.dart';
import 'package:german_lexicon_admin/features/auth/presentation/auth_controller.dart';

class MockAuthRepository implements AuthRepository {
  AdminUserModel? _currentAdmin;
  final _controller = StreamController<AdminUserModel?>.broadcast();
  bool shouldFailWithInvalidCredentials = false;
  bool shouldFailWithInactive = false;
  bool shouldThrowGeneric = false;

  void seedAdmin(AdminUserModel? admin) {
    _currentAdmin = admin;
    _controller.add(admin);
  }

  @override
  bool get isAuthenticated => _currentAdmin != null;

  @override
  Future<AdminUserModel?> getCurrentAdmin() async {
    return _currentAdmin;
  }

  @override
  Future<AdminUserModel> signIn({required String email, required String password}) async {
    if (shouldFailWithInvalidCredentials) {
      throw const AuthFailure('Invalid email or password.');
    }
    if (shouldFailWithInactive) {
      throw const InactiveAdminFailure('Account deactivated. Please contact your system superadmin.');
    }
    if (shouldThrowGeneric) {
      throw Exception('Network connection timeout');
    }

    final admin = AdminUserModel(
      id: 'test-admin-1',
      email: email,
      fullName: 'Super Admin User',
      role: AdminRole.superadmin,
      isActive: true,
      createdAt: DateTime(2026, 10, 1),
    );
    _currentAdmin = admin;
    _controller.add(admin);
    return admin;
  }

  @override
  Future<void> signOut() async {
    _currentAdmin = null;
    _controller.add(null);
  }

  @override
  Stream<AdminUserModel?> watchAdminUser() => _controller.stream;
}

void main() {
  group('AuthController Unit Tests', () {
    late MockAuthRepository mockRepo;
    late AuthController authController;

    setUp(() {
      mockRepo = MockAuthRepository();
      authController = AuthController(repository: mockRepo);
    });

    test('Initial state is unauthenticated after checkSession when no active user', () async {
      await authController.checkSession();
      expect(authController.state.status, AuthStatus.unauthenticated);
      expect(authController.currentAdmin, isNull);
    });

    test('Restores active session if valid admin is present', () async {
      final seeded = AdminUserModel(
        id: 'super-1',
        email: 'super@school.de',
        fullName: 'Lead Superadmin',
        role: AdminRole.superadmin,
        isActive: true,
        createdAt: DateTime.now(),
      );
      mockRepo.seedAdmin(seeded);

      await authController.checkSession();
      expect(authController.state.status, AuthStatus.authenticated);
      expect(authController.currentAdmin?.email, 'super@school.de');
      expect(authController.currentAdmin?.isSuperadmin, isTrue);
    });

    test('SignIn failure with invalid credentials updates AuthState', () async {
      mockRepo.shouldFailWithInvalidCredentials = true;

      final success = await authController.signIn(
        email: 'wrong@school.de',
        password: 'badpassword',
      );

      expect(success, isFalse);
      expect(authController.state.status, AuthStatus.invalidCredentials);
      expect(authController.state.errorMessage, contains('Invalid'));
      expect(authController.currentAdmin, isNull);
    });

    test('SignIn failure with inactive account updates AuthState to inactiveAdmin', () async {
      mockRepo.shouldFailWithInactive = true;

      final success = await authController.signIn(
        email: 'banned@school.de',
        password: 'password',
      );

      expect(success, isFalse);
      expect(authController.state.status, AuthStatus.inactiveAdmin);
      expect(authController.state.errorMessage, contains('deactivated'));
    });

    test('SignOut clears admin and resets state to unauthenticated', () async {
      final seeded = AdminUserModel(
        id: 'rev-1',
        email: 'reviewer@school.de',
        fullName: 'Linguistic Reviewer',
        role: AdminRole.reviewer,
        isActive: true,
        createdAt: DateTime.now(),
      );
      mockRepo.seedAdmin(seeded);
      await authController.checkSession();
      expect(authController.state.isAuthenticated, isTrue);

      await authController.signOut();
      expect(authController.state.status, AuthStatus.unauthenticated);
      expect(authController.currentAdmin, isNull);
    });
  });
}
