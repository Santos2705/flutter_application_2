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

  // Definición de las semanas académicas para 2025
  static final Map<int, DateTimeRange> _academicWeeks = {
    1: DateTimeRange(start: DateTime(2025, 4, 20), end: DateTime(2025, 4, 26)),
    2: DateTimeRange(start: DateTime(2025, 4, 27), end: DateTime(2025, 5, 3)),
    3: DateTimeRange(start: DateTime(2025, 5, 4), end: DateTime(2025, 5, 10)),
    4: DateTimeRange(start: DateTime(2025, 5, 11), end: DateTime(2025, 5, 17)),
    5: DateTimeRange(start: DateTime(2025, 5, 18), end: DateTime(2025, 5, 24)),
    6: DateTimeRange(start: DateTime(2025, 5, 25), end: DateTime(2025, 5, 31)),
    7: DateTimeRange(start: DateTime(2025, 6, 1), end: DateTime(2025, 6, 7)),
    8: DateTimeRange(start: DateTime(2025, 6, 8), end: DateTime(2025, 6, 14)),
    9: DateTimeRange(start: DateTime(2025, 6, 15), end: DateTime(2025, 6, 21)),
    10: DateTimeRange(start: DateTime(2025, 6, 22), end: DateTime(2025, 6, 28)),
    11: DateTimeRange(start: DateTime(2025, 6, 29), end: DateTime(2025, 7, 5)),
    12: DateTimeRange(start: DateTime(2025, 7, 6), end: DateTime(2025, 7, 12)),
  };

  int _getAcademicWeek(DateTime date) {
    for (var entry in _academicWeeks.entries) {
      if (!date.isBefore(entry.value.start) && !date.isAfter(entry.value.end)) {
        return entry.key;
      }
    }
    if (date.isBefore(_academicWeeks[1]!.start)) return 1;
    return 12;
  }

  Set<DateTime> _getTaskDates() {
    final Set<DateTime> dates = {};
    for (var weekTasks in _weeklyTasks.values) {
      for (var task in weekTasks) {
        if (task['fecha'] != null) {
          dates.add(DateTime.parse(task['fecha']));
        }
      }
    }
    return dates;
  }

  List<Map<String, dynamic>> _getTasksForDay(DateTime day) {
    if (widget.username == null) return [];
    
    return _weeklyTasks.values
        .expand((weekTasks) => weekTasks)
        .where((task) => task['fecha'] != null && 
            isSameDay(DateTime.parse(task['fecha']), day))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedWeek = _getAcademicWeek(now);
    _selectedDay = now;
    _focusedDay = now;
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

    final taskDates = _getTaskDates();

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Selector de semana
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
                          'Semana $_selectedWeek (${DateFormat('dd/MM').format(_academicWeeks[_selectedWeek]!.start)} - ${DateFormat('dd/MM').format(_academicWeeks[_selectedWeek]!.end)})',
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
                        final weekRange = _academicWeeks[week]!;
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
                                  '${DateFormat('dd/MM').format(weekRange.start)}-${DateFormat('dd/MM').format(weekRange.end)}',
                                  style: TextStyle(
                                    color: _selectedWeek == week
                                        ? Colors.white
                                        : Colors.grey.shade700,
                                    fontSize: 10,
                                  ),
                                ),
                                Text(
                                  '${_weeklyTasks[week]?.length ?? 0} tareas',
                                  style: TextStyle(
                                    color: _selectedWeek == week
                                        ? Colors.white
                                        : Colors.grey.shade700,
                                    fontSize: 10,
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

            // 2. Lista de tareas
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

            // 3. Calendario con tareas integradas
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    TableCalendar(
                      firstDay: DateTime(2025, 1, 1),
                      lastDay: DateTime(2025, 12, 31),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                          final newWeek = _getAcademicWeek(selectedDay);
                          if (newWeek != _selectedWeek) {
                            _selectedWeek = newWeek;
                            widget.onWeekChanged(newWeek);
                          }
                        });
                      },
                      calendarBuilders: CalendarBuilders(
                        markerBuilder: (context, date, events) {
                          if (taskDates.contains(date)) {
                            return Positioned(
                              right: 1,
                              bottom: 1,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  shape: BoxShape.circle,
                                ),
                                width: 8,
                                height: 8,
                              ),
                            );
                          }
                          return null;
                        },
                      ),
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
                    if (_selectedDay != null)
                      ..._getTasksForDay(_selectedDay!).map((task) => ListTile(
                        title: Text(task['descripcion']),
                        subtitle: Text(
                          'Semana ${task['semana']} • ${task['fecha'] != null ? DateFormat('dd/MM/yyyy').format(DateTime.parse(task['fecha'])) : 'Sin fecha'}',
                        ),
                      )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}