// Script para configurar el sistema de calificaciones
// Este script inicializa los campos de calificación para empleadores existentes

const admin = require('firebase-admin');
const serviceAccount = require('./firebase_service_account.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: "https://tindevs-app-default-rtdb.firebaseio.com"
});

const db = admin.firestore();

async function setupRatingSystem() {
  console.log('🔧 Configurando sistema de calificaciones...');
  
  try {
    // 1. Obtener todos los usuarios empleadores
    const usuariosSnapshot = await db.collection('usuarios')
      .where('tipoUsuario', '==', 'empleador')
      .get();
    
    console.log(`📊 Encontrados ${usuariosSnapshot.docs.length} empleadores`);
    
    // 2. Actualizar cada empleador con campos de calificación iniciales
    const batch = db.batch();
    let count = 0;
    
    for (const doc of usuariosSnapshot.docs) {
      const data = doc.data();
      
      // Solo actualizar si no tiene campos de calificación
      if (!data.hasOwnProperty('averageRating')) {
        batch.update(doc.ref, {
          averageRating: null,
          totalRatings: 0,
          lastRatingUpdate: null
        });
        count++;
        console.log(`✅ Preparando actualización para: ${data.nombre || 'Sin nombre'} (${doc.id})`);
      }
    }
    
    if (count > 0) {
      await batch.commit();
      console.log(`🎉 ${count} empleadores actualizados con campos de calificación`);
    } else {
      console.log('✨ Todos los empleadores ya tienen campos de calificación configurados');
    }
    
    // 3. Crear índices recomendados (esto es solo informativo)
    console.log(`
📝 ÍNDICES RECOMENDADOS EN FIRESTORE CONSOLE:

Para la colección 'empleador_ratings':
- Campo: empleadorId, Orden: Ascending
- Campo: postulanteId, Orden: Ascending  
- Campo: propuestaId, Orden: Ascending

Para optimizar consultas compuestas:
- Campos: empleadorId (Ascending), fecha (Descending)
- Campos: postulanteId (Ascending), empleadorId (Ascending), propuestaId (Ascending)

🔍 Ir a: Firebase Console > Firestore > Indexes para crear estos índices
    `);
    
    // 4. Verificar propuestas existentes y agregar IDs de empleador si faltan
    console.log('\n🔍 Verificando propuestas existentes...');
    const propuestasSnapshot = await db.collection('propuestas').get();
    
    let propuestasActualizadas = 0;
    const propuestasBatch = db.batch();
    
    for (const doc of propuestasSnapshot.docs) {
      const data = doc.data();
      
      // Normalizar campos de empleador
      if (data.idEmpleador && !data.empleadorId) {
        propuestasBatch.update(doc.ref, {
          empleadorId: data.idEmpleador
        });
        propuestasActualizadas++;
      } else if (data.empleadorId && !data.idEmpleador) {
        propuestasBatch.update(doc.ref, {
          idEmpleador: data.empleadorId
        });
        propuestasActualizadas++;
      }
    }
    
    if (propuestasActualizadas > 0) {
      await propuestasBatch.commit();
      console.log(`📋 ${propuestasActualizadas} propuestas actualizadas con campos de empleador normalizados`);
    }
    
    console.log('\n🎯 Sistema de calificaciones configurado exitosamente!');
    console.log(`
🚀 FUNCIONALIDADES IMPLEMENTADAS:

1. ⭐ EVALUACIÓN EN CHAT:
   - Los postulantes pueden evaluar empleadores después de intercambiar 2+ mensajes
   - Botón de estrella aparece en el AppBar del chat
   - Sistema de 1-5 estrellas con comentarios opcionales

2. 📊 VISUALIZACIÓN EN PROPUESTAS:
   - Calificación promedio visible en las tarjetas de propuestas
   - Indicador de número de evaluaciones
   - Colores dinámicos según la calificación (verde=excelente, rojo=malo)

3. 💾 ALMACENAMIENTO:
   - Colección 'empleador_ratings' para evaluaciones individuales
   - Campo 'averageRating' en perfil de empleador
   - Campo 'totalRatings' para mostrar credibilidad

4. 🔒 SEGURIDAD:
   - Un postulante solo puede evaluar una vez por propuesta
   - Requiere intercambio mínimo de mensajes
   - Calificaciones se actualizan automáticamente

¡El sistema está listo para usar! 🎉
    `);
    
  } catch (error) {
    console.error('❌ Error configurando sistema de calificaciones:', error);
  }
  
  process.exit(0);
}

setupRatingSystem();
