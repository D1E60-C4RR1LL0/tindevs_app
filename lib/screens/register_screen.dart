import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tindevs_app/utils/auth_errors.dart';
import 'package:tindevs_app/main.dart';
import 'perfil_postulante_screen.dart';
import 'perfil_empleador_screen.dart';


class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  String _rol = 'postulante';

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    // Validaciones adicionales personalizadas
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    // Validar email
    final emailError = AuthErrors.validateEmail(email);
    if (emailError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(emailError),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validar contraseña
    final passwordError = AuthErrors.validatePassword(password);
    if (passwordError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(passwordError),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validar nombre
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El nombre es obligatorio.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: email,
            password: password,
          );

      final uid = credential.user!.uid;

      await FirebaseFirestore.instance.collection('usuarios').doc(uid).set({
        'nombre': name,
        'correo': email,
        'rol': _rol,
        'fechaRegistro': DateTime.now(),
      });

      if (_rol == 'postulante') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PerfilPostulanteScreen()),
        );
      } else if (_rol == 'empleador') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PerfilEmpleadorScreen()),
        );
      } else if (_rol == 'admin') {
        // Para admin, volver al InitialRouter para navegación reactiva
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const InitialRouter()),
          (route) => false,
        );
      }

      String successMessage;
      if (_rol == 'admin') {
        successMessage = '¡Registro exitoso! Bienvenido al panel de administrador.';
      } else {
        successMessage = '¡Registro exitoso! Completa tu perfil.';
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(
        content: Text(successMessage),
        backgroundColor: Colors.green,
      ));
    } on FirebaseAuthException catch (e) {
      final customMessage = AuthErrors.getCustomErrorMessage(e.code);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(
        content: Text(customMessage),
        backgroundColor: Colors.red,
      ));
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(
        content: Text('Error inesperado. Verifica tu conexión e intenta nuevamente.'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Registro')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Nombre'),
                validator:
                    (value) => value!.isEmpty ? 'Ingresa tu nombre' : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Correo'),
                validator:
                    (value) => value!.isEmpty ? 'Ingresa un correo' : null,
              ),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Contraseña'),
                obscureText: true,
                validator:
                    (value) => value!.length < 6 ? 'Mínimo 6 caracteres' : null,
              ),
              DropdownButtonFormField<String>(
                value: _rol,
                items:
                    ['postulante', 'empleador', 'admin'].map((rol) {
                      String displayName;
                      switch (rol) {
                        case 'postulante':
                          displayName = 'Postulante';
                          break;
                        case 'empleador':
                          displayName = 'Empleador';
                          break;
                        case 'admin':
                          displayName = 'Administrador';
                          break;
                        default:
                          displayName = rol;
                      }
                      return DropdownMenuItem(value: rol, child: Text(displayName));
                    }).toList(),
                onChanged: (value) => setState(() => _rol = value!),
                decoration: InputDecoration(labelText: 'Rol'),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _registerUser,
                child: Text('Registrarse'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
