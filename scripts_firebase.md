# 🧱 Scripts Firebase para TinDevs

Este archivo contiene scripts útiles para configurar y administrar la base de datos Firebase.

## Configuración Inicial de Colecciones

### 1. Script para configurar estructura inicial:
```javascript
// Ejecutar en Firebase Console → Firestore → Terminal
// Crear colecciones básicas con documentos de ejemplo

// Crear colección de configuración
db.collection('config').doc('app').set({
  version: '1.0.0',
  maintenance: false,
  lastUpdate: firebase.firestore.FieldValue.serverTimestamp()
});

// Crear índices recomendados para queries
db.collection('propuestas').doc('_config').set({
  indices: {
    estado_fecha: 'CREATE INDEX estado_fecha ON propuestas (estado, fechaCreacion DESC)',
    empleador_estado: 'CREATE INDEX empleador_estado ON propuestas (idEmpleador, estado)',
    ubicacion: 'CREATE INDEX ubicacion ON propuestas (region, comuna)'
  }
});
```

### 2. Script para datos de prueba:
```javascript
// Crear propuestas de ejemplo
const propuestasEjemplo = [
  {
    titulo: 'Desarrollador Frontend React',
    descripcion: 'Buscamos desarrollador con experiencia en React.js',
    carrera: 'Ingeniería en Informática',
    region: 'Región Metropolitana',
    comuna: 'Providencia',
    latitud: -33.4372,
    longitud: -70.6506,
    experiencia: 2,
    certificacion: 'React Developer',
    estado: 'aprobada',
    estadoValidacion: 'aprobada',
    fechaCreacion: firebase.firestore.FieldValue.serverTimestamp(),
    idEmpleador: 'ejemplo_empleador_1'
  }
];

propuestasEjemplo.forEach(propuesta => {
  db.collection('propuestas').add(propuesta);
});
```

## Comandos Firebase CLI

### Configuración inicial:
```bash
# Instalar Firebase CLI
npm install -g firebase-tools

# Login en Firebase
firebase login

# Inicializar proyecto
firebase init

# Deploy de reglas de seguridad
firebase deploy --only firestore:rules

# Deploy de índices
firebase deploy --only firestore:indexes
```

### Backup y Restore:
```bash
# Exportar datos
gcloud firestore export gs://tu-bucket/backup-$(date +%Y%m%d)

# Importar datos
gcloud firestore import gs://tu-bucket/backup-20250710
```

## Monitoreo y Mantenimiento

### Queries útiles para administración:
```javascript
// Contar propuestas por estado
db.collection('propuestas')
  .where('estado', '==', 'pendiente')
  .get()
  .then(snapshot => console.log('Pendientes:', snapshot.size));

// Usuarios activos en los últimos 7 días
const hace7Dias = new Date();
hace7Dias.setDate(hace7Dias.getDate() - 7);

db.collection('usuarios')
  .where('ultimaConexion', '>=', hace7Dias)
  .get()
  .then(snapshot => console.log('Usuarios activos:', snapshot.size));

// Limpiar datos antiguos (chats > 30 días)
const hace30Dias = new Date();
hace30Dias.setDate(hace30Dias.getDate() - 30);

db.collection('chats')
  .where('fechaCreacion', '<', hace30Dias)
  .get()
  .then(snapshot => {
    const batch = db.batch();
    snapshot.docs.forEach(doc => batch.delete(doc.ref));
    return batch.commit();
  });
```
