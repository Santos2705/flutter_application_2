import 'package:flutter/material.dart';

class NotacionesExample extends StatefulWidget {
  const NotacionesExample({super.key});

  @override
  State<NotacionesExample> createState() => _NotacionesExampleState();
}

class _NotacionesExampleState extends State<NotacionesExample> {
  // Controladores independientes para cada materia
  final List<Materia> _materias = [];
  final _nuevaMateriaController = TextEditingController();
  final List<TextEditingController> _evalControllers = [];
  final List<TextEditingController> _porcentajeControllers = [];
  final List<TextEditingController> _notaControllers = [];

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

  void _agregarMateria() {
    if (_nuevaMateriaController.text.isNotEmpty) {
      setState(() {
        _materias.add(Materia(_nuevaMateriaController.text));
        // Agregar nuevos controladores para esta materia
        _evalControllers.add(TextEditingController());
        _porcentajeControllers.add(TextEditingController());
        _notaControllers.add(TextEditingController());
        _nuevaMateriaController.clear();
      });
    }
  }

  void _agregarEvaluacion(int materiaIndex) {
    final porcentaje =
        double.tryParse(_porcentajeControllers[materiaIndex].text) ?? 0.0;
    final nota = double.tryParse(_notaControllers[materiaIndex].text) ?? 0.0;

    if (_evalControllers[materiaIndex].text.isNotEmpty && porcentaje > 0) {
      setState(() {
        _materias[materiaIndex].evaluaciones.add(
          Evaluacion(_evalControllers[materiaIndex].text, porcentaje, nota),
        );
        // Limpiar solo los controladores de esta materia
        _evalControllers[materiaIndex].clear();
        _porcentajeControllers[materiaIndex].clear();
        _notaControllers[materiaIndex].clear();
      });
    }
  }

  void _eliminarEvaluacion(int materiaIndex, int evalIndex) {
    setState(() {
      _materias[materiaIndex].evaluaciones.removeAt(evalIndex);
    });
  }

  void _eliminarMateria(int materiaIndex) {
    setState(() {
      // Eliminar también los controladores asociados
      _evalControllers.removeAt(materiaIndex);
      _porcentajeControllers.removeAt(materiaIndex);
      _notaControllers.removeAt(materiaIndex);
      _materias.removeAt(materiaIndex);
    });
  }

  double _calcularPromedio(int materiaIndex) {
    return _materias[materiaIndex].evaluaciones.fold<double>(
      0.0,
      (double sum, Evaluacion eval) => sum + eval.puntosObtenidos,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Notas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () {
              setState(() {
                _materias.clear();
                _evalControllers.clear();
                _porcentajeControllers.clear();
                _notaControllers.clear();
              });
            },
            tooltip: 'Borrar todas las materias',
          ),
        ],
      ),
      body: Padding(
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
              child: ListView.builder(
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

                          // Campos para nueva evaluación (usando controladores específicos)
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
                                    controller:
                                        _porcentajeControllers[materiaIndex],
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
                                  onPressed: () =>
                                      _agregarEvaluacion(materiaIndex),
                                ),
                              ],
                            ),
                          ),

                          // Lista de evaluaciones con opción de eliminar
                          ...materia.evaluaciones.asMap().entries.map((entry) {
                            final evalIndex = entry.key;
                            final eval = entry.value;
                            return Dismissible(
                              key: Key('eval-$materiaIndex-$evalIndex'),
                              background: Container(
                                // ignorar: error de aqui abajo, es una recomendacion de mejora
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
  List<Evaluacion> evaluaciones = [];

  Materia(this.nombre);
}

class Evaluacion {
  String nombre;
  double porcentaje;
  double nota;

  Evaluacion(this.nombre, this.porcentaje, this.nota);

  double get puntosObtenidos => (nota * porcentaje) / 100;
}
