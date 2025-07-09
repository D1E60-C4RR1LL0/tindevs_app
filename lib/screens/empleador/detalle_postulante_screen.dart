import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DetallePostulanteScreen extends StatelessWidget {
  final String postulanteId;

  const DetallePostulanteScreen({super.key, required this.postulanteId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil del postulante')),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('usuarios').doc(postulanteId).get(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
            return const Center(child: Text('Postulante no encontrado.'));
          }

          final userData = userSnapshot.data!.data() as Map<String, dynamic>? ?? {};

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('usuarios').doc(postulanteId).get(),
            builder: (context, perfilSnapshot) {
              if (perfilSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final perfilData = perfilSnapshot.data!.data() as Map<String, dynamic>? ?? {};

              return Padding(
                padding: const EdgeInsets.all(16),
                child: ListView(
                  children: [
                    Text('Nombre: ${userData['nombre'] ?? ''}', style: const TextStyle(fontSize: 18)),
                    const SizedBox(height: 8),
                    Text('Correo: ${userData['correo'] ?? ''}'),
                    const SizedBox(height: 8),
                    Text('Carrera: ${perfilData['carrera'] ?? ''}'),
                    const SizedBox(height: 8),
                    Text('Región: ${perfilData['region'] ?? ''}'),
                    const SizedBox(height: 8),
                    Text('Comuna: ${perfilData['comuna'] ?? ''}'),
                    const SizedBox(height: 8),
                    Text('Años de experiencia: ${perfilData['experiencia']?.toString() ?? '0'}'),
                    const SizedBox(height: 8),
                    Text('Certificaciones: ${(perfilData['certificaciones'] as List<dynamic>?)?.join(", ") ?? 'Ninguna'}'),
                    const SizedBox(height: 8),
                    Text('Resumen personal: ${perfilData['descripcion'] ?? 'No disponible'}'),
                    const SizedBox(height: 24),

                    // === BOTONES ACEPTAR / RECHAZAR ===
                    ElevatedButton.icon(
                      icon: const Icon(Icons.thumb_up),
                      label: const Text('Aceptar candidato'),
                      onPressed: () {
                        Navigator.pop(context, 'aceptado');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.thumb_down),
                      label: const Text('Rechazar'),
                      onPressed: () {
                        Navigator.pop(context, 'rechazar');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
