import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:tindevs_app/utils/app_themes.dart';
import 'package:tindevs_app/utils/distancia_util.dart';
import 'chat_screen.dart';

class CandidatosHomeScreen extends StatefulWidget {
  const CandidatosHomeScreen({super.key});

  @override
  State<CandidatosHomeScreen> createState() => _CandidatosHomeScreenState();
}

class _CandidatosHomeScreenState extends State<CandidatosHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Cache para coordenadas de comunas
  Map<String, Map<String, double>>? _coordenadasComunas;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargarCoordenadasComunas();
  }

  Future<void> _cargarCoordenadasComunas() async {
    try {
      final String data = await rootBundle.loadString('assets/data/comunas_latlng.json');
      final List<dynamic> comunas = json.decode(data);
      
      _coordenadasComunas = {};
      for (var comuna in comunas) {
        _coordenadasComunas![comuna['nombre']] = {
          'lat': comuna['lat'].toDouble(),
          'lng': comuna['lng'].toDouble(),
        };
      }
    } catch (e) {
      print('Error al cargar coordenadas de comunas: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _confirmarMatch(String idPropuesta, String idPostulante) async {
    try {
      final user = FirebaseAuth.instance.currentUser!;
      
      // Simplificamos la consulta para evitar índices compuestos
      // Primero obtenemos todos los matches del empleador
      final existingMatches = await FirebaseFirestore.instance
          .collection('matches')
          .where('idEmpleador', isEqualTo: user.uid)
          .get();

      // Verificamos localmente si ya existe el match
      bool matchExists = existingMatches.docs.any((doc) {
        final data = doc.data();
        return data['idPropuesta'] == idPropuesta && data['idPostulante'] == idPostulante;
      });

      if (matchExists) {
        _mostrarSnackBar('El match ya estaba confirmado.', Colors.orange);
        return;
      }

      await FirebaseFirestore.instance.collection('matches').add({
        'idPropuesta': idPropuesta,
        'idPostulante': idPostulante,
        'idEmpleador': user.uid,
        'fecha': DateTime.now(),
        'estado': 'activo',
      });

      _mostrarSnackBar('¡Match confirmado! Ahora pueden chatear.', Colors.green);
    } catch (e) {
      _mostrarSnackBar('Error al confirmar match', Colors.red);
    }
  }

  Future<void> _rechazarCandidato(String idPropuesta, String idPostulante) async {
    try {
      // Simplificamos la consulta para evitar índices compuestos
      // Obtenemos todos los likes de la propuesta
      final likesSnapshot = await FirebaseFirestore.instance
          .collection('likes')
          .where('propuestaId', isEqualTo: idPropuesta)
          .get();

      // Filtramos localmente por postulanteId y eliminamos
      for (var doc in likesSnapshot.docs) {
        final data = doc.data();
        if (data['postulanteId'] == idPostulante) {
          await doc.reference.delete();
        }
      }

      _mostrarSnackBar('Candidato rechazado', Colors.orange);
    } catch (e) {
      _mostrarSnackBar('Error al rechazar candidato', Colors.red);
    }
  }

  Future<void> _abrirChat(String idPropuesta, String idPostulante, 
      String nombrePostulante, String tituloPropuesta) async {
    final user = FirebaseAuth.instance.currentUser!;
    final chatId = '${idPostulante}_${user.uid}_$idPropuesta';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          matchId: chatId,
          otherUserId: idPostulante,
          otherUserName: nombrePostulante,
          propuestaTitle: tituloPropuesta,
          isPostulante: false,
        ),
      ),
    );
  }

  Future<bool> _verificarMatch(String idPropuesta, String idPostulante) async {
    final user = FirebaseAuth.instance.currentUser!;
    
    // Simplificamos la consulta para evitar índices compuestos
    final existingMatches = await FirebaseFirestore.instance
        .collection('matches')
        .where('idEmpleador', isEqualTo: user.uid)
        .get();
    
    // Verificamos localmente si ya existe el match
    return existingMatches.docs.any((doc) {
      final data = doc.data();
      return data['idPropuesta'] == idPropuesta && data['idPostulante'] == idPostulante;
    });
  }

  void _mostrarSnackBar(String mensaje, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('No autenticado'));
    }

    return Column(
      children: [
        // Tab bar integrado
        Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: AppThemes.empleadorPrimary,
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: AppThemes.empleadorAccent,
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorWeight: 3,
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(
                icon: Icon(Icons.person_search),
                text: 'Por Revisar',
              ),
              Tab(
                icon: Icon(Icons.people),
                text: 'Confirmados',
              ),
            ],
          ),
        ),
        // Contenido de las tabs
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildCandidatosPendientes(user.uid),
              _buildCandidatosConfirmados(user.uid),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCandidatosPendientes(String empleadorId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('propuestas')
          .where('idEmpleador', isEqualTo: empleadorId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          print('Error en propuestas: ${snapshot.error}');
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final propuestas = snapshot.data?.docs ?? [];
        // Mostramos TODAS las propuestas del empleador (aprobadas, pendientes y rechazadas)
        print('Propuestas encontradas: ${propuestas.length}');

        if (propuestas.isEmpty) {
          return _buildEmptyState(
            'No tienes propuestas publicadas',
            'Crea una nueva propuesta en la sección "Propuestas" para empezar a recibir candidatos',
            Icons.work_outline,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: propuestas.length,
          itemBuilder: (context, index) {
            final propuesta = propuestas[index];
            final propuestaData = propuesta.data() as Map<String, dynamic>;
            
            return _buildPropuestaCompacta(propuesta.id, propuestaData);
          },
        );
      },
    );
  }

  Widget _buildCandidatosConfirmados(String empleadorId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('matches')
          .where('idEmpleador', isEqualTo: empleadorId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final matches = snapshot.data?.docs ?? [];

        if (matches.isEmpty) {
          return _buildEmptyState(
            'No tienes candidatos confirmados',
            'Acepta candidatos de tus propuestas para verlos aquí y poder chatear con ellos',
            Icons.people_outline,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: matches.length,
          itemBuilder: (context, index) {
            final match = matches[index];
            final matchData = match.data() as Map<String, dynamic>;
            
            return _buildMatchCompacto(matchData);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppThemes.empleadorAccent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon, 
                size: 64, 
                color: AppThemes.empleadorAccent.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropuestaCompacta(String idPropuesta, Map<String, dynamic> propuestaData) {
    final estadoValidacion = propuestaData['estadoValidacion'] ?? 'pendiente';
    
    // Si la propuesta no está aprobada, solo mostrar la información sin candidatos
    if (estadoValidacion != 'aprobada') {
      return Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppThemes.empleadorAccent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.work, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      propuestaData['titulo'] ?? 'Sin título',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Estado de validación
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getValidationStatusColor(estadoValidacion),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getValidationStatusText(estadoValidacion),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                propuestaData['carrera'] ?? 'Carrera no especificada',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 12),
              // Mensaje según el estado
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getValidationStatusColor(estadoValidacion).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getValidationStatusColor(estadoValidacion).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getValidationStatusIcon(estadoValidacion),
                      color: _getValidationStatusColor(estadoValidacion),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getValidationStatusMessage(estadoValidacion),
                        style: TextStyle(
                          color: _getValidationStatusColor(estadoValidacion),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Si está aprobada, mostrar con candidatos
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('likes')
          .where('propuestaId', isEqualTo: idPropuesta)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('Error en likes para propuesta $idPropuesta: ${snapshot.error}');
          return const SizedBox.shrink();
        }

        final likes = snapshot.data?.docs ?? [];
        print('Likes para propuesta $idPropuesta: ${likes.length}');

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 3,
          child: ExpansionTile(
            tilePadding: const EdgeInsets.all(16),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppThemes.empleadorAccent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.work, color: Colors.white, size: 20),
            ),
            title: Text(
              propuestaData['titulo'] ?? 'Sin título',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppThemes.empleadorAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${likes.length} candidato${likes.length != 1 ? 's' : ''}',
                    style: TextStyle(
                      color: AppThemes.empleadorPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'APROBADA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    propuestaData['carrera'] ?? 'Carrera no especificada',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            children: likes.isEmpty ? [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Aún no hay candidatos interesados en esta propuesta',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
            ] : [
              ...likes.map((like) {
                final likeData = like.data() as Map<String, dynamic>;
                final idPostulante = likeData['postulanteId'];
                return _buildCandidatoCompacto(idPropuesta, idPostulante, propuestaData);
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCandidatoCompacto(String idPropuesta, String idPostulante, Map<String, dynamic> propuestaData) {
    return FutureBuilder<List<DocumentSnapshot>>(
      future: Future.wait([
        FirebaseFirestore.instance.collection('usuarios').doc(idPostulante).get(),
        FirebaseFirestore.instance.collection('usuarios').doc(idPostulante).get(),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data![0].exists) {
          return const SizedBox.shrink();
        }

        final postulanteData = snapshot.data![0].data() as Map<String, dynamic>? ?? {};
        final perfilData = snapshot.data![1].data() as Map<String, dynamic>? ?? {};
        final nombre = postulanteData['nombre'] ?? 'Nombre desconocido';

        return FutureBuilder<bool>(
          future: _verificarMatch(idPropuesta, idPostulante),
          builder: (context, matchSnapshot) {
            final yaEsMatch = matchSnapshot.data ?? false;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: yaEsMatch ? Colors.green.shade50 : AppThemes.empleadorBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: yaEsMatch ? Colors.green.shade300 : Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppThemes.postulanteAccent,
                        radius: 20,
                        child: Text(
                          nombre[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    nombre,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (yaEsMatch)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Match',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            Text(
                              _construirInfoCandidato(perfilData, propuestaData),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Botones de acción
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _mostrarPerfilCompleto(postulanteData, perfilData),
                          icon: const Icon(Icons.person, size: 14),
                          label: const Text('Ver', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppThemes.empleadorPrimary,
                            side: BorderSide(color: AppThemes.empleadorPrimary),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (yaEsMatch) ...[
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _abrirChat(
                              idPropuesta,
                              idPostulante,
                              nombre,
                              propuestaData['titulo'] ?? 'Propuesta',
                            ),
                            icon: const Icon(Icons.chat, size: 14),
                            label: const Text('Chat', style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppThemes.empleadorAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                      ] else ...[
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _confirmarMatch(idPropuesta, idPostulante),
                            icon: const Icon(Icons.check, size: 14),
                            label: const Text('Aceptar', style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _rechazarCandidato(idPropuesta, idPostulante),
                            icon: const Icon(Icons.close, size: 14),
                            label: const Text('Rechazar', style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMatchCompacto(Map<String, dynamic> matchData) {
    final idPostulante = matchData['idPostulante'];
    final idPropuesta = matchData['idPropuesta'];

    return FutureBuilder<List<DocumentSnapshot>>(
      future: Future.wait([
        FirebaseFirestore.instance.collection('usuarios').doc(idPostulante).get(),
        FirebaseFirestore.instance.collection('propuestas').doc(idPropuesta).get(),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data![0].exists || !snapshot.data![1].exists) {
          return const SizedBox.shrink();
        }

        final postulanteData = snapshot.data![0].data() as Map<String, dynamic>;
        final propuestaData = snapshot.data![1].data() as Map<String, dynamic>;
        final nombre = postulanteData['nombre'] ?? 'Nombre desconocido';
        final tituloPropuesta = propuestaData['titulo'] ?? 'Propuesta sin título';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: CircleAvatar(
              backgroundColor: AppThemes.postulanteAccent,
              radius: 22,
              child: Text(
                nombre[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              nombre,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tituloPropuesta,
                  style: TextStyle(
                    color: AppThemes.empleadorAccent,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
                Text(
                  'Match: ${_formatearFecha(matchData['fecha'])}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            trailing: ElevatedButton.icon(
              onPressed: () => _abrirChat(idPropuesta, idPostulante, nombre, tituloPropuesta),
              icon: const Icon(Icons.chat, size: 14),
              label: const Text('Chat', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppThemes.empleadorAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
            ),
          ),
        );
      },
    );
  }

  void _mostrarPerfilCompleto(Map<String, dynamic> postulanteData, Map<String, dynamic> perfilData) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [Colors.white, AppThemes.empleadorBackground],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppThemes.postulanteAccent,
                    radius: 30,
                    child: Text(
                      (postulanteData['nombre'] ?? 'N')[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          postulanteData['nombre'] ?? 'Nombre desconocido',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          perfilData['carrera'] ?? 'Carrera no especificada',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              _buildPerfilItem(Icons.email, 'Correo', postulanteData['correo'] ?? 'No especificado'),
              _buildPerfilItem(Icons.location_on, 'Ubicación', '${perfilData['region'] ?? ''}, ${perfilData['comuna'] ?? ''}'),
              _buildPerfilItem(Icons.work, 'Experiencia', '${perfilData['experiencia']?.toString() ?? '0'} años'),
              
              // Manejo seguro de certificaciones
              if (perfilData['certificaciones'] != null) ..._buildCertificaciones(perfilData['certificaciones']),
              
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cerrar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCertificaciones(dynamic certificaciones) {
    try {
      if (certificaciones is List && certificaciones.isNotEmpty) {
        return [
          const SizedBox(height: 16),
          Text(
            'Certificaciones:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppThemes.empleadorPrimary,
            ),
          ),
          const SizedBox(height: 8),
          ...certificaciones.map<Widget>((cert) {
            try {
              if (cert is Map<String, dynamic>) {
                return Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 4),
                  child: Row(
                    children: [
                      Icon(Icons.verified, size: 16, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('${cert['nombre'] ?? 'Sin nombre'} (${cert['estado'] ?? 'Sin estado'})'),
                      ),
                    ],
                  ),
                );
              } else {
                return Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 4),
                  child: Row(
                    children: [
                      Icon(Icons.verified, size: 16, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(cert.toString()),
                      ),
                    ],
                  ),
                );
              }
            } catch (e) {
              print('Error procesando certificación: $e');
              return const SizedBox.shrink();
            }
          }).toList(),
        ];
      }
      return [];
    } catch (e) {
      print('Error procesando certificaciones: $e');
      return [];
    }
  }

  Widget _buildPerfilItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppThemes.empleadorAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Métodos auxiliares para el estado de validación
  Color _getValidationStatusColor(String? estado) {
    switch (estado?.toLowerCase()) {
      case 'aprobada':
        return Colors.green;
      case 'rechazada':
        return Colors.red;
      case 'pendiente':
      default:
        return Colors.orange;
    }
  }

  String _getValidationStatusText(String? estado) {
    switch (estado?.toLowerCase()) {
      case 'aprobada':
        return 'APROBADA';
      case 'rechazada':
        return 'RECHAZADA';
      case 'pendiente':
      default:
        return 'PENDIENTE';
    }
  }

  IconData _getValidationStatusIcon(String? estado) {
    switch (estado?.toLowerCase()) {
      case 'aprobada':
        return Icons.check_circle;
      case 'rechazada':
        return Icons.cancel;
      case 'pendiente':
      default:
        return Icons.schedule;
    }
  }

  String _getValidationStatusMessage(String? estado) {
    switch (estado?.toLowerCase()) {
      case 'aprobada':
        return 'Esta propuesta ha sido aprobada y está visible para los postulantes.';
      case 'rechazada':
        return 'Esta propuesta fue rechazada. Revisa los comentarios del administrador.';
      case 'pendiente':
      default:
        return 'Esta propuesta está en revisión. Los candidatos aparecerán una vez que sea aprobada.';
    }
  }

  String _formatearFecha(dynamic fecha) {
    if (fecha == null) return 'Fecha desconocida';
    
    DateTime dateTime;
    if (fecha is Timestamp) {
      dateTime = fecha.toDate();
    } else if (fecha is DateTime) {
      dateTime = fecha;
    } else {
      return 'Fecha inválida';
    }
    
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays == 0) {
      return 'Hoy';
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }

  String _construirInfoCandidato(Map<String, dynamic> perfilData, Map<String, dynamic> propuestaData) {
    final carrera = perfilData['carrera'] ?? 'Carrera no especificada';
    final experiencia = perfilData['experiencia']?.toString() ?? '0';
    
    // Calcular distancia usando coordenadas de comunas
    String distanciaInfo = '';
    if (_coordenadasComunas != null) {
      final comunaPostulante = perfilData['comuna'];
      final comunaPropuesta = propuestaData['comuna'];
      
      if (comunaPostulante != null && comunaPropuesta != null) {
        final coordsPostulante = _coordenadasComunas![comunaPostulante];
        final coordsPropuesta = _coordenadasComunas![comunaPropuesta];
        
        if (coordsPostulante != null && coordsPropuesta != null) {
          final distancia = DistanciaUtil.calcularDistancia(
            coordsPostulante['lat']!,
            coordsPostulante['lng']!,
            coordsPropuesta['lat']!,
            coordsPropuesta['lng']!,
          );
          distanciaInfo = ' • ${DistanciaUtil.formatearDistancia(distancia)}';
        }
      }
    }
    
    return '$carrera • $experiencia años$distanciaInfo';
  }
}
