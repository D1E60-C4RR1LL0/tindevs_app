# 🚀 TinDevs App - Plataforma de Matching Laboral para Desarrolladores

Una aplicación Flutter que conecta desarrolladores con empleadores, proporcionando un sistema de matching basado en ubicación, habilidades y experiencia.

## 📱 Descripción del Proyecto

TinDevs es una plataforma de matching laboral diseñada específicamente para el sector tecnológico, donde:
- **Empleadores** pueden publicar propuestas de trabajo
- **Desarrolladores** pueden postular a ofertas que coincidan con su perfil
- **Administradores** validan y gestionan las propuestas
- Sistema de **geolocalización** para matching por proximidad
- **Sistema de calificaciones** bidireccional empleador-postulante

## 🏗️ Arquitectura de la Aplicación

### Tipos de Usuario
- **Postulantes**: Desarrolladores buscando oportunidades
- **Empleadores**: Empresas publicando ofertas de trabajo  
- **Administradores**: Gestión y validación de contenido

### Tecnologías Utilizadas
- **Frontend**: Flutter 3.x
- **Backend**: Firebase (Firestore, Auth, Storage)
- **Geolocalización**: Plugin geolocator + datos de comunas chilenas
- **Autenticación**: Firebase Authentication
- **Almacenamiento**: Firebase Storage para documentos

## 🛠️ Instalación y Configuración

### Prerrequisitos
- Flutter SDK (3.0 o superior)
- Dart SDK (2.17 o superior)
- Android Studio / VS Code
- Cuenta de Firebase

### 1. Clonar el Repositorio
```bash
git clone https://github.com/D1E60-C4RR1LL0/tindevs_app.git
cd tindevs_app
```

### 2. Instalar Dependencias
```bash
flutter pub get
```

### 3. Configuración de Firebase

#### Crear proyecto Firebase:
1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Crear nuevo proyecto llamado "tindevs" (o el nombre que prefieras)
3. Habilitar Authentication, Firestore y Storage

#### Configurar credenciales:
4. **Service Account** (para admin): 
   - Ir a "Configuración → Cuentas de servicio"
   - Generar nueva clave privada
   - Guardar como `firebase_service_account.json` en la raíz del proyecto
   - ⚠️ **NO subir este archivo al repositorio**

5. **Android Configuration**:
   - El archivo `android/app/google-services.json` ya está incluido
   - Si usas tu propio proyecto, reemplázalo con el tuyo

#### Estructura de Firebase requerida:
```
Collections:
├── usuarios (users)
├── propuestas (job proposals)
├── matches (user matches)
├── calificaciones (ratings)
├── notificaciones (notifications)
├── intereses (interests)
└── chats (messaging)
```

### 4. Ejecutar la Aplicación

#### Modo Desarrollo (Postulantes/Empleadores):
```bash
flutter run
```

#### Modo Administrador:
```bash
flutter run lib/main_admin.dart
```

#### Ejecutar en dispositivo específico:
```bash
# Ver dispositivos disponibles
flutter devices

# Ejecutar en dispositivo específico
flutter run -d <device_id>
```

## 🎯 Funcionalidades Principales

### 👨‍💼 Para Empleadores
- ✅ Registro y autenticación
- ✅ Crear propuestas de trabajo con:
  - Selección de región y comuna
  - Descripción detallada del cargo
  - Requisitos (carrera, experiencia, certificaciones)
  - Documento de validación empresarial
- ✅ Gestión de propuestas (editar, eliminar)
- ✅ Ver candidatos interesados
- ✅ Sistema de chat con postulantes
- ✅ Calificar postulantes

### 👩‍💻 Para Postulantes (Desarrolladores)
- ✅ Registro con perfil completo
- ✅ Explorar propuestas por swipe
- ✅ Ver distancia a cada propuesta
- ✅ Mostrar interés en propuestas
- ✅ Chat con empleadores
- ✅ Calificar empleadores
- ✅ Gestión de perfil con certificaciones

### 🔧 Para Administradores
- ✅ Dashboard de gestión completa
- ✅ Validar propuestas de empleadores
- ✅ Visualizar documentos de validación empresarial
- ✅ Gestionar usuarios (activar/desactivar)
- ✅ Sistema de solicitud de documentos
- ✅ Eliminar contenido inapropiado

## 🎨 Características Destacadas

### 📍 Geolocalización Inteligente
- Cálculo de distancias usando fórmula de Haversine
- Base de datos de comunas chilenas con coordenadas
- Filtrado por proximidad geográfica
- Formato amigable de distancias ("< 1 km", "15.2 km")

### 📄 Gestión de Documentos
- Subida de documentos de validación empresarial
- Visualización de documentos en nueva pestaña
- Sistema de solicitud de documentos faltantes
- Validación manual por administradores

### ⭐ Sistema de Calificaciones
- Calificaciones bidireccionales (1-5 estrellas)
- Promedio automático de calificaciones
- Comentarios opcionales
- Histórico de calificaciones

### 💬 Sistema de Chat
- Chat en tiempo real entre matches
- Identificación clara de roles (empleador/postulante)
- Mensajes persistentes en Firestore

## 🚀 Comandos de Desarrollo

### Análisis y Limpieza de Código
```bash
# Análisis de código
flutter analyze

# Formatear código
flutter format .

# Verificar dependencias
flutter doctor
```

### Testing
```bash
# Ejecutar tests
flutter test

# Tests con coverage
flutter test --coverage
```

### Build para Producción
```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# Web
flutter build web
```

## 📱 Navegación de la App

### Flujo de Usuario - Postulante
1. **Splash Screen** → **Login/Register**
2. **Completar Perfil** (primera vez)
3. **Home Swipe** → Explorar propuestas
4. **Matches** → Ver conexiones realizadas
5. **Chat** → Comunicación con empleadores
6. **Perfil** → Gestionar información personal

### Flujo de Usuario - Empleador
1. **Splash Screen** → **Login/Register**
2. **Crear Propuesta** → Publicar oferta de trabajo
3. **Gestionar Propuestas** → Ver y editar propuestas
4. **Candidatos** → Ver postulantes interesados
5. **Chat** → Comunicación con postulantes

### Dashboard Administrativo
1. **Login Admin** → `flutter run lib/main_admin.dart`
2. **Gestión de Propuestas** → Validar/rechazar propuestas
3. **Gestión de Usuarios** → Administrar cuentas
4. **Visualización de Documentos** → Revisar validaciones

## 🔒 Configuración de Seguridad

### Reglas de Firestore (firestore.rules)
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Solo usuarios autenticados pueden leer/escribir sus propios datos
    match /usuarios/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Propuestas: empleadores pueden crear, todos pueden leer las aprobadas
    match /propuestas/{proposalId} {
      allow read: if resource.data.estado == 'aprobada';
      allow create, update: if request.auth != null;
    }
    
    // Matches: solo los participantes pueden acceder
    match /matches/{matchId} {
      allow read, write: if request.auth != null && 
        (request.auth.uid in resource.data.participantes);
    }
  }
}
```

### Variables de Entorno
- Credenciales de Firebase en `.env` para producción
- Configuración diferente por ambiente (dev, staging, prod)

## 🐛 Troubleshooting

### Problemas Comunes

#### Error de Firebase
```bash
# Si hay problemas de configuración de Firebase
flutter clean
flutter pub get
```

#### Error de dependencias
```bash
# Resolver conflictos de dependencias
flutter pub deps
flutter pub upgrade
```

#### Error de Android
```bash
# Limpiar cache de Android
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

### Logs y Debugging
```bash
# Ver logs detallados
flutter run --verbose

# Debug en modo release
flutter run --release --verbose
```

## 📊 Estado del Proyecto

### ✅ Completado
- Sistema de autenticación completo
- Funcionalidades core para todos los tipos de usuario
- Dashboard administrativo funcional
- Sistema de geolocalización
- Chat en tiempo real
- Sistema de calificaciones
- Gestión de documentos
- Limpieza completa de warnings/errores

### 🔄 En Desarrollo
- Notificaciones push
- Mejoras de UI/UX
- Sistema de reportes avanzados
- Integración con servicios externos

## 🤝 Contribuciones

Para contribuir al proyecto:

1. Fork el repositorio
2. Crear branch para feature: `git checkout -b feature/nueva-funcionalidad`
3. Commit cambios: `git commit -m 'Agregar nueva funcionalidad'`
4. Push al branch: `git push origin feature/nueva-funcionalidad`
5. Crear Pull Request

## 📄 Licencia

Este proyecto está bajo la Licencia MIT. Ver `LICENSE` para más detalles.

## 👥 Equipo de Desarrollo

- **Desarrollador Principal**: D1E60-C4RR1LL0
- **Contacto**: di.carrillog@duocuc.cl

---

**🎯 TinDevs - Conectando talento tecnológico con oportunidades laborales**
