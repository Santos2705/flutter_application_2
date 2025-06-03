import 'package:flutter/material.dart';
import 'package:flutter_application_2/database_helper.dart';

class InicioExample extends StatefulWidget {
  final String? username; // Recibir el nombre de usuario

  const InicioExample({super.key, this.username});

  @override
  State<InicioExample> createState() => _InicioExampleState();
}

class _InicioExampleState extends State<InicioExample> {
  int _semanaActual = 1; // Controla la semana seleccionada (1-12)
  final TextEditingController _controller = TextEditingController();
  late int _userId;
  List<Map<String, dynamic>> _tareas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    if (widget.username == null) {
      setState(() => _isLoading = false);
      return;
    }

    final user = await DatabaseHelper.instance.getUser(widget.username!);
    if (user != null) {
      setState(() {
        _userId = user['id'];
      });
      await _loadTareas();
    }
    setState(() => _isLoading = false);
  }

  Future<void> _loadTareas() async {
    if (widget.username == null) return;

    final tareas = await DatabaseHelper.instance.getTareasPorSemana(
      _userId,
      _semanaActual,
    );
    setState(() {
      _tareas = tareas;
    });
  }

  Future<void> _agregarTarea() async {
    if (_controller.text.isNotEmpty && widget.username != null) {
      await DatabaseHelper.instance.insertTarea(
        _userId,
        _semanaActual,
        _controller.text,
      );
      _controller.clear();
      await _loadTareas();
    }
  }

  Future<void> _eliminarTarea(int id) async {
    await DatabaseHelper.instance.deleteTarea(id);
    await _loadTareas();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
                    if (selected) {
                      setState(() {
                        _semanaActual = index + 1;
                      });
                      _loadTareas();
                    }
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
            enabled: widget.username != null,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add, color: Color(0xFFFF9800)),
          onPressed: widget.username != null ? _agregarTarea : null,
        ),
      ],
    );
  }

  Widget _buildListaTareas() {
    if (widget.username == null) {
      return const Expanded(
        child: Center(
          child: Text(
            'Inicia sesión para ver tus tareas',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }
    return Expanded(
      child: _tareas.isEmpty
          ? const Center(
              child: Text(
                'No hay tareas para esta semana',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: _tareas.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(_tareas[index]['descripcion']),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _eliminarTarea(_tareas[index]['id']),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
