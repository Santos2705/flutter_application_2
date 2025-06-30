import 'package:flutter/material.dart';
import 'package:flutter_application_2/Core/app_colors.dart';
import 'package:flutter_application_2/Pantallas/database_helper.dart';

class ContactoScreen extends StatefulWidget {
  final String? username;

  const ContactoScreen({super.key, this.username});

  @override
  State<ContactoScreen> createState() => _ContactoScreenState();
}

class _ContactoScreenState extends State<ContactoScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mensajeController = TextEditingController();

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _mensajeController.dispose();
    super.dispose();
  }

  Future<void> _enviarMensaje() async {
    if (_formKey.currentState!.validate()) {
      try {
        await DatabaseHelper.instance.insertMensajeContacto(
          _nombreController.text,
          _emailController.text,
          _mensajeController.text,
        );

        // Mostrar notificación de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mensaje enviado con éxito'),
            backgroundColor: Colors.green,
          ),
        );

        // Limpiar los campos
        _nombreController.clear();
        _emailController.clear();
        _mensajeController.clear();
      } catch (e) {
        // Mostrar notificación de error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar el mensaje: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 236, 236, 236),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
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
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Tu nombre',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa tu nombre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Tu correo electrónico',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa tu correo electrónico';
                  }
                  if (!value.contains('@')) {
                    return 'Por favor ingresa un correo electrónico válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _mensajeController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Tu mensaje',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa un mensaje';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _enviarMensaje,
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