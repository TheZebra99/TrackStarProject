import 'package:flutter/material.dart';
import '../../utils/colors.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({Key? key}) : super(key: key);

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map placeholder
          Container(
            color: AppColors.backgroundLight,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.map_outlined,
                    size: 100,
                    color: AppColors.textGrey.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Mapa će biti ovde',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textGrey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'GPS tracking će biti implementiran',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textGrey.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Top stats overlay (will show during activity)
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
                    _buildStatItem('00:00:00', 'Vreme', Icons.timer_outlined),
                    _buildStatItem('0.00', 'Km', Icons.straighten_outlined),
                    _buildStatItem('0.0', 'km/h', Icons.speed_outlined),
                  ],
                ),
              ),
            ),
          ),

          // Start activity button
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _showActivityTypeSelector,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primaryOrange,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryOrange.withOpacity(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.play_arrow,
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

  void _startActivity(String type) {
    // TODO: Implement GPS tracking
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Započinjanje ${type == 'walk' ? 'šetnje' : type == 'run' ? 'trčanja' : 'vožnje'}...'),
        backgroundColor: AppColors.primaryOrange,
      ),
    );
  }
}