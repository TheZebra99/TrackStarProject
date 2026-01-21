import 'package:flutter/widgets.dart';
import 'package:trackstar/models/user.dart';
import 'package:trackstar/services/database_service.dart';


void main() async {
  // Avoid errors caused by flutter upgrade.
  // Importing 'package:flutter/widgets.dart' is required.
  WidgetsFlutterBinding.ensureInitialized();

  final dbService = DatabaseService.instance; 

  var guy = User(id: 0, name: 'Fido', email: 'myemail@gmail.com', password: '12345');

  await dbService.insertUser(guy);

  print(await dbService.getUsers());

  guy = User(id: guy.id, name: guy.name, email: 'newmail@gmail.com', password: guy.password);
  await dbService.updateUser(guy);

  // Print the updated results.
  print(await dbService.getUsers()); // Prints Fido with age 42.

  // Delete Fido from the database.
  await dbService.deleteUser(guy.id);

  // Print the list of dogs (empty).
  print(await dbService.getUsers());
}