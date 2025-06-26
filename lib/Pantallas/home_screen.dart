import 'package:flutter/material.dart';
import 'package:flutter_application_2/Core/app_colors.dart';
import 'package:flutter_application_2/Pantallas/inicio_screen.dart';
import 'package:flutter_application_2/Pantallas/notaciones.screen.dart';
import 'package:flutter_application_2/Pantallas/perfil_screen.dart';
import 'package:flutter_application_2/Pantallas/login_page.dart';
import 'package:flutter_application_2/Pantallas/comunicacion_screen.dart';
import 'package:flutter_application_2/Pantallas/contacto_screen.dart';

class HomeScreen extends StatefulWidget {
  final String? username;

  const HomeScreen({super.key, this.username});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late bool _isLoggedIn;
  late String? _username;
  late List<Widget> _screens;
  late int _selectedWeek;

  int _getCurrentAcademicWeek() {
    final now = DateTime.now();
    if (now.isBefore(DateTime(2025, 4, 20))) return 1;
    if (now.isAfter(DateTime(2025, 7, 12))) return 12;

    final startDate = DateTime(2025, 4, 20);
    final daysDifference = now.difference(startDate).inDays;
    return (daysDifference ~/ 7) + 1;
  }

  @override
  void initState() {
    super.initState();
    _isLoggedIn = widget.username != null;
    _username = widget.username;
    _selectedWeek = _getCurrentAcademicWeek();
    _initializeScreens();
  }

  void _initializeScreens() {
    _screens = [
      _buildScreen(
        loggedInWidget: InicioExample(
          username: _username,
          onWeekChanged: (newWeek) {
            setState(() => _selectedWeek = newWeek);
          },
          initialWeek: _selectedWeek,
        ),
        featureName: 'tus tareas',
      ),
      _buildScreen(
        loggedInWidget: NotacionesExample(username: _username),
        featureName: 'las anotaciones',
      ),
      _buildScreen(
        loggedInWidget: ComunicacionScreen(username: _username),
        featureName: 'la comunicación',
      ),
      _buildScreen(
        loggedInWidget: PerfilExample(username: _username),
        featureName: 'tu perfil',
      ),
      _buildScreen(
        loggedInWidget: ContactoScreen(
          username: _username,
        ), // Nueva pantalla de contacto
        featureName: 'el contacto',
      ),
    ];
  }

  Widget _buildScreen({
    required Widget loggedInWidget,
    required String featureName,
  }) {
    return _isLoggedIn
        ? loggedInWidget
        : _LoginRequiredScreen(
            featureName: featureName,
            onLoginPressed: _navigateToLogin,
          );
  }

  Future<void> _navigateToLogin() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );

    if (result != null && result is Map) {
      _updateLoginStatus(true, username: result['username']);
    }
  }

  void _updateLoginStatus(bool isLoggedIn, {String? username}) {
    setState(() {
      _isLoggedIn = isLoggedIn;
      _username = username;
      _selectedWeek = _getCurrentAcademicWeek();
      _initializeScreens();
    });
  }

  void _logout() {
    setState(() {
      _isLoggedIn = false;
      _username = null;
      _initializeScreens();
    });
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
          IconButton(
            icon: Icon(_isLoggedIn ? Icons.logout : Icons.login),
            onPressed: _isLoggedIn ? _logout : _navigateToLogin,
            tooltip: _isLoggedIn ? 'Cerrar sesión' : 'Iniciar sesión',
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.edit), label: 'Anotaciones'),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Comunicación',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
          BottomNavigationBarItem(
            icon: Icon(Icons.contact_phone),
            label: 'Contacto',
          ),
        ],
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}

class _LoginRequiredScreen extends StatelessWidget {
  final String featureName;
  final VoidCallback onLoginPressed;

  const _LoginRequiredScreen({
    required this.featureName,
    required this.onLoginPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.account_circle, size: 60, color: Colors.orange),
          const SizedBox(height: 20),
          Text(
            'Inicia sesión para acceder a $featureName',
            style: const TextStyle(fontSize: 18, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: onLoginPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
            child: const Text('Iniciar Sesión'),
          ),
        ],
      ),
    );
  }
}
