import 'package:flutter/material.dart';
import 'package:tindevs_app/utils/themes/app_themes.dart';
import 'postulante/swipe_propuestas_screen.dart';
import 'postulante/matches_postulante_screen.dart';
import 'chat/chats_list_screen.dart';
import 'postulante/perfil_postulante_screen.dart';

class PostulanteHomeScreen extends StatefulWidget {
  const PostulanteHomeScreen({super.key});

  @override
  PostulanteHomeScreenState createState() => PostulanteHomeScreenState();
}

class PostulanteHomeScreenState extends State<PostulanteHomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const SwipePropuestasScreen(),
    const MatchesPostulanteScreen(),
    const ChatsListScreen(isPostulante: true),
    const PerfilPostulanteScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppThemes.postulanteTheme,
      child: Scaffold(
        backgroundColor: AppThemes.postulanteBackground,
        body: SafeArea(
          child: Column(
            children: [
              // Header personalizado para postulantes
              AppThemes.buildUserTypeHeader(
                title: _getPageTitle(),
                isPostulante: true,
                action: AppThemes.buildUserTypeBadge(isPostulante: true),
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
            selectedItemColor: AppThemes.postulantePrimary,
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
                icon: Icon(Icons.search),
                label: 'Explorar',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.thumb_up),
                label: 'Intereses',
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
        return 'Explorar Oportunidades';
      case 1:
        return 'Mis Intereses';
      case 2:
        return 'Mis Chats';
      case 3:
        return 'Mi Perfil';
      default:
        return 'Tindevs';
    }
  }
}
