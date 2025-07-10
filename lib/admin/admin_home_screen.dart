import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_theme.dart';
import 'manage_users_screen.dart';
import 'users_screen.dart';
import 'proposals_screen.dart';
import '../screens/auth/welcome_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  AdminHomeScreenState createState() => AdminHomeScreenState();
}

class AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;
  Map<String, dynamic> _stats = {};
  bool _isLoadingStats = true;

  final List<Widget> _screens = [
    const UsersScreen(),
    const ProposalsScreen(),
  ];

  final List<String> _screenTitles = [
    'Gestión de Usuarios',
    'Gestión de Propuestas',
  ];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final usuarios = await FirebaseFirestore.instance.collection('usuarios').get();
      final propuestas = await FirebaseFirestore.instance.collection('propuestas').get();
      
      int postulantes = 0;
      int empleadores = 0;
      int certificacionesPendientes = 0;
      
      for (var doc in usuarios.docs) {
        final data = doc.data();
        if (data['rol'] == 'postulante') {
          postulantes++;
          final certificaciones = data['certificaciones'] as List<dynamic>? ?? [];
          for (var cert in certificaciones) {
            if (cert is Map && cert['estado'] == 'pendiente') {
              certificacionesPendientes++;
            }
          }
        } else if (data['rol'] == 'empleador') {
          empleadores++;
        }
      }
      
      int propuestasPendientes = 0;
      int propuestasAprobadas = 0;
      
      for (var doc in propuestas.docs) {
        final data = doc.data();
        if (data['estadoValidacion'] == 'pendiente') {
          propuestasPendientes++;
        } else if (data['estadoValidacion'] == 'aprobada') {
          propuestasAprobadas++;
        }
      }
      
      setState(() {
        _stats = {
          'totalUsuarios': usuarios.size,
          'postulantes': postulantes,
          'empleadores': empleadores,
          'totalPropuestas': propuestas.size,
          'propuestasPendientes': propuestasPendientes,
          'propuestasAprobadas': propuestasAprobadas,
          'certificacionesPendientes': certificacionesPendientes,
        };
        _isLoadingStats = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingStats = false;
      });
    }
  }

  void _onDrawerItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      Navigator.pop(context); // Cierra el Drawer
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_screenTitles[_selectedIndex]),
        backgroundColor: AdminTheme.primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
            tooltip: 'Actualizar estadísticas',
          ),
        ],
      ),
      drawer: _buildModernDrawer(context, user),
      body: Column(
        children: [
          if (_selectedIndex == 0) _buildStatsOverview(),
          Expanded(child: _screens[_selectedIndex]),
        ],
      ),
    );
  }

  Widget _buildModernDrawer(BuildContext context, User? user) {
    return Drawer(
      child: Column(
        children: [
          Container(
            height: 200,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AdminTheme.primaryColor, AdminTheme.primaryDark],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.admin_panel_settings,
                    size: 40,
                    color: AdminTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: AdminTheme.spacingM),
                const Text(
                  'Panel de Administración',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (user?.email != null)
                  Text(
                    user!.email!,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AdminTheme.spacingM),
              children: [
                _buildDrawerItem(
                  icon: Icons.people,
                  title: 'Gestión de Usuarios',
                  subtitle: 'Certificaciones y cuentas',
                  isSelected: _selectedIndex == 0,
                  onTap: () => _onDrawerItemTapped(0),
                ),
                _buildDrawerItem(
                  icon: Icons.business_center,
                  title: 'Gestión de Propuestas',
                  subtitle: 'Validar ofertas de empleo',
                  isSelected: _selectedIndex == 1,
                  onTap: () => _onDrawerItemTapped(1),
                ),
                const Divider(height: AdminTheme.spacingL),
                _buildDrawerItem(
                  icon: Icons.manage_accounts,
                  title: 'Gestionar Cuentas',
                  subtitle: 'Administrar usuarios',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ManageUsersScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AdminTheme.spacingM),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: _buildDrawerItem(
              icon: Icons.logout,
              title: 'Cerrar Sesión',
              subtitle: 'Salir del panel',
              textColor: AdminTheme.errorColor,
              onTap: _signOut,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    String? subtitle,
    bool isSelected = false,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AdminTheme.spacingS,
        vertical: AdminTheme.spacingXS,
      ),
      decoration: BoxDecoration(
        color: isSelected ? AdminTheme.primaryColor.withValues(alpha: 0.1) : null,
        borderRadius: BorderRadius.circular(AdminTheme.radiusM),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? AdminTheme.primaryColor : textColor,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? AdminTheme.primaryColor : textColor,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(
                  color: (isSelected ? AdminTheme.primaryColor : textColor)?.withValues(alpha: 0.7) ?? AdminTheme.textSecondary,
                  fontSize: 12,
                ),
              )
            : null,
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AdminTheme.radiusM),
        ),
      ),
    );
  }

  Widget _buildStatsOverview() {
    if (_isLoadingStats) {
      return Container(
        height: 120,
        padding: const EdgeInsets.all(AdminTheme.spacingM),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AdminTheme.spacingM),
      child: Row(
        children: [
          Expanded(
            child: AdminTheme.buildStatsCard(
              title: 'Total Usuarios',
              value: '${_stats['totalUsuarios'] ?? 0}',
              icon: Icons.people,
              color: AdminTheme.primaryColor,
            ),
          ),
          const SizedBox(width: AdminTheme.spacingM),
          Expanded(
            child: AdminTheme.buildStatsCard(
              title: 'Propuestas Pendientes',
              value: '${_stats['propuestasPendientes'] ?? 0}',
              icon: Icons.pending_actions,
              color: AdminTheme.warningColor,
            ),
          ),
          const SizedBox(width: AdminTheme.spacingM),
          Expanded(
            child: AdminTheme.buildStatsCard(
              title: 'Certificaciones Pendientes',
              value: '${_stats['certificacionesPendientes'] ?? 0}',
              icon: Icons.verified,
              color: AdminTheme.accentColor,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cerrar sesión: $e'),
            backgroundColor: AdminTheme.errorColor,
          ),
        );
      }
    }
  }
}
