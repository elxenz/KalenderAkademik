import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../features/calendar/domain/entities/event.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static Database? _database;
  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'calendar.db');
    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        date TEXT NOT NULL,
        startTime TEXT NOT NULL,
        endTime TEXT NOT NULL,
        description TEXT,
        colorValue INTEGER
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
          "ALTER TABLE events ADD COLUMN startTime TEXT NOT NULL DEFAULT '00:00'");
      await db.execute(
          "ALTER TABLE events ADD COLUMN endTime TEXT NOT NULL DEFAULT '00:00'");
    }
    if (oldVersion < 3) {
      await db.execute("ALTER TABLE events ADD COLUMN description TEXT");
      await db.execute(
          "ALTER TABLE events ADD COLUMN colorValue INTEGER NOT NULL DEFAULT 4282557951");
    }
  }

  Future<int> insertEvent(Event event) async {
    final db = await database;
    return await db.insert('events', event.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Event>> getEventsForDay(DateTime date) async {
    final db = await database;
    String dateString = date.toIso8601String().split('T').first;
    final List<Map<String, dynamic>> maps =
        await db.query('events', where: "date = ?", whereArgs: [dateString]);

    return List.generate(maps.length, (i) {
      return Event(
        id: maps[i]['id'],
        title: maps[i]['title'],
        description: maps[i]['description'] ?? '',
        date: DateTime.parse(maps[i]['date']),
        startTime: maps[i]['startTime'],
        endTime: maps[i]['endTime'],
        colorValue: maps[i]['colorValue'],
      );
    });
  }

  Future<List<Event>> getAllEvents() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('events');

    return List.generate(maps.length, (i) {
      return Event(
        id: maps[i]['id'],
        title: maps[i]['title'],
        description: maps[i]['description'] ?? '',
        date: DateTime.parse(maps[i]['date']),
        startTime: maps[i]['startTime'],
        endTime: maps[i]['endTime'],
        colorValue: maps[i]['colorValue'],
      );
    });
  }

  Future<void> updateEvent(Event event) async {
    final db = await database;
    await db.update('events', event.toMap(),
        where: 'id = ?', whereArgs: [event.id]);
  }

  Future<void> deleteEvent(int id) async {
    final db = await database;
    await db.delete('events', where: 'id = ?', whereArgs: [id]);
  }

  // --- FUNGSI BARU UNTUK PENCARIAN ---
  Future<List<Event>> searchEvents(String query) async {
    final db = await database;
    if (query.isEmpty) {
      return [];
    }
    final List<Map<String, dynamic>> maps = await db.query(
      'events',
      where: 'title LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) {
      return Event(
        id: maps[i]['id'],
        title: maps[i]['title'],
        description: maps[i]['description'] ?? '',
        date: DateTime.parse(maps[i]['date']),
        startTime: maps[i]['startTime'],
        endTime: maps[i]['endTime'],
        colorValue: maps[i]['colorValue'],
      );
    });
  }
}
