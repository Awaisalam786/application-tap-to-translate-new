import 'package:flutter/material.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/dashboard/presentation/admin_shell_screen.dart';

class AdminRouter extends StatelessWidget {
  final AuthController authController;

  const AdminRouter({super.key, required this.authController});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: authController,
      builder: (context, _) {
        final state = authController.state;

        if (state.status == AuthStatus.initial || (state.isLoading && state.admin == null)) {
          return const Scaffold(
            backgroundColor: Color(0xFF0F172A),
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          );
        }

        if (state.isAuthenticated) {
          return AdminShellScreen(authController: authController);
        }

        return LoginScreen(authController: authController);
      },
    );
  }
}
