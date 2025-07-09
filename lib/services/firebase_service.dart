import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/models.dart';

// Este archivo proporciona una capa de abstracción para interactuar con Firebase
// y otras fuentes de datos externas
class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Autenticación
  User? get currentUser => _auth.currentUser;

  Future<User?> signIn(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> signUp(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Usuarios
  Future<void> createUserProfile(String userId, Map<String, dynamic> userData) async {
    await _firestore.collection('usuarios').doc(userId).set(userData);
  }

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final doc = await _firestore.collection('usuarios').doc(userId).get();
    return doc.data();
  }

  // Propuestas
  Future<List<Propuesta>> getPropuestas({
    String? estado,
    String? estadoValidacion,
    String? empleadorId,
  }) async {
    Query query = _firestore.collection('propuestas');
    
    if (estado != null) {
      query = query.where('estado', isEqualTo: estado);
    }
    
    if (estadoValidacion != null) {
      query = query.where('estadoValidacion', isEqualTo: estadoValidacion);
    }
    
    if (empleadorId != null) {
      query = query.where('idEmpleador', isEqualTo: empleadorId);
    }
    
    final snapshot = await query.get();
    
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return Propuesta.fromMap(data, doc.id);
    }).toList();
  }

  // Intereses
  Future<List<Interes>> getInteresesForPostulante(String postulanteId) async {
    final snapshot = await _firestore
        .collection('intereses')
        .where('postulanteId', isEqualTo: postulanteId)
        .get();
    
    return snapshot.docs.map((doc) {
      return Interes.fromMap(doc.data(), doc.id);
    }).toList();
  }

  Future<List<Interes>> getInteresesForEmpleador(String empleadorId) async {
    final snapshot = await _firestore
        .collection('intereses')
        .where('empleadorId', isEqualTo: empleadorId)
        .get();
    
    return snapshot.docs.map((doc) {
      return Interes.fromMap(doc.data(), doc.id);
    }).toList();
  }
  
  // Chats
  Stream<List<Chat>> getChatListStream(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Chat.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  Stream<List<Message>> getChatMessagesStream(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Message.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }
}
