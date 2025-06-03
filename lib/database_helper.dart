// database_helper.dart - Versión ampliada
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

    await _createDataTables(db);
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createDataTables(db);
    }
  }

  Future _createDataTables(Database db) async {
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
  }

  // Métodos existentes para usuarios...
  Future<int> createUser(String username, String email, String password) async {
    final db = await instance.database;
    return await db.insert('users', {
      'username': username,
      'email': email,
      'password': password,
    });
  }

  Future<Map<String, dynamic>?> getUser(String username) async {
    final db = await instance.database;
    final result = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
    return result.isNotEmpty ? result.first : null;
  }

  // Nuevos métodos para tareas
  Future<int> insertTarea(int userId, int semana, String descripcion) async {
    final db = await database;
    return await db.insert('tareas', {
      'user_id': userId,
      'semana': semana,
      'descripcion': descripcion,
    });
  }

  Future<List<Map<String, dynamic>>> getTareasPorSemana(
    int userId,
    int semana,
  ) async {
    final db = await database;
    return await db.query(
      'tareas',
      where: 'user_id = ? AND semana = ?',
      whereArgs: [userId, semana],
    );
  }

  Future<int> deleteTarea(int id) async {
    final db = await database;
    return await db.delete('tareas', where: 'id = ?', whereArgs: [id]);
  }

  // Nuevos métodos para materias y evaluaciones
  Future<int> insertMateria(int userId, String nombre) async {
    final db = await database;
    return await db.insert('materias', {'user_id': userId, 'nombre': nombre});
  }

  Future<List<Map<String, dynamic>>> getMaterias(int userId) async {
    final db = await database;
    return await db.query(
      'materias',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<int> deleteMateria(int id) async {
    final db = await database;
    return await db.delete('materias', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertEvaluacion(
    int materiaId,
    String nombre,
    double porcentaje,
    double nota,
  ) async {
    final db = await database;
    return await db.insert('evaluaciones', {
      'materia_id': materiaId,
      'nombre': nombre,
      'porcentaje': porcentaje,
      'nota': nota,
    });
  }

  Future<List<Map<String, dynamic>>> getEvaluacionesPorMateria(
    int materiaId,
  ) async {
    final db = await database;
    return await db.query(
      'evaluaciones',
      where: 'materia_id = ?',
      whereArgs: [materiaId],
    );
  }

  Future<int> deleteEvaluacion(int id) async {
    final db = await database;
    return await db.delete('evaluaciones', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
