import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/postulante/postulante_home_screen.dart';
import 'screens/empleador/empleador_home_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'admin/admin_home_screen.dart';

// Importación de servicios, modelos y componentes centralizados

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
        '/admin_home': (context) => AdminHomeScreen(),
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
      try {
        // Implementar retry logic más robusto para Firestore
        DocumentSnapshot? doc;
        int maxRetries = 5;
        int retryCount = 0;
        
        while (retryCount < maxRetries) {
          await Future.delayed(Duration(milliseconds: 300 * (retryCount + 1)));
          
          doc = await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(user.uid)
              .get();
          
          if (doc.exists && doc.data() != null) {
            final data = doc.data() as Map<String, dynamic>?;
            if (data != null && data['rol'] != null) {
              break;
            }
          }
          
          retryCount++;
          print('Retry $retryCount/$maxRetries para obtener datos del usuario');
        }
        
        if (doc != null && doc.exists && doc.data() != null) {
          final data = doc.data() as Map<String, dynamic>;
          final rol = data['rol'];
          
          print('Usuario autenticado con rol: $rol'); // Debug
          
          if (rol == 'empleador') return const EmpleadorHomeScreen();
          if (rol == 'postulante') return const PostulanteHomeScreen();
          if (rol == 'admin') return AdminHomeScreen();
          
          // Si el rol no es reconocido pero el documento existe
          print('Rol no reconocido: $rol - cerrando sesión');
          await FirebaseAuth.instance.signOut();
        } else {
          // Si después de todos los reintentos no hay documento
          print('Documento de usuario no encontrado después de $maxRetries intentos - cerrando sesión');
          await FirebaseAuth.instance.signOut();
        }
      } catch (e) {
        print('Error al obtener datos del usuario: $e');
        // Solo cerrar sesión en errores críticos, no en problemas de conectividad temporal
        if (e.toString().contains('permission-denied') || 
            e.toString().contains('unauthenticated')) {
          await FirebaseAuth.instance.signOut();
        }
      }
    }

    return const WelcomeScreen();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        // Si no hay usuario autenticado, mostrar WelcomeScreen
        if (authSnapshot.data == null) {
          return const WelcomeScreen();
        }
        
        // Si hay usuario autenticado, determinar qué pantalla mostrar
        return FutureBuilder<Widget>(
          future: _determineStartScreen(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Cargando perfil de usuario...'),
                    ],
                  ),
                ),
              );
            } else if (snapshot.hasError) {
              return const Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text('Error al cargar la aplicación'),
                      SizedBox(height: 8),
                      Text('Por favor, reinicia la app'),
                    ],
                  ),
                ),
              );
            } else {
              return snapshot.data!;
            }
          },
        );
      },
    );
  }
}
