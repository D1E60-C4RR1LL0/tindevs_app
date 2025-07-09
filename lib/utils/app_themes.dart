import 'package:flutter/material.dart';

class AppThemes {
  // Colores para Postulantes (Azul profesional - representa búsqueda y oportunidades)
  static const Color postulanteAccent = Color(0xFF1E88E5); // Azul profesional
  static const Color postulantePrimary = Color(0xFF0D47A1); // Azul oscuro
  static const Color postulanteSecondary = Color(0xFF42A5F5); // Azul claro
  static const Color postulanteBackground = Color(0xFFF3F8FF); // Azul muy claro
  static const Color postulanteCard = Color(0xFFFFFFFF); // Blanco puro
  static const Color postulanteGradientStart = Color(0xFF1976D2);
  static const Color postulanteGradientEnd = Color(0xFF1E88E5);

  // Colores para Empleadores (Verde profesional - representa crecimiento y empresa)
  static const Color empleadorAccent = Color(0xFF43A047); // Verde profesional
  static const Color empleadorPrimary = Color(0xFF1B5E20); // Verde oscuro
  static const Color empleadorSecondary = Color(0xFF66BB6A); // Verde claro
  static const Color empleadorBackground = Color(0xFFF1F8E9); // Verde muy claro
  static const Color empleadorCard = Color(0xFFFFFFFF); // Blanco puro
  static const Color empleadorGradientStart = Color(0xFF388E3C);
  static const Color empleadorGradientEnd = Color(0xFF43A047);

  // Colores para Admin (Púrpura profesional - representa autoridad)
  static const Color adminAccent = Color(0xFF7B1FA2);
  static const Color adminPrimary = Color(0xFF4A148C);
  static const Color adminSecondary = Color(0xFF9C27B0);
  static const Color adminBackground = Color(0xFFF8F3FF);

  // Tema para Postulantes
  static ThemeData postulanteTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: postulanteAccent,
      primary: postulantePrimary,
      secondary: postulanteSecondary,
      surface: postulanteBackground,
      surfaceContainerHighest: postulanteCard,
    ),
    scaffoldBackgroundColor: postulanteBackground,
    appBarTheme: AppBarTheme(
      backgroundColor: postulantePrimary,
      foregroundColor: Colors.white,
      elevation: 2,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardTheme(
      color: postulanteCard,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: postulanteAccent,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: postulantePrimary,
      unselectedItemColor: Colors.grey[600],
      elevation: 8,
      type: BottomNavigationBarType.fixed,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: postulanteAccent,
      foregroundColor: Colors.white,
    ),
  );

  // Tema para Empleadores
  static ThemeData empleadorTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: empleadorAccent,
      primary: empleadorPrimary,
      secondary: empleadorSecondary,
      surface: empleadorBackground,
      surfaceContainerHighest: empleadorCard,
    ),
    scaffoldBackgroundColor: empleadorBackground,
    appBarTheme: AppBarTheme(
      backgroundColor: empleadorPrimary,
      foregroundColor: Colors.white,
      elevation: 2,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardTheme(
      color: empleadorCard,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: empleadorAccent,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: empleadorPrimary,
      unselectedItemColor: Colors.grey[600],
      elevation: 8,
      type: BottomNavigationBarType.fixed,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: empleadorAccent,
      foregroundColor: Colors.white,
    ),
  );

  // Gradientes para efectos visuales
  static LinearGradient postulanteGradient = LinearGradient(
    colors: [postulanteGradientStart, postulanteGradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient empleadorGradient = LinearGradient(
    colors: [empleadorGradientStart, empleadorGradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Widgets de decoración con gradientes
  static Widget buildGradientContainer({
    required Widget child,
    required bool isPostulante,
    double? height,
    BorderRadius? borderRadius,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: isPostulante ? postulanteGradient : empleadorGradient,
        borderRadius: borderRadius ?? BorderRadius.circular(12),
      ),
      child: child,
    );
  }

  // Header personalizado para cada tipo de usuario
  static Widget buildUserTypeHeader({
    required String title,
    required bool isPostulante,
    Widget? action,
  }) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isPostulante ? postulanteGradient : empleadorGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isPostulante ? 'Zona Postulante' : 'Zona Empleador',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (action != null) action,
          ],
        ),
      ),
    );
  }

  // Badge para identificar tipo de usuario
  static Widget buildUserTypeBadge({
    required bool isPostulante,
    double? size,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: (size ?? 1) * 12,
        vertical: (size ?? 1) * 6,
      ),
      decoration: BoxDecoration(
        color: isPostulante ? postulanteAccent : empleadorAccent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPostulante ? Icons.person_search : Icons.business,
            color: Colors.white,
            size: (size ?? 1) * 16,
          ),
          SizedBox(width: (size ?? 1) * 6),
          Text(
            isPostulante ? 'Postulante' : 'Empleador',
            style: TextStyle(
              color: Colors.white,
              fontSize: (size ?? 1) * 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
