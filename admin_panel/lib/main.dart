import 'package:flutter/material.dart';
import 'core/config/app_config.dart';
import 'core/routing/admin_router.dart';
import 'core/supabase/admin_supabase.dart';
import 'core/theme/admin_theme.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/auth_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase if configuration is present
  if (AppConfig.isConfigured) {
    try {
      await AdminSupabase.initialize();
    } catch (e) {
      debugPrint('[AdminApp] Supabase initialization warning: $e');
    }
  }

  final authRepo = SupabaseAuthRepository(client: AdminSupabase.client);
  final authController = AuthController(repository: authRepo);

  // Restore existing session
  await authController.checkSession();

  runApp(GermanLexiconAdminApp(authController: authController));
}

class GermanLexiconAdminApp extends StatelessWidget {
  final AuthController authController;

  const GermanLexiconAdminApp({super.key, required this.authController});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'German Learning School — Master Lexicon Admin',
      debugShowCheckedModeBanner: false,
      theme: AdminTheme.lightTheme,
      home: AdminRouter(authController: authController),
    );
  }
}
