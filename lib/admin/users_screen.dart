import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'admin_theme.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  String _selectedFilter = 'todos';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildFilterAndSearch(),
          Expanded(child: _buildUsersList()),
        ],
      ),
    );
  }

  Widget _buildFilterAndSearch() {
    return Container(
      padding: const EdgeInsets.all(AdminTheme.spacingM),
      decoration: BoxDecoration(
        color: AdminTheme.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Filtros
          Row(
            children: [
              const Text(
                'Filtrar por: ',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AdminTheme.textPrimary,
                ),
              ),
              const SizedBox(width: AdminTheme.spacingM),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('todos', 'Todos'),
                      _buildFilterChip('postulante', 'Postulantes'),
                      _buildFilterChip('empleador', 'Empleadores'),
                      _buildFilterChip('pendientes', 'Con Certificaciones Pendientes'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AdminTheme.spacingM),
          // Búsqueda
          TextField(
            decoration: const InputDecoration(
              hintText: 'Buscar por nombre o correo...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return Container(
      margin: const EdgeInsets.only(right: AdminTheme.spacingS),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = value;
          });
        },
        backgroundColor: AdminTheme.backgroundColor,
        selectedColor: AdminTheme.primaryColor.withValues(alpha: 0.2),
        checkmarkColor: AdminTheme.primaryColor,
        labelStyle: TextStyle(
          color: isSelected ? AdminTheme.primaryColor : AdminTheme.textSecondary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildUsersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _buildFilteredStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AdminTheme.errorColor,
                ),
                const SizedBox(height: AdminTheme.spacingM),
                Text(
                  'Error al cargar usuarios',
                  style: TextStyle(
                    fontSize: 18,
                    color: AdminTheme.errorColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AdminTheme.spacingS),
                Text(
                  snapshot.error.toString(),
                  style: const TextStyle(color: AdminTheme.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: AdminTheme.spacingM),
                Text(
                  'Cargando usuarios...',
                  style: TextStyle(color: AdminTheme.textSecondary),
                ),
              ],
            ),
          );
        }

        final usuarios = snapshot.data!.docs.where((doc) {
          final userData = doc.data() as Map<String, dynamic>;
          final nombre = (userData['nombre'] ?? '').toString().toLowerCase();
          final correo = (userData['correo'] ?? '').toString().toLowerCase();
          
          // Filtrar por búsqueda
          if (_searchQuery.isNotEmpty) {
            if (!nombre.contains(_searchQuery) && !correo.contains(_searchQuery)) {
              return false;
            }
          }
          
          // Filtrar por certificaciones pendientes
          if (_selectedFilter == 'pendientes') {
            final certificaciones = userData['certificaciones'] as List<dynamic>? ?? [];
            bool hasPendientes = false;
            for (var cert in certificaciones) {
              if (cert is Map && cert['estado'] == 'pendiente') {
                hasPendientes = true;
                break;
              }
            }
            return hasPendientes;
          }
          
          return true;
        }).toList();

        if (usuarios.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 64,
                  color: AdminTheme.textSecondary,
                ),
                const SizedBox(height: AdminTheme.spacingM),
                const Text(
                  'No hay usuarios que mostrar',
                  style: TextStyle(
                    fontSize: 18,
                    color: AdminTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AdminTheme.spacingS),
                const Text(
                  'Prueba cambiando los filtros de búsqueda',
                  style: TextStyle(color: AdminTheme.textSecondary),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AdminTheme.spacingM),
          itemCount: usuarios.length,
          itemBuilder: (context, index) {
            final userData = usuarios[index].data() as Map<String, dynamic>;
            final userId = usuarios[index].id;
            return _buildUserCard(userData, userId);
          },
        );
      },
    );
  }

  Stream<QuerySnapshot> _buildFilteredStream() {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection('usuarios');
    
    if (_selectedFilter == 'postulante' || _selectedFilter == 'empleador') {
      query = query.where('rol', isEqualTo: _selectedFilter);
    }
    
    return query.snapshots();
  }

  Widget _buildUserCard(Map<String, dynamic> userData, String userId) {
    final nombre = userData['nombre'] ?? 'Sin nombre';
    final correo = userData['correo'] ?? 'Sin correo';
    final rol = userData['rol'] ?? 'Sin rol';
    
    // Procesar certificaciones
    final rawCertificaciones = userData['certificaciones'];
    List<Map<String, dynamic>> certificaciones = [];

    if (rawCertificaciones != null && rawCertificaciones is List<dynamic>) {
      if (rawCertificaciones.isNotEmpty && rawCertificaciones.first is Map) {
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

    return Card(
      margin: const EdgeInsets.only(bottom: AdminTheme.spacingM),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _getRolColor(rol),
          child: Icon(
            _getRolIcon(rol),
            color: Colors.white,
          ),
        ),
        title: Text(
          nombre,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(correo),
            const SizedBox(height: AdminTheme.spacingXS),
            AdminTheme.buildStatusChip(
              label: rol.toUpperCase(),
              color: _getRolColor(rol),
            ),
          ],
        ),
        children: [
          if (certificaciones.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.all(AdminTheme.spacingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AdminTheme.buildSectionTitle('Certificaciones'),
                  ...certificaciones.map((cert) => _buildCertificationItem(
                        cert,
                        userId,
                      )),
                ],
              ),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.all(AdminTheme.spacingM),
              child: Text(
                'Sin certificaciones registradas',
                style: TextStyle(
                  color: AdminTheme.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCertificationItem(Map<String, dynamic> cert, String userId) {
    final certNombre = cert['nombre'] ?? 'Sin nombre';
    final estado = cert['estado'] ?? 'pendiente';
    final documentoUrl = cert['documentoUrl'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: AdminTheme.spacingS),
      padding: const EdgeInsets.all(AdminTheme.spacingM),
      decoration: BoxDecoration(
        color: AdminTheme.backgroundColor,
        borderRadius: BorderRadius.circular(AdminTheme.radiusM),
        border: Border.all(
          color: _getEstadoColor(estado).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  certNombre,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: AdminTheme.spacingXS),
                AdminTheme.buildStatusChip(
                  label: estado.toUpperCase(),
                  color: _getEstadoColor(estado),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (documentoUrl.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.visibility),
                  onPressed: () => _openDocument(documentoUrl),
                  tooltip: 'Ver documento',
                ),
              if (estado == 'pendiente') ...[
                IconButton(
                  icon: const Icon(Icons.check, color: AdminTheme.accentColor),
                  onPressed: () => _actualizarEstadoCertificacion(
                    userId,
                    certNombre,
                    'aprobada',
                  ),
                  tooltip: 'Aprobar',
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AdminTheme.errorColor),
                  onPressed: () => _actualizarEstadoCertificacion(
                    userId,
                    certNombre,
                    'rechazada',
                  ),
                  tooltip: 'Rechazar',
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Color _getRolColor(String rol) {
    switch (rol) {
      case 'postulante':
        return AdminTheme.accentColor;
      case 'empleador':
        return AdminTheme.primaryColor;
      default:
        return AdminTheme.textSecondary;
    }
  }

  IconData _getRolIcon(String rol) {
    switch (rol) {
      case 'postulante':
        return Icons.person;
      case 'empleador':
        return Icons.business;
      default:
        return Icons.help_outline;
    }
  }

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'aprobada':
        return AdminTheme.accentColor;
      case 'rechazada':
        return AdminTheme.errorColor;
      case 'pendiente':
      default:
        return AdminTheme.warningColor;
    }
  }

  Future<void> _openDocument(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo abrir el documento'),
              backgroundColor: AdminTheme.errorColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir el documento: $e'),
            backgroundColor: AdminTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _actualizarEstadoCertificacion(
    String userId,
    String certNombre,
    String nuevoEstado,
  ) async {
    try {
      final userRef = FirebaseFirestore.instance.collection('usuarios').doc(userId);
      final doc = await userRef.get();

      if (doc.exists) {
        final data = doc.data()!;
        final rawCertificaciones = data['certificaciones'];

        List<Map<String, dynamic>> certificaciones = [];

        if (rawCertificaciones != null && rawCertificaciones is List<dynamic>) {
          if (rawCertificaciones.isNotEmpty && rawCertificaciones.first is Map) {
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

        final index = certificaciones.indexWhere((c) => c['nombre'] == certNombre);

        if (index != -1) {
          certificaciones[index]['estado'] = nuevoEstado;
          await userRef.update({'certificaciones': certificaciones});
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Certificación $nuevoEstado correctamente'),
                backgroundColor: AdminTheme.accentColor,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar certificación: $e'),
            backgroundColor: AdminTheme.errorColor,
          ),
        );
      }
    }
  }
}
