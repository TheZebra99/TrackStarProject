import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:trackstar/models/activity.dart';
import 'package:trackstar/models/user.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;
  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    return openDatabase(
      join(await getDatabasesPath(), 'main_database.db'),
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE users(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, email TEXT UNIQUE, password TEXT)',
        );
        await db.execute('''
          CREATE TABLE activities(
            id            INTEGER PRIMARY KEY AUTOINCREMENT,
            type          TEXT    NOT NULL,
            distance      REAL    NOT NULL,
            duration      INTEGER NOT NULL,
            avgSpeed      REAL    NOT NULL,
            startTime     TEXT    NOT NULL,
            endTime       TEXT,
            routePolyline TEXT,
            userId        INTEGER NOT NULL,
            isFavorite    INTEGER NOT NULL DEFAULT 0,
            FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS activities(
              id            INTEGER PRIMARY KEY AUTOINCREMENT,
              type          TEXT    NOT NULL,
              distance      REAL    NOT NULL,
              duration      INTEGER NOT NULL,
              avgSpeed      REAL    NOT NULL,
              startTime     TEXT    NOT NULL,
              endTime       TEXT,
              routePolyline TEXT,
              userId        INTEGER NOT NULL,
              isFavorite    INTEGER NOT NULL DEFAULT 0,
              FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
            )
          ''');
        }
        if (oldVersion < 3) {
          try {
            await db.execute(
              'ALTER TABLE activities ADD COLUMN isFavorite INTEGER NOT NULL DEFAULT 0',
            );
          } catch (_) {} // column may already exist
        }
      },
      version: 3,
    );
  }

  // user section

  /// Inserts a new user and returns the new row id (= the users id)
  Future<int> insertUser(User user) async {
    final db = await database;
    return db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort, // fail on duplicate email
    );
  }

  /// Returns true if an account with an email already exists
  Future<bool> emailExists(String email) async {
    final db = await database;
    final rows = await db.query('users',
        where: 'email = ?', whereArgs: [email], limit: 1);
    return rows.isNotEmpty;
  }

  Future<List<User>> getUsers() async {
    final db = await database;
    final maps = await db.query('users');
    return maps
        .map((m) => User(
              id: m['id'] as int?,
              name: m['name'] as String,
              email: m['email'] as String,
              password: m['password'] as String,
            ))
        .toList();
  }

  Future<void> updateUser(User user) async {
    final db = await database;
    await db.update('users', user.toMap(),
        where: 'id = ?', whereArgs: [user.id]);
  }

  Future<void> deleteUser(int? id) async {
    final db = await database;
    await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  Future<User?> getUserByEmail(String email) async {
    final db = await database;
    final results =
        await db.query('users', where: 'email = ?', whereArgs: [email]);
    if (results.isEmpty) return null;
    final m = results.first;
    return User(
      id: m['id'] as int?,
      name: m['name'] as String,
      email: m['email'] as String,
      password: m['password'] as String,
    );
  }

  // activity section

  Future<int> insertActivity(Activity activity) async {
    final db = await database;
    return db.insert('activities', activity.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Activity>> getActivitiesByUser(int userId) async {
    final db = await database;
    final maps = await db.query('activities',
        where: 'userId = ?',
        whereArgs: [userId],
        orderBy: 'startTime DESC');
    return maps.map((m) => Activity.fromMap(m)).toList();
  }

  Future<List<Activity>> getActivitiesThisWeek(int userId) async {
    final db = await database;
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final maps = await db.query('activities',
        where: 'userId = ? AND startTime >= ?',
        whereArgs: [userId, weekAgo.toIso8601String()],
        orderBy: 'startTime DESC');
    return maps.map((m) => Activity.fromMap(m)).toList();
  }

  Future<List<Activity>> getFavoriteActivities(int userId) async {
    final db = await database;
    final maps = await db.query('activities',
        where: 'userId = ? AND isFavorite = 1',
        whereArgs: [userId],
        orderBy: 'startTime DESC');
    return maps.map((m) => Activity.fromMap(m)).toList();
  }

  Future<void> toggleFavorite(int activityId, bool isFavorite) async {
    final db = await database;
    await db.update(
      'activities',
      {'isFavorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [activityId],
    );
  }

  Future<Map<String, dynamic>> getUserStats(int userId) async {
    final db = await database;
    final result = await db.rawQuery(
      '''SELECT COUNT(*) AS totalActivities,
                SUM(distance) AS totalDistance,
                SUM(duration) AS totalDuration
         FROM activities WHERE userId = ?''',
      [userId],
    );
    if (result.isEmpty) {
      return {'totalActivities': 0, 'totalDistance': 0.0, 'totalDuration': 0};
    }
    return {
      'totalActivities': result.first['totalActivities'] as int,
      'totalDistance': (result.first['totalDistance'] as num?)?.toDouble() ?? 0.0,
      'totalDuration': result.first['totalDuration'] as int? ?? 0,
    };
  }

  Future<void> deleteActivity(int id) async {
    final db = await database;
    await db.delete('activities', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAllActivitiesForUser(int userId) async {
    final db = await database;
    await db.delete('activities', where: 'userId = ?', whereArgs: [userId]);
  }
}