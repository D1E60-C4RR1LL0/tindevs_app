const admin = require('firebase-admin');

// Inicializar Firebase Admin
const serviceAccount = require('./firebase_service_account.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: "https://tindevs-app-default-rtdb.firebaseio.com"
});

const db = admin.firestore();

async function verificarPropuestasFinales() {
  try {
    console.log('🔍 VERIFICACIÓN FINAL DE PROPUESTAS');
    console.log('=====================================');
    
    // Obtener todas las propuestas
    const propuestasSnapshot = await db.collection('propuestas').get();
    const totalPropuestas = propuestasSnapshot.size;
    
    console.log(`📊 Total de propuestas en la base: ${totalPropuestas}`);
    
    // Categorizar propuestas
    let activasYAprobadas = 0;
    let activasPendientes = 0;
    let activasRechazadas = 0;
    let inactivas = 0;
    let sinEstado = 0;
    let sinValidacion = 0;
    let conCamposUnificados = 0;
    let conCamposLegacy = 0;
    let conCoordenadas = 0;
    
    const propuestasDetalle = [];
    
    propuestasSnapshot.forEach(doc => {
      const data = doc.data();
      const id = doc.id;
      
      // Verificar estado
      const estado = data.estado;
      const estadoValidacion = data.estadoValidacion;
      
      if (!estado) {
        sinEstado++;
      } else if (estado === 'activo') {
        if (!estadoValidacion) {
          sinValidacion++;
        } else if (estadoValidacion === 'aprobada') {
          activasYAprobadas++;
        } else if (estadoValidacion === 'pendiente') {
          activasPendientes++;
        } else if (estadoValidacion === 'rechazada') {
          activasRechazadas++;
        }
      } else {
        inactivas++;
      }
      
      // Verificar campos unificados vs legacy
      const tieneUnificados = data.carrera || data.certificacion || data.experiencia;
      const tieneLegacy = data.carreraRequerida || data.certificacionRequerida || data.experienciaMinima;
      
      if (tieneUnificados) conCamposUnificados++;
      if (tieneLegacy) conCamposLegacy++;
      
      // Verificar coordenadas
      if (data.latitud && data.longitud) {
        conCoordenadas++;
      }
      
      // Guardar detalle para análisis
      propuestasDetalle.push({
        id,
        titulo: data.titulo,
        empresa: data.empresa,
        estado: estado || 'sin_estado',
        estadoValidacion: estadoValidacion || 'sin_validacion',
        tieneUnificados,
        tieneLegacy,
        tieneCoordenadas: !!(data.latitud && data.longitud),
        fechaCreacion: data.fechaCreacion?.toDate?.() || 'N/A'
      });
    });
    
    console.log('\n📈 RESUMEN POR ESTADO:');
    console.log(`✅ Activas y aprobadas (visibles para postulantes): ${activasYAprobadas}`);
    console.log(`⏳ Activas pendientes de aprobación: ${activasPendientes}`);
    console.log(`❌ Activas rechazadas: ${activasRechazadas}`);
    console.log(`🔒 Inactivas: ${inactivas}`);
    console.log(`⚠️  Sin estado definido: ${sinEstado}`);
    console.log(`⚠️  Sin validación definida: ${sinValidacion}`);
    
    console.log('\n🔧 RESUMEN DE CAMPOS:');
    console.log(`🆕 Con campos unificados (carrera, certificacion, experiencia): ${conCamposUnificados}`);
    console.log(`🔄 Con campos legacy (carreraRequerida, certificacionRequerida, experienciaMinima): ${conCamposLegacy}`);
    console.log(`📍 Con coordenadas: ${conCoordenadas}`);
    
    // Mostrar propuestas que están activas y aprobadas (las que ven los postulantes)
    console.log('\n🎯 PROPUESTAS VISIBLES PARA POSTULANTES:');
    console.log('========================================');
    
    const propuestasVisibles = propuestasDetalle.filter(p => 
      p.estado === 'activo' && p.estadoValidacion === 'aprobada'
    );
    
    if (propuestasVisibles.length === 0) {
      console.log('❌ NO HAY PROPUESTAS VISIBLES PARA POSTULANTES');
      console.log('   Esto significa que los postulantes no verán ninguna propuesta en el swipe.');
    } else {
      propuestasVisibles.forEach((prop, index) => {
        console.log(`${index + 1}. "${prop.titulo}" - ${prop.empresa}`);
        console.log(`   ID: ${prop.id}`);
        console.log(`   Campos: ${prop.tieneUnificados ? '✅ Unificados' : '❌'} | ${prop.tieneLegacy ? '✅ Legacy' : '❌'}`);
        console.log(`   Coordenadas: ${prop.tieneCoordenadas ? '✅' : '❌'}`);
        console.log(`   Fecha: ${prop.fechaCreacion}`);
        console.log('');
      });
    }
    
    // Verificar propuestas problemáticas
    console.log('\n⚠️  PROPUESTAS PROBLEMÁTICAS:');
    console.log('==============================');
    
    const problematicas = propuestasDetalle.filter(p => 
      p.estado === 'sin_estado' || p.estadoValidacion === 'sin_validacion' || !p.tieneCoordenadas
    );
    
    if (problematicas.length === 0) {
      console.log('✅ No se encontraron propuestas problemáticas');
    } else {
      problematicas.forEach(prop => {
        console.log(`- "${prop.titulo}" (${prop.id})`);
        if (prop.estado === 'sin_estado') console.log('  ❌ Sin estado definido');
        if (prop.estadoValidacion === 'sin_validacion') console.log('  ❌ Sin validación definida');
        if (!prop.tieneCoordenadas) console.log('  ❌ Sin coordenadas');
        console.log('');
      });
    }
    
    console.log('\n🎉 VERIFICACIÓN COMPLETADA');
    console.log('===========================');
    
    if (activasYAprobadas > 0) {
      console.log(`✅ ÉXITO: ${activasYAprobadas} propuestas están visibles para postulantes`);
    } else {
      console.log('❌ PROBLEMA: No hay propuestas visibles para postulantes');
    }
    
    if (conCamposUnificados > 0) {
      console.log(`✅ ÉXITO: ${conCamposUnificados} propuestas tienen campos unificados`);
    }
    
    if (conCoordenadas === totalPropuestas) {
      console.log('✅ ÉXITO: Todas las propuestas tienen coordenadas');
    } else {
      console.log(`⚠️  ATENCIÓN: ${totalPropuestas - conCoordenadas} propuestas sin coordenadas`);
    }
    
  } catch (error) {
    console.error('❌ Error:', error);
  }
}

verificarPropuestasFinales().then(() => {
  console.log('\n🔚 Verificación finalizada');
  process.exit(0);
}).catch(error => {
  console.error('❌ Error fatal:', error);
  process.exit(1);
});
