import 'package:flutter/material.dart';
import 'package:flutter_application_2/Core/app_colors.dart';

class ComunicacionScreen extends StatelessWidget {
  final String? username;
  final String eventoSemana = "Semana de la Ingeniería 2023";
  final String flyerUrl =
      "https://example.com/flyer.jpg"; // Reemplaza con tu URL real

  const ComunicacionScreen({super.key, this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Comunicación'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Título con signos de exclamación
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Text(
                '¡Estos son los próximos eventos!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Evento de la semana
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.tertiary,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'Evento destacado de la semana:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    eventoSemana,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton(
                    onPressed: () {
                      // Acción para agregar evento
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Agregar Evento'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Espacio para el flyer (imagen)
            Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(15),
                image: DecorationImage(
                  image: NetworkImage(flyerUrl),
                  fit: BoxFit.cover,
                  onError: (exception, stackTrace) => const Icon(Icons.error),
                ),
              ),
              child: flyerUrl.isEmpty
                  ? const Center(
                      child: Icon(Icons.image, size: 50, color: Colors.grey),
                    )
                  : null,
            ),

            const SizedBox(height: 20),

            // Texto explicativo debajo del flyer
            Text(
              '¡No te pierdas nuestros eventos importantes!',
              style: TextStyle(
                fontSize: 18,
                fontStyle: FontStyle.italic,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
