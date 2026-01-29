import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'providers/product_provider.dart';
import 'providers/sales_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/sales_role_dashboard.dart';
import 'screens/admin_dashboard.dart';

void main() {
  // Initialize sqflite FFI for desktop platforms
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => SalesProvider()), // ✅ REQUIRED
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mukisa Farm Supply',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      builder: (context, child) {
        // Global watermark overlay: centered, low opacity image
        return Stack(
          children: [
            if (child != null) child,
            IgnorePointer(
              ignoring: true,
              child: Center(
                child: Opacity(
                  opacity: 0.06,
                  child: Image.asset(
                    'web/icons/Icon-maskable-512.png',
                    width: 500,
                    height: 500,
                    fit: BoxFit.contain,
                    errorBuilder: (ctx, err, st) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (!auth.isAuthenticated) return const LoginScreen();
          if (auth.isAdmin) return const AdminDashboard();
          return const SalesRoleDashboard();
        },
      ),
    );
  }
}
