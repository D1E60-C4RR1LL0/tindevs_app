import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

class CrearPropuestaScreen extends StatefulWidget {
  const CrearPropuestaScreen({super.key});

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

  // NUEVO: documento seleccionado
  XFile? _documentoSeleccionado;

  @override
  void initState() {
    super.initState();
    _cargarCoordenadasComunas();
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

    if (_documentoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe subir el documento de vigencia de la empresa.')),
      );
      return;
    }

    try {
      // Crear propuesta
      final docRef = await FirebaseFirestore.instance.collection('propuestas').add({
        'empleadorId': user.uid,
        'titulo': _tituloController.text.trim(),
        'descripcion': _descripcionController.text.trim(),
        'carreraRequerida': _carreraController.text.trim(),
        'comuna': _comunaSeleccionada ?? '',
        'certificacionRequerida': _certificacionController.text.trim(),
        'experienciaMinima': int.tryParse(_experienciaController.text.trim()) ?? 0,
        'fechaPublicacion': DateTime.now(),
        'latitud': _latitudSeleccionada ?? 0.0,
        'longitud': _longitudSeleccionada ?? 0.0,
        'estadoValidacion': 'pendiente',
        'documentoValidacionUrl': '',
      });

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
        _comunaSeleccionada = null;
        _latitudSeleccionada = null;
        _longitudSeleccionada = null;
        _documentoSeleccionado = null;
      });
    } catch (e) {
      print('Error al crear propuesta: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al publicar propuesta.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Publicar propuesta')),
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
              // Botón seleccionar documento
              ElevatedButton.icon(
                onPressed: _seleccionarDocumento,
                icon: const Icon(Icons.attach_file),
                label: const Text('Subir documento de vigencia'),
              ),
              if (_documentoSeleccionado != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Archivo seleccionado: ${_documentoSeleccionado!.name}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _crearPropuesta,
                child: const Text('Publicar propuesta'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
