import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'database_helper.dart';

class InicioExample extends StatefulWidget {
  final String? username;
  final Function(int) onWeekChanged;
  final int initialWeek;

  const InicioExample({
    super.key,
    this.username,
    required this.onWeekChanged,
    required this.initialWeek,
  });

  @override
  State<InicioExample> createState() => _InicioExampleState();
}

class _InicioExampleState extends State<InicioExample> {
  bool _showWeekSelector = false;
  late int _selectedWeek;
  final Map<int, List<Map<String, dynamic>>> _weeklyTasks = {};
  bool _isLoading = true;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final TextEditingController _taskController = TextEditingController();
  DateTime? _taskDate;

  @override
  void initState() {
    super.initState();
    _selectedWeek = widget.initialWeek;
    _selectedDay = DateTime.now();
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
        await Future.wait(
          List.generate(12, (week) async {
            final weekNumber = week + 1;
            _weeklyTasks[weekNumber] = await DatabaseHelper.instance
                .getTareasPorSemana(user['id'], weekNumber);
          }),
        );
      }
    } catch (e) {
      debugPrint('Error al cargar tareas: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addTask() async {
    if (widget.username == null || _taskController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final user = await DatabaseHelper.instance.getUser(widget.username!);
      if (user != null) {
        await DatabaseHelper.instance.insertTarea(
          user['id'],
          _selectedWeek,
          _taskController.text.trim(),
          fecha: _taskDate,
        );

        _taskController.clear();
        _taskDate = null;
        await _loadWeeklyTasks();
      }
    } catch (e) {
      debugPrint('Error al agregar tarea: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al agregar tarea: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteTask(int taskId) async {
    if (widget.username == null) return;

    setState(() => _isLoading = true);

    try {
      await DatabaseHelper.instance.deleteTarea(taskId);
      await _loadWeeklyTasks();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tarea eliminada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error al eliminar tarea: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar tarea: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectTaskDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _taskDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.orange,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _taskDate = picked;
      });
    }
  }

  void _showAddTaskDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Agregar Tarea'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _taskController,
                      decoration: const InputDecoration(
                        labelText: 'Descripción de la tarea',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _taskDate == null
                                ? 'Sin fecha específica'
                                : 'Fecha: ${DateFormat('dd/MM/yyyy').format(_taskDate!)}',
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.calendar_today, color: Colors.orange),
                          onPressed: () async {
                            await _selectTaskDate(context);
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _addTask();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  child: const Text('Agregar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selector de semana
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
                            widget.onWeekChanged(week);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: _selectedWeek == week
                                  ? Colors.orange
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Semana $week',
                                  style: TextStyle(
                                    color: _selectedWeek == week
                                        ? Colors.white
                                        : Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_weeklyTasks[week]?.length ?? 0} tareas',
                                  style: TextStyle(
                                    color: _selectedWeek == week
                                        ? Colors.white
                                        : Colors.grey.shade700,
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

            // Tareas por semana (ahora arriba)
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
                        IconButton(
                          icon: const Icon(Icons.add, color: Colors.orange),
                          onPressed: _showAddTaskDialog,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _weeklyTasks[_selectedWeek]?.isEmpty ?? true
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Text('No hay tareas esta semana'),
                          )
                        : Column(
                            children: _weeklyTasks[_selectedWeek]!
                                .map(
                                  (task) => Dismissible(
                                    key: Key(task['id'].toString()),
                                    direction: DismissDirection.endToStart,
                                    background: Container(
                                      color: Colors.red,
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.only(right: 20),
                                      child: const Icon(Icons.delete, color: Colors.white),
                                    ),
                                    confirmDismiss: (direction) async {
                                      return await showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Confirmar'),
                                          content: const Text('¿Eliminar esta tarea?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(context).pop(false),
                                              child: const Text('Cancelar'),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.of(context).pop(true),
                                              child: const Text('Eliminar'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    onDismissed: (direction) => _deleteTask(task['id']),
                                    child: ListTile(
                                      title: Text(task['descripcion']),
                                      subtitle: task['fecha'] != null
                                          ? Text(
                                              'Fecha: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(task['fecha']))}',
                                            )
                                          : null,
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _deleteTask(task['id']),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Calendario (ahora abajo)
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  calendarStyle: CalendarStyle(
                    selectedDecoration: BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    leftChevronIcon: Icon(
                      Icons.chevron_left,
                      color: Colors.orange,
                    ),
                    rightChevronIcon: Icon(
                      Icons.chevron_right,
                      color: Colors.orange,
                    ),
                    titleTextStyle: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: TextStyle(color: Colors.orange),
                    weekendStyle: TextStyle(color: Colors.orange),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}