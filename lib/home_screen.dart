import 'package:flutter/material.dart';
import 'package:flutter_application_2/Core/app_colors.dart';
import 'package:flutter_application_2/inicio_screen.dart';
import 'package:flutter_application_2/notaciones.screen.dart';
import 'package:flutter_application_2/perfil_screen.dart';
import 'package:flutter_application_2/login_page.dart';

class HomeScreen extends StatefulWidget {
  final String? username; // Para recibir el nombre de usuario

  const HomeScreen({super.key, this.username});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late bool _isLoggedIn;
  late String _username;

  final List<Widget> _screens = [
    const InicioExample(),
    const NotacionesExample(),
    const PerfilExample(),
  ];

  @override
  void initState() {
    super.initState();
    _isLoggedIn = widget.username != null;
    _username = widget.username ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 236, 236, 236),
      appBar: AppBar(
        title: _isLoggedIn 
            ? Text("Bienvenido, $_username")
            : const Text("MetroStructure"),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.background,
        actions: [
          if (!_isLoggedIn)
            IconButton(
              icon: const Icon(Icons.login),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
              tooltip: 'Iniciar sesión o registrarse',
              color: Colors.orange,
            ),
          if (_isLoggedIn)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                setState(() {
                  _isLoggedIn = false;
                  _username = '';
                });
              },
              tooltip: 'Cerrar sesión',
            ),
        ],
      ),
      body: _screens[_currentIndex],
      floatingActionButton: _isLoggedIn
          ? FloatingActionButton(
              onPressed: () {
                // Acción del FAB para usuarios logueados
              },
              child: const Icon(Icons.add),
            )
          : FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
              backgroundColor: Colors.orange,
              child: const Icon(Icons.login),
              tooltip: 'Registrarse o iniciar sesión',
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.edit), label: 'Notaciones'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}