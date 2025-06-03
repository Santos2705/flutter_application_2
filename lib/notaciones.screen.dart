import 'package:flutter/material.dart';
import 'package:flutter_application_2/database_helper.dart';

class NotacionesExample extends StatefulWidget {
  final String? username;

  const NotacionesExample({super.key, this.username});

  @override
  State<NotacionesExample> createState() => _NotacionesExampleState();
}

class _NotacionesExampleState extends State<NotacionesExample> {
  late int _userId;
  List<Map<String, dynamic>> _materias = [];
  final _nuevaMateriaController = TextEditingController();
  final List<TextEditingController> _evalControllers = [];
  final List<TextEditingController> _porcentajeControllers = [];
  final List<TextEditingController> _notaControllers = [];
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
      await _loadMaterias();
    }
    setState(() => _isLoading = false);
  }

  Future<void> _loadMaterias() async {
    if (widget.username == null) return;

    final materias = await DatabaseHelper.instance.getMaterias(_userId);

    // Cargar evaluaciones para cada materia
    for (var materia in materias) {
      final evaluaciones = await DatabaseHelper.instance
          .getEvaluacionesPorMateria(materia['id']);
      materia['evaluaciones'] = evaluaciones;
    }

    setState(() {
      _materias = materias;
      // Inicializar controladores
      _evalControllers.clear();
      _porcentajeControllers.clear();
      _notaControllers.clear();
      for (var _ in _materias) {
        _evalControllers.add(TextEditingController());
        _porcentajeControllers.add(TextEditingController());
        _notaControllers.add(TextEditingController());
      }
    });
  }

  Future<void> _agregarMateria() async {
    if (_nuevaMateriaController.text.isNotEmpty && widget.username != null) {
      await DatabaseHelper.instance.insertMateria(
        _userId,
        _nuevaMateriaController.text,
      );
      _nuevaMateriaController.clear();
      await _loadMaterias();
    }
  }

  Future<void> _agregarEvaluacion(int materiaIndex) async {
    final materiaId = _materias[materiaIndex]['id'];
    final porcentaje =
        double.tryParse(_porcentajeControllers[materiaIndex].text) ?? 0.0;
    final nota = double.tryParse(_notaControllers[materiaIndex].text) ?? 0.0;

    if (_evalControllers[materiaIndex].text.isNotEmpty && porcentaje > 0) {
      await DatabaseHelper.instance.insertEvaluacion(
        materiaId,
        _evalControllers[materiaIndex].text,
        porcentaje,
        nota,
      );
      // Limpiar controladores
      _evalControllers[materiaIndex].clear();
      _porcentajeControllers[materiaIndex].clear();
      _notaControllers[materiaIndex].clear();
      await _loadMaterias();
    }
  }

  Future<void> _eliminarEvaluacion(int materiaId, int evalId) async {
    await DatabaseHelper.instance.deleteEvaluacion(evalId);
    await _loadMaterias();
  }

  Future<void> _eliminarMateria(int materiaId) async {
    await DatabaseHelper.instance.deleteMateria(materiaId);
    await _loadMaterias();
  }

  double _calcularPromedio(int materiaIndex) {
    if (_materias[materiaIndex]['evaluaciones'] == null) return 0.0;

    return _materias[materiaIndex]['evaluaciones'].fold<double>(
      0.0,
      (double sum, eval) => sum + ((eval['nota'] * eval['porcentaje']) / 100),
    );
  }

  @override
  void dispose() {
    _nuevaMateriaController.dispose();
    for (var controller in _evalControllers) {
      controller.dispose();
    }
    for (var controller in _porcentajeControllers) {
      controller.dispose();
    }
    for (var controller in _notaControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Notas'),
        actions: [
          if (widget.username != null)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Confirmar'),
                    content: const Text(
                      '¿Borrar todas las materias y evaluaciones?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          // Eliminar todas las materias del usuario (las evaluaciones se borran en cascada)
                          final db = await DatabaseHelper.instance.database;
                          await db.delete(
                            'materias',
                            where: 'user_id = ?',
                            whereArgs: [_userId],
                          );
                          await _loadMaterias();
                        },
                        child: const Text(
                          'Borrar',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
              tooltip: 'Borrar todas las materias',
            ),
        ],
      ),
      body: widget.username == null
          ? const Center(
              child: Text(
                'Inicia sesión para gestionar tus materias',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Campo para agregar nueva materia
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nuevaMateriaController,
                          decoration: const InputDecoration(
                            labelText: 'Nueva Materia',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _agregarMateria,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF9800),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Agregar',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Lista de materias
                  Expanded(
                    child: _materias.isEmpty
                        ? const Center(
                            child: Text(
                              'No hay materias registradas',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _materias.length,
                            itemBuilder: (context, materiaIndex) {
                              final materia = _materias[materiaIndex];
                              return Card(
                                elevation: 3,
                                margin: const EdgeInsets.only(bottom: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Encabezado de materia con botón de eliminar
                                      Row(
                                        children: [
                                          Text(
                                            materia['nombre'],
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFFFF9800),
                                            ),
                                          ),
                                          const Spacer(),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                            ),
                                            onPressed: () =>
                                                _eliminarMateria(materia['id']),
                                          ),
                                        ],
                                      ),
                                      const Divider(),

                                      // Campos para nueva evaluación
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8.0,
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              flex: 3,
                                              child: TextField(
                                                controller:
                                                    _evalControllers[materiaIndex],
                                                decoration: InputDecoration(
                                                  labelText: 'Evaluación',
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              flex: 1,
                                              child: TextField(
                                                controller:
                                                    _porcentajeControllers[materiaIndex],
                                                keyboardType:
                                                    TextInputType.number,
                                                decoration: InputDecoration(
                                                  labelText: '%',
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              flex: 1,
                                              child: TextField(
                                                controller:
                                                    _notaControllers[materiaIndex],
                                                keyboardType:
                                                    TextInputType.number,
                                                decoration: InputDecoration(
                                                  labelText: 'Nota',
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.add_circle,
                                                color: Color(0xFFFF6106),
                                              ),
                                              onPressed: () =>
                                                  _agregarEvaluacion(
                                                    materiaIndex,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Lista de evaluaciones
                                      if (materia['evaluaciones'] != null &&
                                          materia['evaluaciones'].isNotEmpty)
                                        ...materia['evaluaciones'].asMap().entries.map((
                                          entry,
                                        ) {
                                          final evalIndex = entry.key;
                                          final eval = entry.value;
                                          return Dismissible(
                                            key: Key(
                                              'eval-${materia['id']}-$evalIndex',
                                            ),
                                            background: Container(
                                              color: Colors.red.withOpacity(
                                                0.3,
                                              ),
                                            ),
                                            confirmDismiss: (direction) async {
                                              return await showDialog(
                                                context: context,
                                                builder: (context) => AlertDialog(
                                                  title: const Text(
                                                    'Confirmar',
                                                  ),
                                                  content: const Text(
                                                    '¿Eliminar esta evaluación?',
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.of(
                                                            context,
                                                          ).pop(false),
                                                      child: const Text(
                                                        'Cancelar',
                                                      ),
                                                    ),
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.of(
                                                            context,
                                                          ).pop(true),
                                                      child: const Text(
                                                        'Eliminar',
                                                        style: TextStyle(
                                                          color: Colors.red,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                            onDismissed: (direction) {
                                              _eliminarEvaluacion(
                                                materia['id'],
                                                eval['id'],
                                              );
                                            },
                                            child: ListTile(
                                              contentPadding: EdgeInsets.zero,
                                              leading: const Icon(
                                                Icons.assignment,
                                                color: Colors.blueAccent,
                                              ),
                                              title: Text(eval['nombre']),
                                              subtitle: Text(
                                                '${eval['porcentaje']}% - Nota: ${eval['nota']}',
                                              ),
                                              trailing: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    '${((eval['nota'] * eval['porcentaje']) / 100).toStringAsFixed(1)} pts',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.delete_outline,
                                                      color: Colors.red,
                                                    ),
                                                    onPressed: () {
                                                      _eliminarEvaluacion(
                                                        materia['id'],
                                                        eval['id'],
                                                      );
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        }),

                                      // Total acumulado
                                      Padding(
                                        padding: const EdgeInsets.only(top: 10),
                                        child: Text(
                                          'Total acumulado: ${_calcularPromedio(materiaIndex).toStringAsFixed(1)} pts',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Color(0xFFFF9800),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
