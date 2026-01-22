import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:trackstar/models/activity.dart';
import 'package:trackstar/models/user.dart';

class DatabaseService {
  // Singleton instance
  static final DatabaseService instance = DatabaseService._init(); // empty constructor

  static Database? _database; 

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    // Open the database and store the reference
    final database = openDatabase(
      join(await getDatabasesPath(), 'main_database.db'),
      // When the database is first created, create tables
      onCreate: (db, version) async {
        // Create users table
        await db.execute(
          'CREATE TABLE users(id INTEGER PRIMARY KEY, name TEXT, email TEXT, password TEXT)',
        );
        
        // Create activities table
        await db.execute(
          '''CREATE TABLE activities(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT NOT NULL,
            distance REAL NOT NULL,
            duration INTEGER NOT NULL,
            avgSpeed REAL NOT NULL,
            startTime TEXT NOT NULL,
            endTime TEXT,
            routePolyline TEXT,
            userId INTEGER NOT NULL,
            FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
          )''',
        );
      },
      version: 2,
      // Handle database upgrades
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Add activities table if upgrading from version 1
          await db.execute(
            '''CREATE TABLE activities(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              type TEXT NOT NULL,
              distance REAL NOT NULL,
              duration INTEGER NOT NULL,
              avgSpeed REAL NOT NULL,
              startTime TEXT NOT NULL,
              endTime TEXT,
              routePolyline TEXT,
              userId INTEGER NOT NULL,
              FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
            )''',
          );
        }
      },
    );
    return database;
  }

  Future<void> insertUser(User user) async {
    final db = await database;

    await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<User>> getUsers() async {
    final db = await database; // reference to the database

    final List<Map<String, Object?>> userMaps = await db.query('users');

    // Convert the list of each user's fields into a list of `User` objects
    return [
      for (final {
          'id': id as int, 
          'name': name as String, 
          'email': email as String, 
          'password': password as String,
        } in userMaps)
        User(
          id: id, 
          name: name, 
          email: email, 
          password: password
        ),
    ];
  }

  Future<void> updateUser(User user) async {
    final db = await database; // reference to the database

    await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<void> deleteUser(int? id) async {
    final db = await database; // reference to the database

    await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<User?> getUserByEmail(String email) async {
    // Query database WHERE email = ?
    // Return User if found, null if not found
    final db = await database;
    
    final List<Map<String, Object?>> results = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    
    if (results.isEmpty) {
      return null;
    }
    
    final userMap = results.first;
    return User(
      id: userMap['id'] as int?,
      name: userMap['name'] as String,
      email: userMap['email'] as String,
      password: userMap['password'] as String,
    );
  }

  // activity methods
  Future<int> insertActivity(Activity activity) async {
    final db = await database;
    final id = await db.insert(
      'activities',
      activity.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return id;
  }

  Future<List<Activity>> getActivitiesByUser(int userId) async {
    final db = await database;
    final List<Map<String, Object?>> activityMaps = await db.query(
      'activities',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'startTime DESC', // Most recent first
    );

    return activityMaps.map((map) => Activity.fromMap(map)).toList();
  }

  /// Get activities from the last 7 days for a specific user
  Future<List<Activity>> getActivitiesThisWeek(int userId) async {
    final db = await database;
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    final List<Map<String, Object?>> activityMaps = await db.query(
      'activities',
      where: 'userId = ? AND startTime >= ?',
      whereArgs: [userId, weekAgo.toIso8601String()],
      orderBy: 'startTime DESC',
    );

    return activityMaps.map((map) => Activity.fromMap(map)).toList();
  }

  Future<Map<String, dynamic>> getUserStats(int userId) async {
    final db = await database;
    final result = await db.rawQuery(
      '''SELECT 
        COUNT(*) as totalActivities,
        SUM(distance) as totalDistance,
        SUM(duration) as totalDuration
      FROM activities 
      WHERE userId = ?''',
      [userId],
    );

    if (result.isEmpty) {
      return {
        'totalActivities': 0,
        'totalDistance': 0.0,
        'totalDuration': 0,
      };
    }

    return {
      'totalActivities': result.first['totalActivities'] as int,
      'totalDistance': (result.first['totalDistance'] as num?)?.toDouble() ?? 0.0,
      'totalDuration': result.first['totalDuration'] as int? ?? 0,
    };
  }

  Future<void> deleteActivity(int id) async {
    final db = await database;
    await db.delete(
      'activities',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteAllActivitiesForUser(int userId) async {
    final db = await database;
    await db.delete(
      'activities',
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }
}