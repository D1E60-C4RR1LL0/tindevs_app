const admin = require('firebase-admin');
const serviceAccount = require('./firebase_service_account.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: 'https://tindevs-app-default-rtdb.firebaseio.com/'
});

const db = admin.firestore();

async function checkPropuestas() {
  try {
    console.log('🔍 Verificando propuestas en la base de datos...');
    
    // Obtener todas las propuestas
    const propuestasSnapshot = await db.collection('propuestas').get();
    console.log('📋 Total de propuestas encontradas:', propuestasSnapshot.size);
    
    // Verificar estados
    const estadosCount = {};
    const validacionCount = {};
    
    propuestasSnapshot.forEach((doc) => {
      const data = doc.data();
      const estado = data.estado || 'sin_estado';
      const estadoValidacion = data.estadoValidacion || 'sin_validacion';
      
      estadosCount[estado] = (estadosCount[estado] || 0) + 1;
      validacionCount[estadoValidacion] = (validacionCount[estadoValidacion] || 0) + 1;
      
      console.log(`📄 Propuesta "${data.titulo}":`);
      console.log(`   - Estado: ${estado}`);
      console.log(`   - Validación: ${estadoValidacion}`);
      console.log(`   - Empresa: ${data.empresa || 'N/A'}`);
      console.log(`   - Región: ${data.region || 'N/A'}`);
      console.log(`   - Comuna: ${data.comuna || 'N/A'}`);
      console.log('');
    });
    
    console.log('📊 Resumen de estados:');
    Object.entries(estadosCount).forEach(([estado, count]) => {
      console.log(`   ${estado}: ${count}`);
    });
    
    console.log('📊 Resumen de validaciones:');
    Object.entries(validacionCount).forEach(([validacion, count]) => {
      console.log(`   ${validacion}: ${count}`);
    });
    
    // Verificar propuestas que cumplen los criterios de filtro
    const propuestasActivas = propuestasSnapshot.docs.filter(doc => {
      const data = doc.data();
      return data.estado === 'activo' && data.estadoValidacion === 'aprobada';
    });
    
    console.log('✅ Propuestas activas Y aprobadas:', propuestasActivas.length);
    
    if (propuestasActivas.length > 0) {
      console.log('🎯 Propuestas que deberían aparecer en el swipe:');
      propuestasActivas.forEach(doc => {
        const data = doc.data();
        console.log(`   - "${data.titulo}" (${data.empresa})`);
      });
    }
    
  } catch (error) {
    console.error('❌ Error:', error);
  }
}

checkPropuestas();
