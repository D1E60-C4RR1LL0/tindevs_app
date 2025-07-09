import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../utils/themes/app_themes.dart';

class ChatScreen extends StatefulWidget {
  final String matchId;
  final String otherUserId;
  final String otherUserName;
  final String propuestaTitle;
  final bool isPostulante;

  const ChatScreen({
    super.key,
    required this.matchId,
    required this.otherUserId,
    required this.otherUserName,
    required this.propuestaTitle,
    required this.isPostulante,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Asegurar que el documento del chat existe
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.matchId)
          .set({
        'participants': [user.uid, widget.otherUserId],
        'propuestaTitle': widget.propuestaTitle,
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error al inicializar chat: $e');
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.matchId)
          .collection('messages')
          .add({
        'senderId': user.uid,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'senderName': await _getUserName(user.uid),
      });

      // Actualizar el timestamp del chat principal
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.matchId)
          .set({
        'lastMessage': message,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'participants': [user.uid, widget.otherUserId],
        'propuestaTitle': widget.propuestaTitle,
      }, SetOptions(merge: true));

      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar mensaje: $e')),
      );
    }
  }

  Future<String> _getUserName(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userId)
          .get();
      return doc.data()?['nombre'] ?? 'Usuario';
    } catch (e) {
      return 'Usuario';
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      backgroundColor: widget.isPostulante 
          ? AppThemes.postulanteBackground 
          : AppThemes.empleadorBackground,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.otherUserName),
            Text(
              widget.propuestaTitle,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: widget.isPostulante 
            ? AppThemes.postulantePrimary 
            : AppThemes.empleadorPrimary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Header con información del match
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  widget.isPostulante ? Icons.business : Icons.person_search,
                  color: widget.isPostulante 
                      ? AppThemes.postulanteAccent 
                      : AppThemes.empleadorAccent,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chat sobre: ${widget.propuestaTitle}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: widget.isPostulante 
                              ? AppThemes.postulantePrimary 
                              : AppThemes.empleadorPrimary,
                        ),
                      ),
                      Text(
                        'Con: ${widget.otherUserName}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.isPostulante 
                        ? AppThemes.postulanteAccent 
                        : AppThemes.empleadorAccent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'MATCH',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Lista de mensajes
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.matchId)
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '¡Inicia la conversación!',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Envía un mensaje para comenzar a chatear',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final messages = snapshot.data!.docs;
                
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final messageData = messages[index].data() as Map<String, dynamic>;
                    final isMe = messageData['senderId'] == currentUser?.uid;
                    final timestamp = messageData['timestamp'] as Timestamp?;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        mainAxisAlignment: isMe 
                            ? MainAxisAlignment.end 
                            : MainAxisAlignment.start,
                        children: [
                          if (!isMe) ...[
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: widget.isPostulante 
                                  ? AppThemes.empleadorAccent 
                                  : AppThemes.postulanteAccent,
                              child: Text(
                                widget.otherUserName[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isMe 
                                    ? (widget.isPostulante 
                                        ? AppThemes.postulanteAccent 
                                        : AppThemes.empleadorAccent)
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    messageData['message'] ?? '',
                                    style: TextStyle(
                                      color: isMe ? Colors.white : Colors.black87,
                                      fontSize: 16,
                                    ),
                                  ),
                                  if (timestamp != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatTime(timestamp.toDate()),
                                      style: TextStyle(
                                        color: isMe 
                                            ? Colors.white70 
                                            : Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          if (isMe) ...[
                            const SizedBox(width: 8),
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: widget.isPostulante 
                                  ? AppThemes.postulanteAccent 
                                  : AppThemes.empleadorAccent,
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Banner de evaluación automático (solo para postulantes)
          if (widget.isPostulante)
            FutureBuilder<bool>(
              future: _canShowRatingButton(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const SizedBox.shrink(); // En caso de error, no mostrar nada
                }
                
                if (snapshot.data == true) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.amber[50]!, Colors.orange[50]!],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber[300]!, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _showRatingDialog(),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.amber[600],
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                child: const Icon(
                                  Icons.star_rate,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '⭐ ¡Evalúa a ${widget.otherUserName}!',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber[800],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Tu opinión ayuda a otros postulantes',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.amber[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.amber[600],
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

          // Campo de texto para escribir mensajes
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Escribir mensaje...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 12),
                FloatingActionButton(
                  onPressed: _sendMessage,
                  backgroundColor: widget.isPostulante 
                      ? AppThemes.postulanteAccent 
                      : AppThemes.empleadorAccent,
                  mini: true,
                  child: const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      // Hoy - mostrar solo la hora
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      // Otro día - mostrar fecha y hora
      return '${dateTime.day}/${dateTime.month} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  // Verificar si se puede mostrar el botón de calificación
  Future<bool> _canShowRatingButton() async {
    if (!widget.isPostulante) return false;
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      // Verificar si ya evaluó a este empleador para esta propuesta
      final existingRating = await FirebaseFirestore.instance
          .collection('empleador_ratings')
          .where('postulanteId', isEqualTo: user.uid)
          .where('empleadorId', isEqualTo: widget.otherUserId)
          .where('propuestaId', isEqualTo: widget.matchId)
          .limit(1)
          .get();

      if (existingRating.docs.isNotEmpty) {
        return false; // Ya evaluó
      }

      // Verificar si han intercambiado al menos 2 mensajes cada uno
      final messagesSnapshot = await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.matchId)
          .collection('messages')
          .limit(50) // Limitar consulta para mejor rendimiento
          .get();

      if (messagesSnapshot.docs.isEmpty) {
        return false;
      }

      final userMessages = messagesSnapshot.docs
          .where((doc) {
            final data = doc.data();
            return data['senderId'] == user.uid;
          })
          .length;
      
      final otherMessages = messagesSnapshot.docs
          .where((doc) {
            final data = doc.data();
            return data['senderId'] == widget.otherUserId;
          })
          .length;

      return userMessages >= 2 && otherMessages >= 2;
    } catch (e) {
      print('Error verificando si puede calificar: $e');
      return false; // En caso de error, no mostrar opción
    }
  }

  // Mostrar diálogo de calificación
  Future<void> _showRatingDialog() async {
    double rating = 5.0;
    String comment = '';
    
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true, // Permitir cerrar tocando afuera
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              maxWidth: 400,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.star_rate, color: Colors.amber[700], size: 28),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Evaluar Empleador',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Evalúa tu experiencia con ${widget.otherUserName}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Propuesta: ${widget.propuestaTitle}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.shade800,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tu calificación ayudará a otros postulantes a tomar mejores decisiones',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Calificación general:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Estrellas en layout más flexible
                        Center(
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            children: List.generate(5, (index) {
                              return GestureDetector(
                                onTap: () {
                                  setDialogState(() {
                                    rating = (index + 1).toDouble();
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  child: Icon(
                                    Icons.star,
                                    size: 36,
                                    color: index < rating
                                        ? Colors.amber[600]
                                        : Colors.grey[300],
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            _getRatingText(rating),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _getRatingColor(rating),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Comentario (opcional):',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          onChanged: (value) => comment = value,
                          decoration: InputDecoration(
                            hintText: 'Comparte tu experiencia...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          maxLines: 3,
                          maxLength: 200,
                        ),
                      ],
                    ),
                  ),
                ),
                // Actions
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber[700],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: const Text('Enviar Evaluación'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (confirmed == true) {
      await _submitRating(rating, comment);
    }
  }

  String _getRatingText(double rating) {
    switch (rating.toInt()) {
      case 1: return 'Muy malo';
      case 2: return 'Malo';
      case 3: return 'Regular';
      case 4: return 'Bueno';
      case 5: return 'Excelente';
      default: return 'Regular';
    }
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4) return Colors.green[700]!;
    if (rating >= 3) return Colors.orange[700]!;
    return Colors.red[700]!;
  }

  // Enviar calificación a Firestore
  Future<void> _submitRating(double rating, String comment) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Mostrar loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              const Text('Enviando evaluación...'),
            ],
          ),
          backgroundColor: AppThemes.postulantePrimary,
          duration: const Duration(seconds: 2),
        ),
      );

      // Guardar la calificación
      await FirebaseFirestore.instance
          .collection('empleador_ratings')
          .add({
        'postulanteId': user.uid,
        'empleadorId': widget.otherUserId,
        'propuestaId': widget.matchId,
        'propuestaTitle': widget.propuestaTitle,
        'rating': rating,
        'comment': comment.trim(),
        'fecha': FieldValue.serverTimestamp(),
      });

      // Actualizar la calificación promedio del empleador
      await _updateEmpleadorAverageRating();

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 16),
                const Text('¡Gracias por tu evaluación!'),
              ],
            ),
            backgroundColor: Colors.green[600],
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar evaluación: $e'),
            backgroundColor: Colors.red[600],
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Actualizar calificación promedio del empleador
  Future<void> _updateEmpleadorAverageRating() async {
    try {
      final ratingsSnapshot = await FirebaseFirestore.instance
          .collection('empleador_ratings')
          .where('empleadorId', isEqualTo: widget.otherUserId)
          .get();

      if (ratingsSnapshot.docs.isNotEmpty) {
        double totalRating = 0;
        int count = 0;

        for (var doc in ratingsSnapshot.docs) {
          final data = doc.data();
          totalRating += (data['rating'] ?? 0).toDouble();
          count++;
        }

        final averageRating = totalRating / count;

        // Actualizar el perfil del empleador con la calificación promedio
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(widget.otherUserId)
            .update({
          'averageRating': averageRating,
          'totalRatings': count,
          'lastRatingUpdate': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error actualizando calificación promedio: $e');
    }
  }
}
