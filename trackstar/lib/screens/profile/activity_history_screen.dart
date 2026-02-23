import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../utils/colors.dart';
import '../../utils/app_settings.dart';
import '../../services/database_service.dart';
import '../../services/location_service.dart';
import '../../models/activity.dart';
import '../../services/user_session.dart';

class ActivityHistoryScreen extends StatefulWidget {
  const ActivityHistoryScreen({Key? key}) : super(key: key);

  @override
  State<ActivityHistoryScreen> createState() => _ActivityHistoryScreenState();
}

class _ActivityHistoryScreenState extends State<ActivityHistoryScreen> {
  int get _currentUserId => UserSession.instance.userId; // dynamic user
  List<Activity> _activities = [];
  bool _isLoading = true;

  // Filter
  String _filter = 'all'; // 'all', 'walk', 'run', 'cycle'

  bool get _isDark => AppSettings.instance.darkMode;
  Color get _bgColor =>
      _isDark ? const Color(0xFF121212) : AppColors.backgroundLight;
  Color get _cardBg => _isDark ? const Color(0xFF1E1E1E) : Colors.white;
  Color get _textPrimary => _isDark ? Colors.white : AppColors.textDark;
  Color get _textSecondary => _isDark ? Colors.white60 : AppColors.textGrey;

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    setState(() => _isLoading = true);
    try {
      final all =
          await DatabaseService.instance.getActivitiesByUser(_currentUserId);
      setState(() {
        _activities = all;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<Activity> get _filtered {
    if (_filter == 'all') return _activities;
    return _activities.where((a) => a.type == _filter).toList();
  }

  Future<void> _toggleFavorite(Activity activity) async {
    final newVal = !activity.isFavorite;
    await DatabaseService.instance.toggleFavorite(activity.id!, newVal);
    setState(() {
      final idx = _activities.indexWhere((a) => a.id == activity.id);
      if (idx != -1) {
        _activities[idx] = activity.copyWithFavorite(newVal);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: Column(
        children: [
          Container(
            color: _cardBg,
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // AppBar content
                  SizedBox(
                    height: 56,
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back, color: _textPrimary),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Text(
                            'Istorija aktivnosti',
                            style: TextStyle(
                              color: _textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Filter chips
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _filterChip('all', 'Sve'),
                          const SizedBox(width: 8),
                          _filterChip('walk', '🚶 Šetnja'),
                          const SizedBox(width: 8),
                          _filterChip('run', '🏃 Trčanje'),
                          const SizedBox(width: 8),
                          _filterChip('cycle', '🚴 Vožnja'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        onRefresh: _loadActivities,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _filtered.length,
                          itemBuilder: (context, i) => _buildCard(_filtered[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String value, String label) {
    final selected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryOrange : _bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.primaryOrange
                : _textSecondary.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : _textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildCard(Activity activity) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _typeColor(activity.type).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(activity.iconEmoji,
                      style: const TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.typeName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _textPrimary,
                        ),
                      ),
                      Text(
                        _formatDate(activity.startTime),
                        style: TextStyle(fontSize: 12, color: _textSecondary),
                      ),
                    ],
                  ),
                ),
                // Star / favourite button
                IconButton(
                  icon: Icon(
                    activity.isFavorite ? Icons.star : Icons.star_border,
                    color: activity.isFavorite ? Colors.amber : _textSecondary,
                  ),
                  onPressed: activity.id != null
                      ? () => _toggleFavorite(activity)
                      : null,
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
                _stat(activity.formattedDistance, 'Distanca'),
                _stat(activity.formattedDuration, 'Vreme'),
                _stat('${activity.avgSpeed.toStringAsFixed(1)} km/h', 'Brzina'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Mini map
          _buildMiniMap(activity),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: _textPrimary)),
        Text(label, style: TextStyle(fontSize: 11, color: _textSecondary)),
      ],
    );
  }

  Widget _buildMiniMap(Activity activity) {
    if (activity.routePolyline == null || activity.routePolyline!.isEmpty) {
      return Container(
        height: 100,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: _typeColor(activity.type).withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text('Nema podataka o ruti',
              style: TextStyle(
                  color: _typeColor(activity.type).withOpacity(0.6),
                  fontSize: 13)),
        ),
      );
    }

    final decoded = LocationService.decodePolyline(activity.routePolyline!);
    final points = decoded.map((p) => LatLng(p[0], p[1])).toList();

    double minLat = points.first.latitude, maxLat = points.first.latitude;
    double minLng = points.first.longitude, maxLng = points.first.longitude;
    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    final center = LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);
    final spread =
        [maxLat - minLat, maxLng - minLng].reduce((a, b) => a > b ? a : b);
    final zoom = spread < 0.002
        ? 17.0
        : spread < 0.01
            ? 15.0
            : spread < 0.05
                ? 13.0
                : 11.0;

    return Container(
      height: 130,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: _typeColor(activity.type).withOpacity(0.3), width: 1.5),
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
                  points: points,
                  strokeWidth: 3.5,
                  color: _typeColor(activity.type)),
            ]),
            MarkerLayer(markers: [
              Marker(
                point: points.first,
                width: 20,
                height: 20,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
              Marker(
                point: points.last,
                width: 20,
                height: 20,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 72, color: _textSecondary.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text('Nema aktivnosti',
              style: TextStyle(fontSize: 18, color: _textSecondary)),
          const SizedBox(height: 8),
          Text(
            'Aktivnosti koje zabeležite pojaviće se ovde.',
            style:
                TextStyle(fontSize: 13, color: _textSecondary.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }

  Color _typeColor(String type) {
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
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) {
      return 'Danas u ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Juče u ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }
}
