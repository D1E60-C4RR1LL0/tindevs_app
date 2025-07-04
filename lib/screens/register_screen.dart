import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      final uid = credential.user!.uid;

      await FirebaseFirestore.instance.collection('usuarios').doc(uid).set({
        'nombre': _nameController.text.trim(),
        'correo': _emailController.text.trim(),
        'rol': _rol,
        'fechaRegistro': DateTime.now(),
      });

      if (_rol == 'postulante') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PerfilPostulanteScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PerfilEmpleadorScreen()),
        );
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Registro exitoso')));
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al registrar: $e')));
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
                    ['postulante', 'empleador'].map((rol) {
                      return DropdownMenuItem(value: rol, child: Text(rol));
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
