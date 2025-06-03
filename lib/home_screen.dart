import 'package:flutter/material.dart';
import 'package:flutter_application_2/Core/app_colors.dart';
import 'package:flutter_application_2/inicio_screen.dart';
import 'package:flutter_application_2/notaciones.screen.dart';
import 'package:flutter_application_2/perfil_screen.dart';

class MetroStructHome extends StatefulWidget {
  const MetroStructHome({super.key});

  @override
  State<MetroStructHome> createState() => _MetroStructHomeState();
}

class _MetroStructHomeState extends State<MetroStructHome> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const InicioExample(), // Pantalla 1
    const NotacionesExample(), // Pantalla 2
    const PerfilExample(), // Pantalla 3
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 236, 236, 236),
      appBar: AppBar(
        title: const Text("MetroStructure"),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.background,
      ),
      body: _screens[_currentIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
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
