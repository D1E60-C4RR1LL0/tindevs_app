import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tindevs_app/utils/app_themes.dart';
import 'chat_screen.dart';
import 'detalle_propuesta_screen.dart';

class MatchesPostulanteScreen extends StatefulWidget {
  const MatchesPostulanteScreen({super.key});

  @override
  State<MatchesPostulanteScreen> createState() => _MatchesPostulanteScreenState();
}

class _MatchesPostulanteScreenState extends State<MatchesPostulanteScreen> 
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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('No autenticado')));
    }

    return Scaffold(
      backgroundColor: AppThemes.postulanteBackground,
      appBar: AppBar(
        title: const Text('Mis Intereses'),
        backgroundColor: AppThemes.postulantePrimary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(
              icon: Icon(Icons.favorite),
              text: 'Mis Postulaciones',
            ),
            Tab(
              icon: Icon(Icons.handshake),
              text: 'Matches',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPostulacionesTab(user.uid),
          _buildMatchesTab(user.uid),
        ],
      ),
    );
  }

  // Tab de todas las postulaciones
  Widget _buildPostulacionesTab(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('intereses')
          .where('postulanteId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red[400]),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                const SizedBox(height: 16),
                Text(
                  'Es posible que necesites hacer algunas postulaciones primero.',
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final postulaciones = snapshot.data?.docs ?? [];

        if (postulaciones.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No has postulado a ninguna propuesta aún',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ve a Explorar y postúlate a oportunidades',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: postulaciones.length,
          itemBuilder: (context, index) {
            final postulacionData = postulaciones[index].data() as Map<String, dynamic>;
            final propuestaId = postulacionData['propuestaId'];
            final fechaPostulacion = postulacionData['fecha'] as Timestamp?;

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('propuestas')
                  .doc(propuestaId)
                  .get(),
              builder: (context, propuestaSnapshot) {
                if (!propuestaSnapshot.hasData) {
                  return const SizedBox.shrink();
                }

                if (!propuestaSnapshot.data!.exists) {
                  return _buildRemovedProposalCard(fechaPostulacion);
                }

                final propuestaData = propuestaSnapshot.data!.data() as Map<String, dynamic>;
                final estado = postulacionData['estado'] ?? 'pendiente';

                return _buildPostulacionCard(
                  propuestaData,
                  fechaPostulacion,
                  estado,
                  postulacionData,
                );
              },
            );
          },
        );
      },
    );
  }

  // Tab solo de matches
  Widget _buildMatchesTab(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('matches')
          .where('idPostulante', isEqualTo: userId)
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
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No tienes matches aún',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Cuando los empleadores te acepten, aparecerán aquí',
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

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: matches.length,
          itemBuilder: (context, index) {
            final matchData = matches[index].data() as Map<String, dynamic>;
            final idPropuesta = matchData['idPropuesta'];

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('propuestas')
                  .doc(idPropuesta)
                  .get(),
              builder: (context, propuestaSnapshot) {
                if (!propuestaSnapshot.hasData || !propuestaSnapshot.data!.exists) {
                  return const SizedBox.shrink();
                }

                final propuestaData = propuestaSnapshot.data!.data() as Map<String, dynamic>;

                return _buildMatchCard(matchData, propuestaData);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildPostulacionCard(
    Map<String, dynamic> propuestaData,
    Timestamp? fechaPostulacion,
    String estado,
    Map<String, dynamic> postulacionData,
  ) {
    // Configuración de colores y textos según el estado
    Color statusColor;
    Color statusBgColor;
    IconData statusIcon;
    String statusText;
    
    switch (estado) {
      case 'aceptado':
        statusColor = Colors.green[700]!;
        statusBgColor = Colors.green[100]!;
        statusIcon = Icons.check_circle;
        statusText = 'Aceptado';
        break;
      case 'rechazado':
        statusColor = Colors.red[700]!;
        statusBgColor = Colors.red[100]!;
        statusIcon = Icons.cancel;
        statusText = 'Rechazado';
        break;
      default:
        statusColor = Colors.orange[700]!;
        statusBgColor = Colors.orange[100]!;
        statusIcon = Icons.schedule;
        statusText = 'Pendiente';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetallePropuestaScreen(
                propuesta: propuestaData,
                isFromInterests: true,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con estado
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 7,
                    child: Text(
                      propuestaData['titulo'] ?? 'Sin título',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          statusIcon,
                          size: 16,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                propuestaData['empresa'] ?? 'Empresa no especificada',
                style: TextStyle(
                  fontSize: 14,
                  color: AppThemes.postulanteAccent,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                propuestaData['descripcion'] ?? 'Sin descripción',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '${propuestaData['region'] ?? ''}, ${propuestaData['comuna'] ?? ''}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Postulado: ${_formatDate(fechaPostulacion)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
              if (estado == 'aceptado') ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final empleadorDoc = await FirebaseFirestore.instance
                          .collection('usuarios')
                          .doc(propuestaData['empleadorId'])
                          .get();
                      
                      final empleadorName = empleadorDoc.data()?['nombre'] ?? 'Empresa';
                      final chatId = '${postulacionData['postulanteId']}_${propuestaData['empleadorId']}_${propuestaData['propuestaId']}';
                      
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            matchId: chatId,
                            otherUserId: propuestaData['empleadorId'],
                            otherUserName: empleadorName,
                            propuestaTitle: propuestaData['titulo'] ?? 'Propuesta',
                            isPostulante: true,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat),
                    label: const Text('Contactar empresa'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppThemes.postulanteAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ] else if (estado == 'rechazado') ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.red[600], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Esta postulación no fue aceptada',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMatchCard(Map<String, dynamic> matchData, Map<String, dynamic> propuestaData) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.handshake,
                  color: Colors.green[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    propuestaData['titulo'] ?? 'Sin título',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              propuestaData['empresa'] ?? 'Empresa no especificada',
              style: TextStyle(
                fontSize: 14,
                color: AppThemes.postulanteAccent,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              'Carrera requerida: ${propuestaData['carreraRequerida'] ?? propuestaData['carrera_requerida'] ?? 'No especificada'}',
              style: const TextStyle(fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              'Match realizado: ${_formatDate(matchData['fecha'] as Timestamp?)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.spaceEvenly,
              children: [
                SizedBox(
                  width: 140,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetallePropuestaScreen(
                            propuesta: propuestaData,
                            isFromInterests: true,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.info_outline, size: 16),
                    label: const Text('Ver detalles', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppThemes.postulanteAccent,
                      side: BorderSide(color: AppThemes.postulanteAccent),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    ),
                  ),
                ),
                SizedBox(
                  width: 140,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final empleadorDoc = await FirebaseFirestore.instance
                          .collection('usuarios')
                          .doc(propuestaData['empleadorId'])
                          .get();
                      
                      final empleadorName = empleadorDoc.data()?['nombre'] ?? 'Empresa';
                      final chatId = '${matchData['idPostulante']}_${matchData['idEmpleador']}_${matchData['idPropuesta']}';
                      
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            matchId: chatId,
                            otherUserId: propuestaData['empleadorId'],
                            otherUserName: empleadorName,
                            propuestaTitle: propuestaData['titulo'] ?? 'Propuesta',
                            isPostulante: true,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat, size: 16),
                    label: const Text('Chatear', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppThemes.postulanteAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemovedProposalCard(Timestamp? fechaPostulacion) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[50],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.grey[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Propuesta no disponible',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Esta propuesta ha sido removida o ya no está disponible.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Postulado: ${_formatDate(fechaPostulacion)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Fecha no disponible';
    
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Hoy';
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
