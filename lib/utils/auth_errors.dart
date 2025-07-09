/// Utilidad para convertir códigos de error de Firebase Auth a mensajes personalizados en español
class AuthErrors {
  /// Convierte un código de error de Firebase Auth a un mensaje personalizado
  static String getCustomErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'invalid-email':
        return 'El formato del correo electrónico no es válido.';
      case 'wrong-password':
        return 'La contraseña ingresada es incorrecta.';
      case 'user-not-found':
        return 'No existe una cuenta con este correo electrónico.';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada.';
      case 'too-many-requests':
        return 'Demasiados intentos fallidos. Intenta nuevamente más tarde.';
      case 'operation-not-allowed':
        return 'Operación no permitida. Contacta al soporte técnico.';
      case 'invalid-credential':
        return 'Las credenciales proporcionadas son incorrectas.';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con este correo electrónico.';
      case 'weak-password':
        return 'La contraseña debe tener al menos 6 caracteres.';
      case 'network-request-failed':
        return 'Error de conexión. Verifica tu conexión a internet.';
      case 'requires-recent-login':
        return 'Por seguridad, debes iniciar sesión nuevamente.';
      case 'credential-already-in-use':
        return 'Estas credenciales ya están en uso por otra cuenta.';
      case 'invalid-verification-code':
        return 'El código de verificación es inválido.';
      case 'invalid-verification-id':
        return 'El ID de verificación es inválido.';
      case 'missing-verification-code':
        return 'Falta el código de verificación.';
      case 'missing-verification-id':
        return 'Falta el ID de verificación.';
      case 'account-exists-with-different-credential':
        return 'Ya existe una cuenta con este correo pero con un método de inicio de sesión diferente.';
      case 'timeout':
        return 'La operación ha expirado. Intenta nuevamente.';
      case 'missing-email':
        return 'Debes proporcionar un correo electrónico.';
      case 'missing-password':
        return 'Debes proporcionar una contraseña.';
      case 'internal-error':
        return 'Error interno del servidor. Intenta nuevamente más tarde.';
      case 'invalid-api-key':
        return 'Error de configuración de la aplicación.';
      case 'app-deleted':
        return 'La aplicación ha sido eliminada del servidor.';
      case 'app-not-authorized':
        return 'La aplicación no está autorizada para usar Firebase.';
      case 'argument-error':
        return 'Argumento inválido proporcionado.';
      case 'invalid-tenant-id':
        return 'ID de tenant inválido.';
      case 'multi-factor-info-not-found':
        return 'Información de autenticación multifactor no encontrada.';
      case 'multi-factor-auth-required':
        return 'Se requiere autenticación multifactor.';
      case 'maximum-second-factor-count-exceeded':
        return 'Se ha excedido el número máximo de factores de autenticación secundarios.';
      case 'unsupported-first-factor':
        return 'Factor de autenticación primario no soportado.';
      case 'unverified-email':
        return 'Debes verificar tu correo electrónico antes de continuar.';
      default:
        return 'Ha ocurrido un error inesperado. Verifica tus datos e intenta nuevamente.';
    }
  }
  
  /// Valida si un email tiene un formato válido
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }
  
  /// Valida si una contraseña cumple con los requisitos mínimos
  static String? validatePassword(String password) {
    if (password.isEmpty) {
      return 'La contraseña es obligatoria.';
    }
    if (password.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres.';
    }
    return null; // Contraseña válida
  }
  
  /// Valida si un email cumple con los requisitos
  static String? validateEmail(String email) {
    if (email.isEmpty) {
      return 'El correo electrónico es obligatorio.';
    }
    if (!isValidEmail(email)) {
      return 'El formato del correo electrónico no es válido.';
    }
    return null; // Email válido
  }
  
  /// Valida campos antes del login
  static String? validateLoginFields(String email, String password) {
    final emailError = validateEmail(email);
    if (emailError != null) return emailError;
    
    final passwordError = validatePassword(password);
    if (passwordError != null) return passwordError;
    
    return null; // Todos los campos son válidos
  }
}
