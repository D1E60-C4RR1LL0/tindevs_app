import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MatchesEmpleadorScreen extends StatelessWidget {
  const MatchesEmpleadorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('No autenticado')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Matches confirmados')),
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
            return const Center(child: Text('No tienes matches aún.'));
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
                        margin: const EdgeInsets.all(8),
                        child: ListTile(
                          title: Text(propuestaData['titulo'] ?? 'Sin título'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                            ],
                          ),
                          trailing: IconButton(
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
