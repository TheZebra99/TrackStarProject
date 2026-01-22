import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import '../../services/database_service.dart';
import '../../models/activity.dart';

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
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppColors.textDark),
            onPressed: () {
              // TODO: Navigate to notifications
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadActivities, // Refresh loads activities
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  // Welcome card with dynamic stats
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
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Spremni za novu avanturu?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _buildQuickStat(
                              '$_totalActivities',
                              'Aktivnosti',
                            ), // dynamic count
                            const SizedBox(width: 20),
                            _buildQuickStat(
                              '${_totalDistance.toStringAsFixed(1)} km',
                              'Ukupno',
                            ), // dynamic distance
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
                        const Text(
                          'Ove nedelje',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        if (_activities.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              // TODO: View all activities
                            },
                            child: const Text(
                              'Vidi sve',
                              style: TextStyle(color: AppColors.primaryOrange),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Activity cards or empty state
                  if (_activities.isEmpty)
                    _buildEmptyState()
                  else
                    ..._activities.map((activity) => _buildActivityCard(activity)),
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
          // Header with activity type and time
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Activity icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getActivityColor(activity.type).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    activity.iconEmoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: 12),
                // Activity info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.typeName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(activity.startTime),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
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
                _buildStatColumn(
                  activity.formattedDistance,
                  'Distanca',
                  Icons.straighten_outlined,
                ),
                _buildStatColumn(
                  activity.formattedDuration,
                  'Vreme',
                  Icons.timer_outlined,
                ),
                _buildStatColumn(
                  '${activity.avgSpeed.toStringAsFixed(1)} km/h',
                  'Brzina',
                  Icons.speed_outlined,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Map placeholder
          Container(
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
                  Icon(
                    Icons.map_outlined,
                    size: 40,
                    color: _getActivityColor(activity.type).withOpacity(0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mapa rute',
                    style: TextStyle(
                      color: _getActivityColor(activity.type).withOpacity(0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
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