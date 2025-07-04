import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'crear_propuesta_screen.dart';
import 'interesados_screen.dart';
import 'matches_empleador_screen.dart';

class PerfilEmpleadorScreen extends StatefulWidget {
  const PerfilEmpleadorScreen({super.key});

  @override
  State<PerfilEmpleadorScreen> createState() => _PerfilEmpleadorScreenState();
}

class _PerfilEmpleadorScreenState extends State<PerfilEmpleadorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _empresaController = TextEditingController();
  final _rubroController = TextEditingController();
  final _ubicacionController = TextEditingController();
  final _descripcionController = TextEditingController();

  Future<void> _guardarPerfil() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('perfiles_empleadores')
          .doc(user.uid)
          .set({
            'empresa': _empresaController.text.trim(),
            'rubro': _rubroController.text.trim(),
            'ubicacion': _ubicacionController.text.trim(),
            'descripcion': _descripcionController.text.trim(),
          });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil guardado con éxito')),
      );
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al guardar el perfil')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil Empleador')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _empresaController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la empresa',
                ),
                validator: (value) => value!.isEmpty ? 'Requerido' : null,
              ),
              TextFormField(
                controller: _rubroController,
                decoration: const InputDecoration(labelText: 'Rubro'),
                validator: (value) => value!.isEmpty ? 'Requerido' : null,
              ),
              TextFormField(
                controller: _ubicacionController,
                decoration: const InputDecoration(
                  labelText: 'Ubicación (ciudad o región)',
                ),
                validator: (value) => value!.isEmpty ? 'Requerido' : null,
              ),
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción de la empresa',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _guardarPerfil,
                child: const Text('Guardar perfil'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CrearPropuestaScreen(),
                    ),
                  );
                },
                child: const Text('Crear propuesta de trabajo'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const InteresadosScreen(),
                    ),
                  );
                },
                child: const Text('Ver interesados'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MatchesEmpleadorScreen(),
                    ),
                  );
                },
                child: const Text('Ver matches'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushReplacementNamed(context, '/');
                },
                child: const Text('Cerrar sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
