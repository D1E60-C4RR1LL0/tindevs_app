import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:card_swiper/card_swiper.dart';

class InteresadosScreen extends StatefulWidget {
  const InteresadosScreen({super.key});

  @override
  State<InteresadosScreen> createState() => _InteresadosScreenState();
}

class _InteresadosScreenState extends State<InteresadosScreen> {
  Future<void> _confirmarMatch(String idPropuesta, String idPostulante) async {
    try {
      final existingMatch =
          await FirebaseFirestore.instance
              .collection('matches')
              .where('idPropuesta', isEqualTo: idPropuesta)
              .where('idPostulante', isEqualTo: idPostulante)
              .where(
                'idEmpleador',
                isEqualTo: FirebaseAuth.instance.currentUser!.uid,
              )
              .get();

      if (existingMatch.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El match ya estaba confirmado.')),
        );
        return;
      }

      await FirebaseFirestore.instance.collection('matches').add({
        'idPropuesta': idPropuesta,
        'idPostulante': idPostulante,
        'idEmpleador': FirebaseAuth.instance.currentUser!.uid,
        'fecha': DateTime.now(),
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('¡Match confirmado!')));
    } catch (e) {
      print('Error al confirmar match: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error al confirmar match')));
    }
  }

  Widget _buildCertificacionesList(Map<String, dynamic> perfilData) {
    final certificaciones =
        (perfilData['certificaciones'] as List<dynamic>?) ?? [];

    if (certificaciones.isEmpty) {
      return const Text('Certificaciones: Ninguna');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Certificaciones:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...certificaciones.map((cert) {
          final nombre = cert['nombre'] ?? 'Sin nombre';
          final estado = cert['estado'] ?? 'Desconocido';

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text('• $nombre (Estado: $estado)'),
          );
        }).toList(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('No autenticado')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Interesados en tus propuestas')),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('propuestas')
                .where('empleadorId', isEqualTo: user.uid)
                .where('estadoValidacion', isEqualTo: 'aprobada')
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final propuestas = snapshot.data?.docs ?? [];

          if (propuestas.isEmpty) {
            return const Center(
              child: Text('No tienes propuestas publicadas.'),
            );
          }

          return ListView(
            children:
                propuestas.map((propuesta) {
                  final propuestaData =
                      propuesta.data() as Map<String, dynamic>;
                  final idPropuesta = propuesta.id;

                  return ExpansionTile(
                    title: Text(propuestaData['titulo'] ?? 'Sin título'),
                    subtitle: Text(
                      'Carrera requerida: ${propuestaData['carreraRequerida'] ?? ''}',
                    ),
                    children: [
                      StreamBuilder<QuerySnapshot>(
                        stream:
                            FirebaseFirestore.instance
                                .collection('likes')
                                .where('propuestaId', isEqualTo: idPropuesta)
                                .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final likes = snapshot.data?.docs ?? [];

                          if (likes.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('No hay interesados aún.'),
                            );
                          }

                          return SizedBox(
                            height: 500,
                            child: Swiper(
                              itemCount: likes.length,
                              itemBuilder: (context, index) {
                                final likeData =
                                    likes[index].data() as Map<String, dynamic>;
                                final idPostulante = likeData['postulanteId'];

                                return FutureBuilder<DocumentSnapshot>(
                                  future:
                                      FirebaseFirestore.instance
                                          .collection('usuarios')
                                          .doc(idPostulante)
                                          .get(),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData ||
                                        !snapshot.data!.exists) {
                                      return const SizedBox.shrink();
                                    }

                                    final postulanteData =
                                        snapshot.data!.data()
                                            as Map<String, dynamic>? ??
                                        {};

                                    return GestureDetector(
                                      onTap: () async {
                                        final perfilSnapshot =
                                            await FirebaseFirestore.instance
                                                .collection(
                                                  'perfiles_postulantes',
                                                )
                                                .doc(idPostulante)
                                                .get();
                                        final perfilData =
                                            perfilSnapshot.data() ??
                                            {};

                                        showDialog(
                                          context: context,
                                          builder:
                                              (context) => AlertDialog(
                                                title: Text(
                                                  postulanteData['nombre'] ??
                                                      'Nombre desconocido',
                                                ),
                                                content: SingleChildScrollView(
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        'Carrera: ${perfilData['carrera'] ?? ''}',
                                                      ),
                                                      Text(
                                                        'Correo: ${postulanteData['correo'] ?? ''}',
                                                      ),
                                                      Text(
                                                        'Región: ${perfilData['region'] ?? ''}',
                                                      ),
                                                      Text(
                                                        'Comuna: ${perfilData['comuna'] ?? ''}',
                                                      ),
                                                      Text(
                                                        'Experiencia: ${perfilData['experiencia']?.toString() ?? '0'} años',
                                                      ),
                                                      const SizedBox(height: 8),
                                                      _buildCertificacionesList(
                                                        perfilData,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed:
                                                        () => Navigator.pop(
                                                          context,
                                                        ),
                                                    child: const Text('Cerrar'),
                                                  ),
                                                ],
                                              ),
                                        );
                                      },
                                      child: Card(
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            mainAxisSize:
                                                MainAxisSize
                                                    .min, // ← CORRECCIÓN CLAVE
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                postulanteData['nombre'] ??
                                                    'Nombre desconocido',
                                                style: const TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Carrera: ${postulanteData['carrera'] ?? ''}',
                                              ),
                                              Text(
                                                'Correo: ${postulanteData['correo'] ?? ''}',
                                              ),

                                              // Descripción personal
                                              if (postulanteData['descripcion'] !=
                                                      null &&
                                                  postulanteData['descripcion']
                                                      .toString()
                                                      .isNotEmpty)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 12,
                                                      ),
                                                  child: Text(
                                                    postulanteData['descripcion'],
                                                    style: const TextStyle(
                                                      fontStyle:
                                                          FontStyle.italic,
                                                    ),
                                                  ),
                                                ),

                                              // Certificaciones
                                              if (postulanteData['certificaciones'] !=
                                                      null &&
                                                  postulanteData['certificaciones']
                                                      is List &&
                                                  postulanteData['certificaciones']
                                                      .isNotEmpty)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 12,
                                                      ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      const Text(
                                                        'Certificaciones:',
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      ...postulanteData['certificaciones'].map<
                                                        Widget
                                                      >((cert) {
                                                        return Text(
                                                          '- ${cert['nombre']} (${cert['estado']})',
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 14,
                                                              ),
                                                        );
                                                      }).toList(),
                                                    ],
                                                  ),
                                                ),

                                              const SizedBox(
                                                height: 16,
                                              ), // ← en lugar de Spacer

                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceEvenly,
                                                children: [
                                                  ElevatedButton.icon(
                                                    onPressed: () async {
                                                      await _confirmarMatch(
                                                        idPropuesta,
                                                        idPostulante,
                                                      );
                                                    },
                                                    icon: const Icon(
                                                      Icons.check,
                                                      color: Colors.white,
                                                    ),
                                                    label: const Text(
                                                      'Aceptar',
                                                    ),
                                                    style:
                                                        ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              Colors.green,
                                                        ),
                                                  ),
                                                  ElevatedButton.icon(
                                                    onPressed: () {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                            'Postulante rechazado.',
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                    icon: const Icon(
                                                      Icons.close,
                                                      color: Colors.white,
                                                    ),
                                                    label: const Text(
                                                      'Rechazar',
                                                    ),
                                                    style:
                                                        ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              Colors.red,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                              viewportFraction: 0.8,
                              scale: 0.9,
                            ),
                          );
                        },
                      ),
                    ],
                  );
                }).toList(),
          );
        },
      ),
    );
  }
}
