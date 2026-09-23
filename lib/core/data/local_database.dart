import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class LocalDatabase {
  static const String defaultDatabaseName = 'earn_your_scroll.db';
  static const int _databaseVersion = 1;

  final String databaseName;
  final bool inMemory;

  Database? _database;
  Future<Database>? _initializingDatabase;

  LocalDatabase({
    this.databaseName = defaultDatabaseName,
    this.inMemory = false,
  });

  Future<Database> get database async {
    if (_database != null) return _database!;

    // Multiple repositories can be read during app startup. Share the first
    // open operation so they cannot create competing handles (particularly
    // important for the in-memory database used by tests).
    _initializingDatabase ??= _initDatabase();
    try {
      _database = await _initializingDatabase;
      return _database!;
    } finally {
      _initializingDatabase = null;
    }
  }

  Future<Database> _initDatabase() async {
    if (inMemory) {
      return openDatabase(
        inMemoryDatabasePath,
        version: _databaseVersion,
        onCreate: _onCreate,
        singleInstance: false,
      );
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE user_settings (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        selected_theme TEXT NOT NULL,
        selected_restricted_apps TEXT NOT NULL,
        reward_rate INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE exercise_sessions (
        id TEXT PRIMARY KEY,
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        push_ups INTEGER NOT NULL,
        earned_seconds INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE time_ledger (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        earned_seconds INTEGER NOT NULL,
        used_seconds INTEGER NOT NULL,
        remaining_seconds INTEGER NOT NULL,
        last_updated TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE daily_stats (
        date TEXT PRIMARY KEY,
        push_ups INTEGER NOT NULL,
        earned_seconds INTEGER NOT NULL,
        used_seconds INTEGER NOT NULL
      )
    ''');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
    _initializingDatabase = null;
  }
}
