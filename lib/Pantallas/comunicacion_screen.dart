import 'package:flutter/material.dart';
import 'package:flutter_application_2/Core/app_colors.dart';

class ComunicacionScreen extends StatelessWidget {
  final String? username;
  final List<Evento> eventos = [
    Evento(
      titulo: "Preinscripción del Servicio Comunitario",
      descripcion: "Facultad de Humanidades - Departamento de Humanidades y Ciencias de la Educación\n\n"
          "¡Elige tu proyecto y escanea el QR!\n\n"
          "Requisitos:\n"
          "• 90 créditos aprobados\n"
          "• Asignatura prelatoria aprobada (FGEDI08 o FGEDI09) hasta el trimestre 2425-3\n"
          "• O el Taller de Inducción (FPTDI01) aprobado",
      fecha: "Preinscripción: 25 de junio de 2025 (9:00 a.m. a 5:00 p.m.)\n"
          "Inscripción: 15 de julio de 2025",
      color: Colors.blue[50]!,
      imagen: "assets/servicio.jpeg",
      proyectos: [
        "Creciendo juntos - BPTHE71-4",
        "Redes para el aprendizaje - BPTHE71-7",
        "Transformando vidas - BPTHE71-8 (oferta de 120 horas en 5 semanas)"
      ],
    ),
    Evento(
      titulo: "Inscripciones Periodo Intensivo",
      descripcion: "OFERTA:\n"
          "• Asignatura 2324-1\n"
          "• Electivas 2324-1",
      fecha: "3 de Julio 2023",
      color: Colors.green[50]!,
      imagen: "assets/intensivo.jpeg",
    ),
    Evento(
      titulo: "Bootcamp Desarrollo de Videojuegos",
      descripcion: "Contenidos digitales para el Metaverso:\n"
          "• Introducción a la Realidad Virtual\n"
          "• Desarrollo de Entornos Tridimensionales interactivos\n"
          "• Modelado artístico 3D",
      fecha: "Del 15-07 hasta 15-08 de 2025",
      color: Colors.purple[50]!,
      imagen: "assets/bootcamp.jpeg",
    ),
  ];

  ComunicacionScreen({super.key, this.username});

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: Text(
                'Próximos Eventos Importantes',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            Column(
              children: eventos.map((evento) => _buildEventBox(context, evento)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventBox(BuildContext context, Evento evento) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: evento.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.event, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    evento.titulo,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            if (evento.imagen != null) ...[
              GestureDetector(
                onTap: () => _showFullImage(context, evento.imagen!),
                child: Hero(
                  tag: evento.imagen!,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      evento.imagen!,
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            
            Text(
              evento.descripcion,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            
            if (evento.proyectos != null && evento.proyectos!.isNotEmpty) ...[
              const Text(
                "Proyectos disponibles:",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              ...evento.proyectos!.map((proyecto) => Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: Text("• $proyecto"),
              )).toList(),
              const SizedBox(height: 12),
            ],
            
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    evento.fecha,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            
            if (evento.titulo.contains("Servicio Comunitario")) ...[
              const SizedBox(height: 12),
              Text(
                "Más información: yguaimaro@unimet.edu.ve",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showFullImage(BuildContext context, String imagePath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 1.0,
              maxScale: 5.0,
              child: Image.asset(
                imagePath,
                width: MediaQuery.of(context).size.width,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Evento {
  final String titulo;
  final String descripcion;
  final String fecha;
  final Color color;
  final String? imagen;
  final List<String>? proyectos;

  const Evento({
    required this.titulo,
    required this.descripcion,
    required this.fecha,
    this.color = Colors.white,
    this.imagen,
    this.proyectos,
  });
}
