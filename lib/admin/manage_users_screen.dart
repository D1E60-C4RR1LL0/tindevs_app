import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'admin_home_screen.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  String _selectedRole = 'postulante';

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      // Crear usuario en Auth
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Guardar en Firestore
      await FirebaseFirestore.instance.collection('usuarios').doc(userCredential.user!.uid).set({
        'nombre': _nameController.text.trim(),
        'correo': _emailController.text.trim(),
        'rol': _selectedRole,
        'fechaRegistro': DateTime.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario creado exitosamente')),
      );

      _formKey.currentState!.reset();
      setState(() {
        _selectedRole = 'postulante';
      });
    } catch (e) {
      print('Error al crear usuario: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al crear usuario')),
      );
    }
  }

  Future<void> _deleteUser(String userId) async {
    try {
      await FirebaseFirestore.instance.collection('usuarios').doc(userId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario eliminado')),
      );
    } catch (e) {
      print('Error al eliminar usuario: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al eliminar usuario')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestionar Cuentas')),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.indigo),
              child: Text('Panel Admin', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Usuarios'),
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => AdminHomeScreen()),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.manage_accounts),
              title: const Text('Gestionar Cuentas'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                    validator: (value) => value!.isEmpty ? 'Ingrese nombre' : null,
                  ),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Correo'),
                    validator: (value) => value!.isEmpty ? 'Ingrese correo' : null,
                  ),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Contraseña'),
                    obscureText: true,
                    validator: (value) => value!.length < 6 ? 'Mínimo 6 caracteres' : null,
                  ),
                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    decoration: const InputDecoration(labelText: 'Rol'),
                    items: const [
                      DropdownMenuItem(value: 'postulante', child: Text('Postulante')),
                      DropdownMenuItem(value: 'empleador', child: Text('Empleador')),
                      DropdownMenuItem(value: 'admin', child: Text('Administrador')),
                    ],
                    onChanged: (value) => setState(() => _selectedRole = value!),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _createUser,
                    icon: const Icon(Icons.add),
                    label: const Text('Crear Usuario'),
                  ),
                ],
              ),
            ),
            const Divider(height: 32),
            const Text('Usuarios registrados:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('usuarios').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final users = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final data = users[index].data() as Map<String, dynamic>;
                      final id = users[index].id;
                      return ListTile(
                        title: Text(data['nombre'] ?? 'Sin nombre'),
                        subtitle: Text('${data['correo']} - ${data['rol']}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteUser(id),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
