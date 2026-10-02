import 'package:flutter/foundation.dart';
import '../data/auth_repository.dart';
import '../domain/admin_user_model.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  invalidCredentials,
  inactiveAdmin,
  error,
}

class AuthState {
  final AuthStatus status;
  final AdminUserModel? admin;
  final String? errorMessage;

  const AuthState({
    required this.status,
    this.admin,
    this.errorMessage,
  });

  factory AuthState.initial() => const AuthState(status: AuthStatus.initial);
  factory AuthState.loading() => const AuthState(status: AuthStatus.loading);
  factory AuthState.authenticated(AdminUserModel admin) =>
      AuthState(status: AuthStatus.authenticated, admin: admin);
  factory AuthState.unauthenticated([String? error]) =>
      AuthState(status: AuthStatus.unauthenticated, errorMessage: error);
  factory AuthState.invalidCredentials([String? msg]) =>
      AuthState(status: AuthStatus.invalidCredentials, errorMessage: msg ?? 'Invalid email or password.');
  factory AuthState.inactiveAdmin(String msg) =>
      AuthState(status: AuthStatus.inactiveAdmin, errorMessage: msg);
  factory AuthState.error(String msg) =>
      AuthState(status: AuthStatus.error, errorMessage: msg);

  bool get isAuthenticated => status == AuthStatus.authenticated && admin != null;
  bool get isLoading => status == AuthStatus.loading;
}

class AuthController extends ChangeNotifier {
  final AuthRepository _repository;
  AuthState _state = AuthState.initial();

  AuthController({required this._repository});

  AuthState get state => _state;
  AdminUserModel? get currentAdmin => _state.admin;

  /// Check active session on startup
  Future<void> checkSession() async {
    _state = AuthState.loading();
    notifyListeners();

    try {
      final admin = await _repository.getCurrentAdmin();
      if (admin != null && admin.isActive) {
        _state = AuthState.authenticated(admin);
      } else {
        _state = AuthState.unauthenticated();
      }
    } catch (e) {
      _state = AuthState.unauthenticated(e.toString());
    }
    notifyListeners();
  }

  /// Sign in with email and password
  Future<bool> signIn({required String email, required String password}) async {
    _state = AuthState.loading();
    notifyListeners();

    try {
      final admin = await _repository.signIn(email: email, password: password);
      _state = AuthState.authenticated(admin);
      notifyListeners();
      return true;
    } on InactiveAdminFailure catch (e) {
      _state = AuthState.inactiveAdmin(e.message);
      notifyListeners();
      return false;
    } on AuthFailure catch (e) {
      if (e.message.toLowerCase().contains('invalid')) {
        _state = AuthState.invalidCredentials(e.message);
      } else {
        _state = AuthState.error(e.message);
      }
      notifyListeners();
      return false;
    } catch (e) {
      _state = AuthState.error('Unexpected error during login: $e');
      notifyListeners();
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    _state = AuthState.loading();
    notifyListeners();

    try {
      await _repository.signOut();
    } finally {
      _state = AuthState.unauthenticated();
      notifyListeners();
    }
  }
}
