import 'package:flutter/material.dart';
import '../../utils/themes/app_themes.dart';
import 'gestionar_propuestas_screen.dart';
import 'interesados_screen.dart';
import '../chat/chats_list_screen.dart';
import 'perfil_empleador_screen.dart';

class EmpleadorHomeScreen extends StatefulWidget {
  const EmpleadorHomeScreen({super.key});

  @override
  EmpleadorHomeScreenState createState() => EmpleadorHomeScreenState();
}

class EmpleadorHomeScreenState extends State<EmpleadorHomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const GestionarPropuestasScreen(),
    const InteresadosScreen(),
    const ChatsListScreen(isPostulante: false),
    const PerfilEmpleadorScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppThemes.empleadorTheme,
      child: Scaffold(
        backgroundColor: AppThemes.empleadorBackground,
        body: SafeArea(
          child: Column(
            children: [
              // Header personalizado para empleadores
              AppThemes.buildUserTypeHeader(
                title: _getPageTitle(),
                isPostulante: false,
                action: AppThemes.buildUserTypeBadge(isPostulante: false),
              ),
              // Contenido principal
              Expanded(child: _pages[_selectedIndex]),
            ],
          ),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            selectedItemColor: AppThemes.empleadorPrimary,
            unselectedItemColor: Colors.grey[600],
            backgroundColor: Colors.white,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.work_outline),
                label: 'Propuestas',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people_outline),
                label: 'Candidatos',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.chat),
                label: 'Chats',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Perfil',
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getPageTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Gestionar Ofertas';
      case 1:
        return 'Candidatos Interesados';
      case 2:
        return 'Mis Chats';
      case 3:
        return 'Mi Empresa';
      default:
        return 'Tindevs';
    }
  }
}
