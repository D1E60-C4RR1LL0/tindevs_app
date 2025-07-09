import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tindevs_app/utils/app_themes.dart';
import 'crear_propuesta_screen.dart';

class GestionarPropuestasScreen extends StatefulWidget {
  const GestionarPropuestasScreen({super.key});

  @override
  State<GestionarPropuestasScreen> createState() => _GestionarPropuestasScreenState();
}

class _GestionarPropuestasScreenState extends State<GestionarPropuestasScreen> {
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemes.empleadorBackground,
      appBar: AppBar(
        title: const Text('Gestionar Ofertas'),
        backgroundColor: AppThemes.empleadorPrimary,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Column(
        children: [
          // Header "Publicar propuesta"
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppThemes.empleadorPrimary.withValues(alpha: 0.8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Mis Propuestas',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CrearPropuestaScreen(),
                      ),
                    ).then((_) => setState(() {}));
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Nueva'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppThemes.empleadorPrimary,
                  ),
                ),
              ],
            ),
          ),
          // Lista de propuestas
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _obtenerPropuestasStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  print('Error en stream de propuestas: ${snapshot.error}');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Error al cargar propuestas',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.red,
                          ),
                        ),
                        SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }

                final propuestas = snapshot.data?.docs ?? [];
                print('Propuestas encontradas: ${propuestas.length}');

                if (propuestas.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.work_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No tienes propuestas publicadas',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Crea tu primera propuesta de trabajo',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: propuestas.length,
                  itemBuilder: (context, index) {
                    final propuesta = propuestas[index];
                    final data = propuesta.data() as Map<String, dynamic>;
                    
                    return _buildPropuestaCard(propuesta.id, data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _obtenerPropuestasStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('Usuario no autenticado en gestionar propuestas');
      return const Stream.empty();
    }

    print('Obteniendo propuestas para empleador: ${user.uid}');
    
    return FirebaseFirestore.instance
        .collection('propuestas')
        .where('idEmpleador', isEqualTo: user.uid)
        .snapshots();
  }

  Widget _buildPropuestaCard(String propuestaId, Map<String, dynamic> data) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppThemes.empleadorPrimary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.work,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    data['titulo'] ?? 'Sin título',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Mostrar estado de validación del admin
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getValidationStatusColor(data['estadoValidacion'] ?? 'pendiente'),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getValidationStatusText(data['estadoValidacion'] ?? 'pendiente'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Details
            if (data['carrera'] != null && data['carrera'].isNotEmpty)
              _buildDetailRow(Icons.school, 'Carrera', data['carrera']),
            
            if ((data['comuna'] != null && data['comuna'].isNotEmpty) || (data['region'] != null && data['region'].isNotEmpty))
              _buildDetailRow(Icons.location_on, 'Ubicación', _formatearUbicacion(data)),
            
            if (data['experiencia'] != null && data['experiencia'] > 0)
              _buildDetailRow(Icons.work_history, 'Experiencia', '${data['experiencia']} años'),
            
            if (data['certificacion'] != null && data['certificacion'].isNotEmpty)
              _buildDetailRow(Icons.verified, 'Certificación', data['certificacion']),
            
            const SizedBox(height: 12),
            
            // Description preview
            if (data['descripcion'] != null && data['descripcion'].isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  data['descripcion'],
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Validation status information
            _buildValidationStatusInfo(data['estadoValidacion'] ?? 'pendiente'),
            
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _editarPropuesta(propuestaId, data),
                    icon: const Icon(Icons.edit),
                    label: const Text('Editar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppThemes.empleadorPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _eliminarPropuesta(propuestaId),
                  icon: const Icon(Icons.delete),
                  color: Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getValidationStatusColor(String estadoValidacion) {
    switch (estadoValidacion.toLowerCase()) {
      case 'aprobada':
        return Colors.green;
      case 'rechazada':
        return Colors.red;
      case 'pendiente':
      default:
        return Colors.orange;
    }
  }

  String _getValidationStatusText(String estadoValidacion) {
    switch (estadoValidacion.toLowerCase()) {
      case 'aprobada':
        return 'APROBADA';
      case 'rechazada':
        return 'RECHAZADA';
      case 'pendiente':
      default:
        return 'PENDIENTE';
    }
  }

  void _editarPropuesta(String propuestaId, Map<String, dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CrearPropuestaScreen(
          propuestaId: propuestaId,
          datosExistentes: data,
        ),
      ),
    ).then((_) => setState(() {}));
  }

  void _eliminarPropuesta(String propuestaId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar propuesta'),
        content: const Text('¿Estás seguro de que quieres eliminar esta propuesta? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await FirebaseFirestore.instance
                    .collection('propuestas')
                    .doc(propuestaId)
                    .delete();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Propuesta eliminada exitosamente'),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al eliminar: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatearUbicacion(Map<String, dynamic> data) {
    final comuna = data['comuna'] ?? '';
    final region = data['region'] ?? '';
    
    if (comuna.isNotEmpty && region.isNotEmpty) {
      return '$comuna, $region';
    } else if (comuna.isNotEmpty) {
      return comuna;
    } else if (region.isNotEmpty) {
      return region;
    }
    return 'No especificada';
  }

  Widget _buildValidationStatusInfo(String estadoValidacion) {
    String mensaje;
    IconData icono;
    Color color;
    
    switch (estadoValidacion.toLowerCase()) {
      case 'aprobada':
        mensaje = 'Tu propuesta ha sido aprobada y está visible para los postulantes';
        icono = Icons.check_circle;
        color = Colors.green;
        break;
      case 'rechazada':
        mensaje = 'Tu propuesta fue rechazada. Revisa los requisitos y crea una nueva';
        icono = Icons.cancel;
        color = Colors.red;
        break;
      case 'pendiente':
      default:
        mensaje = 'Tu propuesta está siendo revisada por un administrador';
        icono = Icons.schedule;
        color = Colors.orange;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icono, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              mensaje,
              style: TextStyle(
                color: color.withValues(alpha: 0.8),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
