import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tindevs_app/utils/app_themes.dart';
import 'chat_screen.dart';

class MatchesEmpleadorScreen extends StatelessWidget {
  const MatchesEmpleadorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('No autenticado')));
    }

    return Scaffold(
      backgroundColor: AppThemes.empleadorBackground,
      appBar: AppBar(
        title: const Text('Candidatos confirmados'),
        backgroundColor: AppThemes.empleadorPrimary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('matches')
                .where('idEmpleador', isEqualTo: user.uid)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final matches = snapshot.data?.docs ?? [];

          if (matches.isEmpty) {
            return const Center(child: Text('No tienes candidatos confirmados aún.'));
          }

          return ListView.builder(
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final matchData = matches[index].data() as Map<String, dynamic>;
              final idPropuesta = matchData['idPropuesta'];
              final idPostulante = matchData['idPostulante'];

              return FutureBuilder<DocumentSnapshot>(
                future:
                    FirebaseFirestore.instance
                        .collection('propuestas')
                        .doc(idPropuesta)
                        .get(),
                builder: (context, propuestaSnapshot) {
                  if (!propuestaSnapshot.hasData ||
                      !propuestaSnapshot.data!.exists) {
                    return const SizedBox.shrink();
                  }

                  final propuestaData =
                      propuestaSnapshot.data!.data() as Map<String, dynamic>;

                  return FutureBuilder<DocumentSnapshot>(
                    future:
                        FirebaseFirestore.instance
                            .collection('usuarios')
                            .doc(idPostulante)
                            .get(),
                    builder: (context, postulanteSnapshot) {
                      if (!postulanteSnapshot.hasData ||
                          !postulanteSnapshot.data!.exists) {
                        return const SizedBox.shrink();
                      }

                      final postulanteData =
                          postulanteSnapshot.data!.data()
                              as Map<String, dynamic>;

                      return Card(
                        margin: const EdgeInsets.all(8),                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                propuestaData['titulo'] ?? 'Sin título',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Postulante: ${postulanteData['nombre'] ?? ''}',
                              ),
                              Text(
                                'Carrera: ${postulanteData['carrera'] ?? ''}',
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Fecha del Match: ${matchData['fecha'] != null ? (matchData['fecha'] as Timestamp).toDate().toLocal().toString().split(' ')[0] : ''}',
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      // Crear ID único para el chat basado en el match
                                      final chatId = '${matchData['idPostulante']}_${matchData['idEmpleador']}_${matchData['idPropuesta']}';
                                      
                                      // Navegar al chat
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ChatScreen(
                                            matchId: chatId,
                                            otherUserId: idPostulante,
                                            otherUserName: postulanteData['nombre'] ?? 'Postulante',
                                            propuestaTitle: propuestaData['titulo'] ?? 'Propuesta',
                                            isPostulante: false,
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.chat),
                                    label: const Text('Chatear'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppThemes.empleadorAccent,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    tooltip: 'Eliminar match',
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder:
                                            (context) => AlertDialog(
                                          title: const Text('¿Eliminar match?'),
                                          content: const Text(
                                            'Esta acción no se puede deshacer.',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed:
                                                  () =>
                                                      Navigator.pop(context, false),
                                              child: const Text('Cancelar'),
                                            ),
                                            TextButton(
                                              onPressed:
                                                  () =>
                                                      Navigator.pop(context, true),
                                              child: const Text(
                                                'Eliminar',
                                                style: TextStyle(color: Colors.red),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirm == true) {
                                        await FirebaseFirestore.instance
                                            .collection('matches')
                                            .doc(matches[index].id)
                                            .delete();
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
