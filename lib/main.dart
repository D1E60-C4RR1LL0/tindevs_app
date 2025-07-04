import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'screens/welcome_screen.dart';
import 'screens/postulante_home_screen.dart';
import 'screens/empleador_home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Verificar si Firebase ya está inicializado
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Si Firebase ya está inicializado, continuar
    if (e.toString().contains('duplicate-app')) {
      print('Firebase ya está inicializado');
    } else {
      print('Error al inicializar Firebase: $e');
      rethrow;
    }
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tindevs',
      debugShowCheckedModeBanner: false,
      home: const InitialRouter(),
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/home': (context) => const PostulanteHomeScreen(),
        '/empleador_home': (context) => const EmpleadorHomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
      },
    );
  }
}

class InitialRouter extends StatelessWidget {
  const InitialRouter({super.key});

  Future<Widget> _determineStartScreen() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).get();
      final rol = doc.data()?['rol'];

      if (rol == 'empleador') return const EmpleadorHomeScreen();
      if (rol == 'postulante') return const PostulanteHomeScreen();
    }

    return const WelcomeScreen();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _determineStartScreen(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('Error al cargar la app')),
          );
        } else {
          return snapshot.data!;
        }
      },
    );
  }
}
