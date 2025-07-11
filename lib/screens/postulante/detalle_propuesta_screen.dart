import 'package:flutter/material.dart';
import '../../utils/themes/app_themes.dart';

class DetallePropuestaScreen extends StatelessWidget {
  final Map<String, dynamic> propuesta;
  final bool? isFromInterests; // Para saber si viene de la vista de intereses

  const DetallePropuestaScreen({
    super.key, 
    required this.propuesta,
    this.isFromInterests = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemes.postulanteBackground,
      appBar: AppBar(
        title: const Text('Detalle de Propuesta'),
        backgroundColor: AppThemes.postulantePrimary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header con información básica
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppThemes.postulantePrimary,
                    AppThemes.postulantePrimary.withValues(alpha: 0.8),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    propuesta['titulo'] ?? 'Sin título',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (propuesta.containsKey('empresa'))
                    Text(
                      propuesta['empresa'],
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  const SizedBox(height: 16),
                  // Badges de información clave
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (propuesta.containsKey('region'))
                        _buildInfoBadge(
                          icon: Icons.location_on,
                          text: propuesta['region'],
                          color: Colors.blue[100]!,
                          textColor: Colors.blue[800]!,
                        ),
                      if (propuesta.containsKey('modalidad'))
                        _buildInfoBadge(
                          icon: Icons.work_outline,
                          text: propuesta['modalidad'],
                          color: Colors.green[100]!,
                          textColor: Colors.green[800]!,
                        ),
                      if (propuesta.containsKey('experienciaMinima') || propuesta.containsKey('experiencia'))
                        _buildInfoBadge(
                          icon: Icons.star_outline,
                          text: '${propuesta['experienciaMinima'] ?? propuesta['experiencia']} años exp.',
                          color: Colors.orange[100]!,
                          textColor: Colors.orange[800]!,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Contenido principal
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Descripción
                  _buildSection(
                    title: 'Descripción del puesto',
                    icon: Icons.description,
                    child: Text(
                      propuesta['descripcion'] ?? 'Sin descripción disponible',
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Información de ubicación
                  _buildSection(
                    title: 'Ubicación',
                    icon: Icons.place,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (propuesta.containsKey('region'))
                          _buildInfoRow(
                            label: 'Región:',
                            value: propuesta['region'],
                          ),
                        if (propuesta.containsKey('comuna'))
                          _buildInfoRow(
                            label: 'Comuna:',
                            value: propuesta['comuna'],
                          ),
                        if (propuesta.containsKey('direccion'))
                          _buildInfoRow(
                            label: 'Dirección:',
                            value: propuesta['direccion'],
                          ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Requisitos y experiencia
                  _buildSection(
                    title: 'Requisitos',
                    icon: Icons.checklist,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (propuesta.containsKey('experienciaMinima') || propuesta.containsKey('experiencia'))
                          _buildInfoRow(
                            label: 'Años de experiencia:',
                            value: '${propuesta['experienciaMinima'] ?? propuesta['experiencia']} años',
                          ),
                        if (propuesta.containsKey('carreraRequerida') || propuesta.containsKey('carrera'))
                          _buildInfoRow(
                            label: 'Carrera requerida:',
                            value: propuesta['carreraRequerida'] ?? propuesta['carrera'],
                          ),
                        if ((propuesta.containsKey('certificacionRequerida') || propuesta.containsKey('certificacion')) &&
                            (propuesta['certificacionRequerida'] != null || propuesta['certificacion'] != null) &&
                            (propuesta['certificacionRequerida']?.toString().isNotEmpty == true || 
                             propuesta['certificacion']?.toString().isNotEmpty == true))
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Certificaciones requeridas:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle_outline,
                                      size: 20,
                                      color: AppThemes.postulanteAccent,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        propuesta['certificacionRequerida'] ?? propuesta['certificacion'],
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Información laboral (si hay campos disponibles)
                  _buildSection(
                    title: 'Información del puesto',
                    icon: Icons.business_center,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow(
                          label: 'Ubicación:',
                          value: propuesta['comuna'] ?? 'No especificada',
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Beneficios (si existen)
                  if (propuesta.containsKey('beneficios') && 
                      propuesta['beneficios'] != null &&
                      propuesta['beneficios'].toString().isNotEmpty)
                    _buildSection(
                      title: 'Beneficios',
                      icon: Icons.card_giftcard,
                      child: Text(
                        propuesta['beneficios'],
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 32),
                  
                  // Botón de acción (solo si no viene de intereses)
                  if (isFromInterests != true)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.thumb_up, color: Colors.white),
                                  const SizedBox(width: 12),
                                  const Text('Interés registrado exitosamente'),
                                ],
                              ),
                              backgroundColor: AppThemes.postulanteAccent,
                            ),
                          );
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppThemes.postulanteAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        icon: const Icon(Icons.thumb_up),
                        label: const Text(
                          'Mostrar interés',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBadge({
    required IconData icon,
    required String text,
    required Color color,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: AppThemes.postulantePrimary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppThemes.postulantePrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
