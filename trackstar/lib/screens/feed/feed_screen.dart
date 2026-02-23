import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../utils/colors.dart';
import '../../utils/app_settings.dart';
import '../../services/database_service.dart';
import '../../services/location_service.dart';
import '../../services/user_session.dart';
import '../../models/activity.dart';
import '../profile/activity_history_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({Key? key}) : super(key: key);

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List<Activity> _activities = [];
  bool _isLoading = true;
  int _totalActivities = 0;
  double _totalDistance = 0.0;

  @override
  void initState() {
    super.initState();
    _loadActivities();
    AppSettings.instance.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    AppSettings.instance.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() => setState(() {});

  Future<void> _loadActivities() async {
    setState(() => _isLoading = true);
    try {
      // Use session userId — fixes multi-user feed contamination
      final userId = UserSession.instance.userId;
      final activities =
          await DatabaseService.instance.getActivitiesThisWeek(userId);
      final stats = await DatabaseService.instance.getUserStats(userId);
      setState(() {
        _activities = activities;
        _totalActivities = stats['totalActivities'] as int;
        _totalDistance = stats['totalDistance'] as double;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading activities: $e');
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
      MaterialPageRoute(builder: (_) => const ActivityHistoryScreen()),
    ).then((_) => _loadActivities());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppSettings.instance.darkMode;
    final bgColor =
        isDark ? const Color(0xFF121212) : AppColors.backgroundLight;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textPrimary = isDark ? Colors.white : AppColors.textDark;
    final textSecondary = isDark ? Colors.white60 : AppColors.textGrey;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        title: Text('TrackStar',
            style: TextStyle(
                color: textPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: textPrimary),
            onPressed: () {},
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
                  // Hero stats card
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
                        Text(
                          'Dobro došli, ${UserSession.instance.displayName}! 👋',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text('Spremni za novu avanturu?',
                            style:
                                TextStyle(color: Colors.white, fontSize: 14)),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _buildQuickStat('$_totalActivities', 'Aktivnosti'),
                            const SizedBox(width: 20),
                            _buildQuickStat(
                                '${_totalDistance.toStringAsFixed(1)} km',
                                'Ukupno'),
                            const SizedBox(width: 16),
                            _buildQuickStat(
                                '${_calculateWeekCalories().toStringAsFixed(0)}',
                                'Kalorije'),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Section header
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Ove nedelje',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textPrimary)),
                        if (_activities.isNotEmpty)
                          TextButton(
                            onPressed: _openActivityHistory,
                            child: const Text('Vidi sve',
                                style:
                                    TextStyle(color: AppColors.primaryOrange)),
                          ),
                      ],
                    ),
                  ),

                  if (_activities.isEmpty)
                    _buildEmptyState(textSecondary)
                  else
                    ..._activities
                        .map((a) => _buildActivityCard(
                            a, cardBg, textPrimary, textSecondary))
                        .toList(),
                ],
              ),
      ),
    );
  }

  double _calculateWeekCalories() {
    double total = 0.0;
    final caloriesPerKm = {
      'walk': 65.0,
      'run': 80.0,
      'cycle': 40.0,
    };
    for (final activity in _activities) {
      total += activity.distance * (caloriesPerKm[activity.type] ?? 50.0);
    }
    return total;
  }

  Widget _buildActivityCard(
      Activity activity, Color cardBg, Color textPrimary, Color textSecondary) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: cardBg,
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
                    color: _getActivityColor(activity.type).withOpacity(0.1),
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
                      Text(activity.typeName,
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textPrimary)),
                      const SizedBox(height: 4),
                      Text(_formatDate(activity.startTime),
                          style: TextStyle(fontSize: 12, color: textSecondary)),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    activity.isFavorite ? Icons.star : Icons.star_border,
                    color: activity.isFavorite ? Colors.amber : textSecondary,
                  ),
                  onPressed: () => _toggleFavorite(activity),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCol(activity.formattedDistance, 'Distanca',
                    Icons.straighten_outlined, textPrimary, textSecondary),
                _buildStatCol(activity.formattedDuration, 'Vreme',
                    Icons.timer_outlined, textPrimary, textSecondary),
                _buildStatCol('${activity.avgSpeed.toStringAsFixed(1)} km/h',
                    'Brzina', Icons.speed_outlined, textPrimary, textSecondary),
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

  Widget _buildStatCol(String value, String label, IconData icon, Color primary,
      Color secondary) {
    return Column(
      children: [
        Icon(icon, size: 20, color: secondary),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: primary)),
        Text(label, style: TextStyle(fontSize: 12, color: secondary)),
      ],
    );
  }

  Widget _buildRouteMap(Activity activity) {
    final List<LatLng> routePoints;
    if (activity.routePolyline != null && activity.routePolyline!.isNotEmpty) {
      final decoded = LocationService.decodePolyline(activity.routePolyline!);
      routePoints = decoded.map((p) => LatLng(p[0], p[1])).toList();
    } else {
      routePoints = [];
    }

    if (routePoints.isEmpty) {
      return Container(
        height: 120,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: _getActivityColor(activity.type).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: _getActivityColor(activity.type).withOpacity(0.3),
              width: 2),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map_outlined,
                  size: 40,
                  color: _getActivityColor(activity.type).withOpacity(0.5)),
              const SizedBox(height: 8),
              Text('Nema podataka o ruti',
                  style: TextStyle(
                    color: _getActivityColor(activity.type).withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                  )),
            ],
          ),
        ),
      );
    }

    double minLat = routePoints.first.latitude;
    double maxLat = routePoints.first.latitude;
    double minLng = routePoints.first.longitude;
    double maxLng = routePoints.first.longitude;
    for (final p in routePoints) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    final center = LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);
    final spread = (maxLat - minLat) > (maxLng - minLng)
        ? maxLat - minLat
        : maxLng - minLng;
    // new zoom levels
    final zoom = spread < 0.001
        ? 16.0
        : spread < 0.005
            ? 15.0
            : spread < 0.02
                ? 14.0
                : spread < 0.05
                    ? 13.0
                    : spread < 0.1
                        ? 12.0
                        : spread < 0.2
                            ? 11.0
                            : 10.0;

    return Container(
      height: 160,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: _getActivityColor(activity.type).withOpacity(0.3), width: 2),
      ),
      child: IgnorePointer(
        child: FlutterMap(
          options: MapOptions(
              center: center,
              zoom: zoom,
              interactiveFlags: InteractiveFlag.none),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.trackstar',
            ),
            PolylineLayer(polylines: [
              Polyline(
                points: routePoints,
                strokeWidth: 4.0,
                color: _getActivityColor(activity.type),
              ),
            ]),
            MarkerLayer(markers: [
              Marker(
                point: routePoints.first,
                width: 24,
                height: 24,
                child: Container(
                  decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2)),
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
                      border: Border.all(color: Colors.white, width: 2)),
                  child: const Icon(Icons.stop, color: Colors.white, size: 14),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

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

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) {
      return 'Danas u ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Juče u ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays < 7) {
      const days = [
        'Ponedeljak',
        'Utorak',
        'Sreda',
        'Četvrtak',
        'Petak',
        'Subota',
        'Nedelja'
      ];
      return days[date.weekday - 1];
    }
    return '${date.day}.${date.month}.${date.year}';
  }

  Widget _buildEmptyState(Color textSecondary) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.directions_run_outlined,
                size: 80, color: textSecondary.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text('Nema aktivnosti',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textSecondary)),
            const SizedBox(height: 8),
            Text(
              'Pritisnite dugme ispod da započnete prvu aktivnost',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14, color: textSecondary.withOpacity(0.7)),
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
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold)),
        Text(label,
            style:
                TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12)),
      ],
    );
  }
}
