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
  final List<Materia> _materias = [];
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

    try {
      final user = await DatabaseHelper.instance.getUser(widget.username!);
      if (user != null) {
        setState(() => _userId = user['id']);
        await _loadMaterias();
      }
    } catch (e) {
      print('Error al cargar usuario: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMaterias() async {
    if (widget.username == null) return;

    setState(() => _isLoading = true);
    
    try {
      final materiasDB = await DatabaseHelper.instance.getMaterias(_userId);
      
      // Limpiar listas antes de cargar nuevos datos
      _materias.clear();
      _evalControllers.clear();
      _porcentajeControllers.clear();
      _notaControllers.clear();

      for (var materiaDB in materiasDB) {
        final evaluacionesDB = await DatabaseHelper.instance
            .getEvaluacionesPorMateria(materiaDB['id']);
        
        final materia = Materia(materiaDB['nombre'], materiaDB['id']);
        materia.evaluaciones = evaluacionesDB.map((eval) => Evaluacion(
          eval['nombre'],
          eval['porcentaje'],
          eval['nota'],
          eval['id'],
        )).toList();

        _materias.add(materia);
        _evalControllers.add(TextEditingController());
        _porcentajeControllers.add(TextEditingController());
        _notaControllers.add(TextEditingController());
      }
    } catch (e) {
      print('Error al cargar materias: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _agregarMateria() async {
    if (_nuevaMateriaController.text.isEmpty || widget.username == null) return;

    setState(() => _isLoading = true);
    
    try {
      final id = await DatabaseHelper.instance.insertMateria(
        _userId,
        _nuevaMateriaController.text,
      );
      
      if (id > 0) {
        _materias.add(Materia(_nuevaMateriaController.text, id));
        _evalControllers.add(TextEditingController());
        _porcentajeControllers.add(TextEditingController());
        _notaControllers.add(TextEditingController());
        _nuevaMateriaController.clear();
      }
    } catch (e) {
      print('Error al agregar materia: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _agregarEvaluacion(int materiaIndex) async {
    final materia = _materias[materiaIndex];
    final porcentaje =
        double.tryParse(_porcentajeControllers[materiaIndex].text) ?? 0.0;
    final nota = double.tryParse(_notaControllers[materiaIndex].text) ?? 0.0;

    if (_evalControllers[materiaIndex].text.isEmpty || porcentaje <= 0) return;

    setState(() => _isLoading = true);
    
    try {
      final id = await DatabaseHelper.instance.insertEvaluacion(
        materia.id,
        _evalControllers[materiaIndex].text,
        porcentaje,
        nota,
      );
      
      if (id > 0) {
        materia.evaluaciones.add(Evaluacion(
          _evalControllers[materiaIndex].text,
          porcentaje,
          nota,
          id,
        ));
        
        _evalControllers[materiaIndex].clear();
        _porcentajeControllers[materiaIndex].clear();
        _notaControllers[materiaIndex].clear();
      }
    } catch (e) {
      print('Error al agregar evaluación: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _eliminarEvaluacion(int materiaIndex, int evalIndex) async {
    final evaluacion = _materias[materiaIndex].evaluaciones[evalIndex];
    
    setState(() => _isLoading = true);
    
    try {
      final count = await DatabaseHelper.instance.deleteEvaluacion(evaluacion.id);
      if (count > 0) {
        setState(() {
          _materias[materiaIndex].evaluaciones.removeAt(evalIndex);
        });
      }
    } catch (e) {
      print('Error al eliminar evaluación: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _eliminarMateria(int materiaIndex) async {
    final materia = _materias[materiaIndex];
    
    setState(() => _isLoading = true);
    
    try {
      final count = await DatabaseHelper.instance.deleteMateria(materia.id);
      if (count > 0) {
        setState(() {
          _materias.removeAt(materiaIndex);
          _evalControllers.removeAt(materiaIndex);
          _porcentajeControllers.removeAt(materiaIndex);
          _notaControllers.removeAt(materiaIndex);
        });
      }
    } catch (e) {
      print('Error al eliminar materia: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  double _calcularPromedio(int materiaIndex) {
    return _materias[materiaIndex].evaluaciones.fold<double>(
      0.0,
      (double sum, Evaluacion eval) => sum + eval.puntosObtenidos,
    );
  }

  Future<void> _eliminarTodasLasMaterias() async {
    if (widget.username == null) return;

    setState(() => _isLoading = true);
    
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete('materias', where: 'user_id = ?', whereArgs: [_userId]);
      
      setState(() {
        _materias.clear();
        _evalControllers.clear();
        _porcentajeControllers.clear();
        _notaControllers.clear();
      });
    } catch (e) {
      print('Error al borrar todas las materias: $e');
    } finally {
      setState(() => _isLoading = false);
    }
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
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Cargando...'),
            ],
          ),
        ),
      );
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
                    content: const Text('¿Borrar todas las materias y evaluaciones?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _eliminarTodasLasMaterias();
                        },
                        child: const Text('Borrar', style: TextStyle(color: Colors.red)),
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
          ? Center(
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
                        ? Center(
                            child: Text(
                              'No hay materias registradas',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
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
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Encabezado de materia con botón de eliminar
                                      Row(
                                        children: [
                                          Text(
                                            materia.nombre,
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
                                            onPressed: () => _eliminarMateria(materiaIndex),
                                          ),
                                        ],
                                      ),
                                      const Divider(),

                                      // Campos para nueva evaluación
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              flex: 3,
                                              child: TextField(
                                                controller: _evalControllers[materiaIndex],
                                                decoration: InputDecoration(
                                                  labelText: 'Evaluación',
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              flex: 1,
                                              child: TextField(
                                                controller: _porcentajeControllers[materiaIndex],
                                                keyboardType: TextInputType.number,
                                                decoration: InputDecoration(
                                                  labelText: '%',
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              flex: 1,
                                              child: TextField(
                                                controller: _notaControllers[materiaIndex],
                                                keyboardType: TextInputType.number,
                                                decoration: InputDecoration(
                                                  labelText: 'Nota',
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.add_circle,
                                                color: Color(0xFFFF6106),
                                              ),
                                              onPressed: () => _agregarEvaluacion(materiaIndex),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Lista de evaluaciones
                                      ...materia.evaluaciones.asMap().entries.map((entry) {
                                        final evalIndex = entry.key;
                                        final eval = entry.value;
                                        return Dismissible(
                                          key: Key('eval-${materia.id}-${eval.id}'),
                                          background: Container(
                                            color: Colors.red.withOpacity(0.3),
                                          ),
                                          confirmDismiss: (direction) async {
                                            return await showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: const Text('Confirmar'),
                                                content: const Text('¿Eliminar esta evaluación?'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.of(context).pop(false),
                                                    child: const Text('Cancelar'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () => Navigator.of(context).pop(true),
                                                    child: const Text(
                                                      'Eliminar',
                                                      style: TextStyle(color: Colors.red),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                          onDismissed: (direction) {
                                            _eliminarEvaluacion(materiaIndex, evalIndex);
                                          },
                                          child: ListTile(
                                            contentPadding: EdgeInsets.zero,
                                            leading: const Icon(
                                              Icons.assignment,
                                              color: Colors.blueAccent,
                                            ),
                                            title: Text(eval.nombre),
                                            subtitle: Text(
                                              '${eval.porcentaje}% - Nota: ${eval.nota}',
                                            ),
                                            trailing: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  '${eval.puntosObtenidos.toStringAsFixed(1)} pts',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.delete_outline,
                                                    color: Colors.red,
                                                  ),
                                                  onPressed: () {
                                                    _eliminarEvaluacion(materiaIndex, evalIndex);
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

class Materia {
  String nombre;
  int id;
  List<Evaluacion> evaluaciones = [];

  Materia(this.nombre, this.id);
}

class Evaluacion {
  String nombre;
  double porcentaje;
  double nota;
  int id;

  Evaluacion(this.nombre, this.porcentaje, this.nota, this.id);

  double get puntosObtenidos => (nota * porcentaje) / 100;
}