const admin = require('firebase-admin');

// Inicializar Firebase Admin SDK
const serviceAccount = require('./firebase_service_account.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function setupInteresesCollection() {
  console.log('🔄 Configurando colección de intereses...');
  
  try {
    // 1. Obtener todos los likes existentes
    const likesSnapshot = await db.collection('likes').get();
    console.log(`📥 Encontrados ${likesSnapshot.size} likes para migrar`);
    
    let createdCount = 0;
    
    // 2. Para cada like, crear un registro en intereses
    for (const likeDoc of likesSnapshot.docs) {
      const likeData = likeDoc.data();
      
      // Verificar si ya existe un interés para esta combinación
      const existingInterest = await db.collection('intereses')
        .where('postulanteId', '==', likeData.postulanteId)
        .where('propuestaId', '==', likeData.propuestaId)
        .limit(1)
        .get();
      
      if (existingInterest.empty) {
        // Obtener información de la propuesta
        let propuestaTitle = 'Propuesta';
        let empresa = 'Empresa';
        try {
          const propuestaDoc = await db.collection('propuestas').doc(likeData.propuestaId).get();
          if (propuestaDoc.exists) {
            const propuestaData = propuestaDoc.data();
            propuestaTitle = propuestaData.titulo || 'Propuesta';
            
            // Obtener nombre de la empresa
            if (propuestaData.empleadorId) {
              const empleadorDoc = await db.collection('usuarios').doc(propuestaData.empleadorId).get();
              if (empleadorDoc.exists) {
                empresa = empleadorDoc.data().nombre || 'Empresa';
              }
            }
          }
        } catch (e) {
          console.log(`⚠️ No se pudo obtener info de propuesta ${likeData.propuestaId}`);
        }
        
        // Verificar si hay match para determinar el estado
        const matchSnapshot = await db.collection('matches')
          .where('idPostulante', '==', likeData.postulanteId)
          .where('idPropuesta', '==', likeData.propuestaId)
          .limit(1)
          .get();
        
        const estado = !matchSnapshot.empty ? 'aceptado' : 'pendiente';
        
        // Crear el registro de interés
        await db.collection('intereses').add({
          postulanteId: likeData.postulanteId || '',
          propuestaId: likeData.propuestaId || '',
          empleadorId: likeData.idEmpleador || likeData.empleadorId || '',
          propuestaTitle: propuestaTitle,
          empresa: empresa,
          fecha: likeData.timestamp || admin.firestore.FieldValue.serverTimestamp(),
          estado: estado
        });
        
        createdCount++;
        console.log(`✅ Creado interés ${createdCount}: ${propuestaTitle} (${estado})`);
      }
    }
    
    console.log(`🎉 Migración completa! Se crearon ${createdCount} nuevos registros de intereses.`);
    
    // 3. Mostrar estadísticas finales
    const totalIntereses = await db.collection('intereses').get();
    const pendientes = await db.collection('intereses').where('estado', '==', 'pendiente').get();
    const aceptados = await db.collection('intereses').where('estado', '==', 'aceptado').get();
    
    console.log(`📊 Estadísticas finales:`);
    console.log(`   Total intereses: ${totalIntereses.size}`);
    console.log(`   Pendientes: ${pendientes.size}`);
    console.log(`   Aceptados: ${aceptados.size}`);
    
  } catch (error) {
    console.error('❌ Error en la configuración:', error);
  }
}

// Ejecutar la función
setupInteresesCollection().then(() => {
  console.log('✅ Proceso completado');
  process.exit(0);
}).catch((error) => {
  console.error('❌ Error:', error);
  process.exit(1);
});
