import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    print('Cargando UsersScreen!! 🚀');

    return Scaffold(
      appBar: AppBar(title: const Text('Panel Admin - Tindevs')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('usuarios').snapshots(),
        builder: (context, snapshot) {
          print('Snapshot: ${snapshot.connectionState}'); // para debug

          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar usuarios'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final usuarios = snapshot.data!.docs;

          if (usuarios.isEmpty) {
            return const Center(child: Text('No hay usuarios registrados'));
          }

          return ListView.builder(
            itemCount: usuarios.length,
            itemBuilder: (context, index) {
              final userData = usuarios[index].data() as Map<String, dynamic>;
              final userId = usuarios[index].id;

              final nombre = userData['nombre'] ?? 'Sin nombre';
              final correo = userData['correo'] ?? 'Sin correo';

              // Nueva lógica: detectar si certificaciones es lista de objetos o lista de string
              final rawCertificaciones = userData['certificaciones'];

              List<Map<String, dynamic>> certificaciones = [];

              if (rawCertificaciones != null) {
                if (rawCertificaciones is List<dynamic>) {
                  // Si ya es la nueva estructura (mapas con nombre/estado)
                  if (rawCertificaciones.isNotEmpty &&
                      rawCertificaciones.first is Map) {
                    certificaciones = rawCertificaciones
                        .map((c) => Map<String, dynamic>.from(c))
                        .toList();
                  } else {
                    // Si es una lista de string antigua
                    certificaciones = rawCertificaciones
                        .map((c) => {
                              'nombre': c,
                              'estado': 'pendiente',
                              'documentoUrl': '',
                            })
                        .toList();
                  }
                }
              }

              return Card(
                margin: const EdgeInsets.all(8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nombre: $nombre',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('Correo: $correo'),
                      const SizedBox(height: 8),
                      const Text(
                        'Certificaciones:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (certificaciones.isEmpty)
                        const Text('Sin certificaciones')
                      else
                        Column(
                          children: certificaciones.map((cert) {
                            final certNombre = cert['nombre'] ?? 'Sin nombre';
                            final estado = cert['estado'] ?? 'pendiente';
                            final documentoUrl = cert['documentoUrl'] ?? '';

                            return Card(
                              color: Colors.grey[100],
                              child: ListTile(
                                title: Text(certNombre),
                                subtitle: Text('Estado: $estado'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (documentoUrl.isNotEmpty)
                                      IconButton(
                                        icon: const Icon(Icons.visibility),
                                        onPressed: () {
                                          launchUrl(
                                            Uri.parse(documentoUrl),
                                            mode: LaunchMode.externalApplication,
                                          );
                                        },
                                      ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.check,
                                        color: Colors.green,
                                      ),
                                      onPressed: () {
                                        _actualizarEstadoCertificacion(
                                          userId,
                                          certNombre,
                                          'aprobada',
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.close,
                                        color: Colors.red,
                                      ),
                                      onPressed: () {
                                        _actualizarEstadoCertificacion(
                                          userId,
                                          certNombre,
                                          'rechazada',
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _actualizarEstadoCertificacion(
    String userId,
    String certNombre,
    String nuevoEstado,
  ) async {
    final userRef = FirebaseFirestore.instance.collection('usuarios').doc(userId);

    final doc = await userRef.get();

    if (doc.exists) {
      final data = doc.data()!;
      final rawCertificaciones = data['certificaciones'];

      List<Map<String, dynamic>> certificaciones = [];

      if (rawCertificaciones != null) {
        if (rawCertificaciones is List<dynamic>) {
          if (rawCertificaciones.isNotEmpty &&
              rawCertificaciones.first is Map) {
            certificaciones = rawCertificaciones
                .map((c) => Map<String, dynamic>.from(c))
                .toList();
          } else {
            certificaciones = rawCertificaciones
                .map((c) => {
                      'nombre': c,
                      'estado': 'pendiente',
                      'documentoUrl': '',
                    })
                .toList();
          }
        }
      }

      final index = certificaciones.indexWhere((c) => c['nombre'] == certNombre);

      if (index != -1) {
        certificaciones[index]['estado'] = nuevoEstado;

        await userRef.update({'certificaciones': certificaciones});
      }
    }
  }
}
