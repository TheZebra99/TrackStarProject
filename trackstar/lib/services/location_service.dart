import 'dart:async';
import 'package:geolocator/geolocator.dart';

// LocationService - Manages GPS tracking for activities
class LocationService {
  // Singleton instance
  static final LocationService instance = LocationService._init();
  LocationService._init();

  StreamSubscription<Position>? _positionStreamSubscription;
  List<Position> _positions = [];
  double _totalDistance = 0.0;
  DateTime? _startTime;
  bool _isTracking = false;

  // public getters
  double get totalDistance => _totalDistance;
  List<Position> get positions => _positions;
  bool get isTracking => _isTracking;
  
  int get duration {
    if (_startTime == null) return 0;
    return DateTime.now().difference(_startTime!).inSeconds;
  }
  
  double get currentSpeed {
    if (_positions.isEmpty) return 0.0;
    // Speed in m/s, convert to km/h
    final speedMps = _positions.last.speed;
    final speedKmh = speedMps * 3.6;
    // clamp to 0-999 km/h
    return speedKmh.clamp(0.0, 999.0);
  }

  Position? get currentPosition {
    if (_positions.isEmpty) return null;
    return _positions.last;
  }

  Future<bool> checkPermissions() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location services are disabled');
      return false;
    }

    // Check permission status
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Location permissions are denied');
        return false;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      print('Location permissions are permanently denied');
      return false;
    }

    print('Location permissions granted');
    return true;
  }

  Future<bool> startTracking() async {
    print('Starting GPS tracking...');
    
    final hasPermission = await checkPermissions();
    if (!hasPermission) {
      print('Cannot start tracking - no permission');
      return false;
    }

    // Reset tracking data
    _positions.clear();
    _totalDistance = 0.0;
    _startTime = DateTime.now();
    _isTracking = true;

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    print('Listening to position updates...');

    // Start listening to position stream
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        _onPositionUpdate(position);
      },
      onError: (error) {
        print('Position stream error: $error');
      },
    );

    print('GPS tracking started');
    return true;
  }

  // Handle position updates from GPS
  void _onPositionUpdate(Position position) {
    print('Position update: ${position.latitude}, ${position.longitude}');
    
    if (_positions.isNotEmpty) {
      // Calculate distance based on the last position
      final lastPosition = _positions.last;
      double distance = Geolocator.distanceBetween(
        lastPosition.latitude,
        lastPosition.longitude,
        position.latitude,
        position.longitude,
      );
      
      // Add to total distance, convert meters to kilometers
      _totalDistance += distance / 1000.0;
      
      print('Distance from last point: ${distance.toStringAsFixed(1)}m');
      print('Total distance: ${_totalDistance.toStringAsFixed(2)}km');
      print('Speed: ${currentSpeed.toStringAsFixed(1)}km/h');
    }

    _positions.add(position);
  }

  Future<void> stopTracking() async {
    print('Stopping GPS tracking...');
    
    await _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _isTracking = false;
    
    print('GPS tracking stopped');
    print('Total distance: ${_totalDistance.toStringAsFixed(2)}km');
    print('Duration: ${duration}s');
    print('Positions recorded: ${_positions.length}');
  }

  // Get current position once, without starting tracking
  Future<Position?> getCurrentPosition() async {
    try {
      print('Getting current position...');
      
      final hasPermission = await checkPermissions();
      if (!hasPermission) {
        print('No permission to get position');
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      print('Current position: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      print('Error getting position: $e');
      return null;
    }
  }

  // Reset tracking data
  void reset() {
    _positions.clear();
    _totalDistance = 0.0;
    _startTime = null;
    print('Tracking data reset');
  }

  void dispose() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _isTracking = false;
    print('LocationService disposed');
  }
}