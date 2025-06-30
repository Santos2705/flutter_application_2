import 'package:flutter/material.dart';
import 'package:flutter_application_2/Core/app_colors.dart';

class ContactoScreen extends StatefulWidget {
  final String? username;

  const ContactoScreen({super.key, this.username});

  @override
  State<ContactoScreen> createState() => _ContactoScreenState();
}

class _ContactoScreenState extends State<ContactoScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 236, 236, 236),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.username != null) ...[
              Text(
                'Hola, ${widget.username}!',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 20),
            ],
            const Text(
              'Contáctanos',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildContactCard(
              icon: Icons.email,
              title: 'Correo Electrónico',
              subtitle: 'contacto@metrostructure.com',
            ),
            const SizedBox(height: 15),
            _buildContactCard(
              icon: Icons.phone,
              title: 'Teléfono',
              subtitle: '0212-2403260',
            ),
            const SizedBox(height: 15),
            _buildContactCard(
              icon: Icons.location_on,
              title: 'Dirección',
              subtitle: 'Ditribuidor metropolitano',
            ),
            const SizedBox(height: 30),
            const Text(
              'Horario de Atención:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Lunes a Viernes: 8:00 AM - 6:00 PM\nSábados: 10:00 AM - 2:00 PM',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            const Text(
              'Envíanos un mensaje:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Tu nombre',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Tu correo electrónico',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextFormField(
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Tu mensaje',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Lógica para enviar el mensaje
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                'Enviar Mensaje',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Row(
          children: [
            Icon(icon, size: 30, color: AppColors.primary),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(subtitle, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
