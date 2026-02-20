import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../utils/colors.dart';
import 'package:latlong2/latlong.dart';
import '../../services/database_service.dart';
import '../../services/location_service.dart';
import '../../models/activity.dart';
import '../profile/activity_history_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({Key? key}) : super(key: key);

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  // State variables
  List<Activity> _activities = [];
  bool _isLoading = true;
  int _totalActivities = 0;
  double _totalDistance = 0.0;
  final int _currentUserId = 1; // TODO: Get from actual logged-in user

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    setState(() => _isLoading = true);

    try {
      // Get this week's activities
      final activities = await DatabaseService.instance
          .getActivitiesThisWeek(_currentUserId);

      // Get total stats
      final stats = await DatabaseService.instance
          .getUserStats(_currentUserId);

      setState(() {
        _activities = activities;
        _totalActivities = stats['totalActivities'] as int;
        _totalDistance = stats['totalDistance'] as double;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading activities: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFavorite(Activity activity) async {
    if (activity.id == null) return;
    final newVal = !activity.isFavorite;
    await DatabaseService.instance.toggleFavorite(activity.id!, newVal);
    setState(() {
      final idx = _activities.indexWhere((a) => a.id == activity.id);
      if (idx != -1) _activities[idx] = activity.copyWithFavorite(newVal);
    });
  }

  void _openActivityHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => const ActivityHistoryScreen()),
    ).then((_) => _loadActivities()); // refresh feed on return
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'TrackStar',
          style: TextStyle(
              color: AppColors.textDark,
              fontSize: 24,
              fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined,
                color: AppColors.textDark),
            onPressed: () {
              // TODO: Navigate to notifications
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadActivities,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryOrange,
                          AppColors.primaryOrange.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryOrange.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Dobro došli nazad! 👋',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Spremni za novu avanturu?',
                          style:
                              TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _buildQuickStat(
                                '$_totalActivities', 'Aktivnosti'),
                            const SizedBox(width: 20),
                            _buildQuickStat(
                                '${_totalDistance.toStringAsFixed(1)} km',
                                'Ukupno'),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Ove nedelje',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark),
                        ),
                        if (_activities.isNotEmpty)
                          TextButton(
                            // vidi sve navigates to activity history
                            onPressed: _openActivityHistory,
                            child: const Text(
                              'Vidi sve',
                              style:
                                  TextStyle(color: AppColors.primaryOrange),
                            ),
                          ),
                      ],
                    ),
                  ),

                  if (_activities.isEmpty)
                    _buildEmptyState()
                  else
                    ..._activities
                        .map((a) => _buildActivityCard(a))
                        .toList(),
                ],
              ),
      ),
    );
  }

  // Build activity card
  Widget _buildActivityCard(Activity activity) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color:
                        _getActivityColor(activity.type).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(activity.iconEmoji,
                      style: const TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.typeName,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(activity.startTime),
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textGrey),
                      ),
                    ],
                  ),
                ),
                // Star button, tap to add/remove from Omiljene rute
                IconButton(
                  icon: Icon(
                    activity.isFavorite ? Icons.star : Icons.star_border,
                    color: activity.isFavorite
                        ? Colors.amber
                        : AppColors.textGrey,
                  ),
                  tooltip: activity.isFavorite
                      ? 'Ukloni iz omiljenih'
                      : 'Dodaj u omiljene rute',
                  onPressed: () => _toggleFavorite(activity),
                ),
              ],
            ),
          ),

          // Stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn(activity.formattedDistance, 'Distanca',
                    Icons.straighten_outlined),
                _buildStatColumn(activity.formattedDuration, 'Vreme',
                    Icons.timer_outlined),
                _buildStatColumn(
                    '${activity.avgSpeed.toStringAsFixed(1)} km/h',
                    'Brzina',
                    Icons.speed_outlined),
              ],
            ),
          ),

          const SizedBox(height: 16),
          _buildRouteMap(activity),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

    Widget _buildRouteMap(Activity activity) {
    // Decode the polyline into LatLng points
    final List<LatLng> routePoints;
    if (activity.routePolyline != null &&
        activity.routePolyline!.isNotEmpty) {
      final decoded =
          LocationService.decodePolyline(activity.routePolyline!);
      routePoints = decoded.map((p) => LatLng(p[0], p[1])).toList();
    } else {
      routePoints = [];
    }

    if (routePoints.isEmpty) {
      // No route data — show placeholder
      return Container(
        height: 120,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: _getActivityColor(activity.type).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getActivityColor(activity.type).withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map_outlined,
                  size: 40,
                  color:
                      _getActivityColor(activity.type).withOpacity(0.5)),
              const SizedBox(height: 8),
              Text(
                'Nema podataka o ruti',
                style: TextStyle(
                  color:
                      _getActivityColor(activity.type).withOpacity(0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Calculate bounds to fit the entire route
    double minLat = routePoints.first.latitude;
    double maxLat = routePoints.first.latitude;
    double minLng = routePoints.first.longitude;
    double maxLng = routePoints.first.longitude;

    for (final point in routePoints) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    final center = LatLng(
      (minLat + maxLat) / 2,
      (minLng + maxLng) / 2,
    );

    // Rough zoom calculation based on route spread
    final latSpread = maxLat - minLat;
    final lngSpread = maxLng - minLng;
    final spread = latSpread > lngSpread ? latSpread : lngSpread;
    double zoom;
    if (spread < 0.002) {
      zoom = 17.0;
    } else if (spread < 0.01) {
      zoom = 15.0;
    } else if (spread < 0.05) {
      zoom = 13.0;
    } else if (spread < 0.2) {
      zoom = 11.0;
    } else {
      zoom = 9.0;
    }

    return Container(
      height: 160,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getActivityColor(activity.type).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: IgnorePointer(
        // Make the mini-map non-interactive
        child: FlutterMap(
          options: MapOptions(
            center: center,
            zoom: zoom,
            interactiveFlags: InteractiveFlag.none,
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.trackstar',
            ),
            PolylineLayer(
              polylines: [
                Polyline(
                  points: routePoints,
                  strokeWidth: 4.0,
                  color: _getActivityColor(activity.type),
                ),
              ],
            ),
            // Start marker
            MarkerLayer(
              markers: [
                Marker(
                  point: routePoints.first,
                  width: 24,
                  height: 24,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.play_arrow,
                        color: Colors.white, size: 14),
                  ),
                ),
                Marker(
                  point: routePoints.last,
                  width: 24,
                  height: 24,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.stop,
                        color: Colors.white, size: 14),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Build stat column
  Widget _buildStatColumn(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.textGrey),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
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

  // Get activity color
  Color _getActivityColor(String type) {
    switch (type) {
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

  // Format date
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Danas u ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Juče u ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      final weekdays = ['Ponedeljak', 'Utorak', 'Sreda', 'Četvrtak', 'Petak', 'Subota', 'Nedelja'];
      return weekdays[date.weekday - 1];
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }

  // updated empty state
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              Icons.directions_run_outlined,
              size: 80,
              color: AppColors.textGrey.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Nema aktivnosti',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textGrey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pritisnite dugme ispod da započnete svoju prvu aktivnost',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textGrey.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStat(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}