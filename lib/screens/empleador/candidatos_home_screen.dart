import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../../utils/themes/app_themes.dart';
import '../../utils/helpers/distancia_util.dart';
import '../chat/chat_screen.dart';

class CandidatosHomeScreen extends StatefulWidget {
  const CandidatosHomeScreen({super.key});

  @override
  State<CandidatosHomeScreen> createState() => _CandidatosHomeScreenState();
}

class _CandidatosHomeScreenState extends State<CandidatosHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, Map<String, double>>? _coordenadasComunas;
  double? _latitud;
  double? _longitud;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _cargarCoordenadasComunas();
    _obtenerCoordenadasDelPerfil();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarCoordenadasComunas() async {
    try {
      final String data = await rootBundle.loadString('assets/data/comunas_latlng.json');
      final List<dynamic> comunas = json.decode(data);
      
      _coordenadasComunas = {};
      for (var comuna in comunas) {
        _coordenadasComunas![comuna['nombre']] = {
          'lat': comuna['lat'],
          'lng': comuna['lng'],
        };
      }
    } catch (e) {
      print('Error al cargar coordenadas de comunas: $e');
    }
  }

  Future<void> _obtenerCoordenadasDelPerfil() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final perfilDoc = await FirebaseFirestore.instance
          .collection('perfiles_empleadores')
          .doc(user.uid)
          .get();

      if (perfilDoc.exists && perfilDoc.data() != null) {
        final perfilData = perfilDoc.data()!;
        final comuna = perfilData['comuna'];
        
        if (comuna != null && _coordenadasComunas != null && _coordenadasComunas!.containsKey(comuna)) {
          setState(() {
            _latitud = _coordenadasComunas![comuna]!['lat'];
            _longitud = _coordenadasComunas![comuna]!['lng'];
          });
        }
      }
    } catch (e) {
      print('Error al obtener coordenadas del perfil: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Candidatos',
          style: TextStyle(color: AppThemes.empleadorPrimary),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppThemes.empleadorPrimary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppThemes.empleadorPrimary,
          tabs: const [
            Tab(text: 'Interesados'),
            Tab(text: 'Matches'),
            Tab(text: 'Sugeridos'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInteresadosTab(),
          _buildMatchesTab(),
          _buildSugeridosTab(),
        ],
      ),
    );
  }

  Widget _buildInteresadosTab() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('No autenticado'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('likes')
          .where('idEmpleador', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final likes = snapshot.data?.docs ?? [];

        if (likes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Aún no tienes candidatos interesados',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: likes.length,
          itemBuilder: (context, index) {
            final like = likes[index].data() as Map<String, dynamic>;
            final postulanteId = like['postulanteId'] as String;
            final propuestaId = like['propuestaId'] as String;

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('usuarios')
                  .doc(postulanteId)
                  .get(),
              builder: (context, postulanteSnapshot) {
                if (!postulanteSnapshot.hasData) {
                  return const SizedBox.shrink();
                }

                final postulanteData = postulanteSnapshot.data!.data() as Map<String, dynamic>?;
                if (postulanteData == null) return const SizedBox.shrink();

                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('propuestas')
                      .doc(propuestaId)
                      .get(),
                  builder: (context, propuestaSnapshot) {
                    if (!propuestaSnapshot.hasData) {
                      return const SizedBox.shrink();
                    }

                    final propuestaData = propuestaSnapshot.data!.data() as Map<String, dynamic>?;
                    if (propuestaData == null) return const SizedBox.shrink();

                    // Calcular distancia entre empleador y postulante
                    double? distancia;
                    if (_latitud != null && _longitud != null &&
                        postulanteData.containsKey('latitud') &&
                        postulanteData.containsKey('longitud')) {
                      distancia = DistanciaUtil.calcularDistancia(
                        _latitud!,
                        _longitud!,
                        postulanteData['latitud'],
                        postulanteData['longitud'],
                      );
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(postulanteData['nombre'] ?? 'Sin nombre'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Propuesta: ${propuestaData['titulo'] ?? 'Sin título'}'),
                            if (distancia != null)
                              Text('Distancia: ${distancia.toStringAsFixed(1)} km'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check, color: Colors.green),
                              onPressed: () => _confirmarMatch(propuestaId, postulanteId),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () => _rechazarPostulante(propuestaId, postulanteId),
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
    );
  }

  Widget _buildMatchesTab() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('No autenticado'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('matches')
          .where('idEmpleador', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final matches = snapshot.data?.docs ?? [];

        if (matches.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.handshake_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Aún no tienes matches confirmados',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: matches.length,
          itemBuilder: (context, index) {
            final match = matches[index].data() as Map<String, dynamic>;
            final idPostulante = match['idPostulante'] as String;
            final idPropuesta = match['idPropuesta'] as String;

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('usuarios')
                  .doc(idPostulante)
                  .get(),
              builder: (context, postulanteSnapshot) {
                if (!postulanteSnapshot.hasData) {
                  return const SizedBox.shrink();
                }

                final postulanteData = postulanteSnapshot.data!.data() as Map<String, dynamic>?;
                if (postulanteData == null) return const SizedBox.shrink();

                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('propuestas')
                      .doc(idPropuesta)
                      .get(),
                  builder: (context, propuestaSnapshot) {
                    if (!propuestaSnapshot.hasData) {
                      return const SizedBox.shrink();
                    }

                    final propuestaData = propuestaSnapshot.data!.data() as Map<String, dynamic>?;
                    if (propuestaData == null) return const SizedBox.shrink();

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(postulanteData['nombre'] ?? 'Sin nombre'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Propuesta: ${propuestaData['titulo'] ?? 'Sin título'}'),
                            Text(
                              'Fecha del match: ${match['fecha'] != null ? (match['fecha'] as Timestamp).toDate().toString().split(' ')[0] : 'N/A'}',
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chat, color: Colors.blue),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                    matchId: '${idPropuesta}_$idPostulante', // Formato de matchId
                                    otherUserId: idPostulante,
                                    otherUserName: postulanteData['nombre'] ?? 'Usuario',
                                    propuestaTitle: propuestaData['titulo'] ?? 'Propuesta',
                                    isPostulante: false,
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _eliminarMatch(matches[index].id),
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
    );
  }

  Widget _buildSugeridosTab() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('No autenticado'));
    }

    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('propuestas')
          .where('empleadorId', isEqualTo: user.uid)
          .get(),
      builder: (context, propuestasSnapshot) {
        if (propuestasSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final propuestas = propuestasSnapshot.data?.docs ?? [];
        if (propuestas.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.work_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Crea propuestas para ver candidatos sugeridos',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        // Usamos la primera propuesta para buscar candidatos sugeridos
        final propuestaData = propuestas.first.data() as Map<String, dynamic>;
        final carreraRequerida = propuestaData['carreraRequerida'] as String?;

        if (carreraRequerida == null || carreraRequerida.isEmpty) {
          return const Center(child: Text('Especifique una carrera en sus propuestas'));
        }

        return FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection('usuarios')
              .where('rol', isEqualTo: 'postulante')
              .get(),
          builder: (context, postulantesSnapshot) {
            if (postulantesSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final postulantes = postulantesSnapshot.data?.docs ?? [];
            List<DocumentSnapshot> postulantesFiltrados = [];

            // Filtrar postulantes con la carrera requerida
            for (final postulante in postulantes) {
              final data = postulante.data() as Map<String, dynamic>;
              if (data['carrera'] == carreraRequerida) {
                postulantesFiltrados.add(postulante);
              }
            }

            if (postulantesFiltrados.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.school_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No hay candidatos que coincidan con la carrera requerida',
                      style: TextStyle(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            // Ordenar por distancia si es posible
            if (_latitud != null && _longitud != null) {
              postulantesFiltrados.sort((a, b) {
                final dataA = a.data() as Map<String, dynamic>;
                final dataB = b.data() as Map<String, dynamic>;

                final latA = dataA['latitud'];
                final lngA = dataA['longitud'];
                final latB = dataB['latitud'];
                final lngB = dataB['longitud'];

                if (latA != null && lngA != null && latB != null && lngB != null) {
                  final distanciaA = DistanciaUtil.calcularDistancia(
                    _latitud!,
                    _longitud!,
                    latA,
                    lngA,
                  );
                  final distanciaB = DistanciaUtil.calcularDistancia(
                    _latitud!,
                    _longitud!,
                    latB,
                    lngB,
                  );
                  return distanciaA.compareTo(distanciaB);
                }
                return 0;
              });
            }

            return ListView.builder(
              itemCount: postulantesFiltrados.length,
              itemBuilder: (context, index) {
                final postulante = postulantesFiltrados[index];
                final postulanteData = postulante.data() as Map<String, dynamic>;
                final postulanteId = postulante.id;

                // Calcular distancia entre empleador y postulante
                double? distancia;
                if (_latitud != null && _longitud != null &&
                    postulanteData.containsKey('latitud') &&
                    postulanteData.containsKey('longitud')) {
                  distancia = DistanciaUtil.calcularDistancia(
                    _latitud!,
                    _longitud!,
                    postulanteData['latitud'],
                    postulanteData['longitud'],
                  );
                }

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppThemes.empleadorSecondary,
                      child: Text(
                        postulanteData['nombre']?.substring(0, 1).toUpperCase() ?? '?',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(postulanteData['nombre'] ?? 'Sin nombre'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Carrera: ${postulanteData['carrera'] ?? 'No especificada'}'),
                        if (distancia != null)
                          Text('Distancia: ${distancia.toStringAsFixed(1)} km'),
                      ],
                    ),
                    trailing: ElevatedButton(
                      onPressed: () => _invitarPostulante(postulanteId, propuestas.first.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppThemes.empleadorPrimary,
                      ),
                      child: const Text('Invitar'),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _confirmarMatch(String propuestaId, String postulanteId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Verificar si ya existe el match
      final existingMatch = await FirebaseFirestore.instance
          .collection('matches')
          .where('idPropuesta', isEqualTo: propuestaId)
          .where('idPostulante', isEqualTo: postulanteId)
          .where('idEmpleador', isEqualTo: user.uid)
          .get();

      if (existingMatch.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El match ya está confirmado')),
        );
        return;
      }

      // Crear match
      await FirebaseFirestore.instance.collection('matches').add({
        'idPropuesta': propuestaId,
        'idPostulante': postulanteId,
        'idEmpleador': user.uid,
        'fecha': DateTime.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Match confirmado!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _rechazarPostulante(String propuestaId, String postulanteId) async {
    try {
      // Eliminar el like
      final likesSnapshot = await FirebaseFirestore.instance
          .collection('likes')
          .where('propuestaId', isEqualTo: propuestaId)
          .where('postulanteId', isEqualTo: postulanteId)
          .get();

      for (var doc in likesSnapshot.docs) {
        await doc.reference.delete();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Candidato rechazado')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _eliminarMatch(String matchId) async {
    try {
      await FirebaseFirestore.instance.collection('matches').doc(matchId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Match eliminado')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _invitarPostulante(String postulanteId, String propuestaId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Crear una invitación
      await FirebaseFirestore.instance.collection('invitaciones').add({
        'empleadorId': user.uid,
        'postulanteId': postulanteId,
        'propuestaId': propuestaId,
        'fecha': DateTime.now(),
        'estado': 'pendiente',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invitación enviada')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}
