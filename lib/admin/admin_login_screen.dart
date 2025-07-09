import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tindevs_app/utils/auth_errors.dart';
import 'package:tindevs_app/main.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  AdminLoginScreenState createState() => AdminLoginScreenState();
}

class AdminLoginScreenState extends State<AdminLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _loading = false;
  String? _errorMessage;

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    // Validar campos antes de enviar a Firebase
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    
    final validationError = AuthErrors.validateLoginFields(email, password);
    if (validationError != null) {
      setState(() {
        _errorMessage = validationError;
        _loading = false;
      });
      return;
    }

    try {
      // Autenticación con Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Verificar si el usuario tiene rol "admin" en Firestore con retry logic
      DocumentSnapshot userDoc;
      int maxRetries = 3;
      int retryCount = 0;
      
      do {
        userDoc = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(userCredential.user!.uid)
            .get();
        
        if (!userDoc.exists && retryCount < maxRetries) {
          // Esperar un poco antes de reintentar
          await Future.delayed(Duration(milliseconds: 500 * (retryCount + 1)));
          retryCount++;
        } else {
          break;
        }
      } while (retryCount < maxRetries);

      if (userDoc.exists && userDoc['rol'] == 'admin') {
        print('Admin login exitoso, navegando al panel...'); // Debug
        
        // Limpiar cualquier error previo
        setState(() {
          _errorMessage = null;
        });
        
        // Esperar un momento para asegurar que todo esté sincronizado
        await Future.delayed(const Duration(milliseconds: 300));
        
        // Navegar al InitialRouter para que maneje la navegación reactiva
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const InitialRouter()),
          (route) => false,
        );
      } else {
        // No es admin → mostrar error y cerrar sesión
        await FirebaseAuth.instance.signOut();
        setState(() {
          _errorMessage = 'Este usuario no tiene permisos de administrador.';
        });
      }
    } on FirebaseAuthException catch (e) {
      final customMessage = AuthErrors.getCustomErrorMessage(e.code);
      setState(() {
        _errorMessage = customMessage;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error inesperado. Verifica tu conexión e intenta nuevamente.';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Panel Admin - Login')),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Ingrese sus credenciales de administrador:', style: TextStyle(fontSize: 18)),
                SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: 'Correo'),
                  validator: (value) => value!.isEmpty ? 'Ingrese un correo' : null,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(labelText: 'Contraseña'),
                  obscureText: true,
                  validator: (value) => value!.isEmpty ? 'Ingrese una contraseña' : null,
                ),
                SizedBox(height: 24),
                _loading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            _login();
                          }
                        },
                        child: Text('Ingresar'),
                      ),
                if (_errorMessage != null) ...[
                  SizedBox(height: 16),
                  Text(_errorMessage!, style: TextStyle(color: Colors.red)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
