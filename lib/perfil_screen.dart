import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class PerfilExample extends StatefulWidget {
  final String? username; // Nuevo parámetro añadido

  const PerfilExample({super.key, this.username}); // Constructor actualizado

  @override
  State<PerfilExample> createState() => _PerfilExampleState();
}

class _PerfilExampleState extends State<PerfilExample> {
  // Controladores para los campos editables
  late TextEditingController _nombreController;
  final TextEditingController _descripcionController = TextEditingController();
  bool _editando = false;

  // Variables para el calendario
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    // Inicializar el controlador con el username o un valor por defecto
    _nombreController = TextEditingController(
      text: widget.username ?? 'No name',
    );
    _descripcionController.text =
        'Estudiante de Ingeniería de Software en la Unimet';
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  void _toggleEdicion() {
    setState(() {
      _editando = !_editando;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Sección de perfil
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9800),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  // Foto de perfil
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person_2,
                      size: 40,
                      color: Color(0xFFFF9800),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Campo de nombre editable
                  _editando
                      ? TextField(
                          controller: _nombreController,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Ingresa tu nombre',
                            hintStyle: TextStyle(color: Colors.white70),
                          ),
                        )
                      : Text(
                          _nombreController.text.isEmpty
                              ? 'No name'
                              : _nombreController.text,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ],
              ),
            ),

            // Sección de descripción editable
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Sobre mí',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFF9800),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              _editando ? Icons.check : Icons.edit,
                              color: const Color(0xFFFF9800),
                            ),
                            onPressed: _toggleEdicion,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _editando
                          ? TextField(
                              controller: _descripcionController,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: 'Escribe tu descripción',
                              ),
                            )
                          : Text(
                              _descripcionController.text.isEmpty
                                  ? 'No description'
                                  : _descripcionController.text,
                              style: const TextStyle(fontSize: 14),
                            ),
                    ],
                  ),
                ),
              ),
            ),

            // Calendario
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      TableCalendar(
                        firstDay: DateTime.now().subtract(
                          const Duration(days: 180),
                        ),
                        lastDay: DateTime.now().add(const Duration(days: 180)),
                        focusedDay: _focusedDay,
                        calendarFormat: _calendarFormat,
                        headerStyle: HeaderStyle(
                          titleTextStyle: const TextStyle(
                            color: Color(0xFFFF9800),
                          ),
                          formatButtonTextStyle: const TextStyle(
                            color: Colors.white,
                          ),
                          formatButtonDecoration: BoxDecoration(
                            color: const Color(0xFFFF9800),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          leftChevronIcon: const Icon(
                            Icons.chevron_left,
                            color: Color(0xFFFF9800),
                          ),
                          rightChevronIcon: const Icon(
                            Icons.chevron_right,
                            color: Color(0xFFFF9800),
                          ),
                        ),
                        calendarStyle: CalendarStyle(
                          todayDecoration: BoxDecoration(
                            color: const Color(0xFFFF9800).withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          selectedDecoration: const BoxDecoration(
                            color: Color(0xFFFF9800),
                            shape: BoxShape.circle,
                          ),
                        ),
                        selectedDayPredicate: (day) =>
                            isSameDay(_selectedDay, day),
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                          });
                        },
                        onFormatChanged: (format) {
                          setState(() {
                            _calendarFormat = format;
                          });
                        },
                      ),
                    ],
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