const admin = require('firebase-admin');
const serviceAccount = require('./firebase_service_account.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function approveLatestProposal() {
  console.log('🔄 Aprobando la propuesta más reciente para testing...');
  
  try {
    // Obtener la propuesta más reciente que esté pendiente
    const snapshot = await db.collection('propuestas')
      .where('estadoValidacion', '==', 'pendiente')
      .orderBy('fechaCreacion', 'desc')
      .limit(1)
      .get();
    
    if (snapshot.empty) {
      console.log('❌ No hay propuestas pendientes para aprobar');
      return;
    }

    const doc = snapshot.docs[0];
    const data = doc.data();
    const propuestaId = doc.id;
    
    console.log(`📋 Propuesta encontrada:`);
    console.log(`  ID: ${propuestaId}`);
    console.log(`  Título: ${data.titulo}`);
    console.log(`  Estado actual: ${data.estadoValidacion}`);
    console.log(`  Estado de propuesta: ${data.estado}`);
    
    // Aprobar la propuesta
    await doc.ref.update({
      estadoValidacion: 'aprobada'
    });
    
    console.log(`\n✅ Propuesta "${data.titulo}" APROBADA exitosamente`);
    console.log(`📱 Ahora será visible para los postulantes en la app móvil`);
    
    // Verificar el resultado
    console.log(`\n🔍 Verificando resultado...`);
    const verifySnapshot = await db.collection('propuestas')
      .where('estadoValidacion', '==', 'aprobada')
      .get();
    
    console.log(`✅ Total de propuestas aprobadas ahora: ${verifySnapshot.size}`);
    
    verifySnapshot.docs.forEach(doc => {
      const data = doc.data();
      console.log(`  - ${data.titulo} (${doc.id})`);
    });

  } catch (error) {
    console.error('❌ Error:', error);
  }
}

async function resetProposalToPending() {
  console.log('🔄 Regresando propuesta a estado pendiente...');
  
  try {
    // Obtener la propuesta más reciente que esté aprobada
    const snapshot = await db.collection('propuestas')
      .where('estadoValidacion', '==', 'aprobada')
      .orderBy('fechaCreacion', 'desc')
      .limit(1)
      .get();
    
    if (snapshot.empty) {
      console.log('❌ No hay propuestas aprobadas para regresar a pendiente');
      return;
    }

    const doc = snapshot.docs[0];
    const data = doc.data();
    const propuestaId = doc.id;
    
    console.log(`📋 Propuesta encontrada:`);
    console.log(`  ID: ${propuestaId}`);
    console.log(`  Título: ${data.titulo}`);
    console.log(`  Estado actual: ${data.estadoValidacion}`);
    
    // Regresar a pendiente
    await doc.ref.update({
      estadoValidacion: 'pendiente'
    });
    
    console.log(`\n⏳ Propuesta "${data.titulo}" regresada a PENDIENTE`);
    console.log(`🔒 Ya NO será visible para los postulantes hasta ser aprobada`);

  } catch (error) {
    console.error('❌ Error:', error);
  }
}

async function main() {
  const action = process.argv[2];
  
  if (action === 'approve') {
    await approveLatestProposal();
  } else if (action === 'pending') {
    await resetProposalToPending();
  } else {
    console.log('📋 Script de gestión de aprobaciones de propuestas');
    console.log('\nUso:');
    console.log('  node manage_approvals.js approve   - Aprobar propuesta más reciente');
    console.log('  node manage_approvals.js pending   - Regresar propuesta a pendiente');
    console.log('\n🔒 Recuerda: Solo las propuestas APROBADAS son visibles para postulantes');
  }
  
  process.exit(0);
}

main().catch(error => {
  console.error('Error:', error);
  process.exit(1);
});
