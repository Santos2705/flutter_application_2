import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_application_2/database_helper.dart';

class PerfilExample extends StatefulWidget {
  final String? username;

  const PerfilExample({super.key, this.username});

  @override
  State<PerfilExample> createState() => _PerfilExampleState();
}

class _PerfilExampleState extends State<PerfilExample> {
  late TextEditingController _nombreController;
  late TextEditingController _emailController;
  late TextEditingController _descripcionController;
  bool _editando = false;
  bool _isLoading = true;
  Map<String, dynamic>? _userData;

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController();
    _emailController = TextEditingController();
    _descripcionController = TextEditingController(
      text: 'Ej: Estudiante De la Unimet ',
    );
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (widget.username == null) {
      setState(() {
        _isLoading = false;
        _nombreController.text = 'Invitado';
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await DatabaseHelper.instance.getUser(widget.username!);
      if (user != null) {
        setState(() {
          _userData = user;
          _nombreController.text = user['username'];
          _emailController.text = user['email'];
          _descripcionController.text =
              user['descripcion'] ??
              'Estudiante de Ingeniería de Software en la Unimet';
        });
      }
    } catch (e) {
      print('Error al cargar datos del usuario: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateUserData() async {
    if (widget.username == null) return;

    if (_nombreController.text.isEmpty || _emailController.text.isEmpty) {
      _showSnackBar('Nombre y email son obligatorios');
      return;
    }

    if (!_emailController.text.contains('@')) {
      _showSnackBar('Ingrese un email válido');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final db = await DatabaseHelper.instance.database;
      await db.update(
        'users',
        {
          'username': _nombreController.text,
          'email': _emailController.text,
          'descripcion': _descripcionController.text,
        },
        where: 'username = ?',
        whereArgs: [widget.username],
      );

      _showSnackBar('Datos actualizados correctamente');
      _toggleEdicion();
    } catch (e) {
      _showSnackBar('Error al actualizar datos: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _toggleEdicion() {
    setState(() {
      _editando = !_editando;
      if (!_editando && widget.username != null) {
        _updateUserData();
      }
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.orange),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _descripcionController.dispose();
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
              Text('Cargando perfil...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
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
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 50,
                      color: Color(0xFFFF9800),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _editando
                      ? TextField(
                          controller: _nombreController,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
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
                          _nombreController.text,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                  if (widget.username != null) ...[
                    const SizedBox(height: 8),
                    _editando
                        ? TextField(
                            controller: _emailController,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Ingresa tu email',
                              hintStyle: TextStyle(color: Colors.white70),
                            ),
                          )
                        : Text(
                            _emailController.text,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 4,
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
                            'Información del Perfil',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFF9800),
                            ),
                          ),
                          if (widget.username != null)
                            IconButton(
                              icon: Icon(
                                _editando ? Icons.check : Icons.edit,
                                color: const Color(0xFFFF9800),
                              ),
                              onPressed: _toggleEdicion,
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Sobre mí',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      _editando
                          ? TextField(
                              controller: _descripcionController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                hintText: 'Describe algo sobre ti',
                              ),
                            )
                          : Text(
                              _descripcionController.text,
                              style: const TextStyle(fontSize: 14),
                            ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      const Text(
                        'Mi Calendario',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF9800),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TableCalendar(
                        firstDay: DateTime.now().subtract(
                          const Duration(days: 365),
                        ),
                        lastDay: DateTime.now().add(const Duration(days: 365)),
                        focusedDay: _focusedDay,
                        calendarFormat: _calendarFormat,
                        headerStyle: HeaderStyle(
                          titleTextStyle: const TextStyle(
                            color: Color(0xFFFF9800),
                            fontWeight: FontWeight.bold,
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
                            color: const Color(0xFFFF9800).withOpacity(0.5),
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