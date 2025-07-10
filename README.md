# 🚀 TinDevs App - Plataforma de Matching Laboral para Desarrolladores

Una aplicación Flutter que conecta desarrolladores con empleadores, proporcionando un sistema de matching basado en ubicación, habilidades y experiencia.

## 📱 Descripción del Proyecto

TinDevs es una plataforma de matching laboral diseñada específicamente para el sector tecnológico, donde:
- **Empleadores** pueden publicar propuestas de trabajo
- **Desarrolladores** pueden postular a ofertas que coincidan con su perfil
- **Administradores** validan y gestionan las propuestas
- Sistema de **geolocalización** para matching por proximidad
- **Sistema de calificaciones** bidireccional empleador-postulante

### Ejecutar la Aplicación

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

## 👥 Equipo de Desarrollo

- **Desarrollador Principal**: D1E60-C4RR1LL0
- **Contacto**: di.carrillog@duocuc.cl

---

**🎯 TinDevs - Conectando talento tecnológico con oportunidades laborales**
