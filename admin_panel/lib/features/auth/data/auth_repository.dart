import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/admin_user_model.dart';

abstract class AuthRepository {
  Future<AdminUserModel?> getCurrentAdmin();
  Future<AdminUserModel> signIn({required String email, required String password});
  Future<void> signOut();
  Stream<AdminUserModel?> watchAdminUser();
  bool get isAuthenticated;
}

class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _client;

  SupabaseAuthRepository({required this._client});

  @override
  bool get isAuthenticated => _client.auth.currentSession != null;

  @override
  Future<AdminUserModel?> getCurrentAdmin() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      final data = await _client
          .from('admin_users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data == null) {
        return null;
      }

      final admin = AdminUserModel.fromJson(data);
      if (!admin.isActive) {
        return null;
      }
      return admin;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<AdminUserModel> signIn({
    required String email,
    required String password,
  }) async {
    final AuthResponse res;
    try {
      res = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('invalid login credentials')) {
        throw const AuthFailure('Invalid email or password.');
      }
      throw AuthFailure(e.message);
    } catch (e) {
      throw AuthFailure('Authentication error: ${e.toString()}');
    }

    final user = res.user;
    if (user == null) {
      throw const AuthFailure('Sign-in failed. No user returned.');
    }

    // Resolve admin profile
    try {
      final data = await _client
          .from('admin_users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data == null) {
        await _client.auth.signOut();
        throw const InactiveAdminFailure(
          'Access denied. This account has not been granted administrative access.',
        );
      }

      final admin = AdminUserModel.fromJson(data);
      if (!admin.isActive) {
        await _client.auth.signOut();
        throw const InactiveAdminFailure(
          'Account deactivated. Please contact your system superadmin.',
        );
      }

      return admin;
    } on AuthFailure {
      rethrow;
    } catch (e) {
      await _client.auth.signOut();
      throw AuthFailure('Failed to load admin profile: ${e.toString()}');
    }
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  @override
  Stream<AdminUserModel?> watchAdminUser() {
    return _client.auth.onAuthStateChange.asyncMap((event) async {
      final session = event.session;
      if (session == null) return null;
      return getCurrentAdmin();
    });
  }
}

class AuthFailure implements Exception {
  final String message;
  const AuthFailure(this.message);

  @override
  String toString() => message;
}

class InactiveAdminFailure extends AuthFailure {
  const InactiveAdminFailure(super.message);
}
