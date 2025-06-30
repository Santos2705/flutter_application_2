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
      version: 6, // Incrementado de 5 a 6 por la nueva tabla
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
        password TEXT NOT NULL,
        descripcion TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE trimestres (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        nombre TEXT NOT NULL,
        fecha_inicio TEXT,
        fecha_fin TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE materias (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        trimestre_id INTEGER NOT NULL,
        nombre TEXT NOT NULL,
        FOREIGN KEY (trimestre_id) REFERENCES trimestres (id) ON DELETE CASCADE
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

    await db.execute('''
      CREATE TABLE tareas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        semana INTEGER NOT NULL,
        descripcion TEXT NOT NULL,
        fecha TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE mensajes_contacto (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        email TEXT NOT NULL,
        mensaje TEXT NOT NULL,
        fecha TEXT NOT NULL
      )
    ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createTables(db);
    }
    if (oldVersion < 3) {
      await db.execute("ALTER TABLE users ADD COLUMN descripcion TEXT");
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE trimestres (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          nombre TEXT NOT NULL,
          fecha_inicio TEXT,
          fecha_fin TEXT,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        ALTER TABLE materias RENAME TO materias_old
      ''');

      await db.execute('''
        CREATE TABLE materias (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          trimestre_id INTEGER NOT NULL,
          nombre TEXT NOT NULL,
          FOREIGN KEY (trimestre_id) REFERENCES trimestres (id) ON DELETE CASCADE
        )
        
      ''');
      await db.execute('''
      CREATE TABLE mensajes_contacto (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        email TEXT NOT NULL,
        mensaje TEXT NOT NULL,
        fecha TEXT NOT NULL
      )
    ''');

      final userIds = await db.query('users', columns: ['id']);
      for (var user in userIds) {
        final trimestreId = await db.insert('trimestres', {
          'user_id': user['id'],
          'nombre': 'Trimestre Inicial',
          'fecha_inicio': DateTime.now().toIso8601String(),
          'fecha_fin': DateTime.now().add(Duration(days: 90)).toIso8601String(),
        });

        final materias = await db.query(
          'materias_old',
          where: 'user_id = ?',
          whereArgs: [user['id']],
        );
        for (var materia in materias) {
          await db.insert('materias', {
            'trimestre_id': trimestreId,
            'nombre': materia['nombre'],
          });
        }
      }

      await db.execute('DROP TABLE materias_old');
    }
    if (oldVersion < 5) {
      await db.execute('ALTER TABLE tareas ADD COLUMN fecha TEXT');
    }
    if (oldVersion < 6) {
      await db.execute('''
        CREATE TABLE mensajes_contacto (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nombre TEXT NOT NULL,
          email TEXT NOT NULL,
          mensaje TEXT NOT NULL,
          fecha TEXT NOT NULL
        )
      ''');
    }
  }

  Future _createTables(Database db) async {
    await _createDB(db, 1);
  }

  // Método para insertar mensajes de contacto
  Future<int> insertMensajeContacto(
    String nombre,
    String email,
    String mensaje,
  ) async {
    final db = await database;
    return await db.insert('mensajes_contacto', {
      'nombre': nombre,
      'email': email,
      'mensaje': mensaje,
      'fecha': DateTime.now().toIso8601String(),
    });
  }

  // Resto de los métodos existentes...
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

  Future<int> insertTrimestre(
    int userId,
    String nombre, {
    String? fechaInicio,
    String? fechaFin,
  }) async {
    final db = await database;
    return await db.insert('trimestres', {
      'user_id': userId,
      'nombre': nombre,
      'fecha_inicio': fechaInicio,
      'fecha_fin': fechaFin,
    });
  }

  Future<List<Map<String, dynamic>>> getTrimestres(int userId) async {
    final db = await database;
    return await db.query(
      'trimestres',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'fecha_inicio ASC',
    );
  }

  Future<int> deleteTrimestre(int id) async {
    final db = await database;
    return await db.delete('trimestres', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getMateriasPorTrimestre(
    int trimestreId,
  ) async {
    final db = await database;
    return await db.query(
      'materias',
      where: 'trimestre_id = ?',
      whereArgs: [trimestreId],
    );
  }

  Future<int> insertMateria(int trimestreId, String nombre) async {
    final db = await database;
    return await db.insert('materias', {
      'trimestre_id': trimestreId,
      'nombre': nombre,
    });
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

  Future<int> insertTarea(
    int userId,
    int semana,
    String descripcion, {
    DateTime? fecha,
  }) async {
    final db = await database;
    return await db.insert('tareas', {
      'user_id': userId,
      'semana': semana,
      'descripcion': descripcion,
      'fecha': fecha?.toIso8601String(),
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

  Future<double> calcularPromedioTrimestre(int trimestreId) async {
    final db = await database;
    final materias = await db.query(
      'materias',
      where: 'trimestre_id = ?',
      whereArgs: [trimestreId],
    );

    double sumaPonderada = 0;
    double totalPorcentaje = 0;

    for (var materia in materias) {
      final evaluaciones = await db.query(
        'evaluaciones',
        where: 'materia_id = ?',
        whereArgs: [materia['id']],
      );

      for (var eval in evaluaciones) {
        sumaPonderada +=
            (eval['nota'] as double) * (eval['porcentaje'] as double);
        totalPorcentaje += eval['porcentaje'] as double;
      }
    }

    return totalPorcentaje > 0 ? sumaPonderada / totalPorcentaje : 0;
  }

  Future<void> close() async {
    final db = await instance.database;
    await db.close();
  }
}
