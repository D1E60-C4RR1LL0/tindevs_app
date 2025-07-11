import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_typeahead/flutter_typeahead.dart';
import '../../utils/themes/app_themes.dart';

import 'package:file_selector/file_selector.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class PerfilPostulanteScreen extends StatefulWidget {
  const PerfilPostulanteScreen({super.key});

  @override
  PerfilPostulanteScreenState createState() => PerfilPostulanteScreenState();
}

Future<String?> subirDocumentoCertificacion(
  String userId,
  String certNombre,
) async {
  final XFile? file = await openFile(
    acceptedTypeGroups: [
      XTypeGroup(label: 'Documents', extensions: ['pdf', 'jpg', 'jpeg', 'png']),
    ],
  );

  if (file != null) {
    final filePath = file.path;
    final fileName = file.name;

    final storageRef = FirebaseStorage.instance.ref().child(
      'certificaciones/$userId/$certNombre/$fileName',
    );

    final uploadTask = await storageRef.putFile(File(filePath));

    final downloadUrl = await uploadTask.ref.getDownloadURL();
    return downloadUrl;
  } else {
    return null;
  }
}

class PerfilPostulanteScreenState extends State<PerfilPostulanteScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _carreraController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _certificacionBusquedaController =
      TextEditingController();

  double? _latitud;
  double? _longitud;

  List<String> _regiones = [];
  Map<String, List<String>> _comunasPorRegion = {};

  String? _regionSeleccionada;
  String? _comunaSeleccionada;

  List<Map<String, dynamic>> _certificacionesSeleccionadas = [];
  List<String> _todasCertificaciones = [];

  @override
  void initState() {
    super.initState();
    cargarRegionesYComunas();
    cargarCertificaciones();
    solicitarUbicacionAlEntrar();
    cargarPerfilPostulante();
  }

  @override
  void dispose() {
    _carreraController.dispose();
    _descripcionController.dispose();
    _certificacionBusquedaController.dispose();
    super.dispose();
  }

  Future<void> cargarRegionesYComunas() async {
    try {
      final String response = await rootBundle.loadString(
        'assets/data/comunas.json',
      );
      final data = json.decode(response) as List;

      final Set<String> regionesSet = {};
      final Map<String, List<String>> comunasMap = {};

      for (var comuna in data) {
        final region = comuna['region'] as String;
        final nombreComuna = comuna['nombre'] as String;

        regionesSet.add(region);

        if (!comunasMap.containsKey(region)) {
          comunasMap[region] = [];
        }

        comunasMap[region]!.add(nombreComuna);
      }

      setState(() {
        _regiones = regionesSet.toList()..sort();
        _comunasPorRegion = comunasMap;
      });
    } catch (e) {
      print('Error al cargar comunas desde asset: $e');
    }
  }

  Future<void> cargarCertificaciones() async {
    try {
      final String response = await rootBundle.loadString(
        'assets/data/certificaciones.json',
      );
      final List<dynamic> data = json.decode(response);

      setState(() {
        _todasCertificaciones = data.cast<String>();
      });
    } catch (e) {
      print('Error al cargar certificaciones desde asset: $e');
    }
  }

  Future<void> cargarPerfilPostulante() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(user.uid)
              .get();

      if (doc.exists) {
        final data = doc.data() ?? {};

        setState(() {
          _carreraController.text = data['carrera'] ?? '';
          _descripcionController.text = data['descripcion'] ?? '';
          _regionSeleccionada = data['region'];
          _comunaSeleccionada = data['comuna'];
          _certificacionesSeleccionadas = List<Map<String, dynamic>>.from(
            (data['certificaciones'] ?? []).map(
              (c) => Map<String, dynamic>.from(c),
            ),
          );
          _latitud = data['latitud'];
          _longitud = data['longitud'];
        });
        
        // Actualizar coordenadas basadas en la comuna si no las tenemos o son inválidas
        if (_comunaSeleccionada != null && (_latitud == null || _longitud == null)) {
          _actualizarCoordenadasDeComuna();
        }
      }
    } catch (e) {
      print('Error al cargar perfil: $e');
    }
  }

  Future<void> solicitarUbicacionAlEntrar() async {
    // Ya no necesitamos solicitar ubicación GPS
    // Las coordenadas se actualizarán cuando se seleccione una comuna
    print('Sistema configurado para usar coordenadas basadas en comuna seleccionada');
  }

  Future<void> _guardarPerfil() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .update({
            'carrera': _carreraController.text.trim(),
            'descripcion': _descripcionController.text.trim(),
            'region': _regionSeleccionada,
            'comuna': _comunaSeleccionada,
            'certificaciones': _certificacionesSeleccionadas,
            'latitud': _latitud,
            'longitud': _longitud,
          });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil guardado con éxito')),
      );
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al guardar el perfil')),
      );
    }
  }

  Future<Map<String, double>?> _obtenerCoordenadasComuna(String nombreComuna) async {
    try {
      final String response = await rootBundle.loadString(
        'assets/data/comunas_latlng.json',
      );
      final List<dynamic> comunas = json.decode(response);
      
      for (var comuna in comunas) {
        if (comuna['nombre'] == nombreComuna) {
          return {
            'lat': comuna['lat'].toDouble(),
            'lng': comuna['lng'].toDouble(),
          };
        }
      }
      return null;
    } catch (e) {
      print('Error al obtener coordenadas de comuna: $e');
      return null;
    }
  }
  
  Future<void> _actualizarCoordenadasDeComuna() async {
    if (_comunaSeleccionada != null) {
      final coordenadas = await _obtenerCoordenadasComuna(_comunaSeleccionada!);
      if (coordenadas != null) {
        setState(() {
          _latitud = coordenadas['lat'];
          _longitud = coordenadas['lng'];
        });
        print('Coordenadas actualizadas para $_comunaSeleccionada: $_latitud, $_longitud');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemes.postulanteBackground,
      appBar: AppBar(
        title: const Text('Perfil Postulante'),
        backgroundColor: AppThemes.postulantePrimary,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _carreraController,
                decoration: const InputDecoration(labelText: 'Carrera'),
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Ingrese su carrera'
                            : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción personal',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Región'),
                value: _regionSeleccionada,
                items:
                    _regiones.map((region) {
                      return DropdownMenuItem<String>(
                        value: region,
                        child: Text(region),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    _regionSeleccionada = value;
                    _comunaSeleccionada = null;
                  });
                },
              ),
              const SizedBox(height: 12),
              if (_regionSeleccionada != null)
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Comuna'),
                  value: _comunaSeleccionada,
                  items:
                      _comunasPorRegion[_regionSeleccionada]!.map((comuna) {
                        return DropdownMenuItem<String>(
                          value: comuna,
                          child: Text(comuna),
                        );
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _comunaSeleccionada = value;
                    });
                    // Actualizar coordenadas basadas en la comuna seleccionada
                    if (value != null) {
                      _actualizarCoordenadasDeComuna();
                    }
                  },
                ),
              const SizedBox(height: 12),
              TypeAheadField<String>(
                controller: _certificacionBusquedaController,
                suggestionsCallback: (pattern) {
                  return _todasCertificaciones
                      .where(
                        (cert) =>
                            cert.toLowerCase().contains(
                              pattern.toLowerCase(),
                            ) &&
                            !_certificacionesSeleccionadas.any(
                              (c) => c['nombre'] == cert,
                            ),
                      )
                      .take(10)
                      .toList();
                },
                itemBuilder: (context, cert) {
                  return ListTile(title: Text(cert));
                },
                onSelected: (cert) {
                  setState(() {
                    _certificacionesSeleccionadas.add({
                      'nombre': cert,
                      'estado': 'pendiente',
                      'documentoUrl': '',
                    });
                  });
                },
                builder: (context, textController, focusNode) {
                  return TextField(
                    controller: textController,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: 'Buscar certificación',
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children:
                    _certificacionesSeleccionadas.map((cert) {
                      return InputChip(
                        label: Text(cert['nombre']),
                        onDeleted: () {
                          setState(() {
                            _certificacionesSeleccionadas.remove(cert);
                          });
                        },
                      );
                    }).toList(),
              ),

              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _certificacionesSeleccionadas.length,
                itemBuilder: (context, index) {
                  final cert = _certificacionesSeleccionadas[index];
                  return ListTile(
                    title: Text(cert['nombre']),
                    subtitle: Text('Estado: ${cert['estado']}'),
                    trailing: ElevatedButton(
                      child: Text(
                        cert['documentoUrl'] == ''
                            ? 'Subir documento'
                            : 'Ver documento',
                      ),
                      onPressed: () async {
                        final documentoUrl = await subirDocumentoCertificacion(
                          FirebaseAuth.instance.currentUser!.uid,
                          cert['nombre'],
                        );

                        if (documentoUrl != null) {
                          setState(() {
                            _certificacionesSeleccionadas[index]['documentoUrl'] =
                                documentoUrl;
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Documento subido exitosamente'),
                            ),
                          );
                        }
                      },
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _guardarPerfil,
                child: const Text('Guardar perfil'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, // rojo para el logout
                ),
                onPressed: () async {
                  try {
                    await FirebaseAuth.instance.signOut();
                    Navigator.pushNamedAndRemoveUntil(context, '/welcome', (route) => false);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al cerrar sesión: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('Cerrar sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
