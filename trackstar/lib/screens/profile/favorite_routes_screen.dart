import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../utils/colors.dart';
import '../../utils/app_settings.dart';
import '../../services/database_service.dart';
import '../../services/location_service.dart';
import '../../models/activity.dart';

class FavoriteRoutesScreen extends StatefulWidget {
  const FavoriteRoutesScreen({Key? key}) : super(key: key);

  @override
  State<FavoriteRoutesScreen> createState() => _FavoriteRoutesScreenState();
}

class _FavoriteRoutesScreenState extends State<FavoriteRoutesScreen> {
  final int _currentUserId = 1;
  List<Activity> _favorites = [];
  bool _isLoading = true;

  // Night mode helpers
  bool get _isDark => AppSettings.instance.darkMode;
  Color get _bgColor => _isDark ? const Color(0xFF121212) : AppColors.backgroundLight;
  Color get _cardBg  => _isDark ? const Color(0xFF1E1E1E) : Colors.white;
  Color get _textPrimary   => _isDark ? Colors.white : AppColors.textDark;
  Color get _textSecondary => _isDark ? Colors.white60 : AppColors.textGrey;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final favs = await DatabaseService.instance
          .getFavoriteActivities(_currentUserId);
      setState(() {
        _favorites = favs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removeFavorite(Activity activity) async {
    await DatabaseService.instance.toggleFavorite(activity.id!, false);
    setState(() => _favorites.removeWhere((a) => a.id == activity.id));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Uklonjena iz omiljenih'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _cardBg,
        elevation: 0,
        title: Text(
          'Omiljene rute',
          style: TextStyle(
              color: _textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _favorites.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _favorites.length,
                    itemBuilder: (context, i) => _buildCard(_favorites[i]),
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
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
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
                      Text(activity.typeName,
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _textPrimary)),
                      Text(_formatDate(activity.startTime),
                          style: TextStyle(
                              fontSize: 12, color: _textSecondary)),
                    ],
                  ),
                ),
                // Un-star button
                IconButton(
                  icon: const Icon(Icons.star, color: Colors.amber),
                  tooltip: 'Ukloni iz omiljenih',
                  onPressed: () => _removeFavorite(activity),
                ),
              ],
            ),
          ),
          // Stats row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _stat(activity.formattedDistance, 'Distanca'),
                _stat(activity.formattedDuration, 'Vreme'),
                _stat('${activity.avgSpeed.toStringAsFixed(1)} km/h',
                    'Brzina'),
              ],
            ),
          ),
          const SizedBox(height: 12),
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
        Text(label,
            style: TextStyle(fontSize: 11, color: _textSecondary)),
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
            borderRadius: BorderRadius.circular(12)),
        child: Center(
            child: Text('Nema podataka o ruti',
                style: TextStyle(
                    color: _typeColor(activity.type).withOpacity(0.6),
                    fontSize: 13))),
      );
    }

    final decoded =
        LocationService.decodePolyline(activity.routePolyline!);
    final points = decoded.map((p) => LatLng(p[0], p[1])).toList();

    double minLat = points.first.latitude, maxLat = points.first.latitude;
    double minLng = points.first.longitude, maxLng = points.first.longitude;
    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    final center =
        LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);
    final spread = [maxLat - minLat, maxLng - minLng]
        .reduce((a, b) => a > b ? a : b);
    final zoom = spread < 0.002
        ? 17.0
        : spread < 0.01
            ? 15.0
            : 13.0;

    return Container(
      height: 140,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: _typeColor(activity.type).withOpacity(0.3),
            width: 1.5),
      ),
      child: IgnorePointer(
        child: FlutterMap(
          options: MapOptions(
              center: center,
              zoom: zoom,
              interactiveFlags: InteractiveFlag.none),
          children: [
            TileLayer(
              urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.trackstar',
            ),
            PolylineLayer(polylines: [
              Polyline(
                  points: points,
                  strokeWidth: 3.5,
                  color: _typeColor(activity.type)),
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
          Icon(Icons.star_border,
              size: 72, color: _textSecondary.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text('Nema omiljenih ruta',
              style: TextStyle(fontSize: 18, color: _textSecondary)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Zvezdicu možete dodati na kartice aktivnosti u Feedu ili Istoriji.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13,
                  color: _textSecondary.withOpacity(0.7)),
            ),
          ),
        ],
      ),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'walk':  return Colors.green;
      case 'run':   return AppColors.primaryOrange;
      case 'cycle': return Colors.blue;
      default:      return AppColors.primaryOrange;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}