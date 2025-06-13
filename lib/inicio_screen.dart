import 'package:flutter/material.dart';
import 'database_helper.dart';

class InicioExample extends StatefulWidget {
  final String? username;

  const InicioExample({super.key, this.username, required Null Function(dynamic newWeek) onWeekChanged, required int initialWeek});

  @override
  State<InicioExample> createState() => _InicioExampleState();
}

class _InicioExampleState extends State<InicioExample> {
  bool _showWeekSelector = false;
  int _selectedWeek = 1;
  final Map<int, List<Map<String, dynamic>>> _weeklyTasks = {};
  bool _isLoading = true;
  final GlobalKey<_WeekTaskScreenState> _weekTaskScreenKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadWeeklyTasks();
  }

  Future<void> _loadWeeklyTasks() async {
    if (widget.username == null) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final user = await DatabaseHelper.instance.getUser(widget.username!);
      if (user != null) {
        await Future.wait(List.generate(12, (week) async {
          final weekNumber = week + 1;
          _weeklyTasks[weekNumber] = await DatabaseHelper.instance.getTareasPorSemana(user['id'], weekNumber);
        }));
      }
    } catch (e) {
      debugPrint('Error al cargar tareas: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _navigateToWeekScreen(int week) async {
    // Guardamos la semana seleccionada antes de navegar
    final previousWeek = _selectedWeek;
    
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WeekTaskScreen(
          key: _weekTaskScreenKey,
          weekNumber: week,
          username: widget.username,
          tasks: List.from(_weeklyTasks[week] ?? []),
          onTaskUpdated: () => _loadWeekTasks(week),
        ),
      ),
    );

    // Restauramos la semana seleccionada al regresar
    if (mounted) {
      setState(() {
        _selectedWeek = previousWeek;
      });
    }
  }

  Future<void> _loadWeekTasks(int week) async {
    if (widget.username == null) return;

    try {
      final user = await DatabaseHelper.instance.getUser(widget.username!);
      if (user != null) {
        final updatedTasks = await DatabaseHelper.instance.getTareasPorSemana(user['id'], week);
        if (mounted) {
          setState(() {
            _weeklyTasks[week] = updatedTasks;
          });
        }
      }
    } catch (e) {
      debugPrint('Error al actualizar tareas: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Semana académica',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => setState(() => _showWeekSelector = !_showWeekSelector),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.orange),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Semana $_selectedWeek',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Icon(
                          _showWeekSelector ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          color: Colors.orange,
                        ),
                      ],
                    ),
                  ),
                ),
                if (_showWeekSelector)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1.5,
                      children: List.generate(12, (index) {
                        final week = index + 1;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedWeek = week;
                              _showWeekSelector = false;
                            });
                            _navigateToWeekScreen(week);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: _selectedWeek == week ? Colors.orange : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Semana $week',
                                  style: TextStyle(
                                    color: _selectedWeek == week ? Colors.white : Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_weeklyTasks[week]?.length ?? 0} tareas',
                                  style: TextStyle(
                                    color: _selectedWeek == week ? Colors.white : Colors.grey.shade700,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tareas Semana $_selectedWeek',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        TextButton(
                          onPressed: () => _navigateToWeekScreen(_selectedWeek),
                          child: const Text(
                            'Ver todas',
                            style: TextStyle(color: Colors.orange),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _weeklyTasks[_selectedWeek]?.isEmpty ?? true
                        ? const Text('No hay tareas esta semana')
                        : Column(
                            children: [
                              ..._weeklyTasks[_selectedWeek]!
                                  .take(3)
                                  .map((task) => ListTile(
                                        title: Text(task['descripcion']),
                                        dense: true,
                                        contentPadding: EdgeInsets.zero,
                                      ))
                                  .toList(),
                              if (_weeklyTasks[_selectedWeek]!.length > 3)
                                const Text('... más tareas', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: widget.username != null
          ? FloatingActionButton(
              onPressed: () => _navigateToWeekScreen(_selectedWeek),
              backgroundColor: Colors.orange,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}

class WeekTaskScreen extends StatefulWidget {
  final int weekNumber;
  final String? username;
  final List<Map<String, dynamic>> tasks;
  final VoidCallback onTaskUpdated;

  const WeekTaskScreen({
    super.key,
    required this.weekNumber,
    required this.username,
    required this.tasks,
    required this.onTaskUpdated,
  });

  @override
  State<WeekTaskScreen> createState() => _WeekTaskScreenState();
}

class _WeekTaskScreenState extends State<WeekTaskScreen> {
  final TextEditingController _taskController = TextEditingController();
  bool _isLoading = false;
  late List<Map<String, dynamic>> _currentTasks;

  @override
  void initState() {
    super.initState();
    _currentTasks = List.from(widget.tasks);
  }

  Future<void> _addTask() async {
    if (widget.username == null || _taskController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);
    
    try {
      final user = await DatabaseHelper.instance.getUser(widget.username!);
      if (user != null) {
        final newTaskId = await DatabaseHelper.instance.insertTarea(
          user['id'],
          widget.weekNumber,
          _taskController.text.trim(),
        );
        
        setState(() {
          _currentTasks.insert(0, {
            'id': newTaskId,
            'descripcion': _taskController.text.trim(),
          });
        });
        
        _taskController.clear();
        widget.onTaskUpdated();
      }
    } catch (e) {
      debugPrint('Error al agregar tarea: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al agregar tarea: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteTask(int taskId) async {
    setState(() => _isLoading = true);
    
    try {
      await DatabaseHelper.instance.deleteTarea(taskId);
      setState(() {
        _currentTasks.removeWhere((task) => task['id'] == taskId);
      });
      widget.onTaskUpdated();
    } catch (e) {
      debugPrint('Error al eliminar tarea: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar tarea: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tareas Semana ${widget.weekNumber}'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _taskController,
                  decoration: InputDecoration(
                    labelText: 'Nueva tarea',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.add, color: Colors.orange),
                      onPressed: _isLoading ? null : _addTask,
                    ),
                  ),
                  onSubmitted: (_) => _addTask(),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: _currentTasks.isEmpty
                      ? const Center(
                          child: Text('No hay tareas para esta semana'),
                        )
                      : ListView.builder(
                          itemCount: _currentTasks.length,
                          itemBuilder: (context, index) {
                            final task = _currentTasks[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ListTile(
                                title: Text(task['descripcion']),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: _isLoading
                                      ? null
                                      : () => _deleteTask(task['id']),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }
}
