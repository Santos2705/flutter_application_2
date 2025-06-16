import 'package:flutter/material.dart';
import 'package:flutter_application_2/Core/app_colors.dart';
import 'package:flutter_application_2/inicio_screen.dart';
import 'package:flutter_application_2/notaciones.screen.dart';
import 'package:flutter_application_2/perfil_screen.dart';
import 'package:flutter_application_2/login_page.dart';

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
  int _selectedWeek = 1;

  @override
  void initState() {
    super.initState();
    _isLoggedIn = widget.username != null;
    _username = widget.username;
    _initializeScreens();
  }

  void _initializeScreens() {
    _screens = [
      _buildScreen(
        loggedInWidget: InicioExample(
          username: _username,
          onWeekChanged: (newWeek) {
            setState(() => _selectedWeek = newWeek);
            return null;
          },
          initialWeek: _selectedWeek,
        ),
        featureName: 'tus tareas',
      ),
      _buildScreen(
        loggedInWidget: NotacionesExample(username: _username),
        featureName: 'las notaciones',
      ),
      _buildScreen(
        loggedInWidget: PerfilExample(username: _username),
        featureName: 'tu perfil',
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
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoggedIn
            ? () {
                /* Acción para usuarios logueados */
              }
            : _navigateToLogin,
        backgroundColor: _isLoggedIn ? AppColors.primary : Colors.orange,
        child: Icon(_isLoggedIn ? Icons.add : Icons.login),
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
