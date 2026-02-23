import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../utils/colors.dart';
import '../../utils/app_settings.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:trackstar/services/location_service.dart';
import 'package:trackstar/services/database_service.dart';
import 'package:trackstar/services/user_session.dart';
import 'package:trackstar/models/activity.dart';
import 'package:trackstar/models/achievement.dart';
import 'package:trackstar/screens/profile/achievements_screen.dart';
import '../../services/tracking_notification_service.dart';
import 'dart:async';
import 'package:trackstar/widgets/achievement_banner.dart';
import 'dart:io';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({Key? key}) : super(key: key);

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService.instance;
  final TrackingNotificationService _notifService =
      TrackingNotificationService.instance;

  bool _isTracking = false;
  bool _isPaused = false;
  String _activityType = 'walk';
  DateTime? _startTime;
  List<LatLng> _routePoints = [];
  LatLng? _currentPosition;
  int? _currentActivityId;

  double _distance = 0.0;
  int _duration = 0;
  double _speed = 0.0;

  Timer? _statsTimer;

  bool _hasPermission = false;
  bool _isLoadingMap = true;

  bool _gpsLost = false;
  bool _internetLost = false;

  // Night mode helpers
  bool get _isDark => AppSettings.instance.darkMode;
  Color get _cardBg => _isDark ? const Color(0xFF1E1E1E) : Colors.white;
  Color get _sheetBg => _isDark ? const Color(0xFF1E1E1E) : Colors.white;
  Color get _textPrimary => _isDark ? Colors.white : AppColors.textDark;
  Color get _textSecondary => _isDark ? Colors.white60 : AppColors.textGrey;
  Color get _tileBorder =>
      _isDark ? Colors.white12 : AppColors.textGrey.withOpacity(0.2);

  String _activityLabel(String type) {
    switch (type) {
      case 'run':
        return 'Trčanje';
      case 'cycle':
        return 'Vožnja biciklom';
      default:
        return 'Šetnja';
    }
  }

  @override
  void initState() {
    super.initState();
    _initLocationCallbacks();
    _initializeMap();
  }

  void _initLocationCallbacks() {
    _locationService.onGpsLost = () {
      if (!mounted) return;
      setState(() => _gpsLost = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('GPS signal izgubljen – čekanje obnavljanja…'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
    };

    _locationService.onGpsRestored = () {
      if (!mounted) return;
      setState(() => _gpsLost = false);
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('GPS signal obnovljen'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    };

    _locationService.onAutoSave = () {
      if (!mounted || !_isTracking) return;
      _saveActivity(isCheckpoint: true);
    };
  }

  /// Returns the IDs of achievements that are locked before this save
  Future<Set<String>> _getLockedBefore() async {
    final stats = await DatabaseService.instance
        .getUserStats(UserSession.instance.userId);
    final acts = stats['totalActivities'] as int;
    final dist = stats['totalDistance'] as double;
    final maxSingle = stats['maxSingleDistance'] as double;
    return allAchievements
        .where((a) => !a.isUnlocked(acts, dist, maxSingle))
        .map((a) => a.id)
        .toSet();
  }

  void _notifyNewAchievements(
      List<Achievement> newlyUnlocked, Map<String, dynamic> stats) {
    if (newlyUnlocked.isEmpty) return;
    for (final achievement in newlyUnlocked) {
      _showAchievementOverlay(achievement, stats);
    }
  }

  void _showAchievementOverlay(
      Achievement achievement, Map<String, dynamic> stats) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => AchievementBanner(
        achievement: achievement,
        onDismiss: () => entry.remove(),
        onTap: () {
          entry.remove();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AchievementsScreen(
                totalActivities: stats['totalActivities'] as int,
                totalDistance: stats['totalDistance'] as double,
                maxSingleDistance: stats['maxSingleDistance'] as double,
              ),
            ),
          );
        },
      ),
    );

    overlay.insert(entry);
  }

  @override
  Widget build(BuildContext context) {
    return WithForegroundTask(
      child: Scaffold(
        body: Stack(
          children: [
            _isLoadingMap
                ? const Center(child: CircularProgressIndicator())
                : !_hasPermission
                    ? _buildNoPermissionView()
                    : FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          center: _currentPosition ?? LatLng(44.0165, 21.0059),
                          zoom: 15.0,
                          minZoom: 3.0,
                          maxZoom: 18.0,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.trackstar',
                            errorTileCallback: (_, __,
                                ___) {}, // shows blank tile when offline instead of crashing
                          ),
                          if (_routePoints.isNotEmpty)
                            PolylineLayer(polylines: [
                              Polyline(
                                points: _routePoints,
                                strokeWidth: 4.0,
                                color: _getRouteColor(),
                              ),
                            ]),
                          if (_currentPosition != null)
                            MarkerLayer(markers: [
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
                                  child: const Icon(Icons.navigation,
                                      color: Colors.white, size: 20),
                                ),
                              ),
                            ]),
                        ],
                      ),

            // Stats overlay — respects night mode
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _cardBg,
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
                      _buildStatItem(_formatDuration(_duration), 'Vreme',
                          Icons.timer_outlined),
                      _buildStatItem(_distance.toStringAsFixed(2), 'Km',
                          Icons.straighten_outlined),
                      _buildStatItem(_speed.toStringAsFixed(1), 'km/h',
                          Icons.speed_outlined),
                    ],
                  ),
                ),
              ),
            ),

            if (_gpsLost || _internetLost)
              Positioned(
                top: 120,
                left: 16,
                right: 16,
                child: Column(
                  children: [
                    if (_gpsLost)
                      _buildStatusChip(
                        icon: Icons.gps_off,
                        label: 'GPS izgubljen – čekanje…',
                        color: Colors.orange,
                      ),
                    if (_internetLost) ...[
                      if (_gpsLost) const SizedBox(height: 6),
                      _buildStatusChip(
                        icon: Icons.wifi_off,
                        label: 'Bez interneta – karta nije dostupna',
                        color: Colors.grey[700]!,
                      ),
                    ],
                  ],
                ),
              ),

            // Start / Stop button
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap:
                      _isTracking ? _stopActivity : _showActivityTypeSelector,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _isTracking ? Colors.red : AppColors.primaryOrange,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (_isTracking
                                  ? Colors.red
                                  : AppColors.primaryOrange)
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
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: _textSecondary, size: 20),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _textPrimary)),
        Text(label, style: TextStyle(fontSize: 12, color: _textSecondary)),
      ],
    );
  }

  void _showActivityTypeSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: _sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _textSecondary.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Izaberite aktivnost',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _textPrimary,
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
          border: Border.all(color: _tileBorder),
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
              child: Icon(icon, color: AppColors.primaryOrange, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _textPrimary)),
                  Text(subtitle,
                      style: TextStyle(fontSize: 14, color: _textSecondary)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: _textSecondary, size: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _startActivity(String type) async {
    // cant continue without notification permissions
    final notifOk = await _ensureNotificationPermission();
    if (!notifOk) return;

    // Location permission check
    final hasPermission = await _locationService.checkPermissions();
    if (!hasPermission) {
      _showPermissionDeniedDialog();
      return;
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showLocationDisabledDialog();
      return;
    }

    // Start GPS tracking
    final started = await _locationService.startTracking(activityType: type);
    if (!started) return;

    // Start foreground service notification
    await _notifService.start(activityLabel: _activityLabel(type));

    setState(() {
      _activityType = type;
      _isTracking = true;
      _isPaused = false;
      _startTime = DateTime.now();
      _currentActivityId = null;
      _routePoints.clear();
      _distance = 0.0;
      _duration = 0;
      _gpsLost = false;
    });

    // Check internet state for map tiles
    _checkInternet();

    // 1-second stats timer for screen updates and notifications
    _statsTimer =
        Timer.periodic(const Duration(seconds: 1), (_) => _updateStats());
  }

  Future<void> _stopActivity() async {
    final avgSpeed = _distance > 0 ? (_distance / (_duration / 3600)) : 0.0;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _cardBg,
        title: Text('Završi aktivnost?', style: TextStyle(color: _textPrimary)),
        content: Text(
          'Distanca: ${_distance.toStringAsFixed(2)} km\n'
          'Trajanje: ${_duration ~/ 60}m ${_duration % 60}s\n'
          'Prosečna brzina: ${avgSpeed.toStringAsFixed(1)} km/h',
          style: TextStyle(color: _textSecondary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Otkaži')),
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange),
              onPressed: () => Navigator.pop(context, true),
              child:
                  const Text('Završi', style: TextStyle(color: Colors.white))),
        ],
      ),
    );

    if (confirmed != true) return;

    await _locationService.stopTracking();
    await _notifService.stop();
    _statsTimer?.cancel();

    final lockedBefore = await _getLockedBefore();
    await _saveActivity(isCheckpoint: false);

    setState(() {
      _isTracking = false;
      _isPaused = false;
      _gpsLost = false;
    });

    final statsAfter = await DatabaseService.instance
        .getUserStats(UserSession.instance.userId);
    final newlyUnlocked = allAchievements
        .where((a) =>
            lockedBefore.contains(a.id) &&
            a.isUnlocked(
              statsAfter['totalActivities'] as int,
              statsAfter['totalDistance'] as double,
              statsAfter['maxSingleDistance'] as double,
            ))
        .toList();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aktivnost sačuvana!'),
          backgroundColor: Colors.green,
        ),
      );
      _notifyNewAchievements(newlyUnlocked, statsAfter);
    }
  }

  Future<void> _saveActivity({required bool isCheckpoint}) async {
    if (_startTime == null) return;
    final routePolyline = _locationService.encodeRoutePolyline();
    final activity = Activity(
      id: _currentActivityId,
      type: _activityType,
      distance: _distance,
      duration: _duration,
      avgSpeed: _distance / ((_duration == 0 ? 1 : _duration) / 3600),
      startTime: _startTime!,
      endTime: DateTime.now(),
      routePolyline: routePolyline.isNotEmpty ? routePolyline : null,
      userId: UserSession.instance.userId,
    );

    if (_currentActivityId == null) {
      // First save - insert new activity
      _currentActivityId =
          await DatabaseService.instance.insertActivity(activity);
      print('Activity created with ID: $_currentActivityId');
    } else {
      // Checkpoint or final save - update existing activity
      await DatabaseService.instance.updateActivity(activity);
      if (isCheckpoint) {
        print(
            'Auto-save checkpoint updated (${_distance.toStringAsFixed(2)} km)');
      }
    }
  }

  void _updateStats() {
    if (!_isTracking || _isPaused) return;
    setState(() {
      _distance = _locationService.totalDistance;
      _duration = _locationService.duration;
      _speed = _locationService.currentSpeed;
      _routePoints = _locationService.positions
          .map((p) => LatLng(p.latitude, p.longitude))
          .toList();
      if (_locationService.currentPosition != null) {
        final pos = _locationService.currentPosition!;
        _currentPosition = LatLng(pos.latitude, pos.longitude);
        _mapController.move(_currentPosition!, 17.0);
      }
    });

    // Push updated stats to the notification widget
    _notifService.updateStats(
      activityLabel: _activityLabel(_activityType),
      elapsed: _duration,
      distanceKm: _distance,
      speedKmh: _speed,
    );
  }

  Future<void> _initializeMap() async {
    _hasPermission = await _locationService.checkPermissions();
    if (_hasPermission) {
      final position = await _locationService.getCurrentPosition();
      if (position != null && mounted) {
        // added mounted check
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _isLoadingMap = false;
        });
        _mapController.move(_currentPosition!, 15.0);
        return; // early return avoids errors
      }
    }
    if (mounted) setState(() => _isLoadingMap = false);
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Dozvola za lokaciju potrebna'),
        content: const Text(
            'TrackStar treba pristup lokaciji da bi pratio aktivnosti.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Otkaži')),
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
      builder: (_) => AlertDialog(
        title: const Text('Lokacija isključena'),
        content:
            const Text('Molimo uključite lokaciju u podešavanjima telefona.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _statsTimer?.cancel();
    if (_isTracking) {
      _locationService.stopTracking();
      _notifService.stop();
    }
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Widget _buildNoPermissionView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.location_off, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Dozvola za lokaciju potrebna',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
            onPressed: () async => Geolocator.openAppSettings(),
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

  Future<bool> _ensureNotificationPermission() async {
    if (await _notifService.hasNotificationPermission()) return true;
    final granted = await _notifService.requestNotificationPermission();
    if (granted) return true;
    if (mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          backgroundColor: _cardBg,
          title: Text('Obaveštenja su potrebna',
              style: TextStyle(color: _textPrimary)),
          content: Text(
            'TrackStar prikazuje vaše statistike kao obaveštenje na zaključanom '
            'ekranu i statusnoj traci dok trenirate.\n\n'
            'Bez ove dozvole praćenje aktivnosti nije moguće.',
            style: TextStyle(color: _textSecondary),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Otkaži')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange),
              onPressed: () {
                Navigator.pop(context);
                openAppSettings();
              },
              child: const Text('Otvori Podešavanja',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
    return false;
  }

  Future<void> _checkInternet() async {
    try {
      final result = await InternetAddress.lookup('openstreetmap.org')
          .timeout(const Duration(seconds: 3));
      final ok = result.isNotEmpty && result.first.rawAddress.isNotEmpty;
      if (mounted) setState(() => _internetLost = !ok);
    } catch (_) {
      if (mounted) setState(() => _internetLost = true);
    }
  }

  Widget _buildStatusChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 13)),
        ],
      ),
    );
  }
}
