import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:url_launcher/url_launcher.dart';
import 'package:tindevs_app/utils/app_themes.dart';

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
  List<Map<String, dynamic>> _regiones = [];
  String? _regionSeleccionada;
  String? _comunaSeleccionada;
  double? _latitudSeleccionada;
  double? _longitudSeleccionada;

  // NUEVO: documento seleccionado
  XFile? _documentoSeleccionado;
  String? _documentoExistenteUrl;

  @override
  void initState() {
    super.initState();
    _cargarDatosGeograficos();
    if (widget.datosExistentes != null) {
      _cargarDatosExistentes();
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _carreraController.dispose();
    _certificacionController.dispose();
    _experienciaController.dispose();
    super.dispose();
  }

  void _cargarDatosExistentes() {
    final datos = widget.datosExistentes!;
    _tituloController.text = datos['titulo'] ?? '';
    _descripcionController.text = datos['descripcion'] ?? '';
    _carreraController.text = datos['carrera'] ?? '';
    _certificacionController.text = datos['certificacion'] ?? '';
    _experienciaController.text = datos['experiencia']?.toString() ?? '';
    _comunaSeleccionada = datos['comuna'];
    _regionSeleccionada = datos['region'];
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

  Future<void> _cargarDatosGeograficos() async {
    try {
      // Cargar regiones y comunas
      final String comunasResponse = await rootBundle.loadString('assets/data/comunas.json');
      final comunasData = json.decode(comunasResponse) as List;

      // Cargar coordenadas
      final String coordenadasResponse = await rootBundle.loadString('assets/data/comunas_latlng.json');
      final coordenadasData = json.decode(coordenadasResponse) as List;

      // Crear mapa de coordenadas para búsqueda rápida
      Map<String, Map<String, double>> coordenadasMap = {};
      for (var coord in coordenadasData) {
        coordenadasMap[coord['nombre']] = {
          'lat': coord['lat'].toDouble(),
          'lng': coord['lng'].toDouble(),
        };
      }

      // Procesar regiones únicas
      Set<String> regionesUnicas = {};
      List<Map<String, dynamic>> comunasConCoordenadas = [];

      for (var comuna in comunasData) {
        regionesUnicas.add(comuna['region']);
        
        // Agregar coordenadas si están disponibles
        Map<String, double>? coordenadas = coordenadasMap[comuna['nombre']];
        
        comunasConCoordenadas.add({
          'nombre': comuna['nombre'],
          'region': comuna['region'],
          'lat': coordenadas?['lat'],
          'lng': coordenadas?['lng'],
        });
      }

      setState(() {
        _regiones = regionesUnicas.map((region) => {'nombre': region}).toList();
        _regiones.sort((a, b) => a['nombre'].compareTo(b['nombre']));
        _coordenadasComunas = comunasConCoordenadas;
      });
    } catch (e) {
      print('Error al cargar datos geográficos: $e');
    }
  }

  List<Map<String, dynamic>> _obtenerComunasPorRegion() {
    if (_regionSeleccionada == null) return [];
    
    return _coordenadasComunas
        .where((comuna) => comuna['region'] == _regionSeleccionada)
        .toList();
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

  Future<void> _crearPropuesta() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_comunaSeleccionada == null || _latitudSeleccionada == null || _longitudSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe seleccionar una comuna válida.')),
      );
      return;
    }

    // Solo requerir documento para nuevas propuestas
    if (widget.propuestaId == null && _documentoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe subir el documento de vigencia de la empresa.')),
      );
      return;
    }

    try {
      final propuestaData = {
        'idEmpleador': user.uid,
        'titulo': _tituloController.text.trim(),
        'descripcion': _descripcionController.text.trim(),
        'carrera': _carreraController.text.trim(),
        'region': _regionSeleccionada ?? '',
        'comuna': _comunaSeleccionada ?? '',
        'certificacion': _certificacionController.text.trim(),
        'experiencia': int.tryParse(_experienciaController.text.trim()) ?? 0,
        'latitud': _latitudSeleccionada ?? 0.0,
        'longitud': _longitudSeleccionada ?? 0.0,
        'estado': 'activo',
      };

      if (widget.propuestaId != null) {
        // Editar propuesta existente
        await FirebaseFirestore.instance
            .collection('propuestas')
            .doc(widget.propuestaId)
            .update(propuestaData);

        // Si hay un nuevo documento seleccionado, subirlo y actualizar la URL
        if (_documentoSeleccionado != null) {
          final documentoUrl = await _subirDocumento(widget.propuestaId!);
          if (documentoUrl != null) {
            await FirebaseFirestore.instance
                .collection('propuestas')
                .doc(widget.propuestaId)
                .update({'documentoValidacionUrl': documentoUrl});
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_documentoSeleccionado != null 
                ? 'Propuesta y documento actualizados exitosamente'
                : 'Propuesta actualizada exitosamente'),
            backgroundColor: AppThemes.empleadorPrimary,
          ),
        );
      } else {
        // Crear nueva propuesta
        propuestaData['fechaCreacion'] = DateTime.now();
        propuestaData['estadoValidacion'] = 'pendiente';
        propuestaData['documentoValidacionUrl'] = '';

        final docRef = await FirebaseFirestore.instance.collection('propuestas').add(propuestaData);

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

        // Reset
        _formKey.currentState!.reset();
        setState(() {
          _regionSeleccionada = null;
          _comunaSeleccionada = null;
          _latitudSeleccionada = null;
          _longitudSeleccionada = null;
          _documentoSeleccionado = null;
        });
      }

      // Si estamos editando, volver atrás
      if (widget.propuestaId != null) {
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error al crear/actualizar propuesta: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al ${widget.propuestaId != null ? "actualizar" : "publicar"} propuesta.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.propuestaId != null;
    
    return Theme(
      data: AppThemes.empleadorTheme,
      child: Scaffold(
        backgroundColor: AppThemes.empleadorBackground,
        appBar: AppBar(
          title: Text(isEditing ? 'Editar propuesta' : 'Publicar propuesta'),
          backgroundColor: AppThemes.empleadorPrimary,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                // Título del cargo
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Información del cargo',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppThemes.empleadorPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _tituloController,
                          decoration: InputDecoration(
                            labelText: 'Título del cargo',
                            labelStyle: TextStyle(color: AppThemes.empleadorPrimary),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppThemes.empleadorPrimary, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: Icon(Icons.work, color: AppThemes.empleadorPrimary),
                          ),
                          validator: (value) => value!.isEmpty ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descripcionController,
                          decoration: InputDecoration(
                            labelText: 'Descripción del trabajo',
                            labelStyle: TextStyle(color: AppThemes.empleadorPrimary),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppThemes.empleadorPrimary, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: Icon(Icons.description, color: AppThemes.empleadorPrimary),
                          ),
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Requisitos
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Requisitos',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppThemes.empleadorPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _carreraController,
                          decoration: InputDecoration(
                            labelText: 'Carrera requerida',
                            labelStyle: TextStyle(color: AppThemes.empleadorPrimary),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppThemes.empleadorPrimary, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: Icon(Icons.school, color: AppThemes.empleadorPrimary),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _certificacionController,
                          decoration: InputDecoration(
                            labelText: 'Certificación requerida',
                            labelStyle: TextStyle(color: AppThemes.empleadorPrimary),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppThemes.empleadorPrimary, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: Icon(Icons.verified, color: AppThemes.empleadorPrimary),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _experienciaController,
                          decoration: InputDecoration(
                            labelText: 'Años de experiencia mínima',
                            labelStyle: TextStyle(color: AppThemes.empleadorPrimary),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppThemes.empleadorPrimary, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: Icon(Icons.timeline, color: AppThemes.empleadorPrimary),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Ubicación
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ubicación',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppThemes.empleadorPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Selector de Región
                        SizedBox(
                          width: double.infinity,
                          child: DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: 'Región',
                              labelStyle: TextStyle(color: AppThemes.empleadorPrimary),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppThemes.empleadorPrimary, width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              prefixIcon: Icon(Icons.map, color: AppThemes.empleadorPrimary),
                            ),
                            value: _regionSeleccionada,
                            isExpanded: true, // Esto previene el overflow
                            items: _regiones.map((region) {
                              return DropdownMenuItem<String>(
                                value: region['nombre'],
                                child: Text(
                                  region['nombre'],
                                  style: TextStyle(fontSize: 14),
                                  overflow: TextOverflow.ellipsis, // Maneja texto largo
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _regionSeleccionada = value;
                                _comunaSeleccionada = null; // Reset comuna selection
                                _latitudSeleccionada = null;
                                _longitudSeleccionada = null;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor selecciona una región';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Selector de Comuna
                        SizedBox(
                          width: double.infinity,
                          child: DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: 'Comuna',
                              labelStyle: TextStyle(color: AppThemes.empleadorPrimary),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppThemes.empleadorPrimary, width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              prefixIcon: Icon(Icons.location_on, color: AppThemes.empleadorPrimary),
                            ),
                            value: _comunaSeleccionada,
                            isExpanded: true, // Esto previene el overflow
                            items: _obtenerComunasPorRegion().map((comuna) {
                              return DropdownMenuItem<String>(
                                value: comuna['nombre'],
                                child: Text(
                                  comuna['nombre'],
                                  style: TextStyle(fontSize: 14),
                                  overflow: TextOverflow.ellipsis, // Maneja texto largo
                                ),
                              );
                            }).toList(),
                            onChanged: _regionSeleccionada == null ? null : (value) {
                              setState(() {
                                _comunaSeleccionada = value;
                                if (value != null) {
                                  final comunaData = _coordenadasComunas.firstWhere((c) => c['nombre'] == value);
                                  _latitudSeleccionada = comunaData['lat'];
                                  _longitudSeleccionada = comunaData['lng'];
                                }
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor selecciona una comuna';
                              }
                              return null;
                            },
                          ),
                        ),
                        
                        // Mostrar coordenadas seleccionadas (solo para debug)
                        if (_latitudSeleccionada != null && _longitudSeleccionada != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Ubicación seleccionada: $_comunaSeleccionada, $_regionSeleccionada',
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontSize: 12,
                                    ),
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
                const SizedBox(height: 16),
                
                // Documento de validación (para nuevas propuestas y edición)
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Documentación',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppThemes.empleadorPrimary,
                              ),
                            ),
                            if (isEditing) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppThemes.empleadorSecondary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppThemes.empleadorSecondary),
                                ),
                                child: Text(
                                  'Opcional',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppThemes.empleadorSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // Mostrar documento existente si estamos editando
                        if (isEditing && _documentoExistenteUrl != null && _documentoExistenteUrl!.isNotEmpty) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.description, color: Colors.blue.shade600, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Documento actual',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blue.shade800,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Ya tienes un documento de validación subido.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    try {
                                      final uri = Uri.parse(_documentoExistenteUrl!);
                                      // En web, esto abrirá el documento en una nueva pestaña
                                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('No se pudo abrir el documento: $e')),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.open_in_new, size: 16),
                                  label: const Text('Ver documento actual'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade600,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    textStyle: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        
                        // Texto explicativo
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppThemes.empleadorPrimary.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppThemes.empleadorPrimary.withOpacity(0.2)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isEditing ? Icons.info_outline : Icons.security,
                                color: AppThemes.empleadorPrimary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  isEditing 
                                      ? 'Puedes cambiar el documento de validación subiendo uno nuevo (opcional).'
                                      : 'Debes subir un documento que demuestre la vigencia de tu empresa (ej: certificado de empresas vigentes, estados financieros, etc.).',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppThemes.empleadorPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Botón para seleccionar documento
                        Container(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _seleccionarDocumento,
                            icon: Icon(
                              isEditing ? Icons.refresh : Icons.attach_file, 
                              color: AppThemes.empleadorPrimary
                            ),
                            label: Text(
                              isEditing 
                                  ? 'Cambiar documento de validación'
                                  : 'Subir documento de vigencia',
                              style: TextStyle(color: AppThemes.empleadorPrimary),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppThemes.empleadorPrimary, width: 2),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        
                        // Mostrar archivo seleccionado
                        if (_documentoSeleccionado != null)
                          Container(
                            margin: const EdgeInsets.only(top: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppThemes.empleadorSecondary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppThemes.empleadorSecondary),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, color: AppThemes.empleadorSecondary),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isEditing ? 'Nuevo archivo seleccionado' : 'Archivo seleccionado',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppThemes.empleadorPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _documentoSeleccionado!.name,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: AppThemes.empleadorSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _documentoSeleccionado = null;
                                    });
                                  },
                                  icon: Icon(Icons.close, color: Colors.red.shade400),
                                  tooltip: 'Quitar archivo',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                
                // Botón de acción
                Container(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _crearPropuesta,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppThemes.empleadorPrimary,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      shadowColor: AppThemes.empleadorPrimary.withOpacity(0.4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isEditing ? Icons.update : Icons.publish,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          isEditing ? 'Actualizar propuesta' : 'Publicar propuesta',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
