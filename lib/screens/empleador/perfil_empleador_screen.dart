import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../utils/themes/app_themes.dart';

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

  @override
  void initState() {
    super.initState();
    _cargarPerfilEmpleador();
  }

  @override
  void dispose() {
    _empresaController.dispose();
    _rubroController.dispose();
    _ubicacionController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _cargarPerfilEmpleador() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() ?? {};
        setState(() {
          _empresaController.text = data['empresa'] ?? '';
          _rubroController.text = data['rubro'] ?? '';
          _ubicacionController.text = data['ubicacion'] ?? '';
          _descripcionController.text = data['descripcion'] ?? '';
        });
      }
    } catch (e) {
      print('Error al cargar perfil del empleador: $e');
    }
  }

  Future<void> _guardarPerfil() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .update({
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
      backgroundColor: AppThemes.empleadorBackground,
      appBar: AppBar(
        title: const Text('Perfil Empleador'),
        backgroundColor: AppThemes.empleadorPrimary,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppThemes.empleadorPrimary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Guardar perfil'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await FirebaseAuth.instance.signOut();
                    Navigator.pushNamedAndRemoveUntil(context, '/welcome', (route) => false);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al cerrar sesión: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Cerrar sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
