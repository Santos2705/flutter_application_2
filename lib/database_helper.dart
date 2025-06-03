import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('metro_structure.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2, // Incrementamos la versión
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE tareas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        semana INTEGER NOT NULL,
        descripcion TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE materias (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        nombre TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE evaluaciones (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        materia_id INTEGER NOT NULL,
        nombre TEXT NOT NULL,
        porcentaje REAL NOT NULL,
        nota REAL NOT NULL,
        FOREIGN KEY (materia_id) REFERENCES materias (id) ON DELETE CASCADE
      )
    ''');
    
    // Agregado para depuración
    print('Todas las tablas creadas correctamente');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createDataTables(db);
    }
  }

  // Este método se mantiene aunque parece duplicado para compatibilidad
  Future _createDataTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tareas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        semana INTEGER NOT NULL,
        descripcion TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS materias (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        nombre TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS evaluaciones (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        materia_id INTEGER NOT NULL,
        nombre TEXT NOT NULL,
        porcentaje REAL NOT NULL,
        nota REAL NOT NULL,
        FOREIGN KEY (materia_id) REFERENCES materias (id) ON DELETE CASCADE
      )
    ''');
    
    print('Tablas adicionales creadas en upgrade');
  }

  // Métodos existentes para usuarios...
  Future<int> createUser(String username, String email, String password) async {
    final db = await instance.database;
    try {
      final id = await db.insert('users', {
        'username': username,
        'email': email,
        'password': password,
      });
      print('Usuario creado con ID: $id');
      return id;
    } catch (e) {
      print('Error al crear usuario: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUser(String username) async {
    final db = await instance.database;
    try {
      final result = await db.query(
        'users',
        where: 'username = ?',
        whereArgs: [username],
      );
      print('Usuario obtenido: ${result.isNotEmpty ? result.first : null}');
      return result.isNotEmpty ? result.first : null;
    } catch (e) {
      print('Error al obtener usuario: $e');
      return null;
    }
  }

  // Métodos para tareas
  Future<int> insertTarea(int userId, int semana, String descripcion) async {
    final db = await database;
    try {
      final id = await db.insert('tareas', {
        'user_id': userId,
        'semana': semana,
        'descripcion': descripcion,
      });
      print('Tarea creada con ID: $id');
      return id;
    } catch (e) {
      print('Error al crear tarea: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getTareasPorSemana(
    int userId, 
    int semana,
  ) async {
    final db = await database;
    try {
      final tareas = await db.query(
        'tareas',
        where: 'user_id = ? AND semana = ?',
        whereArgs: [userId, semana],
      );
      print('Tareas obtenidas: ${tareas.length}');
      return tareas;
    } catch (e) {
      print('Error al obtener tareas: $e');
      return [];
    }
  }

  Future<int> deleteTarea(int id) async {
    final db = await database;
    try {
      final count = await db.delete('tareas', where: 'id = ?', whereArgs: [id]);
      print('Tareas eliminadas: $count');
      return count;
    } catch (e) {
      print('Error al eliminar tarea: $e');
      return 0;
    }
  }

  // Métodos para materias
  Future<int> insertMateria(int userId, String nombre) async {
    final db = await database;
    try {
      final id = await db.insert('materias', {
        'user_id': userId,
        'nombre': nombre,
      });
      print('Materia creada con ID: $id');
      return id;
    } catch (e) {
      print('Error al crear materia: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getMaterias(int userId) async {
    final db = await database;
    try {
      final materias = await db.query(
        'materias',
        where: 'user_id = ?',
        whereArgs: [userId],
      );
      print('Materias obtenidas: ${materias.length}');
      return materias;
    } catch (e) {
      print('Error al obtener materias: $e');
      return [];
    }
  }

  Future<int> deleteMateria(int id) async {
    final db = await database;
    try {
      final count = await db.delete('materias', where: 'id = ?', whereArgs: [id]);
      print('Materias eliminadas: $count');
      return count;
    } catch (e) {
      print('Error al eliminar materia: $e');
      return 0;
    }
  }

  // Métodos para evaluaciones
  Future<int> insertEvaluacion(
    int materiaId,
    String nombre,
    double porcentaje,
    double nota,
  ) async {
    final db = await database;
    try {
      final id = await db.insert('evaluaciones', {
        'materia_id': materiaId,
        'nombre': nombre,
        'porcentaje': porcentaje,
        'nota': nota,
      });
      print('Evaluación creada con ID: $id');
      return id;
    } catch (e) {
      print('Error al crear evaluación: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getEvaluacionesPorMateria(
    int materiaId,
  ) async {
    final db = await database;
    try {
      final evaluaciones = await db.query(
        'evaluaciones',
        where: 'materia_id = ?',
        whereArgs: [materiaId],
      );
      print('Evaluaciones obtenidas: ${evaluaciones.length}');
      return evaluaciones;
    } catch (e) {
      print('Error al obtener evaluaciones: $e');
      return [];
    }
  }

  Future<int> deleteEvaluacion(int id) async {
    final db = await database;
    try {
      final count = await db.delete('evaluaciones', where: 'id = ?', whereArgs: [id]);
      print('Evaluaciones eliminadas: $count');
      return count;
    } catch (e) {
      print('Error al eliminar evaluación: $e');
      return 0;
    }
  }

  Future<void> close() async {
    final db = await instance.database;
    await db.close();
    print('Base de datos cerrada');
  }
}