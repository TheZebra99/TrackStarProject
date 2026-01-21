import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:trackstar/models/user.dart';

class DatabaseService {
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
      // When the database is first created, create a table to store users
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE users(id INTEGER PRIMARY KEY, name TEXT, email TEXT, password TEXT)',
        );
      },
      // Set the version. This executes the onCreate function and provides a
      // path to perform database upgrades and downgrades.
      version: 1,
    );
    return database;
  }

  Future<void> insertUser(User user) async {
    // Get a reference to the database.
    final db = await database;

    // Insert the User into the correct table
    await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // A method that retrieves all the users from the users table.
  Future<List<User>> getUsers() async {
    // Get a reference to the database.
    final db = await database;

    // Query the table for all the users.
    final List<Map<String, Object?>> userMaps = await db.query('users');

    // Convert the list of each user's fields into a list of `User` objects.
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
    // Get a reference to the database.
    final db = await database;

    // Update the given User.
    await db.update(
      'users',
      user.toMap(),
      // Ensure that the User has a matching id.
      where: 'id = ?',
      // Pass the Users's id as a whereArg to prevent SQL injection.
      whereArgs: [user.id],
    );
  }

  Future<void> deleteUser(int? id) async {
    // Get a reference to the database.
    final db = await database;

    await db.delete(
      'users',
      // Use a `where` clause to delete a specific user.
      where: 'id = ?',
      // Pass the User's id as a whereArg to prevent SQL injection.
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
}