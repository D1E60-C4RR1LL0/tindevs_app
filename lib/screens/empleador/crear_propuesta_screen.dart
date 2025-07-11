import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../../utils/themes/app_themes.dart';

class CrearPropuestaScreen extends StatefulWidget {
  final String? propuestaId;
  final Map<String, dynamic>? datosExistentes;
  
  const CrearPropuestaScreen({
    super.key, 
    this.propuestaId,
    this.datosExistentes,
  });

  @override
  State<CrearPropuestaScreen> createState() => _CrearPropuestaScreenState();
}

class _CrearPropuestaScreenState extends State<CrearPropuestaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _carreraController = TextEditingController();
  final _certificacionController = TextEditingController();
  final _experienciaController = TextEditingController();

  List<Map<String, dynamic>> _coordenadasComunas = [];
  List<Map<String, dynamic>> _todasLasComunas = [];
  List<String> _regiones = [];
  List<String> _comunasFiltradas = [];
  String? _regionSeleccionada;
  String? _comunaSeleccionada;
  double? _latitudSeleccionada;
  double? _longitudSeleccionada;

  // Variables para soporte de edición
  String? _documentoExistenteUrl;

  // NUEVO: documento seleccionado
  XFile? _documentoSeleccionado;

  @override
  void initState() {
    super.initState();
    _cargarCoordenadasComunas().then((_) {
      // Cargar datos existentes después de cargar las coordenadas
      if (widget.datosExistentes != null) {
        _cargarDatosExistentes();
      }
    });
  }
  
  void _cargarDatosExistentes() {
    final datos = widget.datosExistentes!;
    _tituloController.text = datos['titulo'] ?? '';
    _descripcionController.text = datos['descripcion'] ?? '';
    
    // Cargar carrera - compatible con ambos formatos
    _carreraController.text = datos['carrera'] ?? datos['carreraRequerida'] ?? '';
    
    // Cargar certificación - compatible con ambos formatos
    _certificacionController.text = datos['certificacion'] ?? datos['certificacionRequerida'] ?? '';
    
    // Cargar experiencia - compatible con ambos formatos
    final experiencia = datos['experiencia'] ?? datos['experienciaMinima'] ?? 0;
    _experienciaController.text = experiencia.toString();
    
    // Cargar comuna y determinar región
    final comunaGuardada = datos['comuna'];
    if (comunaGuardada != null && comunaGuardada.isNotEmpty) {
      // Buscar la región de esta comuna
      final comunaData = _todasLasComunas.firstWhere(
        (comuna) => comuna['nombre'] == comunaGuardada,
        orElse: () => {'region': '', 'nombre': ''},
      );
      
      if (comunaData['region'] != null && comunaData['region'].isNotEmpty) {
        _regionSeleccionada = comunaData['region'];
        _filtrarComunasPorRegion(_regionSeleccionada!);
        _comunaSeleccionada = comunaGuardada;
      }
    }
    
    // Si no se pudo determinar la región desde la comuna, usar la región guardada
    if (_regionSeleccionada == null && datos['region'] != null && datos['region'].isNotEmpty) {
      _regionSeleccionada = datos['region'];
      _filtrarComunasPorRegion(_regionSeleccionada!);
    }
    
    // Cargar URL del documento existente
    _documentoExistenteUrl = datos['documentoValidacionUrl'] ?? 
                            datos['documentoUrl'] ?? 
                            datos['imagenUrl'] ?? 
                            datos['archivoUrl'] ?? '';
    
    // Cargar coordenadas si están disponibles
    if (datos['latitud'] != null && datos['longitud'] != null) {
      _latitudSeleccionada = datos['latitud'];
      _longitudSeleccionada = datos['longitud'];
    }
  }

  void _filtrarComunasPorRegion(String region) {
    setState(() {
      _regionSeleccionada = region;
      _comunaSeleccionada = null; // Reset comuna selection
      _latitudSeleccionada = null;
      _longitudSeleccionada = null;
      
      _comunasFiltradas = _todasLasComunas
          .where((comuna) => comuna['region'] == region)
          .map((comuna) => comuna['nombre'] as String)
          .toList()
        ..sort();
    });
  }

  void _seleccionarComuna(String comuna) {
    // Buscar coordenadas de la comuna seleccionada
    final comunaData = _coordenadasComunas.firstWhere(
      (c) => c['nombre'] == comuna,
      orElse: () => {'nombre': comuna, 'lat': 0.0, 'lng': 0.0},
    );
    
    setState(() {
      _comunaSeleccionada = comuna;
      _latitudSeleccionada = comunaData['lat'];
      _longitudSeleccionada = comunaData['lng'];
    });
  }

  Future<void> _cargarCoordenadasComunas() async {
    try {
      // Cargar coordenadas de comunas
      final String responseCoords = await rootBundle.loadString('assets/data/comunas_latlng.json');
      final coordsData = json.decode(responseCoords) as List;

      // Cargar regiones y comunas
      final String responseComunas = await rootBundle.loadString('assets/data/comunas.json');
      final comunasData = json.decode(responseComunas) as List;

      setState(() {
        _coordenadasComunas = coordsData.map((item) => {
          'nombre': item['nombre'],
          'lat': item['lat'],
          'lng': item['lng'],
        }).toList();

        _todasLasComunas = comunasData.map((item) => {
          'region': item['region'],
          'nombre': item['nombre'],
        }).toList();

        // Extraer regiones únicas
        _regiones = _todasLasComunas
            .map((comuna) => comuna['region'] as String)
            .toSet()
            .toList()
          ..sort();
      });
    } catch (e) {
      print('Error al cargar datos de comunas: $e');
    }
  }

  Future<void> _seleccionarDocumento() async {
    try {
      const XTypeGroup typeGroup = XTypeGroup(
        label: 'Documentos',
        extensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );
      final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);

      if (file != null) {
        setState(() {
          _documentoSeleccionado = file;
        });
      }
    } catch (e) {
      print('Error al seleccionar documento: $e');
    }
  }

  Future<String?> _subirDocumento(String propuestaId) async {
    if (_documentoSeleccionado == null) return null;

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('propuestas/$propuestaId/validacion_documento.${_documentoSeleccionado!.name.split('.').last}');

      final uploadTask = await storageRef.putData(await _documentoSeleccionado!.readAsBytes());

      final url = await uploadTask.ref.getDownloadURL();
      return url;
    } catch (e) {
      print('Error al subir documento: $e');
      return null;
    }
  }

  Future<void> _guardarPropuesta() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_comunaSeleccionada == null || _latitudSeleccionada == null || _longitudSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe seleccionar una comuna válida.')),
      );
      return;
    }

    // Si es creación nueva, requiere documento
    final esEdicion = widget.propuestaId != null;
    if (!esEdicion && _documentoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe subir el documento de vigencia de la empresa.')),
      );
      return;
    }

    try {
      // Obtener información del perfil del empleador
      String nombreEmpresa = 'Empresa no especificada';
      try {
        final perfilDoc = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .get();
        
        if (perfilDoc.exists) {
          final perfilData = perfilDoc.data() ?? {};
          nombreEmpresa = perfilData['empresa'] ?? 'Empresa no especificada';
        }
      } catch (e) {
        print('Error al obtener perfil del empleador: $e');
      }

      final datosActualizados = {
        'titulo': _tituloController.text.trim(),
        'descripcion': _descripcionController.text.trim(),
        // Campos principales que usa el sistema
        'carrera': _carreraController.text.trim(),
        'certificacion': _certificacionController.text.trim(),
        'experiencia': int.tryParse(_experienciaController.text.trim()) ?? 0,
        'region': _regionSeleccionada ?? '',
        'comuna': _comunaSeleccionada ?? '',
        'latitud': _latitudSeleccionada ?? 0.0,
        'longitud': _longitudSeleccionada ?? 0.0,
        'empresa': nombreEmpresa,
        // Campos de compatibilidad adicionales
        'carreraRequerida': _carreraController.text.trim(),
        'certificacionRequerida': _certificacionController.text.trim(),
        'experienciaMinima': int.tryParse(_experienciaController.text.trim()) ?? 0,
      };

      if (esEdicion) {
        // Actualizar propuesta existente
        final docRef = FirebaseFirestore.instance.collection('propuestas').doc(widget.propuestaId!);
        
        // Si hay nuevo documento, subirlo
        String? nuevaUrlDocumento;
        if (_documentoSeleccionado != null) {
          nuevaUrlDocumento = await _subirDocumento(widget.propuestaId!);
          if (nuevaUrlDocumento != null) {
            datosActualizados['documentoValidacionUrl'] = nuevaUrlDocumento;
          }
        }
        
        await docRef.update(datosActualizados);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Propuesta actualizada exitosamente.')),
        );
      } else {
        // Crear nueva propuesta
        datosActualizados.addAll({
          'empleadorId': user.uid,
          'idEmpleador': user.uid, // Compatibilidad
          'fechaPublicacion': DateTime.now(),
          'fechaCreacion': DateTime.now(), // Compatibilidad
          'estadoValidacion': 'pendiente',
          'estado': 'activo', // CRÍTICO: Para que sea visible a postulantes cuando se apruebe
          'documentoValidacionUrl': '',
        });

        final docRef = await FirebaseFirestore.instance.collection('propuestas').add(datosActualizados);

        // Subir documento
        final documentoUrl = await _subirDocumento(docRef.id);

        // Actualizar con URL
        await docRef.update({
          'documentoValidacionUrl': documentoUrl ?? '',
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'La propuesta ha sido enviada para validación. Será publicada al ser aprobada por un administrador.',
            ),
          ),
        );

        // Reset solo en creación
        _formKey.currentState!.reset();
        setState(() {
          _comunaSeleccionada = null;
          _latitudSeleccionada = null;
          _longitudSeleccionada = null;
          _documentoSeleccionado = null;
          _documentoExistenteUrl = null;
        });

        // Navegar al inicio de las propuestas
        Navigator.of(context).pop(true);
      }

      // Si es edición, volver a la pantalla anterior
      if (esEdicion) {
        Navigator.of(context).pop(true); // true indica que se guardaron cambios
      }
    } catch (e) {
      print('Error al guardar propuesta: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al ${esEdicion ? 'actualizar' : 'publicar'} propuesta.')),
      );
    }
  }

  // Métodos helper para UI estilizada
  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha((0.1 * 255).toInt()),
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
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppThemes.empleadorAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: AppThemes.empleadorAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppThemes.empleadorPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon, color: AppThemes.empleadorAccent) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppThemes.empleadorAccent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _buildStyledDropdown<T>({
    required T? value,
    required String label,
    String? hint,
    IconData? icon,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    String? Function(T?)? validator,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      validator: validator,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon, color: AppThemes.empleadorAccent) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppThemes.empleadorAccent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _buildExistingDocumentCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppThemes.empleadorAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppThemes.empleadorAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppThemes.empleadorAccent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Documento actual',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.description, size: 20, color: Colors.grey),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Documento de validación subido',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Documento existente confirmado')),
                  );
                },
                child: const Text('Ver'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentSelector() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: AppThemes.empleadorAccent.withValues(alpha: 0.3), width: 2),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade50,
      ),
      child: ElevatedButton.icon(
        onPressed: _seleccionarDocumento,
        icon: const Icon(Icons.cloud_upload_outlined, size: 24),
        label: Flexible(
          child: Text(
            widget.propuestaId != null 
              ? 'Seleccionar nuevo documento' 
              : 'Subir documento de vigencia',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: AppThemes.empleadorAccent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedDocumentCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: AppThemes.empleadorAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppThemes.empleadorAccent),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppThemes.empleadorAccent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Archivo seleccionado',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _documentoSeleccionado!.name,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppThemes.empleadorTheme,
      child: Scaffold(
        backgroundColor: AppThemes.empleadorBackground,
        appBar: AppBar(
          title: Text(
            widget.propuestaId != null ? 'Editar Propuesta' : 'Crear Propuesta',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          backgroundColor: AppThemes.empleadorPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,            colors: [
              AppThemes.empleadorPrimary.withValues(alpha: 0.05),
              AppThemes.empleadorBackground,
            ],
            ),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header con iconos
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: AppThemes.empleadorGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppThemes.empleadorAccent.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Icon(
                            widget.propuestaId != null ? Icons.edit : Icons.add_business,
                            size: 40,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.propuestaId != null 
                              ? 'Actualizar propuesta'
                              : 'Crear nueva propuesta',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.propuestaId != null 
                              ? 'Modifica los detalles de tu oferta'
                              : 'Completa los campos para publicar',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Información básica
                    _buildSection(
                      title: 'Información Básica',
                      icon: Icons.info_outline,
                      children: [
                        _buildStyledTextField(
                          controller: _tituloController,
                          label: 'Título del cargo',
                          hint: 'Ej: Desarrollador Full Stack',
                          icon: Icons.work_outline,
                          validator: (value) => value!.isEmpty ? 'Este campo es obligatorio' : null,
                        ),
                        const SizedBox(height: 12),
                        _buildStyledTextField(
                          controller: _descripcionController,
                          label: 'Descripción del trabajo',
                          hint: 'Describe las responsabilidades y tareas del puesto',
                          icon: Icons.description_outlined,
                          maxLines: 4,
                        ),
                        const SizedBox(height: 12),
                        _buildStyledTextField(
                          controller: _carreraController,
                          label: 'Carrera requerida',
                          hint: 'Ej: Ingeniería en Informática',
                          icon: Icons.school_outlined,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Ubicación
                    _buildSection(
                      title: 'Ubicación',
                      icon: Icons.location_on_outlined,
                      children: [
                        _buildStyledDropdown<String>(
                          value: _regionSeleccionada,
                          label: 'Región',
                          hint: 'Selecciona una región',
                          icon: Icons.map_outlined,
                          items: _regiones.map((region) {
                            return DropdownMenuItem<String>(
                              value: region,
                              child: Text(
                                region,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              _filtrarComunasPorRegion(value);
                            }
                          },
                          validator: (value) => value == null ? 'Debe seleccionar una región' : null,
                        ),
                        const SizedBox(height: 12),
                        _buildStyledDropdown<String>(
                          value: _comunaSeleccionada,
                          label: 'Comuna',
                          hint: 'Selecciona una comuna',
                          icon: Icons.place_outlined,
                          items: _comunasFiltradas.map((comuna) {
                            return DropdownMenuItem<String>(
                              value: comuna,
                              child: Text(
                                comuna,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (_regionSeleccionada != null && value != null) {
                              _seleccionarComuna(value);
                            }
                          },
                          validator: (value) => value == null ? 'Debe seleccionar una comuna' : null,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Requisitos
                    _buildSection(
                      title: 'Requisitos',
                      icon: Icons.checklist_outlined,
                      children: [
                        _buildStyledTextField(
                          controller: _certificacionController,
                          label: 'Certificación requerida',
                          hint: 'Ej: Certificación en Python (opcional)',
                          icon: Icons.verified_outlined,
                        ),
                        const SizedBox(height: 12),
                        _buildStyledTextField(
                          controller: _experienciaController,
                          label: 'Años de experiencia mínima',
                          hint: 'Ej: 2',
                          icon: Icons.timeline_outlined,
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Documento
                    _buildSection(
                      title: 'Documento de Vigencia',
                      icon: Icons.file_present_outlined,
                      children: [
                        if (widget.propuestaId != null && _documentoExistenteUrl != null && _documentoExistenteUrl!.isNotEmpty)
                          _buildExistingDocumentCard(),
                        const SizedBox(height: 12),
                        _buildDocumentSelector(),
                        if (_documentoSeleccionado != null)
                          _buildSelectedDocumentCard(),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Botón de acción
                    Container(
                      decoration: BoxDecoration(
                        gradient: AppThemes.empleadorGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppThemes.empleadorAccent.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _guardarPropuesta,
                        icon: Icon(
                          widget.propuestaId != null ? Icons.update : Icons.publish,
                          size: 24,
                        ),
                        label: Flexible(
                          child: Text(
                            widget.propuestaId != null ? 'Actualizar Propuesta' : 'Publicar Propuesta',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
