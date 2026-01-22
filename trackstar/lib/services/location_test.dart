import 'package:flutter/widgets.dart';
import 'package:trackstar/services/location_service.dart';

// Test LocationService
// 1. Check location permissions
// 2. Get current position
// 3. Start GPS tracking for 30 seconds
// 4. Display tracking data
// 5. Stop tracking

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('========================================');
  print('LOCATION SERVICE TEST');
  print('========================================\n');

  final locationService = LocationService.instance;

  print('Test 1: Checking location permissions...');
  final hasPermission = await locationService.checkPermissions();
  
  if (!hasPermission) {
    print('\nFAILED: Location permissions not granted');
    print('Please enable location permissions in app settings.');
    print('Then run this test again.\n');
    return;
  }
  
  print('Permissions granted!\n');

  print('Test 2: Getting current position...');
  final currentPos = await locationService.getCurrentPosition();
  
  if (currentPos == null) {
    print('FAILED: Could not get current position');
    print('Make sure location services are enabled.\n');
    return;
  }
  
  print('Current position obtained!');
  print('Latitude: ${currentPos.latitude}');
  print('Longitude: ${currentPos.longitude}');
  print('Accuracy: ${currentPos.accuracy.toStringAsFixed(1)}m\n');

  print('Test 3: Starting GPS tracking...');
  print('Will track for 30 seconds.');
  print('WALK AROUND or MOVE to see distance changes!\n');
  
  final started = await locationService.startTracking();
  
  if (!started) {
    print('FAILED: Could not start tracking\n');
    return;
  }
  
  print('Tracking started!\n');

  print('Test 4: Monitoring tracking data...');
  print('(displaying updates every 5 seconds)\n');
  
  for (int i = 1; i <= 6; i++) {
    await Future.delayed(const Duration(seconds: 5));
    
    print('--- ${i * 5} seconds ---');
    print('Distance: ${locationService.totalDistance.toStringAsFixed(3)} km');
    print('Speed: ${locationService.currentSpeed.toStringAsFixed(1)} km/h');
    print('Duration: ${locationService.duration}s');
    print('Positions: ${locationService.positions.length}');
    
    if (locationService.currentPosition != null) {
      final pos = locationService.currentPosition!;
      print('Current: ${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}');
    }
    print('');
  }

  print('Test 5: Stopping tracking...');
  await locationService.stopTracking();
  print('Tracking stopped!\n');

  print('========================================');
  print('FINAL RESULTS');
  print('========================================');
  print('Total Distance: ${locationService.totalDistance.toStringAsFixed(3)} km');
  print('Total Duration: ${locationService.duration}s (${(locationService.duration / 60).toStringAsFixed(1)} min)');
  print('Total Positions: ${locationService.positions.length}');
  
  if (locationService.totalDistance > 0) {
    final avgSpeed = (locationService.totalDistance / (locationService.duration / 3600));
    print('Average Speed: ${avgSpeed.toStringAsFixed(1)} km/h');
  }
  
  print('\n========================================');
  
  if (locationService.totalDistance > 0.01) {
    print('ALL TESTS PASSED!');
    print('========================================\n');
  } else {
    print('TESTS COMPLETED BUT NO MOVEMENT DETECTED');
  }
}