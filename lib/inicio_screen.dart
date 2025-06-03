import 'package:flutter/material.dart';

class InicioExample extends StatefulWidget {
  const InicioExample({super.key});

  @override
  State<InicioExample> createState() => _InicioExampleState();
}

class _InicioExampleState extends State<InicioExample> {
  int _semanaActual = 1; // Controla la semana seleccionada (1-12)
  final TextEditingController _controller = TextEditingController();

  // Mapa que almacena listas de tareas por semana (semana: [tareas])
  final Map<int, List<String>> _tareasPorSemana = {};

  @override
  void initState() {
    super.initState();
    // Inicializa las 12 semanas con listas vacías
    for (int i = 1; i <= 12; i++) {
      _tareasPorSemana[i] = [];
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _agregarTarea() {
    if (_controller.text.isNotEmpty) {
      setState(() {
        _tareasPorSemana[_semanaActual]!.add(_controller.text);
        _controller.clear();
      });
    }
  }

  void _eliminarTarea(int index) {
    setState(() {
      _tareasPorSemana[_semanaActual]!.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título y selector de semana
            _buildHeader(),
            const SizedBox(height: 20),
            // Input para añadir tareas
            _buildInputTarea(),
            const SizedBox(height: 20),
            // Lista de tareas
            _buildListaTareas(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "¿Qué tareas tienes para hoy?",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        // Selector de semanas (1-12)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(12, (index) {
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text("Semana ${index + 1}"),
                  selected: _semanaActual == index + 1,
                  onSelected: (selected) {
                    setState(() {
                      _semanaActual = index + 1;
                    });
                  },
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildInputTarea() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            decoration: const InputDecoration(
              hintText: "Añade una tarea",
              border: OutlineInputBorder(),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add, color: Color(0xFFFF9800)),
          onPressed: _agregarTarea,
        ),
      ],
    );
  }

  Widget _buildListaTareas() {
    return Expanded(
      child: ListView.builder(
        itemCount: _tareasPorSemana[_semanaActual]!.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(_tareasPorSemana[_semanaActual]![index]),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _eliminarTarea(index),
              ),
            ),
          );
        },
      ),
    );
  }
}
