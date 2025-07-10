# Configuración de Firebase para Desarrollo

## Credenciales de Firebase

Para el correcto funcionamiento de la aplicación, necesitas configurar las credenciales de Firebase:

### 1. Archivo de Service Account

Crea un archivo `firebase_service_account.json` en la raíz del proyecto con las credenciales de tu proyecto de Firebase.

**⚠️ IMPORTANTE:** Este archivo **NO** debe ser subido al repositorio por motivos de seguridad.

### 2. Estructura del archivo

```json
{
  "type": "service_account",
  "project_id": "tu-proyecto-id",
  "private_key_id": "tu-private-key-id",
  "private_key": "-----BEGIN PRIVATE KEY-----\ntu-private-key\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-xxx@tu-proyecto.iam.gserviceaccount.com",
  "client_id": "tu-client-id",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-xxx%40tu-proyecto.iam.gserviceaccount.com"
}
```

### 3. Cómo obtener las credenciales

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Selecciona tu proyecto
3. Ve a "Configuración del proyecto" (icono de engranaje)
4. Pestaña "Cuentas de servicio"
5. Haz clic en "Generar nueva clave privada"
6. Guarda el archivo JSON descargado como `firebase_service_account.json`

### 4. Configuración adicional

Asegúrate de que tu proyecto de Firebase tenga:
- Authentication habilitado
- Firestore Database configurado
- Storage configurado
- Las reglas de seguridad apropiadas

## Archivos importantes

- `firebase_service_account.json` - Credenciales del servidor (NO subir al repo)
- `android/app/google-services.json` - Configuración de Android (incluido en el repo)
- `ios/Runner/GoogleService-Info.plist` - Configuración de iOS (si aplica)

## Seguridad

- **NUNCA** subas archivos de credenciales al repositorio
- Las credenciales están incluidas en `.gitignore`
- Usa variables de entorno en producción
- Rota las credenciales periódicamente
