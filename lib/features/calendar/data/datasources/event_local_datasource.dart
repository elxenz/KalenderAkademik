import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/event_model.dart';

abstract class EventLocalDataSource {
  Future<List<EventModel>> getAllEvents();
  Future<int> insertEvent(EventModel event);
  Future<void> updateEvent(EventModel event);
  Future<void> deleteEvent(int id);
  Future<List<EventModel>> searchEvents(String query);
}

class EventLocalDataSourceImpl implements EventLocalDataSource {
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'calendar.db');
    return await openDatabase(
      path,
      version: 4,
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
        colorValue INTEGER,
        isRecurring INTEGER,
        recurrenceRule TEXT
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
    if (oldVersion < 4) {
      await db.execute(
          "ALTER TABLE events ADD COLUMN isRecurring INTEGER NOT NULL DEFAULT 0");
      await db.execute(
          "ALTER TABLE events ADD COLUMN recurrenceRule TEXT NOT NULL DEFAULT 'none'");
    }
  }

  @override
  Future<int> insertEvent(EventModel event) async {
    final db = await database;
    return await db.insert('events', event.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<List<EventModel>> getAllEvents() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('events');
    return List.generate(maps.length, (i) => EventModel.fromMap(maps[i]));
  }

  @override
  Future<void> updateEvent(EventModel event) async {
    final db = await database;
    await db.update('events', event.toMap(),
        where: 'id = ?', whereArgs: [event.id]);
  }

  @override
  Future<void> deleteEvent(int id) async {
    final db = await database;
    await db.delete('events', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<EventModel>> searchEvents(String query) async {
    final db = await database;
    if (query.isEmpty) return [];
    final maps = await db.query('events',
        where: 'title LIKE ?', whereArgs: ['%$query%'], orderBy: 'date DESC');
    return List.generate(maps.length, (i) => EventModel.fromMap(maps[i]));
  }
}
