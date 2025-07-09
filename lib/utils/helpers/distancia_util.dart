import 'dart:math';
import 'package:flutter/material.dart';

class DistanciaUtil {
  /// Calcula la distancia entre dos puntos usando la fórmula de Haversine
  /// [lat1], [lon1]: coordenadas del primer punto
  /// [lat2], [lon2]: coordenadas del segundo punto
  /// Retorna la distancia en kilómetros
  static double calcularDistancia(double lat1, double lon1, double lat2, double lon2) {
    const double p = 0.017453292519943295; // pi/180
    const double c = 6371; // radio de la tierra en km
    final a =
        0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return c * 2 * asin(sqrt(a));
  }

  /// Formatea la distancia para mostrar en la UI
  /// [distancia]: distancia en kilómetros
  /// Retorna una cadena formateada como "15.2 km" o "< 1 km"
  static String formatearDistancia(double distancia) {
    if (distancia < 1) {
      return '< 1 km';
    } else if (distancia < 10) {
      return '${distancia.toStringAsFixed(1)} km';
    } else {
      return '${distancia.round()} km';
    }
  }

  /// Obtiene un emoji que representa la cercanía de la distancia
  static String obtenerEmojiDistancia(double distancia) {
    if (distancia < 5) {
      return '🚶‍♂️'; // Caminando
    } else if (distancia < 20) {
      return '🚲'; // Bicicleta
    } else if (distancia < 50) {
      return '🚗'; // Auto
    } else {
      return '✈️'; // Avión
    }
  }

  /// Obtiene el color que representa la cercanía de la distancia
  static Color obtenerColorDistancia(double distancia) {
    if (distancia < 5) {
      return Colors.green;
    } else if (distancia < 20) {
      return Colors.orange;
    } else if (distancia < 50) {
      return Colors.red;
    } else {
      return Colors.grey;
    }
  }
}
