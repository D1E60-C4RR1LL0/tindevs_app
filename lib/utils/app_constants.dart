// Este archivo contiene constantes utilizadas en toda la aplicación

class AppConstants {
  // Estados de propuestas
  static const String estadoPropuestaActivo = 'activo';
  static const String estadoPropuestaInactivo = 'inactivo';
  static const String estadoPropuestaPendiente = 'pendiente';
  
  // Estados de validación de propuestas
  static const String validacionPropuestaAprobada = 'aprobada';
  static const String validacionPropuestaPendiente = 'pendiente';
  static const String validacionPropuestaRechazada = 'rechazada';
  
  // Estados de intereses
  static const String interesEstadoPendiente = 'pendiente';
  static const String interesEstadoAceptado = 'aceptado';
  static const String interesEstadoRechazado = 'rechazado';
  
  // Tipos de usuario
  static const String tipoPostulante = 'postulante';
  static const String tipoEmpleador = 'empleador';
  static const String tipoAdmin = 'admin';
  
  // Colecciones de Firestore
  static const String coleccionUsuarios = 'usuarios';
  static const String coleccionPropuestas = 'propuestas';
  static const String coleccionLikes = 'likes';
  static const String coleccionDislikes = 'dislikes';
  static const String coleccionIntereses = 'intereses';
  static const String coleccionChats = 'chats';
  static const String coleccionMensajes = 'messages';
  static const String coleccionCalificaciones = 'calificaciones';
  
  // Assets
  static const String assetComunas = 'assets/data/comunas.json';
  static const String assetComunasLatLng = 'assets/data/comunas_latlng.json';
  static const String assetCertificaciones = 'assets/data/certificaciones.json';
}
