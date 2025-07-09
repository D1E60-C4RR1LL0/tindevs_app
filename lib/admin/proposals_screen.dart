import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'admin_theme.dart';

class ProposalsScreen extends StatefulWidget {
  const ProposalsScreen({super.key});

  @override
  State<ProposalsScreen> createState() => _ProposalsScreenState();
}

class _ProposalsScreenState extends State<ProposalsScreen> {
  String _selectedFilter = 'todos';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildFilterAndSearch(),
          Expanded(child: _buildProposalsList()),
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
            color: Colors.black.withOpacity(0.05),
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
                'Filtrar por estado: ',
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
                      _buildFilterChip('todos', 'Todas'),
                      _buildFilterChip('pendiente', 'Pendientes'),
                      _buildFilterChip('aprobada', 'Aprobadas'),
                      _buildFilterChip('rechazada', 'Rechazadas'),
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
              hintText: 'Buscar por título o descripción...',
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
        selectedColor: AdminTheme.primaryColor.withOpacity(0.2),
        checkmarkColor: AdminTheme.primaryColor,
        labelStyle: TextStyle(
          color: isSelected ? AdminTheme.primaryColor : AdminTheme.textSecondary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildProposalsList() {
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
                  'Error al cargar propuestas',
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
                  'Cargando propuestas...',
                  style: TextStyle(color: AdminTheme.textSecondary),
                ),
              ],
            ),
          );
        }

        final propuestas = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final titulo = (data['titulo'] ?? '').toString().toLowerCase();
          final descripcion = (data['descripcion'] ?? '').toString().toLowerCase();
          
          if (_searchQuery.isNotEmpty) {
            return titulo.contains(_searchQuery) || descripcion.contains(_searchQuery);
          }
          return true;
        }).toList();

        if (propuestas.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.business_center_outlined,
                  size: 64,
                  color: AdminTheme.textSecondary,
                ),
                const SizedBox(height: AdminTheme.spacingM),
                const Text(
                  'No hay propuestas que mostrar',
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
          itemCount: propuestas.length,
          itemBuilder: (context, index) {
            final data = propuestas[index].data() as Map<String, dynamic>;
            final propuestaId = propuestas[index].id;
            return _buildProposalCard(data, propuestaId);
          },
        );
      },
    );
  }

  Stream<QuerySnapshot> _buildFilteredStream() {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection('propuestas');
    
    if (_selectedFilter != 'todos') {
      query = query.where('estadoValidacion', isEqualTo: _selectedFilter);
    }
    
    return query.snapshots();
  }

  Widget _buildProposalCard(Map<String, dynamic> data, String propuestaId) {
    final titulo = data['titulo'] ?? 'Sin título';
    final descripcion = data['descripcion'] ?? 'Sin descripción';
    final estado = data['estadoValidacion'] ?? 'pendiente';
    // Buscar URL del documento en diferentes campos posibles
    final documentoUrl = data['documentoValidacionUrl'] ?? 
                        data['documentoUrl'] ?? 
                        data['imagenUrl'] ?? 
                        data['archivoUrl'] ?? '';
    final empleadorId = data['empleadorId'] ?? data['idEmpleador'] ?? '';
    final fechaCreacion = data['fechaCreacion'] as Timestamp?;
    final solicitudDocumentoEnviada = data['solicitudDocumentoEnviada'] ?? false;
    final solicitudDocumentoFecha = data['solicitudDocumentoFecha'] as Timestamp?;
    
    // Información adicional para el admin
    final region = data['region'] ?? '';
    final comuna = data['comuna'] ?? '';
    final experiencia = data['experiencia'] ?? 0;
    final carrera = data['carrera'] ?? '';
    final certificacion = data['certificacion'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: AdminTheme.spacingM),
      child: Padding(
        padding: const EdgeInsets.all(AdminTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AdminTheme.textPrimary,
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
                if (fechaCreacion != null)
                  Text(
                    _formatDate(fechaCreacion.toDate()),
                    style: const TextStyle(
                      color: AdminTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AdminTheme.spacingM),
            Text(
              descripcion,
              style: const TextStyle(
                color: AdminTheme.textSecondary,
                fontSize: 14,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AdminTheme.spacingM),
            // Panel expandible con información detallada de la propuesta
            Container(
              decoration: BoxDecoration(
                color: AdminTheme.surfaceColor,
                borderRadius: BorderRadius.circular(AdminTheme.radiusM),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ExpansionTile(
                leading: Icon(
                  Icons.info_outline,
                  color: AdminTheme.primaryColor,
                ),
                title: const Text(
                  'Información Detallada',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AdminTheme.textPrimary,
                  ),
                ),
                subtitle: const Text(
                  'Revisar antes de aprobar',
                  style: TextStyle(
                    fontSize: 12,
                    color: AdminTheme.textSecondary,
                  ),
                ),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AdminTheme.spacingM),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('📍 Ubicación', '$region, $comuna'),
                        _buildInfoRow('💼 Experiencia', '$experiencia años'),
                        _buildInfoRow('🎓 Carrera', carrera.isNotEmpty ? carrera : 'No especificada'),
                        _buildInfoRow('🏆 Certificación', certificacion.isNotEmpty ? certificacion : 'No requerida'),
                        const SizedBox(height: AdminTheme.spacingS),
                        Container(
                          padding: const EdgeInsets.all(AdminTheme.spacingS),
                          decoration: BoxDecoration(
                            color: estado == 'pendiente' 
                                ? AdminTheme.warningColor.withOpacity(0.1) 
                                : AdminTheme.accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AdminTheme.radiusS),
                            border: Border.all(
                              color: estado == 'pendiente' 
                                  ? AdminTheme.warningColor 
                                  : AdminTheme.accentColor,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                estado == 'pendiente' ? Icons.pending : Icons.check_circle,
                                color: estado == 'pendiente' 
                                    ? AdminTheme.warningColor 
                                    : AdminTheme.accentColor,
                                size: 16,
                              ),
                              const SizedBox(width: AdminTheme.spacingS),
                              Expanded(
                                child: Text(
                                  estado == 'pendiente' 
                                      ? '⚠️ REQUIERE APROBACIÓN ANTES DE SER VISIBLE'
                                      : '✅ PROPUESTA APROBADA Y VISIBLE PARA POSTULANTES',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: estado == 'pendiente' 
                                        ? AdminTheme.warningColor 
                                        : AdminTheme.accentColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Debug info para documentos
            Container(
              margin: const EdgeInsets.symmetric(vertical: AdminTheme.spacingXS),
              padding: const EdgeInsets.all(AdminTheme.spacingS),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(AdminTheme.radiusS),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        documentoUrl.isNotEmpty ? Icons.check_circle : Icons.info,
                        size: 16,
                        color: documentoUrl.isNotEmpty ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: AdminTheme.spacingXS),
                      Text(
                        'Estado del documento: ${documentoUrl.isNotEmpty ? "DISPONIBLE" : "NO DISPONIBLE"}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: documentoUrl.isNotEmpty ? Colors.green[700] : Colors.orange[700],
                        ),
                      ),
                    ],
                  ),
                  if (documentoUrl.isNotEmpty) ...[
                    const SizedBox(height: AdminTheme.spacingXS),
                    Text(
                      'URL: ${documentoUrl.substring(0, documentoUrl.length > 60 ? 60 : documentoUrl.length)}${documentoUrl.length > 60 ? "..." : ""}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AdminTheme.textSecondary,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AdminTheme.spacingM),
            Row(
              children: [
                if (documentoUrl.isNotEmpty) ...[
                  Expanded(
                    child: AdminTheme.buildActionButton(
                      label: 'Ver Documento',
                      icon: Icons.visibility,
                      onPressed: () => _openDocument(documentoUrl),
                      backgroundColor: AdminTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  if (estado == 'pendiente')
                    const SizedBox(width: AdminTheme.spacingS),
                ],
                if (estado == 'pendiente') ...[
                  Expanded(
                    child: AdminTheme.buildActionButton(
                      label: '✅ Aprobar',
                      icon: Icons.check_circle,
                      onPressed: () => _showApprovalConfirmDialog(
                        context,
                        titulo,
                        propuestaId,
                        documentoUrl,
                      ),
                      backgroundColor: AdminTheme.accentColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: AdminTheme.spacingS),
                  Expanded(
                    child: AdminTheme.buildActionButton(
                      label: 'Rechazar',
                      icon: Icons.close,
                      onPressed: () => _showConfirmDialog(
                        context,
                        'Rechazar Propuesta',
                        '¿Está seguro que desea rechazar esta propuesta?',
                        () => _updatePropuesta(propuestaId, 'rechazada'),
                      ),
                      backgroundColor: AdminTheme.errorColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
            if (documentoUrl.isEmpty)
              Container(
                margin: const EdgeInsets.only(top: AdminTheme.spacingS),
                padding: const EdgeInsets.all(AdminTheme.spacingM),
                decoration: BoxDecoration(
                  color: AdminTheme.warningColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AdminTheme.radiusM),
                  border: Border.all(color: AdminTheme.warningColor.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber,
                          color: AdminTheme.warningColor,
                          size: 20,
                        ),
                        const SizedBox(width: AdminTheme.spacingS),
                        Expanded(
                          child: Text(
                            'Documento de validación no disponible',
                            style: TextStyle(
                              color: AdminTheme.warningColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AdminTheme.spacingS),
                    Text(
                      'El empleador no ha subido un documento de validación para verificar la vigencia de esta propuesta.',
                      style: TextStyle(
                        color: AdminTheme.warningColor.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: AdminTheme.spacingM),
                    Row(
                      children: [
                        Expanded(
                          child: solicitudDocumentoEnviada
                              ? Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(AdminTheme.spacingM),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(AdminTheme.radiusM),
                                    border: Border.all(color: Colors.grey[400]!),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.schedule,
                                        color: Colors.grey[600],
                                        size: 20,
                                      ),
                                      const SizedBox(width: AdminTheme.spacingS),
                                      Expanded(
                                        child: Text(
                                          solicitudDocumentoFecha != null 
                                              ? 'Solicitado ${_formatFecha(solicitudDocumentoFecha)}'
                                              : 'Solicitud Enviada',
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : AdminTheme.buildActionButton(
                                  label: 'Solicitar Documento',
                                  icon: Icons.file_upload_outlined,
                                  onPressed: () => _solicitarDocumento(propuestaId, empleadorId),
                                  backgroundColor: AdminTheme.warningColor,
                                  foregroundColor: Colors.white,
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AdminTheme.spacingS),
            // Botón de eliminar siempre visible en fila separada
            SizedBox(
              width: double.infinity,
              child: AdminTheme.buildActionButton(
                label: 'Eliminar Propuesta',
                icon: Icons.delete_forever,
                onPressed: () => _showDeleteConfirmDialog(
                  context,
                  titulo,
                  propuestaId,
                  empleadorId,
                ),
                backgroundColor: Colors.red[700]!,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget helper para mostrar información en filas
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AdminTheme.spacingS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AdminTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: AdminTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Hoy';
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} días';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatFecha(Timestamp timestamp) {
    final fecha = timestamp.toDate();
    final ahora = DateTime.now();
    final diferencia = ahora.difference(fecha);

    if (diferencia.inDays == 0) {
      if (diferencia.inHours == 0) {
        return 'hace ${diferencia.inMinutes} min';
      } else {
        return 'hace ${diferencia.inHours} h';
      }
    } else if (diferencia.inDays == 1) {
      return 'ayer';
    } else if (diferencia.inDays < 7) {
      return 'hace ${diferencia.inDays} días';
    } else {
      return '${fecha.day}/${fecha.month}/${fecha.year}';
    }
  }

  Future<void> _openDocument(String url) async {
    try {
      // Mostrar loading mientras se abre el documento
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: AdminTheme.spacingM),
              const Text('Abriendo documento de validación...'),
            ],
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: AdminTheme.primaryColor,
        ),
      );

      final uri = Uri.parse(url);
      
      // Intentar abrir en nueva pestaña/ventana
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri, 
          mode: LaunchMode.externalApplication,
          webOnlyWindowName: '_blank',
        );
        
        // Ocultar loading y mostrar éxito
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.open_in_new, color: Colors.white, size: 20),
                  const SizedBox(width: AdminTheme.spacingM),
                  const Expanded(
                    child: Text(
                      'Documento abierto en nueva pestaña',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              backgroundColor: AdminTheme.accentColor,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw Exception('No se puede abrir la URL del documento');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        
        // Mostrar dialog con opciones cuando falla
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.error_outline, color: AdminTheme.errorColor),
                const SizedBox(width: AdminTheme.spacingM),
                const Text('Error al abrir documento'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('No se pudo abrir el documento automáticamente.'),
                const SizedBox(height: AdminTheme.spacingM),
                Container(
                  padding: const EdgeInsets.all(AdminTheme.spacingM),
                  decoration: BoxDecoration(
                    color: AdminTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(AdminTheme.radiusM),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'URL del documento:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: AdminTheme.spacingXS),
                      SelectableText(
                        url,
                        style: TextStyle(
                          fontSize: 12,
                          color: AdminTheme.primaryColor,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AdminTheme.spacingM),
                Text(
                  'Puedes copiar la URL y abrirla manualmente en tu navegador.',
                  style: TextStyle(
                    color: AdminTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Intentar copiar al portapapeles si es posible
                  Navigator.pop(context);
                  try {
                    // En web, intentar copiar al portapapeles
                    await launchUrl(Uri.parse(url));
                  } catch (e) {
                    // Si falla, mostrar la URL nuevamente
                  }
                },
                child: const Text('Intentar Nuevamente'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _showApprovalConfirmDialog(
    BuildContext context,
    String titulo,
    String propuestaId,
    String documentoUrl,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.security, color: AdminTheme.accentColor),
            const SizedBox(width: AdminTheme.spacingM),
            const Text('🔒 Aprobar Propuesta'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AdminTheme.spacingM),
                decoration: BoxDecoration(
                  color: AdminTheme.accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AdminTheme.radiusM),
                  border: Border.all(color: AdminTheme.accentColor.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📋 "$titulo"',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: AdminTheme.spacingM),
                    const Text(
                      '⚠️ Al aprobar será VISIBLE para postulantes',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AdminTheme.spacingM),
              Container(
                padding: const EdgeInsets.all(AdminTheme.spacingM),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(AdminTheme.radiusM),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '✅ Checklist de Verificación:',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: AdminTheme.spacingS),
                    _buildChecklistItem('• ¿Revisó toda la información detallada?'),
                    _buildChecklistItem('• ¿La ubicación y datos son coherentes?'),
                    _buildChecklistItem('• ¿El salario y contrato son apropiados?'),
                    if (documentoUrl.isNotEmpty)
                      _buildChecklistItem('• ¿Verificó el documento de validación?')
                    else
                      _buildChecklistItem('• ⚠️ NO hay documento de validación'),
                    _buildChecklistItem('• ¿La propuesta cumple políticas de la plataforma?'),
                  ],
                ),
              ),
              const SizedBox(height: AdminTheme.spacingM),
              Text(
                '¿Confirma que ha revisado toda la información y autoriza la publicación?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AdminTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminTheme.accentColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('✅ Aprobar y Publicar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _updatePropuesta(propuestaId, 'aprobada');
    }
  }

  Widget _buildChecklistItem(String text) {
    final isWarning = text.contains('⚠️');
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: isWarning ? AdminTheme.warningColor : AdminTheme.textSecondary,
          fontWeight: isWarning ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Future<void> _showConfirmDialog(
    BuildContext context,
    String title,
    String message,
    VoidCallback onConfirm,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      onConfirm();
    }
  }

  Future<void> _updatePropuesta(String propuestaId, String newEstado) async {
    try {
      await FirebaseFirestore.instance
          .collection('propuestas')
          .doc(propuestaId)
          .update({'estadoValidacion': newEstado});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Propuesta $newEstado correctamente'),
            backgroundColor: AdminTheme.accentColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar propuesta: $e'),
            backgroundColor: AdminTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _showDeleteConfirmDialog(
    BuildContext context,
    String titulo,
    String propuestaId,
    String empleadorId,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Eliminar Propuesta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Está seguro que desea eliminar permanentemente la propuesta?'),
            const SizedBox(height: AdminTheme.spacingM),
            Container(
              padding: const EdgeInsets.all(AdminTheme.spacingM),
              decoration: BoxDecoration(
                color: AdminTheme.errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AdminTheme.radiusM),
                border: Border.all(color: AdminTheme.errorColor.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📋 "$titulo"',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: AdminTheme.spacingS),
                  const Text(
                    '⚠️ Esta acción es irreversible:',
                    style: TextStyle(
                      color: AdminTheme.errorColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  const Text(
                    '• Se eliminará de la base de datos\n• Se removerá de la vista del empleador\n• Los postulantes no podrán verla',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar Definitivamente'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _deletePropuesta(propuestaId, empleadorId, titulo);
    }
  }

  Future<void> _deletePropuesta(
    String propuestaId,
    String empleadorId,
    String titulo,
  ) async {
    try {
      // Mostrar loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: AdminTheme.spacingM),
                Text('Eliminando propuesta...'),
              ],
            ),
            duration: Duration(seconds: 10),
            backgroundColor: AdminTheme.warningColor,
          ),
        );
      }

      // 1. Eliminar la propuesta de la colección principal
      await FirebaseFirestore.instance
          .collection('propuestas')
          .doc(propuestaId)
          .delete();

      // 2. Si hay un empleadorId, eliminar la referencia en el usuario empleador
      if (empleadorId.isNotEmpty) {
        final empleadorRef = FirebaseFirestore.instance
            .collection('usuarios')
            .doc(empleadorId);
        
        final empleadorDoc = await empleadorRef.get();
        if (empleadorDoc.exists) {
          final data = empleadorDoc.data()!;
          
          // Si el empleador tiene un campo 'propuestas', remover esta propuesta
          if (data.containsKey('propuestas')) {
            Map<String, dynamic> propuestas = Map<String, dynamic>.from(data['propuestas'] ?? {});
            propuestas.remove(propuestaId);
            
            await empleadorRef.update({'propuestas': propuestas});
          }
        }
      }

      // 3. Eliminar cualquier aplicación/interés relacionado con esta propuesta
      // Buscar en likes/dislikes que puedan referenciar esta propuesta
      final likesSnapshot = await FirebaseFirestore.instance
          .collection('likes')
          .where('propuestaId', isEqualTo: propuestaId)
          .get();
      
      final dislikesSnapshot = await FirebaseFirestore.instance
          .collection('dislikes')
          .where('propuestaId', isEqualTo: propuestaId)
          .get();

      // Eliminar likes relacionados
      for (var doc in likesSnapshot.docs) {
        await doc.reference.delete();
      }

      // Eliminar dislikes relacionados
      for (var doc in dislikesSnapshot.docs) {
        await doc.reference.delete();
      }

      // Ocultar loading y mostrar éxito
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: AdminTheme.spacingM),
                Expanded(
                  child: Text(
                    'Propuesta "$titulo" eliminada correctamente',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: AdminTheme.accentColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Ocultar loading y mostrar error
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: AdminTheme.spacingM),
                Expanded(
                  child: Text(
                    'Error al eliminar propuesta: $e',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: AdminTheme.errorColor,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _solicitarDocumento(String propuestaId, String empleadorId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.file_upload_outlined, color: AdminTheme.primaryColor),
            const SizedBox(width: AdminTheme.spacingM),
            const Text('Solicitar Documento'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Esta acción enviará una notificación al empleador solicitando que suba un documento de validación para verificar la vigencia de la propuesta.',
            ),
            const SizedBox(height: AdminTheme.spacingM),
            Container(
              padding: const EdgeInsets.all(AdminTheme.spacingM),
              decoration: BoxDecoration(
                color: AdminTheme.backgroundColor,
                borderRadius: BorderRadius.circular(AdminTheme.radiusM),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Información que se enviará:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: AdminTheme.spacingS),
                  Text('• Propuesta ID: $propuestaId', style: TextStyle(fontSize: 12)),
                  Text('• Empleador ID: $empleadorId', style: TextStyle(fontSize: 12)),
                  const Text('• Fecha de solicitud: Ahora', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _enviarSolicitudDocumento(propuestaId, empleadorId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Enviar Solicitud'),
          ),
        ],
      ),
    );
  }

  Future<void> _enviarSolicitudDocumento(String propuestaId, String empleadorId) async {
    try {
      // Mostrar loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: AdminTheme.spacingM),
              const Text('Enviando solicitud de documento...'),
            ],
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: AdminTheme.primaryColor,
        ),
      );

      // Actualizar la propuesta con la fecha de solicitud
      await FirebaseFirestore.instance
          .collection('propuestas')
          .doc(propuestaId)
          .update({
        'solicitudDocumentoFecha': FieldValue.serverTimestamp(),
        'solicitudDocumentoEnviada': true,
      });

      // Crear notificación para el empleador (si existe la colección de notificaciones)
      if (empleadorId.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('notificaciones')
            .add({
          'empleadorId': empleadorId,
          'propuestaId': propuestaId,
          'tipo': 'solicitud_documento',
          'titulo': 'Documento de validación requerido',
          'mensaje': 'Se requiere que suba un documento para validar la vigencia de su propuesta.',
          'fecha': FieldValue.serverTimestamp(),
          'leida': false,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: AdminTheme.spacingM),
                const Expanded(
                  child: Text(
                    'Solicitud enviada exitosamente',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: AdminTheme.accentColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white, size: 20),
                const SizedBox(width: AdminTheme.spacingM),
                Expanded(
                  child: Text(
                    'Error al enviar solicitud: ${e.toString()}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: AdminTheme.errorColor,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}
