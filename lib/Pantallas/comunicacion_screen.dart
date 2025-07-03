import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:flutter_html/flutter_html.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';

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
        debugInfo = "✅ HTML obtenido correctamente (${response.body.length} bytes)\n";
        
        final eventosEstrategia1 = parseEventosEstrategia1(response.body);
        if (eventosEstrategia1.isNotEmpty) {
          debugInfo += "🔄 Eventos encontrados (Estrategia 1): ${eventosEstrategia1.length}\n";
          final eventosFiltrados = _filtrarEventos(eventosEstrategia1);
          debugInfo += "🔍 Eventos después de filtrar: ${eventosFiltrados.length}\n";
          return eventosFiltrados;
        }
        
        debugInfo += "⚠ No se encontraron eventos con Estrategia 1\n";
        final eventosEstrategia2 = parseEventosEstrategia2(response.body);
        debugInfo += "🔄 Eventos encontrados (Estrategia 2): ${eventosEstrategia2.length}\n";
        final eventosFiltradosAlt = _filtrarEventos(eventosEstrategia2);
        debugInfo += "🔍 Eventos después de filtrar: ${eventosFiltradosAlt.length}\n";
        
        if (eventosFiltradosAlt.isNotEmpty) {
          return eventosFiltradosAlt;
        }
        
        debugInfo += "⚠ No se encontraron eventos con Estrategia 2\n";
        final eventosPatron = parseEventosPorPatron(response.body);
        debugInfo += "🔄 Eventos encontrados (Patrón): ${eventosPatron.length}\n";
        final eventosFiltradosPatron = _filtrarEventos(eventosPatron);
        debugInfo += "🔍 Eventos después de filtrar: ${eventosFiltradosPatron.length}\n";
        
        return eventosFiltradosPatron;
      } else {
        throw Exception('Error HTTP: ${response.statusCode}');
      }
    } catch (e) {
      debugInfo += "❌ Error: $e\n";
      throw Exception('Error de conexión: $e');
    }
  }

  bool _esTituloExcluido(String titulo) {
    final titulosExcluidos = [
      'Información',
      '¿Qué hacemos?',
      'Vías de ingreso',
      'Información, que hacemos y vías de ingreso',
      'Gerencia',
      'Diplomados',
      'Prueba Diagnóstica de Ubicación (PDU)',
    ];
    
    final tituloNormalizado = _normalizarTexto(titulo);
    return titulosExcluidos.any((excluido) => 
        tituloNormalizado == _normalizarTexto(excluido) ||
        tituloNormalizado.contains(_normalizarTexto(excluido)));
  }

  List<Evento> _filtrarEventos(List<Evento> eventos) {
    final eventosUnicos = <Evento>[];
    final clavesVistas = <String>{};

    for (var evento in eventos) {
      if (_esTituloExcluido(evento.titulo)) {
        debugInfo += "🚫 Evento excluido por título: ${evento.titulo}\n";
        continue;
      }

      final claveUnica = '${_normalizarTexto(evento.titulo)}'
          '-${_normalizarFecha(evento.fecha)}'
          '-${_normalizarTexto(evento.descripcion).length}';

      if (!clavesVistas.contains(claveUnica)) {
        clavesVistas.add(claveUnica);
        eventosUnicos.add(evento);
        debugInfo += "➕ Evento único: ${evento.titulo}\n";
      } else {
        debugInfo += "⚠ Duplicado eliminado: ${evento.titulo}\n";
      }
    }
    return eventosUnicos;
  }

  String _normalizarTexto(String texto) {
    return texto.toLowerCase()
      .trim()
      .replaceAll(RegExp(r'[^\w\sáéíóúñ]'), '')
      .replaceAll(RegExp(r'\s+'), ' ');
  }

  String _normalizarFecha(String fecha) {
    try {
      return fecha.toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .substring(0, 10);
    } catch (e) {
      return fecha;
    }
  }

  List<Evento> parseEventosEstrategia1(String html) {
    final document = parser.parse(html);
    final eventos = <Evento>[];

    final items = document.querySelectorAll('.tribe-events-list__event, article.event, .evento-item');

    for (var item in items) {
      try {
        final titleElement = item.querySelector('.tribe-events-list-event-title, h2, h3');
        final title = titleElement?.text.trim() ?? 'Evento sin título';
        if (title.isEmpty || _esTituloExcluido(title)) continue;

        // Extracción mejorada de descripción
        String description = '';
        final descriptionElement = item.querySelector('.tribe-events-list-event-description, .description, .event-description');
        
        if (descriptionElement != null) {
          description = descriptionElement.innerHtml.trim();
          if (description.isEmpty) {
            description = descriptionElement.text.trim();
          }
        }
        
        if (description.isEmpty) {
          var nextElement = titleElement?.nextElementSibling;
          while (nextElement != null && description.isEmpty) {
            if (nextElement.localName == 'p' || 
                nextElement.classes.contains('event-details') ||
                nextElement.classes.contains('event-content')) {
              description = nextElement.text.trim();
            }
            nextElement = nextElement.nextElementSibling;
          }
        }

        if (description.isEmpty) {
          final firstParagraph = item.querySelector('p');
          description = firstParagraph?.text.trim() ?? 'Descripción no disponible';
        }

        description = _limpiarDescripcion(description);

        String fecha = 'Evento sin fecha';
        final dateElement = item.querySelector('.tribe-event-date, .event-date, time, .fecha-evento');
        
        if (dateElement != null) {
          fecha = dateElement.text.trim();
          fecha = fecha.replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
          
          final dateRegex = RegExp(r'\d{1,2}[/\-]\d{1,2}[/\-]\d{2,4}|\d{1,2}\s+(?:ene|feb|mar|abr|may|jun|jul|ago|sep|oct|nov|dic)[a-z]*\s+\d{4}', caseSensitive: false);
          if (!dateRegex.hasMatch(fecha)) {
            fecha = 'Evento sin fecha';
          }
        }

        String? imageUrl;
        final imageElement = item.querySelector('.tribe-events-event-image img, .event-image img');
        if (imageElement != null) {
          imageUrl = imageElement.attributes['src'] ?? 
                    imageElement.attributes['data-src'] ??
                    imageElement.attributes['data-lazy-src'];
          
          if (imageUrl != null && !imageUrl.startsWith('http')) {
            imageUrl = 'https://www.unimet.edu.ve${imageUrl.startsWith('/') ? '' : '/'}$imageUrl';
          }
        }

        final linkElement = item.querySelector('a.tribe-event-url, a[href]');
        final link = linkElement?.attributes['href'];

        eventos.add(Evento(
          titulo: title,
          descripcion: description,
          fecha: fecha,
          imagenUrl: imageUrl,
          enlace: link,
        ));

      } catch (e) {
        debugInfo += "⚠ Error (E1): $e\n";
      }
    }
    return eventos;
  }

  String _limpiarDescripcion(String descripcion) {
    descripcion = descripcion.replaceAll(RegExp(r'\s+'), ' ');
    descripcion = descripcion.replaceAll('Leer más', '');
    descripcion = descripcion.replaceAll('Ver más', '');
    descripcion = descripcion.replaceAll('Más información', '');
    return descripcion.trim();
  }

  List<Evento> parseEventosEstrategia2(String html) {
    final document = parser.parse(html);
    final eventos = <Evento>[];

    final items = document.querySelectorAll('article, .item, .evento');

    for (var item in items) {
      try {
        if (item.querySelector('article') != null) continue;

        final titleElement = item.querySelector('h2, h3, .title');
        final title = titleElement?.text.trim() ?? 'Evento sin título';
        if (title.isEmpty || _esTituloExcluido(title)) continue;

        String description = '';
        final descriptionElement = item.querySelector('.content, .descripcion, .event-content, .entry-content');
        
        if (descriptionElement != null) {
          description = descriptionElement.innerHtml.trim();
          if (description.isEmpty) {
            description = descriptionElement.text.trim();
          }
        }
        
        if (description.isEmpty) {
          var nextElement = titleElement?.nextElementSibling;
          while (nextElement != null && description.isEmpty) {
            if (nextElement.localName == 'p' || 
                nextElement.localName == 'div' ||
                nextElement.classes.contains('event-details')) {
              description = nextElement.text.trim();
            }
            nextElement = nextElement.nextElementSibling;
          }
        }

        description = _limpiarDescripcion(description);

        String fecha = 'Evento sin fecha';
        final dateElement = item.querySelector('.date, time, .meta, .fecha');
        
        if (dateElement != null) {
          fecha = dateElement.text.trim();
          fecha = fecha.replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
          
          final dateRegex = RegExp(r'\d{1,2}[/\-]\d{1,2}[/\-]\d{2,4}|\d{1,2}\s+(?:ene|feb|mar|abr|may|jun|jul|ago|sep|oct|nov|dic)[a-z]*\s+\d{4}', caseSensitive: false);
          if (!dateRegex.hasMatch(fecha)) {
            fecha = 'Evento sin fecha';
          }
        }

        String? imageUrl;
        final imageElement = item.querySelector('img');
        if (imageElement != null && 
            !imageElement.classes.contains('logo') && 
            !imageElement.classes.contains('icon')) {
          imageUrl = imageElement.attributes['src'] ?? imageElement.attributes['data-src'];
          if (imageUrl != null && !imageUrl.startsWith('http')) {
            imageUrl = 'https://www.unimet.edu.ve${imageUrl.startsWith('/') ? '' : '/'}$imageUrl';
          }
        }

        final linkElement = item.querySelector('a[href]');
        final link = linkElement?.attributes['href'];

        eventos.add(Evento(
          titulo: title,
          descripcion: description.isNotEmpty ? description : 'No hay descripción disponible',
          fecha: fecha,
          imagenUrl: imageUrl,
          enlace: link,
        ));

      } catch (e) {
        debugInfo += "⚠ Error (E2): $e\n";
      }
    }
    return eventos;
  }

  List<Evento> parseEventosPorPatron(String html) {
    final eventos = <Evento>[];
    final document = parser.parse(html);

    final possibleEvents = document.querySelectorAll('div, section, article');

    for (var item in possibleEvents) {
      try {
        final titleElement = item.querySelector('h2, h3, h4');
        final title = titleElement?.text.trim();
        if (title == null || title.isEmpty || _esTituloExcluido(title)) continue;

        String description = '';
        var descElement = titleElement?.nextElementSibling;
        
        while (descElement != null && (description.isEmpty || description.length < 20)) {
          if (descElement.localName == 'p' || 
              descElement.localName == 'div' ||
              descElement.classes.contains('description') ||
              descElement.classes.contains('content')) {
            description += '${descElement.text.trim()}\n';
          }
          descElement = descElement.nextElementSibling;
        }

        description = _limpiarDescripcion(description);

        String fecha = 'Evento sin fecha';
        var dateElement = item.querySelector('time, .date, .fecha');
        
        if (dateElement != null) {
          fecha = dateElement.text.trim();
          
          final dateRegex = RegExp(r'\d{1,2}[/\-]\d{1,2}[/\-]\d{2,4}|\d{1,2}\s+(?:ene|feb|mar|abr|may|jun|jul|ago|sep|oct|nov|dic)[a-z]*\s+\d{4}', caseSensitive: false);
          if (!dateRegex.hasMatch(fecha)) {
            fecha = 'Evento sin fecha';
          }
        } else {
          final dateRegex = RegExp(r'\d{1,2}\s+(?:ene|feb|mar|abr|may|jun|jul|ago|sep|oct|nov|dic)[a-z]*\s+\d{4}', caseSensitive: false);
          final dateMatch = dateRegex.firstMatch(item.text);
          if (dateMatch != null) {
            fecha = dateMatch.group(0)!;
          }
        }

        String? imageUrl;
        final imageElement = item.querySelector('img');
        if (imageElement != null) {
          imageUrl = imageElement.attributes['src'] ?? imageElement.attributes['data-src'];
          if (imageUrl != null && !imageUrl.startsWith('http')) {
            imageUrl = 'https://www.unimet.edu.ve${imageUrl.startsWith('/') ? '' : '/'}$imageUrl';
          }
        }

        eventos.add(Evento(
          titulo: title,
          descripcion: description.isNotEmpty ? description : 'No hay descripción disponible',
          fecha: fecha,
          imagenUrl: imageUrl,
          enlace: null,
        ));

        debugInfo += "➕ Evento (patrón): $title\n";

      } catch (e) {
        debugInfo += "⚠ Error (Patrón): $e\n";
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

  void _mostrarImagenAmpliada(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Imagen del evento'),
            backgroundColor: Colors.black,
            actions: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          body: Container(
            color: Colors.black,
            child: PhotoView(
              imageProvider: NetworkImage(imageUrl),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2,
              initialScale: PhotoViewComputedScale.contained,
              heroAttributes: PhotoViewHeroAttributes(tag: imageUrl),
            ),
          ),
        ),
      ),
    );
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
            onPressed: () => setState(() => showDebugInfo = !showDebugInfo),
          ),
        ],
      ),
      body: Column(
        children: [
          if (showDebugInfo) ...[
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.all(8),
                color: Colors.black,
                child: SingleChildScrollView(
                  child: Text(
                    debugInfo,
                    style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ),
            ),
            const Divider(height: 2, color: Colors.white),
          ],
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
                        Text('Error: ${snapshot.error}', textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _refresh,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }

                final eventos = snapshot.data ?? [];
                if (eventos.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.event_busy, size: 50),
                        const SizedBox(height: 16),
                        const Text('No se encontraron eventos disponibles'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _refresh,
                          child: const Text('Intentar nuevamente'),
                        ),
                        TextButton(
                          onPressed: () => setState(() => showDebugInfo = true),
                          child: const Text('Ver detalles técnicos'),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.builder(
                    itemCount: eventos.length,
                    itemBuilder: (context, index) {
                      final evento = eventos[index];
                      return Card(
                        margin: const EdgeInsets.all(8),
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (evento.imagenUrl != null)
                              GestureDetector(
                                onTap: () => _mostrarImagenAmpliada(context, evento.imagenUrl!),
                                child: Hero(
                                  tag: evento.imagenUrl!,
                                  child: CachedNetworkImage(
                                    imageUrl: evento.imagenUrl!,
                                    height: 180,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => Container(
                                      color: Colors.grey[200],
                                      child: const Center(child: CircularProgressIndicator()),
                                    ),
                                    errorWidget: (_, __, ___) => Container(
                                      color: Colors.grey[200],
                                      child: const Center(child: Icon(Icons.broken_image)),
                                    ),
                                  ),
                                ),
                              ),
                            Padding(
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
                                  if (evento.fecha != 'Evento sin fecha')
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.calendar_today, size: 16),
                                          const SizedBox(width: 8),
                                          Text(
                                            evento.fecha,
                                            style: const TextStyle(
                                              color: Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (evento.descripcion.isNotEmpty && evento.descripcion != 'No hay descripción disponible')
                                    Padding(
                                      padding: const EdgeInsets.only(top: 12),
                                      child: Text(
                                        evento.descripcion,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  if (evento.enlace != null) ...[
                                    const SizedBox(height: 8),
                                    InkWell(
                                      onTap: () {},
                                      child: const Text(
                                        'Más información',
                                        style: TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
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