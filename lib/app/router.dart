// lib/app/router.dart

import 'package:go_router/go_router.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/reader/presentation/screens/reader_screen.dart';

GoRouter createAppRouter({String initialLocation = '/'}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/reader',
      builder: (context, state) => const ReaderScreen(),
    ),
  ],
);

final appRouter = createAppRouter();
