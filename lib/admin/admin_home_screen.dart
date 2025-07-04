import 'package:flutter/material.dart';
import 'package:tindevs_app/admin/manage_users_screen.dart';
import 'package:tindevs_app/admin/users_screen.dart';
import 'package:tindevs_app/admin/proposals_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  @override
  _AdminHomeScreenState createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [UsersScreen(), ProposalsScreen()];

  void _onDrawerItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      Navigator.pop(context); // Cierra el Drawer
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Panel Admin - Tindevs')),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                'Panel Admin',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Certificaciones (Postulantes)'),
              onTap: () => _onDrawerItemTapped(0),
            ),
            ListTile(
              leading: Icon(Icons.business),
              title: Text('Propuestas de Empleo'),
              onTap: () => _onDrawerItemTapped(1),
            ),
            ListTile(
              leading: Icon(Icons.manage_accounts),
              title: Text('Gestionar Cuentas'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ManageUsersScreen()),
                );
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Cerrar sesión'),
              onTap: () async {
                // Cerrar sesión y volver al login
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/', (route) => false);
              },
            ),
          ],
        ),
      ),
      body: _screens[_selectedIndex],
    );
  }
}
