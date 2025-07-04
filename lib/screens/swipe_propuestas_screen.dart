import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:swipable_stack/swipable_stack.dart';
import 'package:tindevs_app/screens/detalle_propuesta_screen.dart';

class SwipePropuestasScreen extends StatefulWidget {
  const SwipePropuestasScreen({super.key});

  @override
  _SwipePropuestasScreenState createState() => _SwipePropuestasScreenState();
}

class _SwipePropuestasScreenState extends State<SwipePropuestasScreen> {
  double? _latitud;
  double? _longitud;

  List<Map<String, dynamic>> _propuestas = [];
  bool _cargando = true; // Nuevo

  @override
  void initState() {
    super.initState();
    _detectarUbicacionYcargarPropuestas();
  }

  Future<void> _detectarUbicacionYcargarPropuestas() async {
    try {
      Position pos = await Geolocator.getCurrentPosition();
      setState(() {
        _latitud = pos.latitude;
        _longitud = pos.longitude;
      });

      print('Ubicación del postulante: $_latitud, $_longitud');

      await cargarPropuestas();
    } catch (e) {
      print('Error al obtener ubicación: $e');
    }
  }

  Future<void> cargarPropuestas() async {
    setState(() {
      _cargando = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Obtener likes
    final likesSnapshot =
        await FirebaseFirestore.instance
            .collection('likes')
            .where('postulanteId', isEqualTo: user.uid)
            .get();
    final likedPropuestaIds =
        likesSnapshot.docs.map((doc) => doc['propuestaId'] as String).toSet();

    // Obtener dislikes
    final dislikesSnapshot =
        await FirebaseFirestore.instance
            .collection('dislikes')
            .where('postulanteId', isEqualTo: user.uid)
            .get();
    final dislikedPropuestaIds =
        dislikesSnapshot.docs
            .map((doc) => doc['propuestaId'] as String)
            .toSet();

    // Obtener propuestas aprobadas
    final snapshot =
        await FirebaseFirestore.instance
            .collection('propuestas')
            .where('estadoValidacion', isEqualTo: 'aprobada')
            .get();

    List<Map<String, dynamic>> propuestas =
        snapshot.docs
            .map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            })
            .where(
              (propuesta) =>
                  propuesta.containsKey('latitud') &&
                  propuesta.containsKey('longitud') &&
                  !likedPropuestaIds.contains(propuesta['id']) &&
                  !dislikedPropuestaIds.contains(propuesta['id']),
            )
            .toList();

    if (_latitud != null && _longitud != null) {
      propuestas.sort((a, b) {
        final distanciaA = calcularDistancia(
          _latitud!,
          _longitud!,
          double.parse(a['latitud'].toString()),
          double.parse(a['longitud'].toString()),
        );
        final distanciaB = calcularDistancia(
          _latitud!,
          _longitud!,
          double.parse(b['latitud'].toString()),
          double.parse(b['longitud'].toString()),
        );
        return distanciaA.compareTo(distanciaB);
      });
    }

    setState(() {
      _propuestas = propuestas;
      _cargando = false;
    });

    print('Propuestas cargadas: ${_propuestas.length}');
  }

  double calcularDistancia(double lat1, double lon1, double lat2, double lon2) {
    const double p = 0.017453292519943295;
    const double c = 6371;
    final a =
        0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return c * 2 * asin(sqrt(a));
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_propuestas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No hay más propuestas disponibles por ahora.'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                // Eliminar dislikes para este usuario
                final dislikesSnapshot =
                    await FirebaseFirestore.instance
                        .collection('dislikes')
                        .where('postulanteId', isEqualTo: user!.uid)
                        .get();

                for (var doc in dislikesSnapshot.docs) {
                  await doc.reference.delete();
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Dislikes reiniciados. Nuevas propuestas aparecerán.',
                    ),
                  ),
                );

                await cargarPropuestas();
              },
              child: const Text('Volver a mostrar propuestas rechazadas'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        const SizedBox(height: 16),
        const Text(
          'Propuestas cercanas',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: SwipableStack(
            itemCount: _propuestas.length,
            builder: (context, properties) {
              final propuesta = _propuestas[properties.index];

              final lat = double.parse(propuesta['latitud'].toString());
              final lon = double.parse(propuesta['longitud'].toString());

              final distancia = calcularDistancia(
                _latitud!,
                _longitud!,
                lat,
                lon,
              );

              return Align(
                alignment: Alignment.center, // Centra la card
                child: SizedBox(
                  width: 350, // <<< ancho fijo (ajustable, ej: 350 px)
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder:
                              (_) =>
                                  DetallePropuestaScreen(propuesta: propuesta),
                        ),
                      );
                    },
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 6,
                      child: Container(
                        height: 420, // <<< altura fija
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              propuesta['titulo'] ?? 'Sin título',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              propuesta['descripcion'] ?? 'Sin descripción',
                              style: const TextStyle(fontSize: 16),
                              maxLines: 5,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Distancia: ${distancia.toStringAsFixed(1)} km',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
            onSwipeCompleted: (index, direction) async {
              final propuesta = _propuestas[index];
              final user = FirebaseAuth.instance.currentUser;

              if (user == null) return;

              if (direction == SwipeDirection.up) {
                // Like
                try {
                  await FirebaseFirestore.instance.collection('likes').add({
                    'postulanteId': user.uid,
                    'propuestaId': propuesta['id'],
                    'empleadorId': propuesta['empleadorId'],
                    'timestamp': FieldValue.serverTimestamp(),
                  });
                  print('Like guardado en Firestore');
                } catch (e) {
                  print('Error al guardar like: $e');
                }
              } else if (direction == SwipeDirection.down) {
                // Dislike
                try {
                  await FirebaseFirestore.instance.collection('dislikes').add({
                    'postulanteId': user.uid,
                    'propuestaId': propuesta['id'],
                    'timestamp': FieldValue.serverTimestamp(),
                  });
                  print('Dislike guardado en Firestore');
                } catch (e) {
                  print('Error al guardar dislike: $e');
                }
              }

              print(
                'Swipe ${direction.name} on propuesta: ${propuesta['titulo']}',
              );
            },
            onWillMoveNext: (index, direction) {
              return direction == SwipeDirection.up ||
                  direction == SwipeDirection.down;
            },
          ),
        ),
      ],
    );
  }
}
