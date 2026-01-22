class Activity {
  final int? id;
  final String type; // 'walk', 'run', 'cycle'
  final double distance; // in kilometers
  final int duration; // in seconds
  final double avgSpeed; // km/h
  final DateTime startTime;
  final DateTime? endTime;
  final String? routePolyline; // encoded route coordinates (optional for now)
  final int userId;

  Activity({
    this.id,
    required this.type,
    required this.distance,
    required this.duration,
    required this.avgSpeed,
    required this.startTime,
    this.endTime,
    this.routePolyline,
    required this.userId,
  });

  // Convert Activity to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'distance': distance,
      'duration': duration,
      'avgSpeed': avgSpeed,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'routePolyline': routePolyline,
      'userId': userId,
    };
  }

  // Create Activity from database Map
  factory Activity.fromMap(Map<String, dynamic> map) {
    return Activity(
      id: map['id'] as int?,
      type: map['type'] as String,
      distance: map['distance'] as double,
      duration: map['duration'] as int,
      avgSpeed: map['avgSpeed'] as double,
      startTime: DateTime.parse(map['startTime'] as String),
      endTime: map['endTime'] != null ? DateTime.parse(map['endTime'] as String) : null,
      routePolyline: map['routePolyline'] as String?,
      userId: map['userId'] as int,
    );
  }

  // Formatted distance for display
  String get formattedDistance {
    return '${distance.toStringAsFixed(2)} km';
  }

  // Formatted duration for display
  String get formattedDuration {
    final hours = duration ~/ 3600;
    final minutes = (duration % 3600) ~/ 60;
    final seconds = duration % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  // Get activity type display name
  String get typeName {
    switch (type) {
      case 'walk':
        return 'Šetnja';
      case 'run':
        return 'Trčanje';
      case 'cycle':
        return 'Vožnja';
      default:
        return type;
    }
  }

  // Get activity icon
  String get iconEmoji {
    switch (type) {
      case 'walk':
        return '🚶';
      case 'run':
        return '🏃';
      case 'cycle':
        return '🚴';
      default:
        return '🏃';
    }
  }
}