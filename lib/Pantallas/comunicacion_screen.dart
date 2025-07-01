import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:flutter_html/flutter_html.dart';

class ComunicacionScreen extends StatefulWidget {
  const ComunicacionScreen({super.key, String? username});

  @override
  State<ComunicacionScreen> createState() => _ComunicacionScreenState();
}

class _ComunicacionScreenState extends State<ComunicacionScreen> {
  late Future<List<Evento>> futureEventos;
  String debugInfo = "";
  bool showDebugInfo = false;

  @override
  void initState() {
    super.initState();
    futureEventos = fetchEventos();
  }

  Future<List<Evento>> fetchEventos() async {
    try {
      final response = await http.get(
        Uri.parse('https://www.unimet.edu.ve/eventos/'),
        headers: {'User-Agent': 'Mozilla/5.0'},
      );

      if (response.statusCode == 200) {
        debugInfo = "✅ HTML obtenido correctamente\n";
        final eventos = parseEventos(response.body);
        
        // Filtramos eventos duplicados
        final eventosUnicos = _filtrarEventosUnicos(eventos);
        debugInfo += "🔄 Eventos encontrados: ${eventos.length} | Únicos: ${eventosUnicos.length}\n";
        
        return eventosUnicos;
      } else {
        throw Exception('Error HTTP: ${response.statusCode}');
      }
    } catch (e) {
      debugInfo += "❌ Error: $e\n";
      throw Exception('Error de conexión: $e');
    }
  }

  List<Evento> _filtrarEventosUnicos(List<Evento> eventos) {
    final eventosUnicos = <Evento>[];
    final titulosVistos = <String>{};

    for (var evento in eventos) {
      // Normalizamos el título para mejor comparación
      final tituloNormalizado = evento.titulo
          .toLowerCase()
          .replaceAll(RegExp(r'[^\w\s]'), '')
          .trim();

      if (!titulosVistos.contains(tituloNormalizado)) {
        titulosVistos.add(tituloNormalizado);
        eventosUnicos.add(evento);
      } else {
        debugInfo += "⚠ Eliminado duplicado: ${evento.titulo}\n";
      }
    }

    return eventosUnicos;
  }

  List<Evento> parseEventos(String html) {
    final document = parser.parse(html);
    final eventos = <Evento>[];

    // Estrategia mejorada para identificar eventos distintos
    final eventItems = document.querySelectorAll('article, .item, .evento-item, .event');

    for (var item in eventItems) {
      try {
        final titleElement = item.querySelector('h2, h3, .title, [itemprop="name"]');
        final title = titleElement?.text.trim() ?? 'Evento sin título';

        // Saltar elementos sin título o con título genérico
        if (title == 'Evento sin título' || title.isEmpty) continue;

        final descriptionElement = item.querySelector('.description, .content, [itemprop="description"]');
        var description = descriptionElement?.innerHtml.trim() ?? '';

        // Mejorar descripción si está vacía
        if (description.isEmpty) {
          final firstParagraph = item.querySelector('p:not(:has(img))');
          description = firstParagraph?.text.trim() ?? 'No hay descripción disponible';
        }

        final dateElement = item.querySelector('.date, time, [itemprop="datePublished"]');
        var date = dateElement?.text.trim() ?? 'Fecha no especificada';

        // Limpiar formato de fecha si es necesario
        date = date.replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

        final imageElement = item.querySelector('img, [itemprop="image"]');
        String? imageUrl = imageElement?.attributes['src'] ?? imageElement?.attributes['data-src'];

        if (imageUrl != null && !imageUrl.startsWith('http')) {
          imageUrl = 'https://www.unimet.edu.ve${imageUrl.startsWith('/') ? '' : '/'}$imageUrl';
        }

        final linkElement = item.querySelector('a[href]');
        final link = linkElement?.attributes['href'];

        eventos.add(Evento(
          titulo: title,
          descripcion: description,
          fecha: date,
          imagenUrl: imageUrl,
          enlace: link,
        ));

        debugInfo += "➕ Evento añadido: $title\n";

      } catch (e) {
        debugInfo += "⚠ Error procesando elemento: $e\n";
      }
    }

    // Si no encontramos eventos, intentamos una estrategia alternativa
    if (eventos.isEmpty) {
      debugInfo += "⚠ No se encontraron eventos con selectores principales. Intentando método alternativo...\n";
      
      final allHeadings = document.querySelectorAll('h2, h3');
      for (var heading in allHeadings) {
        try {
          final title = heading.text.trim();
          if (title.isEmpty) continue;

          // Buscamos elementos relacionados cerca del título
          var nextElement = heading.nextElementSibling;
          var description = '';
          var date = 'Fecha no especificada';

          while (nextElement != null && description.isEmpty) {
            if (nextElement.localName == 'p') {
              description = nextElement.text.trim();
            } else if (nextElement.querySelector('.date, time') != null) {
              date = nextElement.querySelector('.date, time')!.text.trim();
            }
            nextElement = nextElement.nextElementSibling;
          }

          eventos.add(Evento(
            titulo: title,
            descripcion: description.isNotEmpty ? description : 'No hay descripción disponible',
            fecha: date,
            imagenUrl: null,
          ));

          debugInfo += "➕ Evento alternativo añadido: $title\n";

        } catch (e) {
          debugInfo += "⚠ Error procesando heading: $e\n";
        }
      }
    }

    return eventos;
  }

  Future<void> _refresh() async {
    setState(() {
      debugInfo += "\n🔄 Actualizando eventos...\n";
      futureEventos = fetchEventos();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eventos UNIMET'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () {
              setState(() {
                showDebugInfo = !showDebugInfo;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (showDebugInfo)
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.all(8),
                color: Colors.black,
                child: SingleChildScrollView(
                  child: Text(
                    debugInfo,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          if (showDebugInfo)
            const Divider(height: 2, color: Colors.white),
          Expanded(
            flex: showDebugInfo ? 3 : 1,
            child: FutureBuilder<List<Evento>>(
              future: futureEventos,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 50, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${snapshot.error}',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _refresh,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_available, size: 50),
                        SizedBox(height: 16),
                        Text('No se encontraron eventos'),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final evento = snapshot.data![index];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              evento.titulo,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 16),
                                const SizedBox(width: 8),
                                Text(evento.fecha),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Html(data: evento.descripcion),
                            if (evento.enlace != null) ...[
                              const SizedBox(height: 8),
                              const Text(
                                'Más información',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class Evento {
  final String titulo;
  final String descripcion;
  final String fecha;
  final String? imagenUrl;
  final String? enlace;

  const Evento({
    required this.titulo,
    required this.descripcion,
    required this.fecha,
    this.imagenUrl,
    this.enlace,
  });
}