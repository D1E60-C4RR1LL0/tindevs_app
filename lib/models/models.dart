// Archivo central para definiciones de modelos
// Este archivo proporciona modelos de datos compartidos entre diferentes partes de la aplicación

class Usuario {
  final String id;
  final String nombre;
  final String email;
  final String? comuna;
  final String? region;
  final String tipo; // 'postulante' o 'empleador'
  final double? calificacion;
  final int? totalCalificaciones;

  Usuario({
    required this.id,
    required this.nombre,
    required this.email,
    this.comuna,
    this.region,
    required this.tipo,
    this.calificacion,
    this.totalCalificaciones,
  });

  factory Usuario.fromMap(Map<String, dynamic> data, String id) {
    return Usuario(
      id: id,
      nombre: data['nombre'] ?? '',
      email: data['email'] ?? '',
      comuna: data['comuna'],
      region: data['region'],
      tipo: data['tipo'] ?? '',
      calificacion: data['averageRating']?.toDouble(),
      totalCalificaciones: data['totalRatings'],
    );
  }
}

class Propuesta {
  final String id;
  final String titulo;
  final String descripcion;
  final String idEmpleador;
  final String empresa;
  final String comuna;
  final String region;
  final double latitud;
  final double longitud;
  final String estado;
  final String estadoValidacion;
  final DateTime fechaCreacion;

  Propuesta({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.idEmpleador,
    required this.empresa,
    required this.comuna,
    required this.region,
    required this.latitud,
    required this.longitud,
    required this.estado,
    required this.estadoValidacion,
    required this.fechaCreacion,
  });

  factory Propuesta.fromMap(Map<String, dynamic> data, String id) {
    return Propuesta(
      id: id,
      titulo: data['titulo'] ?? '',
      descripcion: data['descripcion'] ?? '',
      idEmpleador: data['idEmpleador'] ?? data['empleadorId'] ?? '',
      empresa: data['empresa'] ?? '',
      comuna: data['comuna'] ?? '',
      region: data['region'] ?? '',
      latitud: double.parse(data['latitud'].toString()),
      longitud: double.parse(data['longitud'].toString()),
      estado: data['estado'] ?? 'inactivo',
      estadoValidacion: data['estadoValidacion'] ?? 'pendiente',
      fechaCreacion: data['fechaCreacion']?.toDate() ?? DateTime.now(),
    );
  }
}

class Interes {
  final String id;
  final String postulanteId;
  final String propuestaId;
  final String empleadorId;
  final String propuestaTitle;
  final String empresa;
  final String estado; // pendiente, aceptado, rechazado
  final DateTime fecha;

  Interes({
    required this.id,
    required this.postulanteId,
    required this.propuestaId,
    required this.empleadorId,
    required this.propuestaTitle,
    required this.empresa,
    required this.estado,
    required this.fecha,
  });

  factory Interes.fromMap(Map<String, dynamic> data, String id) {
    return Interes(
      id: id,
      postulanteId: data['postulanteId'] ?? '',
      propuestaId: data['propuestaId'] ?? '',
      empleadorId: data['empleadorId'] ?? '',
      propuestaTitle: data['propuestaTitle'] ?? '',
      empresa: data['empresa'] ?? '',
      estado: data['estado'] ?? 'pendiente',
      fecha: data['fecha']?.toDate() ?? DateTime.now(),
    );
  }
}

class Chat {
  final String id;
  final List<String> participants;
  final String lastMessage;
  final DateTime? lastMessageTime;
  final String propuestaTitle;

  Chat({
    required this.id,
    required this.participants,
    required this.lastMessage,
    this.lastMessageTime,
    required this.propuestaTitle,
  });

  factory Chat.fromMap(Map<String, dynamic> data, String id) {
    return Chat(
      id: id,
      participants: List<String>.from(data['participants'] ?? []),
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTime: data['lastMessageTime']?.toDate(),
      propuestaTitle: data['propuestaTitle'] ?? '',
    );
  }
}

class Message {
  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;

  Message({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
  });

  factory Message.fromMap(Map<String, dynamic> data, String id) {
    return Message(
      id: id,
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      timestamp: data['timestamp']?.toDate() ?? DateTime.now(),
    );
  }
}
