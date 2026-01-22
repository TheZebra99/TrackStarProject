import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:trackstar/models/activity.dart';
import 'package:trackstar/models/user.dart';
import 'package:trackstar/services/database_service.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();



  final dbService = DatabaseService.instance; 
  
  print('Deleting old database...');
  final databasePath = await getDatabasesPath();
  final path = join(databasePath, 'main_database.db');
  await deleteDatabase(path);
  print('Old database deleted!\n');
  
  print('========================================');
  print('DATABASE TEST - USERS');
  print('========================================\n');

  print('1. Creating user...');
  var guy = User(
    id: null,
    name: 'Fido',
    email: 'myemail@gmail.com',
    password: '12345',
  );

  await dbService.insertUser(guy);
  print('User created');

  print('\n2. Getting all users...');
  var users = await dbService.getUsers();
  print('Found ${users.length} users');
  for (var user in users) {
    print('ID: ${user.id}, Name: ${user.name}, Email: ${user.email}');
    guy = user; // Get the actual user with DB id
  }

  print('\n3. Updating user email...');
  guy = User(
    id: guy.id,
    name: guy.name,
    email: 'newmail@gmail.com',
    password: guy.password,
  );
  await dbService.updateUser(guy);
  print('User updated');

  // Print the updated results
  users = await dbService.getUsers();
  print('   Updated email: ${users.first.email}');

  print('\n========================================');
  print('DATABASE TEST - ACTIVITIES');
  print('========================================\n');

  print('4. Creating test activity (run)...');
  final activity1 = Activity(
    id: null,
    type: 'run',
    distance: 5.2,
    duration: 1800, // 30 minutes
    avgSpeed: 10.4,
    startTime: DateTime.now().subtract(const Duration(hours: 1)),
    endTime: DateTime.now(),
    userId: guy.id!,
  );

  final activityId = await dbService.insertActivity(activity1);
  print('Activity created with ID: $activityId');
  print('Type: ${activity1.typeName}');
  print('Distance: ${activity1.formattedDistance}');
  print('Duration: ${activity1.formattedDuration}');
  print('Speed: ${activity1.avgSpeed.toStringAsFixed(1)} km/h');

  print('\n5. Creating another activity (walk)...');
  final activity2 = Activity(
    id: null,
    type: 'walk',
    distance: 2.1,
    duration: 1200, // 20 minutes
    avgSpeed: 6.3,
    startTime: DateTime.now().subtract(const Duration(days: 2)),
    endTime: DateTime.now().subtract(const Duration(days: 2, hours: -1)),
    userId: guy.id!,
  );

  await dbService.insertActivity(activity2);
  print('Second activity created');
  print('Type: ${activity2.typeName}');
  print('Distance: ${activity2.formattedDistance}');

  print('\n6. Getting all activities for user...');
  final activities = await dbService.getActivitiesByUser(guy.id!);
  print('Found ${activities.length} activities');
  for (var activity in activities) {
    print('   - ${activity.iconEmoji} ${activity.typeName}: ${activity.formattedDistance} in ${activity.formattedDuration}');
  }

  print('\n7. Getting this week\'s activities...');
  final weekActivities = await dbService.getActivitiesThisWeek(guy.id!);
  print('Found ${weekActivities.length} activities this week');

  print('\n8. Calculating user statistics...');
  final stats = await dbService.getUserStats(guy.id!);
  print('Stats calculated:');
  print('Total activities: ${stats['totalActivities']}');
  print('Total distance: ${(stats['totalDistance'] as double).toStringAsFixed(2)} km');
  print('Total duration: ${(stats['totalDuration'] as int) ~/ 60} minutes');

  print('9. Deleting all activities...');
  await dbService.deleteAllActivitiesForUser(guy.id!);
  print('Activities deleted');

  final remainingActivities = await dbService.getActivitiesByUser(guy.id!);
  print('Remaining activities: ${remainingActivities.length}');

  print('\n10. Deleting user...');
  await dbService.deleteUser(guy.id);
  print('User deleted');

  // Print the list of users (should be empty or only original users)
  final remainingUsers = await dbService.getUsers();
  print('Remaining users: ${remainingUsers.length}');

  print('\n========================================');
  print('ALL TESTS PASSED!');
  print('========================================\n');

}