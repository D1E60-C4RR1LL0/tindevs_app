import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swipable_stack/swipable_stack.dart';
import 'detalle_propuesta_screen.dart';
import '../../utils/themes/app_themes.dart';

class SwipePropuestasScreen extends StatefulWidget {
  const SwipePropuestasScreen({super.key});

  @override
  SwipePropuestasScreenState createState() => SwipePropuestasScreenState();
}

class SwipePropuestasScreenState extends State<SwipePropuestasScreen> {
  double? _latitud;
  double? _longitud;

  List<Map<String, dynamic>> _propuestas = [];
  bool _cargando = true;
  // Agregar un temporizador para evitar bloqueos infinitos en la carga
  Timer? _timeoutTimer;
  
  // Cache para coordenadas de comunas
  Map<String, Map<String, double>>? _coordenadasComunas;
  
  // Controlador para los swipes programáticos
  final SwipableStackController _swipeController = SwipableStackController();

  @override
  void initState() {
    super.initState();
    _cargarCoordenadasYPropuestas();
  }

  Future<void> _cargarCoordenadasYPropuestas() async {
    await _cargarCoordenadasComunas();
    await _obtenerCoordenadasDelPerfil();
    await cargarPropuestas();
  }

  Future<void> _cargarCoordenadasComunas() async {
    try {
      print('📥 Cargando coordenadas de comunas...');
      final String data = await rootBundle.loadString('assets/data/comunas_latlng.json');
      final List<dynamic> comunas = json.decode(data);
      
      _coordenadasComunas = {};
      for (var comuna in comunas) {
        _coordenadasComunas![comuna['nombre']] = {
          'lat': comuna['lat'].toDouble(),
          'lng': comuna['lng'].toDouble(),
        };
      }
      print('✅ Coordenadas de ${_coordenadasComunas!.length} comunas cargadas exitosamente');
    } catch (e) {
      print('❌ Error al cargar coordenadas de comunas: $e');
    }
  }

  Future<void> _obtenerCoordenadasDelPerfil() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ Usuario no autenticado');
        return;
      }

      print('🔍 Buscando perfil para usuario: ${user.uid}');
      final perfilDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();

      if (perfilDoc.exists) {
        final perfilData = perfilDoc.data()!;
        print('✅ Perfil encontrado: $perfilData');
        final comuna = perfilData['comuna'];
        
        if (comuna != null && _coordenadasComunas != null) {
          print('🌍 Buscando coordenadas para comuna: "$comuna"');
          
          // Búsqueda exacta primero
          var coordenadas = _coordenadasComunas![comuna];
          
          // Si no encuentra, buscar de forma más flexible (sin mayúsculas/minúsculas)
          if (coordenadas == null) {
            print('❓ Búsqueda exacta falló, intentando búsqueda flexible...');
            final comunaLower = comuna.toLowerCase().trim();
            
            for (var entry in _coordenadasComunas!.entries) {
              if (entry.key.toLowerCase().trim() == comunaLower) {
                coordenadas = entry.value;
                print('✅ Coincidencia encontrada: "${entry.key}" -> "$comuna"');
                break;
              }
            }
          }
          
          if (coordenadas != null) {
            setState(() {
              _latitud = coordenadas!['lat'];
              _longitud = coordenadas['lng'];
            });
            print('✅ Coordenadas obtenidas de la comuna $comuna: $_latitud, $_longitud');
          } else {
            print('❌ No se encontraron coordenadas para la comuna: "$comuna"');
            print('📍 Comunas disponibles (primeras 10): ${_coordenadasComunas!.keys.take(10).toList()}');
            print('📍 Total de comunas cargadas: ${_coordenadasComunas!.length}');
          }
        } else {
          if (comuna == null) {
            print('❌ El usuario no tiene comuna seleccionada en su perfil');
          }
          if (_coordenadasComunas == null) {
            print('❌ No se han cargado las coordenadas de comunas');
          }
        }
      } else {
        print('❌ No se encontró perfil para el usuario');
      }
    } catch (e) {
      print('❌ Error al obtener coordenadas del perfil: $e');
    }
  }

  Future<void> cargarPropuestas() async {
    if (mounted) {
      setState(() {
        _cargando = true;
      });
      
      // Configurar un temporizador de seguridad para evitar quedarse en estado de carga
      _timeoutTimer?.cancel(); // Cancelar timer anterior si existe
      _timeoutTimer = Timer(const Duration(seconds: 10), () {
        if (mounted && _cargando) {
          print('⚠️ Tiempo de espera excedido al cargar propuestas');
          setState(() {
            _cargando = false;
          });
        }
      });
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('❌ Usuario no autenticado para cargar propuestas');
      // Cancelamos el timer y salimos del estado de carga si no hay usuario
      _timeoutTimer?.cancel();
      if (mounted) {
        setState(() {
          _cargando = false;
        });
      }
      return;
    }

    try {
      print('🔍 Cargando propuestas para usuario: ${user.uid}');

      // Obtener likes
      final likesSnapshot =
          await FirebaseFirestore.instance
              .collection('likes')
              .where('postulanteId', isEqualTo: user.uid)
              .get();
      final likedPropuestaIds =
          likesSnapshot.docs.map((doc) => doc['propuestaId'] as String).toSet();
      print('👍 Likes encontrados: ${likedPropuestaIds.length}');

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
      print('👎 Dislikes encontrados: ${dislikedPropuestaIds.length}');

      // Obtener SOLO propuestas activas Y aprobadas por el admin (doble filtro de seguridad)
      final snapshot =
          await FirebaseFirestore.instance
              .collection('propuestas')
              .where('estado', isEqualTo: 'activo')
              .where('estadoValidacion', isEqualTo: 'aprobada')
              .get();
      
      print('📋 Propuestas activas Y aprobadas encontradas: ${snapshot.docs.length}');
      print('🔒 SEGURIDAD: Solo propuestas aprobadas por admin serán mostradas');

      // Primero convertir todos los documentos a Map
      List<Map<String, dynamic>> todasLasPropuestas = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      
      print('🔍 Analizando filtros de propuestas...');
      print('📊 Total de propuestas activas y aprobadas: ${todasLasPropuestas.length}');
      
      // Analizar cada filtro por separado
      final conCoordenadas = todasLasPropuestas.where((p) => 
          p.containsKey('latitud') && p.containsKey('longitud')).toList();
      print('📍 Con coordenadas: ${conCoordenadas.length}');
      
      final sinLikes = conCoordenadas.where((p) => 
          !likedPropuestaIds.contains(p['id'])).toList();
      print('👍 Sin likes del usuario: ${sinLikes.length}');
      
      final sinDislikes = sinLikes.where((p) => 
          !dislikedPropuestaIds.contains(p['id'])).toList();
      print('👎 Sin dislikes del usuario: ${sinDislikes.length}');
      
      // Verificar estadoValidacion
      final estadosValidacion = sinDislikes.map((p) => p['estadoValidacion']).toSet();
      print('📋 Estados de validación encontrados: $estadosValidacion');
      
      // Aplicar filtro de validación CRÍTICO DE SEGURIDAD
      List<Map<String, dynamic>> propuestas = sinDislikes.where((propuesta) {
        final estadoValidacion = propuesta['estadoValidacion'];
        
        // Log del estado de cada propuesta
        print('🔍 Propuesta "${propuesta['titulo']}": estadoValidacion = "$estadoValidacion"');
        
        // ⚠️ CRÍTICO: Solo mostrar propuestas APROBADAS por el administrador
        // Esto previene fraudes y asegura que todas las propuestas sean revisadas
        final esAprobada = estadoValidacion == 'aprobada';
        
        if (!esAprobada) {
          print('🚫 Propuesta "${propuesta['titulo']}" NO mostrada: estado = "$estadoValidacion" (requiere aprobación admin)');
        } else {
          print('✅ Propuesta "${propuesta['titulo']}" APROBADA: será mostrada al postulante');
        }
        
        return esAprobada;
      }).toList();

      print('✅ Propuestas filtradas finales: ${propuestas.length}');
      
      // Debug: mostrar detalles de las primeras propuestas
      if (propuestas.isNotEmpty) {
        print('📍 Ejemplo de propuesta encontrada:');
        final ejemplo = propuestas.first;
        print('  - ID: ${ejemplo['id']}');
        print('  - Título: ${ejemplo['titulo']}');
        print('  - Estado: ${ejemplo['estado']}');
        print('  - Validación: ${ejemplo['estadoValidacion']}');
        print('  - Región: ${ejemplo['region']}');
        print('  - Comuna: ${ejemplo['comuna']}');
        print('  - Latitud: ${ejemplo['latitud']}');
        print('  - Longitud: ${ejemplo['longitud']}');
      } else {
        print('❌ No se encontraron propuestas que cumplan los criterios');
      }
      
      // Verificar coordenadas del usuario
      print('🌍 Coordenadas del usuario: lat=$_latitud, lng=$_longitud');

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

      // Cancelamos el temporizador de seguridad ya que la carga terminó con éxito
      _timeoutTimer?.cancel();
      
      // Asegurarse de actualizar el estado solo una vez con toda la información necesaria
      if (mounted) {
        setState(() {
          _propuestas = propuestas;
          _cargando = false;
        });

        // Log de diagnóstico
        print('Propuestas cargadas: ${_propuestas.length}');
        
        // Forzar un refresco de la interfaz si no hay propuestas
        if (propuestas.isEmpty) {
          print('No hay propuestas disponibles, actualizando UI...');
        }
      } else {
        print('Widget desmontado, no se actualiza el estado');
      }
    } catch (e) {
      // En caso de error, asegurarse de cancelar el timer y actualizar el estado
      print('❌ Error al cargar propuestas: $e');
      _timeoutTimer?.cancel();
      if (mounted) {
        setState(() {
          _cargando = false;
        });
      }
    }
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

    // Verificar si el usuario tiene ubicación configurada
    if (_latitud == null || _longitud == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppThemes.postulanteGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.location_off,
                  size: 64,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Configura tu ubicación',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Para ver oportunidades cerca de ti, configura tu comuna en tu perfil.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  // Navegar al perfil o recargar
                  _cargarCoordenadasYPropuestas();
                },
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text(
                  'Recargar',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppThemes.postulanteAccent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_propuestas.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppThemes.postulanteGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.search_off,
                  size: 64,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '¡Has visto todas las oportunidades!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppThemes.postulantePrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'No hay más propuestas disponibles en tu área por el momento.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              AppThemes.buildGradientContainer(
                isPostulante: true,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    // Variable para asegurar que siempre actualicemos la UI al final
                    bool operacionCompletada = false;

                    try {
                      // Mostrar un indicador de carga para feedback visual inmediato
                      if (mounted) {
                        setState(() {
                          _cargando = true;
                        });
                      }

                      // Temporizador de seguridad específico para esta operación
                      Timer? reinicioTimer = Timer(const Duration(seconds: 8), () {
                        if (mounted && _cargando && !operacionCompletada) {
                          print('⚠️ Tiempo de espera excedido al reiniciar propuestas');
                          setState(() {
                            _cargando = false;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.warning, color: Colors.white, size: 20),
                                  const SizedBox(width: 8),
                                  const Flexible(
                                    child: Text(
                                      'La operación está tardando demasiado. Intente nuevamente.',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: Colors.orange[800],
                              behavior: SnackBarBehavior.floating,
                              width: 280,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              margin: const EdgeInsets.all(16),
                            ),
                          );
                        }
                      });

                      // Eliminar dislikes para este usuario
                      print('🔄 Reiniciando propuestas rechazadas...');
                      final dislikesSnapshot =
                          await FirebaseFirestore.instance
                              .collection('dislikes')
                              .where('postulanteId', isEqualTo: user!.uid)
                              .get();

                      // Eliminar los dislikes en Firestore
                      int eliminados = 0;
                      for (var doc in dislikesSnapshot.docs) {
                        await doc.reference.delete();
                        eliminados++;
                        print('✓ Dislike eliminado: ${doc.id}');
                      }

                      print('🗑️ Total de dislikes eliminados: $eliminados');

                      // Cancela el timer de seguridad
                      reinicioTimer.cancel();
                      operacionCompletada = true;

                      // Mostrar notificación de éxito
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.refresh, color: Colors.white, size: 20),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    '¡Propuestas reiniciadas! ($eliminados)',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: AppThemes.postulanteAccent,
                            behavior: SnackBarBehavior.floating,
                            width: 280, // Ancho fijo para el SnackBar
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            margin: const EdgeInsets.all(16),
                          ),
                        );
                      }

                      // Cargar las propuestas inmediatamente después de eliminar dislikes
                      await cargarPropuestas();

                      // Verificar si se cargaron propuestas
                      if (mounted) {
                        print('✅ Propuestas recargadas: ${_propuestas.length}');
                      }
                    } catch (e) {
                      print('❌ Error al reiniciar propuestas: $e');
                      operacionCompletada = true;
                      // Asegurarnos de que no se quede en estado de carga
                      if (mounted) {
                        setState(() {
                          _cargando = false;
                        });
                        
                        // Mostrar mensaje de error
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                                const SizedBox(width: 8),
                                const Flexible(
                                  child: Text(
                                    'No se pudieron reiniciar las propuestas',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: Colors.red[700],
                            behavior: SnackBarBehavior.floating,
                            width: 280,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            margin: const EdgeInsets.all(16),
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: const Text(
                    'Ver propuestas rechazadas',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Header mejorado para la sección de explorar
        Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(
                Icons.explore,
                color: AppThemes.postulantePrimary,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Descubre oportunidades cerca de ti',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppThemes.postulantePrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SwipableStack(
            controller: _swipeController,
            itemCount: _propuestas.length,
            overlayBuilder: (context, properties) {
              // Detectar dirección y progreso del swipe
              final direction = properties.direction;
              final double progress = properties.swipeProgress;
              
              if (progress == 0.0) {
                return const SizedBox.shrink();
              }
              
              // Solo mostrar overlay para swipes verticales
              final bool isVerticalSwipe = 
                  direction == SwipeDirection.up || direction == SwipeDirection.down;
              
              if (!isVerticalSwipe) {
                return const SizedBox.shrink();
              }
              
              final bool isLike = direction == SwipeDirection.up;
              final double opacity = (progress * 0.8).clamp(0.0, 0.8);
              
              return Container(
                decoration: BoxDecoration(
                  color: (isLike ? AppThemes.postulanteAccent : Colors.red)
                      .withValues(alpha: opacity),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isLike ? Icons.thumb_up : Icons.close,
                          size: 50,
                          color: isLike ? AppThemes.postulanteAccent : Colors.red,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isLike ? '¡ME INTERESA!' : 'DESCARTAR',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isLike ? AppThemes.postulanteAccent : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            builder: (context, properties) {
              final propuesta = _propuestas[properties.index];

              // Calcular distancia solo si tenemos coordenadas válidas
              double? distancia;
              print('🔍 Calculando distancia: userLat=$_latitud, userLng=$_longitud');
              if (_latitud != null && _longitud != null) {
                final lat = double.parse(propuesta['latitud'].toString());
                final lon = double.parse(propuesta['longitud'].toString());

                distancia = calcularDistancia(
                  _latitud!,
                  _longitud!,
                  lat,
                  lon,
                );
                print('📏 Distancia calculada: ${distancia.toStringAsFixed(1)} km');
              } else {
                print('❌ No se puede calcular distancia: coordenadas del usuario son null');
              }

              return Align(
                alignment: Alignment.center,
                child: SizedBox(
                  width: 350,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => DetallePropuestaScreen(propuesta: propuesta),
                        ),
                      );
                    },
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 8,
                      child: Container(
                        height: 420,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white,
                              AppThemes.postulanteBackground.withValues(alpha: 0.3),
                            ],
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Badge de oportunidad
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  gradient: AppThemes.postulanteGradient,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  '💼 OPORTUNIDAD',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Información del empleador y calificación
                              FutureBuilder<Map<String, dynamic>?>(
                                future: _getEmpleadorInfo(propuesta['idEmpleador'] ?? propuesta['empleadorId']),
                                builder: (context, empleadorSnapshot) {
                                  final empleadorData = empleadorSnapshot.data;
                                  final averageRating = empleadorData?['averageRating']?.toDouble();
                                  final totalRatings = empleadorData?['totalRatings'] ?? 0;
                                  
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (averageRating != null && totalRatings > 0) ...[
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: _getRatingBackgroundColor(averageRating),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: _getRatingBorderColor(averageRating),
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.star,
                                                color: _getRatingIconColor(averageRating),
                                                size: 16,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${averageRating.toStringAsFixed(1)}',
                                                style: TextStyle(
                                                  color: _getRatingTextColor(averageRating),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                '($totalRatings ${totalRatings == 1 ? 'evaluación' : 'evaluaciones'})',
                                                style: TextStyle(
                                                  color: _getRatingTextColor(averageRating).withValues(alpha: 0.8),
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                      ] else ...[
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: Colors.grey.shade300),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.help_outline, color: Colors.grey.shade600, size: 16),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Sin evaluaciones aún',
                                                style: TextStyle(
                                                  color: Colors.grey.shade700,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                      ],
                                    ],
                                  );
                                },
                              ),
                              Text(
                                propuesta['titulo'] ?? 'Sin título',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppThemes.postulantePrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: Text(
                                  propuesta['descripcion'] ?? 'Sin descripción',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                    height: 1.4,
                                  ),
                                  maxLines: 8,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Footer con distancia y CTA
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppThemes.postulanteSecondary,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.location_on,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          distancia != null 
                                            ? '${distancia.toStringAsFixed(1)} km'
                                            : 'Sin ubicación',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    'Desliza para decidir',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
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
                  // Guardar like (para lógica de matches)
                  await FirebaseFirestore.instance.collection('likes').add({
                    'postulanteId': user.uid,
                    'propuestaId': propuesta['id'],
                    'idEmpleador': propuesta['idEmpleador'],
                    'timestamp': FieldValue.serverTimestamp(),
                  });
                  
                  // Guardar interés (para vista de "Mis Intereses")
                  await FirebaseFirestore.instance.collection('intereses').add({
                    'postulanteId': user.uid,
                    'propuestaId': propuesta['id'],
                    'empleadorId': propuesta['idEmpleador'],
                    'propuestaTitle': propuesta['titulo'],
                    'empresa': propuesta['empresa'],
                    'fecha': FieldValue.serverTimestamp(),
                    'estado': 'pendiente', // pendiente, aceptado, rechazado
                  });
                  
                  print('Like e interés guardados en Firestore');
                  
                  // Mostrar feedback visual mejorado
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        mainAxisSize: MainAxisSize.min, // Minimiza el tamaño para evitar overflow
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.thumb_up, 
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              '¡Excelente! Has mostrado interés',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: AppThemes.postulanteAccent,
                      duration: const Duration(seconds: 3),
                      behavior: SnackBarBehavior.floating,
                      width: 280, // Ancho fijo para el SnackBar
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.all(16),
                    ),
                  );
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
                  
                  // Mostrar feedback visual mejorado
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        mainAxisSize: MainAxisSize.min, // Minimiza el tamaño para evitar overflow
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.close, 
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              'Propuesta descartada',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.red[600],
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                      width: 280, // Ancho fijo para el SnackBar
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.all(16),
                    ),
                  );
                } catch (e) {
                  print('Error al guardar dislike: $e');
                }
              }

              print(
                'Swipe ${direction.name} on propuesta: ${propuesta['titulo']}',
              );

              // Verificar si se acabaron las propuestas después de este swipe
              if (index == _propuestas.length - 1) {
                print('⚠️ Se acabaron las propuestas disponibles');
                // Usar un pequeño delay para permitir que la animación termine
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted) {
                    setState(() {
                      _propuestas = [];
                    });
                  }
                });
              }
            },
            onWillMoveNext: (index, direction) {
              return direction == SwipeDirection.up ||
                  direction == SwipeDirection.down;
            },
          ),
        ),
        
        // Botones de acción mejorados en la parte inferior
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Botón de Descartar propuesta
              _buildActionButton(
                icon: Icons.close,
                label: 'Descartar',
                color: Colors.red,
                onPressed: () {
                  _swipeController.next(swipeDirection: SwipeDirection.down);
                  
                  // Verificar si era la última propuesta y actualizar la UI
                  if (_propuestas.length == 1) {
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (mounted) {
                        setState(() {
                          _propuestas = [];
                        });
                      }
                    });
                  }
                },
              ),
              
              // Botón de Ver detalles
              _buildActionButton(
                icon: Icons.info_outline,
                label: 'Ver más',
                color: AppThemes.postulanteSecondary,
                onPressed: () {
                  if (_propuestas.isNotEmpty) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DetallePropuestaScreen(propuesta: _propuestas.first),
                      ),
                    );
                  }
                },
              ),
              
              // Botón de Mostrar interés
              _buildActionButton(
                icon: Icons.thumb_up,
                label: 'Me interesa',
                color: AppThemes.postulanteAccent,
                onPressed: () {
                  _swipeController.next(swipeDirection: SwipeDirection.up);
                  
                  // Verificar si era la última propuesta y actualizar la UI
                  if (_propuestas.length == 1) {
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (mounted) {
                        setState(() {
                          _propuestas = [];
                        });
                      }
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: color, width: 2),
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(icon, color: color, size: 28),
            iconSize: 28,
            padding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // Obtener información del empleador incluyendo calificación
  Future<Map<String, dynamic>?> _getEmpleadorInfo(String? empleadorId) async {
    if (empleadorId == null || empleadorId.isEmpty) return null;
    
    try {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(empleadorId)
          .get();
      
      if (doc.exists) {
        return doc.data();
      }
    } catch (e) {
      print('Error obteniendo info del empleador: $e');
    }
    return null;
  }

  // Métodos para colores de calificación
  Color _getRatingBackgroundColor(double rating) {
    if (rating >= 4.5) return Colors.green.shade50;
    if (rating >= 4.0) return Colors.lightGreen.shade50;
    if (rating >= 3.5) return Colors.orange.shade50;
    if (rating >= 3.0) return Colors.deepOrange.shade50;
    return Colors.red.shade50;
  }

  Color _getRatingBorderColor(double rating) {
    if (rating >= 4.5) return Colors.green.shade300;
    if (rating >= 4.0) return Colors.lightGreen.shade300;
    if (rating >= 3.5) return Colors.orange.shade300;
    if (rating >= 3.0) return Colors.deepOrange.shade300;
    return Colors.red.shade300;
  }

  Color _getRatingIconColor(double rating) {
    if (rating >= 4.5) return Colors.green.shade600;
    if (rating >= 4.0) return Colors.lightGreen.shade600;
    if (rating >= 3.5) return Colors.orange.shade600;
    if (rating >= 3.0) return Colors.deepOrange.shade600;
    return Colors.red.shade600;
  }

  Color _getRatingTextColor(double rating) {
    if (rating >= 4.5) return Colors.green.shade800;
    if (rating >= 4.0) return Colors.lightGreen.shade800;
    if (rating >= 3.5) return Colors.orange.shade800;
    if (rating >= 3.0) return Colors.deepOrange.shade800;
    return Colors.red.shade800;
  }

  @override
  void dispose() {
    // Cancelar temporizadores para prevenir memory leaks
    _timeoutTimer?.cancel();
    super.dispose();
  }
}
