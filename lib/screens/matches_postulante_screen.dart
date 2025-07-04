import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MatchesPostulanteScreen extends StatelessWidget {
  const MatchesPostulanteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('No autenticado')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mis Matches')),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('matches')
                .where('idPostulante', isEqualTo: user.uid)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final matches = snapshot.data?.docs ?? [];

          if (matches.isEmpty) {
            return const Center(child: Text('No tienes matches aún.'));
          }

          return ListView.builder(
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final matchData = matches[index].data() as Map<String, dynamic>;
              final idPropuesta = matchData['idPropuesta'];

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

                  return Card(
                    margin: const EdgeInsets.all(8),
                    child: Padding(
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
                            'Carrera requerida: ${propuestaData['carreraRequerida'] ?? ''}',
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Fecha del Match: ${matchData['fecha'] != null ? (matchData['fecha'] as Timestamp).toDate().toLocal().toString().split(' ')[0] : ''}',
                          ),

                          const SizedBox(height: 16),

                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Funcionalidad de chat en desarrollo',
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.chat),
                              label: const Text('Contactar a la empresa'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                foregroundColor: Colors.white,
                              ),
                            ),
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
      ),
    );
  }
}
