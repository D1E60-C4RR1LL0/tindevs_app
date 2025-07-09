import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

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
    _cargarCoordenadasComunas();
    if (widget.datosExistentes != null) {
      _cargarDatosExistentes();
    }
  }
  
  void _cargarDatosExistentes() {
    final datos = widget.datosExistentes!;
    _tituloController.text = datos['titulo'] ?? '';
    _descripcionController.text = datos['descripcion'] ?? '';
    _carreraController.text = datos['carrera'] ?? '';
    _certificacionController.text = datos['certificacion'] ?? '';
    _experienciaController.text = datos['experiencia']?.toString() ?? '';
    _comunaSeleccionada = datos['comuna'];
    
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

  Future<void> _cargarCoordenadasComunas() async {
    try {
      final String response = await rootBundle.loadString('assets/data/comunas_latlng.json');
      final data = json.decode(response) as List;

      setState(() {
        _coordenadasComunas = data.map((item) => {
          'nombre': item['nombre'],
          'lat': item['lat'],
          'lng': item['lng'],
        }).toList();
      });
    } catch (e) {
      print('Error al cargar comunas_latlng.json: $e');
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
      final datosActualizados = {
        'titulo': _tituloController.text.trim(),
        'descripcion': _descripcionController.text.trim(),
        'carreraRequerida': _carreraController.text.trim(),
        'comuna': _comunaSeleccionada ?? '',
        'certificacionRequerida': _certificacionController.text.trim(),
        'experienciaMinima': int.tryParse(_experienciaController.text.trim()) ?? 0,
        'latitud': _latitudSeleccionada ?? 0.0,
        'longitud': _longitudSeleccionada ?? 0.0,
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
          'fechaPublicacion': DateTime.now(),
          'estadoValidacion': 'pendiente',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.propuestaId != null ? 'Editar propuesta' : 'Publicar propuesta'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _tituloController,
                decoration: const InputDecoration(labelText: 'Título del cargo'),
                validator: (value) => value!.isEmpty ? 'Requerido' : null,
              ),
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(labelText: 'Descripción del trabajo'),
                maxLines: 3,
              ),
              TextFormField(
                controller: _carreraController,
                decoration: const InputDecoration(labelText: 'Carrera requerida'),
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Comuna'),
                value: _comunaSeleccionada,
                items: _coordenadasComunas.map((comuna) {
                  return DropdownMenuItem<String>(
                    value: comuna['nombre'],
                    child: Text(comuna['nombre']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _comunaSeleccionada = value;
                    final comunaData = _coordenadasComunas.firstWhere((c) => c['nombre'] == value);
                    _latitudSeleccionada = comunaData['lat'];
                    _longitudSeleccionada = comunaData['lng'];
                  });
                },
              ),
              TextFormField(
                controller: _certificacionController,
                decoration: const InputDecoration(labelText: 'Certificación requerida'),
              ),
              TextFormField(
                controller: _experienciaController,
                decoration: const InputDecoration(labelText: 'Años de experiencia mínima'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              
              // Sección de documento
              const Text(
                'Documento de vigencia de la empresa',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              
              // Mostrar documento existente si estamos editando
              if (widget.propuestaId != null && _documentoExistenteUrl != null && _documentoExistenteUrl!.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Documento actual:',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.description, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Documento de validación subido',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              // Aquí podrías abrir el documento si fuera necesario
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
                ),
                const SizedBox(height: 8),
                const Text(
                  'Para reemplazar el documento actual, selecciona uno nuevo:',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 8),
              ],
              
              // Botón para seleccionar documento
              ElevatedButton.icon(
                onPressed: _seleccionarDocumento,
                icon: const Icon(Icons.attach_file),
                label: Text(
                  widget.propuestaId != null 
                    ? 'Seleccionar nuevo documento' 
                    : 'Subir documento de vigencia'
                ),
              ),
              
              // Mostrar archivo seleccionado
              if (_documentoSeleccionado != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      border: Border.all(color: Colors.green),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Nuevo archivo: ${_documentoSeleccionado!.name}',
                            style: const TextStyle(fontSize: 14, color: Colors.green),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _guardarPropuesta,
                child: Text(widget.propuestaId != null ? 'Actualizar propuesta' : 'Publicar propuesta'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
