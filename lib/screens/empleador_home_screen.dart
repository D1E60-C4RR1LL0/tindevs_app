import 'package:flutter/material.dart';
import 'crear_propuesta_screen.dart';
import 'matches_empleador_screen.dart';
import 'perfil_empleador_screen.dart';

class EmpleadorHomeScreen extends StatefulWidget {
  const EmpleadorHomeScreen({super.key});

  @override
  _EmpleadorHomeScreenState createState() => _EmpleadorHomeScreenState();
}

class _EmpleadorHomeScreenState extends State<EmpleadorHomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const CrearPropuestaScreen(),
    const MatchesEmpleadorScreen(),
    const PerfilEmpleadorScreen(),
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
            icon: Icon(Icons.work),
            label: 'Propuestas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
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
