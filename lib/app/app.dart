// lib/app/app.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'router.dart';
import 'theme.dart';

class GermanReaderApp extends ConsumerWidget {
  final GoRouter? router;
  const GermanReaderApp({super.key, this.router});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'German PDF Reader',
      theme: AppTheme.lightTheme,
      routerConfig: router ?? appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
