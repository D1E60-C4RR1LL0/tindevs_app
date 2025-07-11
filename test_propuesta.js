// Script para crear una propuesta de prueba con todos los campos correctos
// Ejecutar este script en la consola de Firebase para verificar que todos los campos estén bien

const admin = require('firebase-admin');

// Configurar Firebase (reemplaza con tu configuración)
const serviceAccount = require('./firebase_service_account.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: 'https://tindevs-app-default-rtdb.firebaseio.com'
});

const firestore = admin.firestore();

async function crearPropuestaDePrueba() {
  try {
    const propuestaPrueba = {
      titulo: 'Desarrollador Full Stack - TEST',
      descripcion: 'Posición para desarrollar aplicaciones web y móviles con React, Node.js y Flutter.',
      
      // Campos principales que usa el sistema
      carrera: 'Ingeniería en Informática, Ingeniería en Computación',
      certificacion: 'Certificación en React, Node.js',
      experiencia: 2,
      region: 'Región Metropolitana de Santiago',
      comuna: 'Las Condes',
      latitud: -33.4084,
      longitud: -70.5450,
      empresa: 'TechCorp S.A.',
      
      // Campos de compatibilidad
      carreraRequerida: 'Ingeniería en Informática, Ingeniería en Computación',
      certificacionRequerida: 'Certificación en React, Node.js',
      experienciaMinima: 2,
      
      // Campos administrativos
      empleadorId: 'test-empleador-id',
      idEmpleador: 'test-empleador-id',
      fechaPublicacion: admin.firestore.Timestamp.now(),
      fechaCreacion: admin.firestore.Timestamp.now(),
      estadoValidacion: 'pendiente',
      documentoValidacionUrl: 'https://ejemplo.com/documento.pdf',
      
      // Campos adicionales
      estado: 'activo',
      modalidad: 'Presencial'
    };

    const docRef = await firestore.collection('propuestas').add(propuestaPrueba);
    console.log('✅ Propuesta de prueba creada exitosamente con ID:', docRef.id);
    console.log('📋 Datos guardados:', JSON.stringify(propuestaPrueba, null, 2));
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error al crear propuesta de prueba:', error);
    process.exit(1);
  }
}

crearPropuestaDePrueba();
