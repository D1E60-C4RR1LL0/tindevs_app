import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart'; // <<--- IMPORTANTE!
import 'admin/admin_login_screen.dart';
import 'admin/admin_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // <<--- IMPORTANTE!
  );
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TinDevs - Panel de Administración',
      theme: AdminTheme.themeData,
      debugShowCheckedModeBanner: false,
      home: AdminLoginScreen(),
    );
  }
}
