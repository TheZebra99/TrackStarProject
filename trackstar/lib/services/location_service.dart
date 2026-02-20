import 'dart:async';
import 'dart:math';
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
  String _activityType = 'walk';

  // public getters
  double get totalDistance => _totalDistance;
  List<Position> get positions => _positions;
  bool get isTracking => _isTracking;
  String get activityType => _activityType;
  
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
    return speedKmh.clamp(0.0, _getMaxRealisticSpeed());
  }

  Position? get currentPosition {
    if (_positions.isEmpty) return null;
    return _positions.last;
  }

  // Distance filter in meters = how far you must move before the GPS reports a new position
  int _getDistanceFilter() {
    switch (_activityType) {
      case 'walk':
        return 5;   // 5 m — captures slow, short movements
      case 'run':
        return 10;  // 10 m — balanced for jogging pace
      case 'cycle':
        return 15;  // 15 m — avoids noisy updates at speed
      default:
        return 10;
    }
  }

  // Maximum realistic speed (km/h) for the chosen activity
  double _getMaxRealisticSpeed() {
    switch (_activityType) {
      case 'walk':
        return 12.0;
      case 'run':
        return 30.0;
      case 'cycle':
        return 70.0;
      default:
        return 30.0;
    }
  }

  // Minimum distance (meters) between consecutive points
  double _getMinSegmentDistance() {
    switch (_activityType) {
      case 'walk':
        return 1.5;
      case 'run':
        return 3.0;
      case 'cycle':
        return 5.0;
      default:
        return 2.0;
    }
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

  Future<bool> startTracking({String activityType = 'walk'}) async {
    print('Starting GPS tracking for activity: $activityType');

    final hasPermission = await checkPermissions();
    if (!hasPermission) {
      print('Cannot start tracking - no permission');
      return false;
    }

    _positions.clear();
    _totalDistance = 0.0;
    _startTime = DateTime.now();
    _isTracking = true;
    _activityType = activityType;

    final LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: _getDistanceFilter(),
    );

    print('Distance filter: ${_getDistanceFilter()}m');
    print('Max speed cap: ${_getMaxRealisticSpeed()} km/h');
    print('Min segment: ${_getMinSegmentDistance()}m');

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

  // Handle position updates from GPS, added 3D calculation that includes height changes
  void _onPositionUpdate(Position position) {
    print('Position update: ${position.latitude}, ${position.longitude}');
    print('Altitude: ${position.altitude.toStringAsFixed(1)}m');

    if (_positions.isNotEmpty) {
      final lastPosition = _positions.last;

      double horizontalDistance = Geolocator.distanceBetween(
        lastPosition.latitude,
        lastPosition.longitude,
        position.latitude,
        position.longitude,
      );

      //reject tiny segments
      if (horizontalDistance < _getMinSegmentDistance()) {
        print('Skipping: segment ${horizontalDistance.toStringAsFixed(1)}m '
            '< min ${_getMinSegmentDistance()}m');
        return;
      }

      //reject unrealistic speed
      if (_positions.length >= 2) {
        final timeDeltaSeconds = position.timestamp
                .difference(lastPosition.timestamp)
                .inMilliseconds / 1000.0;
        if (timeDeltaSeconds > 0) {
          final segmentSpeedKmh =
              (horizontalDistance / timeDeltaSeconds) * 3.6;
          if (segmentSpeedKmh > _getMaxRealisticSpeed()) {
            print('Skipping: segment speed ${segmentSpeedKmh.toStringAsFixed(1)} km/h '
                '> max ${_getMaxRealisticSpeed()} km/h');
            return;
          }
        }
      }

      // Vertical distance (altitude)
      double verticalDistance =
          (position.altitude - lastPosition.altitude).abs();
      verticalDistance = verticalDistance.clamp(0.0, 30.0);

      // True 3D distance
      double distance3D = sqrt(
        (horizontalDistance * horizontalDistance) +
            (verticalDistance * verticalDistance),
      );

      _totalDistance += distance3D / 1000.0;

      print('Horizontal: ${horizontalDistance.toStringAsFixed(1)}m');
      print('Vertical: ${verticalDistance.toStringAsFixed(1)}m');
      print('3D Distance: ${distance3D.toStringAsFixed(1)}m');
      print('Total: ${_totalDistance.toStringAsFixed(2)}km');
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

  // Polyline encoding/decoding for map routes in feed
  String encodeRoutePolyline() {
    if (_positions.isEmpty) return '';

    StringBuffer encoded = StringBuffer();
    int prevLat = 0;
    int prevLng = 0;

    for (final position in _positions) {
      int lat = (position.latitude * 1e5).round();
      int lng = (position.longitude * 1e5).round();

      _encodeValue(lat - prevLat, encoded);
      _encodeValue(lng - prevLng, encoded);

      prevLat = lat;
      prevLng = lng;
    }

    return encoded.toString();
  }

  void _encodeValue(int value, StringBuffer encoded) {
    int v = value < 0 ? ~(value << 1) : (value << 1);
    while (v >= 0x20) {
      encoded.writeCharCode((0x20 | (v & 0x1f)) + 63);
      v >>= 5;
    }
    encoded.writeCharCode(v + 63);
  }

  /// Decode a polyline string back into a list of [lat, lng] pairs
  static List<List<double>> decodePolyline(String encoded) {
    List<List<double>> points = [];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int result = 0;
      int shift = 0;
      int b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      result = 0;
      shift = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      points.add([lat / 1e5, lng / 1e5]);
    }

    return points;
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