import 'package:flutter/material.dart';
import 'package:flutter_application_2/Pantallas/database_helper.dart';

class NotacionesExample extends StatefulWidget {
  final String? username;

  const NotacionesExample({super.key, this.username});

  @override
  State<NotacionesExample> createState() => _NotacionesExampleState();
}

class _NotacionesExampleState extends State<NotacionesExample> {
  late int _userId;
  List<Map<String, dynamic>> _trimestres = [];
  final _nuevoTrimestreController = TextEditingController();
  bool _isLoading = true;
  int? _trimestreSeleccionado;
  double _promedioTrimestre = 0;
  bool _mostrarPromedio = false;

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
        await _loadTrimestres();
      }
    } catch (e) {
      debugPrint('Error al cargar usuario: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTrimestres() async {
    if (widget.username == null) return;

    setState(() => _isLoading = true);

    try {
      final trimestresDB = await DatabaseHelper.instance.getTrimestres(_userId);
      setState(() => _trimestres = trimestresDB);
    } catch (e) {
      debugPrint('Error al cargar trimestres: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> calcularPromedioTrimestre() async {
    if (_trimestreSeleccionado == null) return;

    setState(() {
      _isLoading = true;
      _mostrarPromedio = false; // Cambiado a false para ocultar el promedio
    });

    try {
      final promedio = await DatabaseHelper.instance.calcularPromedioTrimestre(
        _trimestreSeleccionado!,
      );
      setState(() => _promedioTrimestre = promedio);
    } catch (e) {
      debugPrint('Error al calcular promedio: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _agregarTrimestre() async {
    if (_nuevoTrimestreController.text.isEmpty || widget.username == null) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final id = await DatabaseHelper.instance.insertTrimestre(
        _userId,
        _nuevoTrimestreController.text,
      );

      if (id > 0) {
        _nuevoTrimestreController.clear();
        await _loadTrimestres();
      }
    } catch (e) {
      debugPrint('Error al agregar trimestre: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al agregar trimestre: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _eliminarTrimestre(int trimestreId) async {
    setState(() => _isLoading = true);

    try {
      final count = await DatabaseHelper.instance.deleteTrimestre(trimestreId);
      if (count > 0) {
        await _loadTrimestres();
        if (_trimestreSeleccionado == trimestreId) {
          _trimestreSeleccionado = null;
          _mostrarPromedio = false;
        }
      }
    } catch (e) {
      debugPrint('Error al eliminar trimestre: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar trimestre: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nuevoTrimestreController.dispose();
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
        title: Text(
          _trimestreSeleccionado == null
              ? 'Anotaciones de Trimestres'
              : 'Materias del Trimestre',
          style: TextStyle(fontSize: 18),
        ),
        leading: _trimestreSeleccionado != null
            ? IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _trimestreSeleccionado = null;
                    _promedioTrimestre = 0;
                    _mostrarPromedio = false;
                  });
                },
              )
            : null,
        actions: [
          if (widget.username != null &&
              _trimestres.isNotEmpty &&
              _trimestreSeleccionado == null)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Confirmar'),
                    content: const Text('¿Borrar todos los trimestres?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          for (var trimestre in _trimestres) {
                            await DatabaseHelper.instance.deleteTrimestre(
                              trimestre['id'],
                            );
                          }
                          await _loadTrimestres();
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
              tooltip: 'Borrar todos los trimestres',
            ),
        ],
      ),
      body: widget.username == null
          ? Center(
              child: Text(
                'Inicia sesión para gestionar tus trimestres',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: _trimestreSeleccionado == null
                  ? _buildListaTrimestres()
                  : Column(
                      children: [
                        // Se ha eliminado el widget que mostraba el promedio
                        Expanded(
                          child: MateriasDelTrimestre(
                            trimestreId: _trimestreSeleccionado!,
                            trimestreNombre: _trimestres.firstWhere(
                              (t) => t['id'] == _trimestreSeleccionado,
                            )['nombre'],
                            username: widget.username,
                            onMateriasUpdated: _loadTrimestres,
                            calcularPromedio: calcularPromedioTrimestre,
                          ),
                        ),
                      ],
                    ),
            ),
    );
  }

  Widget _buildListaTrimestres() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _nuevoTrimestreController,
                decoration: const InputDecoration(
                  labelText: 'Nuevo Trimestre',
                  hintText: 'Ej: Trimestre 1 - 2022',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: _agregarTrimestre,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8200),
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
        const SizedBox(height: 10),
        const SizedBox(height: 20),
        Expanded(
          child: _trimestres.isEmpty
              ? Center(
                  child: Text(
                    'No hay trimestres registrados',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: _trimestres.length,
                  itemBuilder: (context, index) {
                    final trimestre = _trimestres[index];
                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        title: Text(
                          trimestre['nombre'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[800],
                          ),
                        ),
                        subtitle:
                            trimestre['fecha_inicio'] != null ||
                                trimestre['fecha_fin'] != null
                            ? Text(
                                '${trimestre['fecha_inicio'] ?? 'Sin fecha'} - ${trimestre['fecha_fin'] ?? 'Sin fecha'}',
                              )
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () =>
                                  _eliminarTrimestre(trimestre['id']),
                            ),
                          ],
                        ),
                        onTap: () {
                          setState(() {
                            _trimestreSeleccionado = trimestre['id'];
                            _promedioTrimestre = 0;
                            _mostrarPromedio = false;
                          });
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class MateriasDelTrimestre extends StatefulWidget {
  final int trimestreId;
  final String trimestreNombre;
  final String? username;
  final VoidCallback? onMateriasUpdated;
  final Future<void> Function() calcularPromedio;

  const MateriasDelTrimestre({
    super.key,
    required this.trimestreId,
    required this.trimestreNombre,
    this.username,
    this.onMateriasUpdated,
    required this.calcularPromedio,
  });

  @override
  State<MateriasDelTrimestre> createState() => _MateriasDelTrimestreState();
}

class _MateriasDelTrimestreState extends State<MateriasDelTrimestre> {
  final List<Materia> _materias = [];
  final _nuevaMateriaController = TextEditingController();
  final List<TextEditingController> _evalControllers = [];
  final List<TextEditingController> _porcentajeControllers = [];
  final List<TextEditingController> _notaControllers = [];
  bool _isLoading = true;
  final Map<int, TextEditingController> _editMateriaControllers = {};
  final Map<int, TextEditingController> _editEvalNotaControllers = {};

  @override
  void initState() {
    super.initState();
    _loadMaterias();
  }

  Future<void> _loadMaterias() async {
    if (widget.username == null) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final materiasDB = await DatabaseHelper.instance.getMateriasPorTrimestre(
        widget.trimestreId,
      );

      _materias.clear();
      _evalControllers.clear();
      _porcentajeControllers.clear();
      _notaControllers.clear();
      _editMateriaControllers.clear();
      _editEvalNotaControllers.clear();

      for (var materiaDB in materiasDB) {
        final evaluacionesDB = await DatabaseHelper.instance
            .getEvaluacionesPorMateria(materiaDB['id']);

        final materia = Materia(materiaDB['nombre'], materiaDB['id']);
        materia.evaluaciones = evaluacionesDB
            .map(
              (eval) => Evaluacion(
                eval['nombre'],
                eval['porcentaje'],
                eval['nota']?.toDouble() ?? 0.0,
                eval['id'],
              ),
            )
            .toList();

        _materias.add(materia);
        _evalControllers.add(TextEditingController());
        _porcentajeControllers.add(TextEditingController());
        _notaControllers.add(TextEditingController());
        _editMateriaControllers[materia.id] = TextEditingController(
          text: materia.nombre,
        );
      }
    } catch (e) {
      debugPrint('Error al cargar materias: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar materias: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _agregarMateria() async {
    if (_nuevaMateriaController.text.isEmpty || widget.username == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingrese un nombre para la materia'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final id = await DatabaseHelper.instance.insertMateria(
        widget.trimestreId,
        _nuevaMateriaController.text,
      );

      if (id > 0) {
        _materias.add(Materia(_nuevaMateriaController.text, id));
        _evalControllers.add(TextEditingController());
        _porcentajeControllers.add(TextEditingController());
        _notaControllers.add(TextEditingController());
        _editMateriaControllers[id] = TextEditingController(
          text: _nuevaMateriaController.text,
        );
        _nuevaMateriaController.clear();
        if (widget.onMateriasUpdated != null) {
          widget.onMateriasUpdated!();
        }
      }
    } catch (e) {
      debugPrint('Error al agregar materia: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al agregar materia: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _editarNombreMateria(int materiaId) async {
    final controller = _editMateriaControllers[materiaId];
    if (controller == null || controller.text.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final count = await DatabaseHelper.instance.updateNombreMateria(
        materiaId,
        controller.text,
      );

      if (count > 0) {
        final materiaIndex = _materias.indexWhere((m) => m.id == materiaId);
        if (materiaIndex != -1) {
          setState(() {
            _materias[materiaIndex].nombre = controller.text;
          });
        }
        if (widget.onMateriasUpdated != null) {
          widget.onMateriasUpdated!();
        }
      }
    } catch (e) {
      debugPrint('Error al editar materia: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al editar materia: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _agregarEvaluacion(int materiaIndex) async {
    final nombreEvaluacion = _evalControllers[materiaIndex].text;
    final porcentajeText = _porcentajeControllers[materiaIndex].text;

    if (nombreEvaluacion.isEmpty || porcentajeText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complete nombre y porcentaje'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final porcentaje = double.tryParse(porcentajeText) ?? 0.0;
    if (porcentaje <= 0 || porcentaje > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El porcentaje debe estar entre 0.1 y 100'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final notaText = _notaControllers[materiaIndex].text;
    final nota = notaText.isNotEmpty ? double.tryParse(notaText) ?? 0.0 : 0.0;

    setState(() => _isLoading = true);

    try {
      final id = await DatabaseHelper.instance.insertEvaluacion(
        _materias[materiaIndex].id,
        nombreEvaluacion,
        porcentaje,
        nota,
      );

      if (id > 0) {
        _materias[materiaIndex].evaluaciones.add(
          Evaluacion(nombreEvaluacion, porcentaje, nota, id),
        );

        _evalControllers[materiaIndex].clear();
        _porcentajeControllers[materiaIndex].clear();
        _notaControllers[materiaIndex].clear();
        if (widget.onMateriasUpdated != null) {
          widget.onMateriasUpdated!();
        }
      }
    } catch (e) {
      debugPrint('Error al agregar evaluación: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al agregar evaluación: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _editarNotaEvaluacion(int materiaIndex, int evalIndex) async {
    final evaluacion = _materias[materiaIndex].evaluaciones[evalIndex];
    final controller =
        _editEvalNotaControllers[evaluacion.id] ??
        TextEditingController(text: evaluacion.nota.toString());
    _editEvalNotaControllers[evaluacion.id] = controller;

    final nota = double.tryParse(controller.text);
    if (nota == null || nota < 0 || nota > 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La nota debe ser un número entre 0 y 20'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final count = await DatabaseHelper.instance.updateNotaEvaluacion(
        evaluacion.id,
        nota,
      );

      if (count > 0) {
        setState(() {
          _materias[materiaIndex].evaluaciones[evalIndex].nota = nota;
        });
        if (widget.onMateriasUpdated != null) {
          widget.onMateriasUpdated!();
        }
        await widget.calcularPromedio();
      }
    } catch (e) {
      debugPrint('Error al actualizar nota: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar nota: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _eliminarEvaluacion(int materiaIndex, int evalIndex) async {
    final evaluacion = _materias[materiaIndex].evaluaciones[evalIndex];

    setState(() => _isLoading = true);

    try {
      final count = await DatabaseHelper.instance.deleteEvaluacion(
        evaluacion.id,
      );
      if (count > 0) {
        setState(() {
          _materias[materiaIndex].evaluaciones.removeAt(evalIndex);
        });
        if (widget.onMateriasUpdated != null) {
          widget.onMateriasUpdated!();
        }
        await widget.calcularPromedio();
      }
    } catch (e) {
      debugPrint('Error al eliminar evaluación: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar evaluación: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
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
          _editMateriaControllers.remove(materia.id);
        });
        if (widget.onMateriasUpdated != null) {
          widget.onMateriasUpdated!();
        }
        await widget.calcularPromedio();
      }
    } catch (e) {
      debugPrint('Error al eliminar materia: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar materia: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  double _calcularTotalAcumulado(int materiaIndex) {
    final evaluaciones = _materias[materiaIndex].evaluaciones;
    if (evaluaciones.isEmpty) return 0.0;

    double total = 0.0;
    for (var eval in evaluaciones) {
      total += (eval.nota * eval.porcentaje) / 100;
    }
    return total;
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
    for (var controller in _editMateriaControllers.values) {
      controller.dispose();
    }
    for (var controller in _editEvalNotaControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Cargando materias...'),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Text(
            ' ${widget.trimestreNombre}',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: Colors.orange[800],
            ),
          ),
        ),
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
            SizedBox(
              width: 120,
              child: ElevatedButton(
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
            ),
          ],
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: 120,
            child: ElevatedButton.icon(
              icon: Icon(Icons.calculate, size: 16),
              label: Text('Promedio', style: TextStyle(fontSize: 12)),
              onPressed: () {
                double suma = 0;
                int cantidad = 0;
                for (var materia in _materias) {
                  double sumaPonderada = 0.0;
                  double sumaPorcentajes = 0.0;
                  for (var eval in materia.evaluaciones) {
                    sumaPonderada += eval.nota * eval.porcentaje;
                    sumaPorcentajes += eval.porcentaje;
                  }
                  if (sumaPorcentajes > 0) {
                    suma += (sumaPonderada / sumaPorcentajes);
                    cantidad++;
                  }
                }
                double promedio = cantidad > 0 ? suma / cantidad : 0;
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Promedio de Materias'),
                    content: Text(
                      'El promedio de tu trimestre es: ${promedio.toStringAsFixed(2)}',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cerrar'),
                      ),
                    ],
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9800),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: _materias.isEmpty
              ? Center(
                  child: Text(
                    'No hay materias registradas en este trimestre',
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
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    materia.nombre,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFFF8200),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Color(0xFFFF8200),
                                  ),
                                  onPressed: () {
                                    _showEditMateriaDialog(
                                      materia.id,
                                      materia.nombre,
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () =>
                                      _eliminarMateria(materiaIndex),
                                ),
                              ],
                            ),
                            const Divider(),
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
                                          borderRadius: BorderRadius.circular(
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
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: '%',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
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
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: 'Nota (0-20)',
                                        hintText: 'Opcional (default 0)',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
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
                                        _agregarEvaluacion(materiaIndex),
                                  ),
                                ],
                              ),
                            ),
                            ...materia.evaluaciones.asMap().entries.map((
                              entry,
                            ) {
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
                                      content: const Text(
                                        '¿Eliminar esta evaluación?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(false),
                                          child: const Text('Cancelar'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(true),
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
                                    color: Color(0xFFFF6106),
                                  ),
                                  title: Text(eval.nombre),
                                  subtitle: Text(
                                    '${eval.porcentaje}% - Nota: ${eval.nota.toStringAsFixed(1)}',
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${((eval.nota * eval.porcentaje) / 100).toStringAsFixed(1)} pts',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          color: Color(0xFFFF6106),
                                        ),
                                        onPressed: () {
                                          _showEditNotaDialog(
                                            materiaIndex,
                                            evalIndex,
                                            eval,
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.red,
                                        ),
                                        onPressed: () {
                                          _eliminarEvaluacion(
                                            materiaIndex,
                                            evalIndex,
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Text(
                                'Total acumulado: ${_calcularTotalAcumulado(materiaIndex).toStringAsFixed(1)} pts',
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
    );
  }

  void _showEditMateriaDialog(int materiaId, String currentName) {
    final controller =
        _editMateriaControllers[materiaId] ??
        TextEditingController(text: currentName);
    _editMateriaControllers[materiaId] = controller;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Editar nombre de materia'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: 'Nuevo nombre',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _editarNombreMateria(materiaId);
              },
              child: Text('Guardar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFF8200),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showEditNotaDialog(int materiaIndex, int evalIndex, Evaluacion eval) {
    final controller =
        _editEvalNotaControllers[eval.id] ??
        TextEditingController(text: eval.nota.toString());
    _editEvalNotaControllers[eval.id] = controller;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Editar nota de evaluación'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${eval.nombre} (${eval.porcentaje}%)'),
              SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Nota (0-20)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _editarNotaEvaluacion(materiaIndex, evalIndex);
              },
              child: Text('Guardar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFF8200),
              ),
            ),
          ],
        );
      },
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