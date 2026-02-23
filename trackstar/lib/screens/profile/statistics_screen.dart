import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../utils/colors.dart';
import '../../utils/app_settings.dart';
import '../../services/database_service.dart';
import '../../services/user_session.dart';
import '../../models/activity.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  String _period = 'week'; // 'day', 'week', 'month', 'year'
  List<Activity> _activities = [];
  bool _isLoading = true;

  bool get _isDark => AppSettings.instance.darkMode;
  Color get _bgColor =>
      _isDark ? const Color(0xFF121212) : AppColors.backgroundLight;
  Color get _cardBg => _isDark ? const Color(0xFF1E1E1E) : Colors.white;
  Color get _textPrimary => _isDark ? Colors.white : AppColors.textDark;
  Color get _textSecondary => _isDark ? Colors.white60 : AppColors.textGrey;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final userId = UserSession.instance.userId;
      final all = await DatabaseService.instance.getActivitiesByUser(userId);
      setState(() {
        _activities = all;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Map<String, double> _getBarChartData() {
    final now = DateTime.now();
    final data = <String, double>{};

    if (_period == 'day') {
      // Last 24 hours by hour
      for (int i = 23; i >= 0; i--) {
        final hour = now.subtract(Duration(hours: i)).hour;
        data['${hour}h'] = 0.0;
      }
      for (final activity in _activities) {
        if (activity.startTime
            .isAfter(now.subtract(const Duration(hours: 24)))) {
          final key = '${activity.startTime.hour}h';
          data[key] = (data[key] ?? 0.0) + activity.distance;
        }
      }
    } else if (_period == 'week') {
      // Last 7 days
      final weekdays = ['Pon', 'Uto', 'Sre', 'Čet', 'Pet', 'Sub', 'Ned'];
      for (int i = 6; i >= 0; i--) {
        final day = now.subtract(Duration(days: i));
        final weekday = weekdays[(day.weekday - 1) % 7];
        data[weekday] = 0.0;
      }
      for (final activity in _activities) {
        if (activity.startTime.isAfter(now.subtract(const Duration(days: 7)))) {
          final weekday = weekdays[(activity.startTime.weekday - 1) % 7];
          data[weekday] = (data[weekday] ?? 0.0) + activity.distance;
        }
      }
    } else if (_period == 'month') {
      // Last 30 days by week
      for (int i = 4; i >= 0; i--) {
        data['W${5 - i}'] = 0.0;
      }
      for (final activity in _activities) {
        if (activity.startTime
            .isAfter(now.subtract(const Duration(days: 30)))) {
          final weekNum =
              (now.difference(activity.startTime).inDays / 7).floor();
          if (weekNum < 5) {
            data['W${5 - weekNum}'] =
                (data['W${5 - weekNum}'] ?? 0.0) + activity.distance;
          }
        }
      }
    } else {
      // Last 12 months
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Maj',
        'Jun',
        'Jul',
        'Avg',
        'Sep',
        'Okt',
        'Nov',
        'Dec'
      ];
      for (int i = 11; i >= 0; i--) {
        final month = DateTime(now.year, now.month - i, 1);
        data[months[month.month - 1]] = 0.0;
      }
      for (final activity in _activities) {
        if (activity.startTime.isAfter(DateTime(now.year - 1, now.month, 1))) {
          final monthName = months[activity.startTime.month - 1];
          data[monthName] = (data[monthName] ?? 0.0) + activity.distance;
        }
      }
    }

    return data;
  }

  double _getTotalCalories() {
    final activities = _getActivitiesForPeriod();
    double total = 0.0;
    for (final activity in activities) {
      total += _calculateCalories(activity);
    }
    return total;
  }

  double _calculateCalories(Activity activity) {
    // Calories per km based on activity type
    final caloriesPerKm = {
      'walk': 65.0, // ~65 cal/km
      'run': 80.0, // ~80 cal/km
      'cycle': 40.0, // ~40 cal/km
    };
    return activity.distance * (caloriesPerKm[activity.type] ?? 50.0);
  }

  List<Activity> _getActivitiesForPeriod() {
    final now = DateTime.now();
    if (_period == 'day') {
      return _activities
          .where((a) =>
              a.startTime.isAfter(now.subtract(const Duration(hours: 24))))
          .toList();
    } else if (_period == 'week') {
      return _activities
          .where(
              (a) => a.startTime.isAfter(now.subtract(const Duration(days: 7))))
          .toList();
    } else if (_period == 'month') {
      return _activities
          .where((a) =>
              a.startTime.isAfter(now.subtract(const Duration(days: 30))))
          .toList();
    } else {
      return _activities
          .where(
              (a) => a.startTime.isAfter(DateTime(now.year - 1, now.month, 1)))
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _cardBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Statistika',
            style: TextStyle(
                color: _textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // Period selector
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _periodChip('day', 'Dan'),
                        const SizedBox(width: 8),
                        _periodChip('week', 'Nedelja'),
                        const SizedBox(width: 8),
                        _periodChip('month', 'Mesec'),
                        const SizedBox(width: 8),
                        _periodChip('year', 'Godina'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Summary stats
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _cardBg,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          '${_getActivitiesForPeriod().length}',
                          'Aktivnosti',
                          Icons.directions_run,
                        ),
                        Container(
                            height: 40,
                            width: 1,
                            color: _textSecondary.withOpacity(0.2)),
                        _buildStatItem(
                          '${_getActivitiesForPeriod().fold<double>(0, (sum, a) => sum + a.distance).toStringAsFixed(1)} km',
                          'Distanca',
                          Icons.straighten,
                        ),
                        Container(
                            height: 40,
                            width: 1,
                            color: _textSecondary.withOpacity(0.2)),
                        _buildStatItem(
                          '${_getTotalCalories().toStringAsFixed(0)}',
                          'Kalorije',
                          Icons.local_fire_department,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Bar chart
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _cardBg,
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
                        Text('Distanca po periodu',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _textPrimary)),
                        const SizedBox(height: 20),
                        SizedBox(height: 200, child: _buildBarChart()),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Heat map (only for month period), similar to github
                  if (_period == 'month')
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _cardBg,
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
                          Text('Toplotna mapa aktivnosti',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _textPrimary)),
                          const SizedBox(height: 20),
                          _buildHeatMap(),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _periodChip(String value, String label) {
    final selected = _period == value;
    return GestureDetector(
      onTap: () => setState(() => _period = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryOrange : Colors.transparent,
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
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : _textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primaryOrange, size: 24),
        const SizedBox(height: 8),
        Text(value,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _textPrimary)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: _textSecondary)),
      ],
    );
  }

  Widget _buildBarChart() {
    final data = _getBarChartData();
    final keys = data.keys.toList();
    final maxY = data.values.fold<double>(0, (max, v) => v > max ? v : max);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY * 1.2,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < keys.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      keys[value.toInt()],
                      style: TextStyle(fontSize: 10, color: _textSecondary),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toStringAsFixed(1)}',
                  style: TextStyle(fontSize: 10, color: _textSecondary),
                );
              },
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY > 0 ? maxY / 4 : 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: _textSecondary.withOpacity(0.1),
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(
          keys.length,
          (index) => BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: data[keys[index]]!,
                color: AppColors.primaryOrange,
                width: 16,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeatMap() {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0);
    final daysInMonth = lastDay.day;

    // Calculate activity counts per day
    final activityCounts = <int, int>{};
    for (final activity in _activities) {
      final activityDate = activity.startTime;
      if (activityDate.year == now.year && activityDate.month == now.month) {
        final day = activityDate.day;
        activityCounts[day] = (activityCounts[day] ?? 0) + 1;
        print('Heat map: Day $day has ${activityCounts[day]} activities');
      }
    }
    print('Heat map total days with activities: ${activityCounts.length}');
    print('Heat map activity counts: $activityCounts');

    final maxCount =
        activityCounts.values.fold<int>(0, (max, v) => v > max ? v : max);
    final firstDayWeekday = firstDay.weekday; // 1 = Monday, 7 = Sunday

    return Column(
      children: [
        // Week day labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['Pon', 'Uto', 'Sre', 'Čet', 'Pet', 'Sub', 'Ned']
              .map((day) => SizedBox(
                    width: 36,
                    child: Center(
                      child: Text(day,
                          style:
                              TextStyle(fontSize: 10, color: _textSecondary)),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),
        // Calendar grid - generate 6 weeks to ensure all days fit
        ...List.generate(
          6, // Max 6 weeks in a month
          (weekIndex) {
            final weekCells = <Widget>[];

            for (int dayOfWeek = 1; dayOfWeek <= 7; dayOfWeek++) {
              // Calculate the actual day number
              final dayNum = weekIndex * 7 + dayOfWeek - (firstDayWeekday - 1);

              if (dayNum < 1 || dayNum > daysInMonth) {
                // Empty cell
                weekCells.add(const SizedBox(width: 36, height: 36));
              } else {
                // Day cell
                final count = activityCounts[dayNum] ?? 0;
                final intensity = maxCount > 0 ? count / maxCount : 0.0;
                final isToday = dayNum == now.day;

                weekCells.add(
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: count == 0
                          ? _textSecondary.withOpacity(0.1)
                          : AppColors.primaryOrange
                              .withOpacity(0.4 + intensity * 0.6),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isToday
                            ? AppColors.accentBlue // Blue border for today
                            : count > 0
                                ? AppColors.primaryOrange.withOpacity(0.5)
                                : _textSecondary.withOpacity(0.1),
                        width: isToday ? 2 : (count > 0 ? 2 : 1),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$dayNum',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              count > 0 ? FontWeight.bold : FontWeight.normal,
                          color: count > 0
                              ? Colors.white // White text on orange background
                              : _textSecondary,
                        ),
                      ),
                    ),
                  ),
                );
              }
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: weekCells,
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Manje',
                style: TextStyle(fontSize: 10, color: _textSecondary)),
            const SizedBox(width: 8),
            ...List.generate(
              5,
              (i) => Container(
                width: 16,
                height: 16,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange.withOpacity(0.2 + i * 0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text('Više', style: TextStyle(fontSize: 10, color: _textSecondary)),
          ],
        ),
      ],
    );
  }
}
