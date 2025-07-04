import 'package:flutter/material.dart';
import 'swipe_propuestas_screen.dart';
import 'matches_postulante_screen.dart';
import 'perfil_postulante_screen.dart';

class PostulanteHomeScreen extends StatefulWidget {
  const PostulanteHomeScreen({super.key});

  @override
  _PostulanteHomeScreenState createState() => _PostulanteHomeScreenState();
}

class _PostulanteHomeScreenState extends State<PostulanteHomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const SwipePropuestasScreen(),
    const MatchesPostulanteScreen(),
    const PerfilPostulanteScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: _pages[_selectedIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: theme.colorScheme.secondary.withValues(alpha: 0.5),
        backgroundColor: theme.scaffoldBackgroundColor,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Matches',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
