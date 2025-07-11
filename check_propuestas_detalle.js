const admin = require('firebase-admin');
const serviceAccount = require('./firebase_service_account.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: 'https://tindevs-app-default-rtdb.firebaseio.com/'
});

const db = admin.firestore();

async function checkPropuestasDetalle() {
  try {
    console.log('🔍 Verificando propuestas activas y aprobadas en detalle...');
    
    const propuestasSnapshot = await db.collection('propuestas')
      .where('estado', '==', 'activo')
      .where('estadoValidacion', '==', 'aprobada')
      .get();
    
    console.log('📋 Propuestas activas y aprobadas:', propuestasSnapshot.size);
    
    propuestasSnapshot.forEach((doc) => {
      const data = doc.data();
      console.log(`\n📄 Propuesta "${data.titulo}" (ID: ${doc.id}):`);
      console.log(`   - Estado: ${data.estado}`);
      console.log(`   - Validación: ${data.estadoValidacion}`);
      console.log(`   - Empresa: ${data.empresa || 'N/A'}`);
      console.log(`   - Región: ${data.region || 'N/A'}`);
      console.log(`   - Comuna: ${data.comuna || 'N/A'}`);
      console.log(`   - Latitud: ${data.latitud || 'N/A'}`);
      console.log(`   - Longitud: ${data.longitud || 'N/A'}`);
      console.log(`   - Carrera: ${data.carrera || data.carreraRequerida || 'N/A'}`);
      console.log(`   - Certificación: ${data.certificacion || data.certificacionRequerida || 'N/A'}`);
      console.log(`   - Experiencia: ${data.experiencia || data.experienciaMinima || 'N/A'}`);
      console.log(`   - Fecha creación: ${data.fechaCreacion || data.fechaPublicacion || 'N/A'}`);
      console.log(`   - Empleador ID: ${data.empleadorId || data.idEmpleador || 'N/A'}`);
      
      // Verificar campos críticos
      const tieneCoordenadas = data.latitud && data.longitud;
      console.log(`   - ✅ Tiene coordenadas: ${tieneCoordenadas}`);
      
      if (!tieneCoordenadas) {
        console.log('   ❌ PROBLEMA: Sin coordenadas, no aparecerá en el swipe');
      }
    });
    
  } catch (error) {
    console.error('❌ Error:', error);
  }
}

checkPropuestasDetalle();
