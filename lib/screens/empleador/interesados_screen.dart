import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../utils/themes/app_themes.dart';
import '../chat/chat_screen.dart';

class InteresadosScreen extends StatefulWidget {
  const InteresadosScreen({super.key});

  @override
  State<InteresadosScreen> createState() => _InteresadosScreenState();
}

class _InteresadosScreenState extends State<InteresadosScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  Future<void> _confirmarMatch(String idPropuesta, String idPostulante) async {
    try {
      final user = FirebaseAuth.instance.currentUser!;
      
      final existingMatch = await FirebaseFirestore.instance
          .collection('matches')
          .where('idPropuesta', isEqualTo: idPropuesta)
          .where('idPostulante', isEqualTo: idPostulante)
          .where('idEmpleador', isEqualTo: user.uid)
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
        'idEmpleador': user.uid,
        'fecha': DateTime.now(),
        'estado': 'activo',
      });

      // Actualizar el estado del interés a 'aceptado'
      final interesesSnapshot = await FirebaseFirestore.instance
          .collection('intereses')
          .where('postulanteId', isEqualTo: idPostulante)
          .where('propuestaId', isEqualTo: idPropuesta)
          .get();
      
      for (var doc in interesesSnapshot.docs) {
        await doc.reference.update({'estado': 'aceptado'});
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Match confirmado! Ahora pueden chatear.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al confirmar match'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rechazarCandidato(String idPropuesta, String idPostulante) async {
    try {
      // Eliminar el like
      await FirebaseFirestore.instance
          .collection('likes')
          .where('propuestaId', isEqualTo: idPropuesta)
          .where('postulanteId', isEqualTo: idPostulante)
          .get()
          .then((snapshot) {
        for (var doc in snapshot.docs) {
          doc.reference.delete();
        }
      });

      // Actualizar el estado del interés a 'rechazado'
      final interesesSnapshot = await FirebaseFirestore.instance
          .collection('intereses')
          .where('postulanteId', isEqualTo: idPostulante)
          .where('propuestaId', isEqualTo: idPropuesta)
          .get();
      
      for (var doc in interesesSnapshot.docs) {
        await doc.reference.update({'estado': 'rechazado'});
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Candidato rechazado'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al rechazar candidato'),
          backgroundColor: Colors.red,
        ),
      );
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
    final existingMatch = await FirebaseFirestore.instance
        .collection('matches')
        .where('idPropuesta', isEqualTo: idPropuesta)
        .where('idPostulante', isEqualTo: idPostulante)
        .where('idEmpleador', isEqualTo: user.uid)
        .get();
    
    return existingMatch.docs.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('No autenticado')));
    }

    return Scaffold(
      backgroundColor: AppThemes.empleadorBackground,
      appBar: AppBar(
        title: const Text('Candidatos Interesados'),
        backgroundColor: AppThemes.empleadorPrimary,
        foregroundColor: Colors.white,
        elevation: 2,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Pendientes', icon: Icon(Icons.person_search)),
            Tab(text: 'Confirmados', icon: Icon(Icons.people)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCandidatosPendientes(user.uid),
          _buildCandidatosConfirmados(user.uid),
        ],
      ),
    );
  }

  Widget _buildCandidatosPendientes(String empleadorId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('propuestas')
          .where('empleadorId', isEqualTo: empleadorId)
          .where('estadoValidacion', isEqualTo: 'aprobada')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final propuestas = snapshot.data?.docs ?? [];

        if (propuestas.isEmpty) {
          return _buildEmptyState(
            'No tienes propuestas publicadas',
            'Crea una nueva propuesta para empezar a recibir candidatos',
            Icons.work_outline,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: propuestas.length,
          itemBuilder: (context, index) {
            final propuesta = propuestas[index];
            final propuestaData = propuesta.data() as Map<String, dynamic>;
            
            return _buildPropuestaCard(propuesta.id, propuestaData);
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
          .orderBy('fecha', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final matches = snapshot.data?.docs ?? [];

        if (matches.isEmpty) {
          return _buildEmptyState(
            'No tienes candidatos confirmados',
            'Acepta candidatos de tus propuestas para verlos aquí',
            Icons.people_outline,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: matches.length,
          itemBuilder: (context, index) {
            final match = matches[index];
            final matchData = match.data() as Map<String, dynamic>;
            
            return _buildMatchCard(matchData);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPropuestaCard(String idPropuesta, Map<String, dynamic> propuestaData) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.white, AppThemes.empleadorBackground],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.all(16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppThemes.empleadorAccent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.work, color: Colors.white),
          ),
          title: Text(
            propuestaData['titulo'] ?? 'Sin título',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                'Carrera: ${propuestaData['carreraRequerida'] ?? 'No especificada'}',
                style: TextStyle(
                  color: AppThemes.empleadorPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Ubicación: ${propuestaData['comuna'] ?? 'No especificada'}',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
          children: [
            _buildCandidatesList(idPropuesta, propuestaData),
          ],
        ),
      ),
    );
  }

  Widget _buildCandidatesList(String idPropuesta, Map<String, dynamic> propuestaData) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('likes')
          .where('propuestaId', isEqualTo: idPropuesta)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final likes = snapshot.data?.docs ?? [];

        if (likes.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(
                  Icons.person_search,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 8),
                Text(
                  'No hay candidatos interesados aún',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: AppThemes.empleadorAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${likes.length} candidato${likes.length != 1 ? 's' : ''} interesado${likes.length != 1 ? 's' : ''}',
                style: TextStyle(
                  color: AppThemes.empleadorPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...likes.map((like) {
              final likeData = like.data() as Map<String, dynamic>;
              final idPostulante = likeData['postulanteId'];
              return _buildCandidateCard(idPropuesta, idPostulante, propuestaData);
            }),
          ],
        );
      },
    );
  }

  Widget _buildCandidateCard(String idPropuesta, String idPostulante, Map<String, dynamic> propuestaData) {
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
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: yaEsMatch ? Colors.green.shade50 : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: yaEsMatch ? Colors.green.shade300 : Colors.grey.shade300,
                  width: yaEsMatch ? 2 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppThemes.postulanteAccent,
                        radius: 24,
                        child: Text(
                          nombre[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nombre,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              perfilData['carrera'] ?? 'Carrera no especificada',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (yaEsMatch)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Match',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Información adicional
                  Row(
                    children: [
                      Icon(Icons.work, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${perfilData['experiencia']?.toString() ?? '0'} años de experiencia',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          perfilData['comuna'] ?? 'Ubicación no especificada',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Botones de acción
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _mostrarPerfilCompleto(postulanteData, perfilData),
                          icon: const Icon(Icons.person, size: 16),
                          label: const Text('Ver Perfil'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppThemes.empleadorPrimary,
                            side: BorderSide(color: AppThemes.empleadorPrimary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (yaEsMatch) ...[
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _abrirChat(
                              idPropuesta,
                              idPostulante,
                              nombre,
                              propuestaData['titulo'] ?? 'Propuesta',
                            ),
                            icon: const Icon(Icons.chat, size: 16),
                            label: const Text('Chatear'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppThemes.empleadorAccent,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ] else ...[
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _confirmarMatch(idPropuesta, idPostulante),
                            icon: const Icon(Icons.check, size: 16),
                            label: const Text('Aceptar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _rechazarCandidato(idPropuesta, idPostulante),
                            icon: const Icon(Icons.close, size: 16),
                            label: const Text('Rechazar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
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

  Widget _buildMatchCard(Map<String, dynamic> matchData) {
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
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: AppThemes.postulanteAccent,
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
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Propuesta: $tituloPropuesta',
                  style: TextStyle(
                    color: AppThemes.empleadorAccent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Match confirmado: ${_formatearFecha(matchData['fecha'])}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            trailing: ElevatedButton.icon(
              onPressed: () => _abrirChat(idPropuesta, idPostulante, nombre, tituloPropuesta),
              icon: const Icon(Icons.chat, size: 16),
              label: const Text('Chat'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppThemes.empleadorAccent,
                foregroundColor: Colors.white,
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
              
              if (perfilData['certificaciones'] != null && perfilData['certificaciones'] is List && perfilData['certificaciones'].isNotEmpty) ...[
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
                ...perfilData['certificaciones'].map<Widget>((cert) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 4),
                    child: Row(
                      children: [
                        Icon(Icons.verified, size: 16, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('${cert['nombre']} (${cert['estado']})'),
                        ),
                      ],
                    ),
                  );
                }),
              ],
              
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
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
