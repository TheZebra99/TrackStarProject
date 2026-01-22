import 'package:flutter/material.dart';
import '../../utils/colors.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:trackstar/services/location_service.dart';
import 'package:trackstar/services/database_service.dart';
import 'package:trackstar/models/activity.dart';
import 'dart:async';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({Key? key}) : super(key: key);

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  final MapController _mapController = MapController();

  final LocationService _locationService = LocationService.instance;

  // Tracking state
  bool _isTracking = false;
  bool _isPaused = false;
  String _activityType = 'walk';
  DateTime? _startTime;
  List<LatLng> _routePoints = [];
  LatLng? _currentPosition;

  // Stats
  double _distance = 0.0;
  int _duration = 0;
  double _speed = 0.0;

  Timer? _statsTimer;

  int _currentUserId = 1; // TODO: Get from actual logged-in user

  // Error handling
  bool _hasPermission = false;
  bool _isLoadingMap = true;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // replace the placeholder with map view
          _isLoadingMap
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : !_hasPermission
                  ? _buildNoPermissionView()
                  : FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        center: _currentPosition ??
                            LatLng(44.0165, 21.0059), // Novi Sad default
                        zoom: 15.0,
                        minZoom: 3.0,
                        maxZoom: 18.0,
                      ),
                      children: [
                        // Tile layer - OpenStreetMap tiles are saved as PNG images
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              /*
                                Where:
                                - {z} = zoom level (0-19)
                                - {x} = tile X coordinate
                                - {y} = tile Y coordinate
                              */ 
                          userAgentPackageName: 'com.example.trackstar',
                        ),

                        // Route line - orange path showing where you've been
                        if (_routePoints.isNotEmpty)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: _routePoints,
                                strokeWidth: 4.0,
                                color: _getRouteColor(), // changes based on activity type
                              ),
                            ],
                          ),

                        // Current position marker - blue dot
                        if (_currentPosition != null)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _currentPosition!,
                                width: 40,
                                height: 40,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 3),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.navigation,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),

          // Top stats overlay - shows real-time data
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      _formatDuration(_duration),
                      'Vreme',
                      Icons.timer_outlined,
                    ),
                    _buildStatItem(
                      _distance.toStringAsFixed(2),
                      'Km',
                      Icons.straighten_outlined,
                    ),
                    _buildStatItem(
                      _speed.toStringAsFixed(1),
                      'km/h',
                      Icons.speed_outlined,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Start/Stop activity button - changes based on tracking state
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _isTracking ? _stopActivity : _showActivityTypeSelector,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _isTracking ? Colors.red : AppColors.primaryOrange,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color:
                            (_isTracking ? Colors.red : AppColors.primaryOrange)
                                .withOpacity(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isTracking ? Icons.stop : Icons.play_arrow,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.textGrey, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textGrey,
          ),
        ),
      ],
    );
  }

  void _showActivityTypeSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Izaberite aktivnost',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 24),
            _buildActivityOption(
              icon: Icons.directions_walk,
              title: 'Šetnja',
              subtitle: 'Započnite šetnju',
              onTap: () {
                Navigator.pop(context);
                _startActivity('walk');
              },
            ),
            const SizedBox(height: 12),
            _buildActivityOption(
              icon: Icons.directions_run,
              title: 'Trčanje',
              subtitle: 'Započnite trčanje',
              onTap: () {
                Navigator.pop(context);
                _startActivity('run');
              },
            ),
            const SizedBox(height: 12),
            _buildActivityOption(
              icon: Icons.directions_bike,
              title: 'Vožnja biciklom',
              subtitle: 'Započnite vožnju',
              onTap: () {
                Navigator.pop(context);
                _startActivity('cycle');
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.textGrey.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: AppColors.primaryOrange,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textGrey,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startActivity(String type) async {
    // Check permissions first
    final hasPermission = await _locationService.checkPermissions();

    if (!hasPermission) {
      _showPermissionDeniedDialog();
      return;
    }

    // Check location services
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showLocationDisabledDialog();
      return;
    }

    // Start tracking
    final started = await _locationService.startTracking();

    if (started) {
      setState(() {
        _activityType = type; //passed parameter
        _isTracking = true;
        _isPaused = false;
        _startTime = DateTime.now();
        _routePoints.clear();
        _distance = 0.0;
        _duration = 0;
      });

      // Start stats update timer
      _statsTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _updateStats();
      });

      print('Activity started!');
    }
  }

  Future<void> _stopActivity() async {
    final avgSpeed = _distance > 0 ? (_distance / (_duration / 3600)) : 0.0;
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Završi aktivnost?'),
        content: Text(
          'Distanca: ${_distance.toStringAsFixed(2)} km\n'
          'Trajanje: ${_duration ~/ 60}m ${_duration % 60}s\n'
          'Prosečna brzina: ${avgSpeed.toStringAsFixed(1)} km/h\n',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Otkaži'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Završi'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Stop location tracking
      await _locationService.stopTracking();

      // Stop stats timer
      _statsTimer?.cancel();

      // Save activity to database
      await _saveActivity();

      setState(() {
        _isTracking = false;
        _isPaused = false;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aktivnost sačuvana!'),
          backgroundColor: Colors.green,
        ),
      );

      print('Activity stopped and saved!');
    }
  }

  Future<void> _saveActivity() async {
    final activity = Activity(
      id: null,
      type: _activityType,
      distance: _distance,
      duration: _duration,
      avgSpeed: _distance / (_duration / 3600), // km/h
      startTime: _startTime!,
      endTime: DateTime.now(),
      userId: _currentUserId,
    );

    await DatabaseService.instance.insertActivity(activity);
    print('Activity saved to database');
  }

  Future<void> _selectActivityType() async {
    final type = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tip aktivnosti'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Text('🚶', style: TextStyle(fontSize: 24)),
              title: const Text('Šetnja'),
              onTap: () => Navigator.pop(context, 'walk'),
            ),
            ListTile(
              leading: const Text('🏃', style: TextStyle(fontSize: 24)),
              title: const Text('Trčanje'),
              onTap: () => Navigator.pop(context, 'run'),
            ),
            ListTile(
              leading: const Text('🚴', style: TextStyle(fontSize: 24)),
              title: const Text('Vožnja bicikla'),
              onTap: () => Navigator.pop(context, 'cycle'),
            ),
          ],
        ),
      ),
    );

    if (type != null) {
      setState(() {
        _activityType = type;
      });
    }
  }

  void _updateStats() {
    if (!_isTracking || _isPaused) return;

    setState(() {
      _distance = _locationService.totalDistance;
      _duration = _locationService.duration;
      _speed = _locationService.currentSpeed;

      // Update route points
      _routePoints = _locationService.positions
          .map((p) => LatLng(p.latitude, p.longitude))
          .toList();

      // Update current position
      if (_locationService.currentPosition != null) {
        final pos = _locationService.currentPosition!;
        _currentPosition = LatLng(pos.latitude, pos.longitude);

        // Move map to follow user
        _mapController.move(_currentPosition!, 17.0);
      }
    });
  }

  Future<void> _initializeMap() async {
    _hasPermission = await _locationService.checkPermissions();

    if (_hasPermission) {
      final position = await _locationService.getCurrentPosition();

      if (position != null) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _isLoadingMap = false;
        });

        _mapController.move(_currentPosition!, 15.0);
      } else {
        setState(() {
          _isLoadingMap = false;
        });
      }
    } else {
      setState(() {
        _isLoadingMap = false;
      });
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dozvola za lokaciju potrebna'),
        content: const Text(
          'TrackStar treba pristup lokaciji da bi pratio vaše aktivnosti. '
          'Molimo omogućite lokaciju u podešavanjima.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Otkaži'),
          ),
          ElevatedButton(
            onPressed: () {
              Geolocator.openLocationSettings();
              Navigator.pop(context);
            },
            child: const Text('Otvori Podešavanja'),
          ),
        ],
      ),
    );
  }

  void _showLocationDisabledDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lokacija isključena'),
        content: const Text(
          'Molimo uključite lokaciju u podešavanjima telefona.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _statsTimer?.cancel();
    if (_isTracking) {
      _locationService.stopTracking();
    }
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
  }

  Widget _buildNoPermissionView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.location_off, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Dozvola za lokaciju potrebna',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Omogućite pristup lokaciji da biste pratili aktivnosti.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              await Geolocator.openAppSettings();
            },
            child: const Text('Otvori Podešavanja'),
          ),
        ],
      ),
    );
  }

  Color _getRouteColor() {
    switch (_activityType) {
      case 'walk':
        return Colors.green;
      case 'run':
        return AppColors.primaryOrange;
      case 'cycle':
        return Colors.blue;
      default:
        return AppColors.primaryOrange;
    }
  }
}
