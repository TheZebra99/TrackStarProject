import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import '../../utils/app_settings.dart';
import '../../models/achievement.dart';

class AchievementsScreen extends StatelessWidget {
  final int totalActivities;
  final double totalDistance;
  final double maxSingleDistance;

  const AchievementsScreen({
    Key? key,
    required this.totalActivities,
    required this.totalDistance,
    required this.maxSingleDistance,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = AppSettings.instance.darkMode;
    final bgColor =
        isDark ? const Color(0xFF121212) : AppColors.backgroundLight;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textPrimary = isDark ? Colors.white : AppColors.textDark;
    final textSecondary = isDark ? Colors.white60 : AppColors.textGrey;

    final unlocked = allAchievements
        .where((a) =>
            a.isUnlocked(totalActivities, totalDistance, maxSingleDistance))
        .map((a) => a.id)
        .toSet();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        title: Text('Dostignuća',
            style: TextStyle(
                color: textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: AppColors.primaryOrange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryOrange.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.emoji_events,
                        color: AppColors.primaryOrange, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${unlocked.length} / ${allAchievements.length} otključano',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textPrimary),
                      ),
                      Text('Nastavite da trenirate!',
                          style: TextStyle(fontSize: 13, color: textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text('Sva dostignuća',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textSecondary)),
            const SizedBox(height: 16),

            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 20,
                  childAspectRatio: 0.75,
                ),
                itemCount: allAchievements.length,
                itemBuilder: (context, i) {
                  final a = allAchievements[i];
                  final isUnlocked = unlocked.contains(a.id);
                  return _AchievementTile(
                    achievement: a,
                    isUnlocked: isUnlocked,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    cardBg: cardBg,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final Achievement achievement;
  final bool isUnlocked;
  final Color textPrimary;
  final Color textSecondary;
  final Color cardBg;

  const _AchievementTile({
    required this.achievement,
    required this.isUnlocked,
    required this.textPrimary,
    required this.textSecondary,
    required this.cardBg,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Row(children: [
            Icon(achievement.icon,
                color: isUnlocked ? AppColors.primaryOrange : Colors.grey),
            const SizedBox(width: 8),
            Flexible(child: Text(achievement.title)),
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(achievement.description),
              if (!isUnlocked) ...[
                const SizedBox(height: 8),
                Text(
                  '🔒 Još nije otključano',
                  style: TextStyle(
                      color: Colors.grey, fontStyle: FontStyle.italic),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'))
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isUnlocked
                  ? AppColors.primaryOrange.withOpacity(0.12)
                  : Colors.grey.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: isUnlocked
                    ? AppColors.primaryOrange.withOpacity(0.5)
                    : Colors.grey.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(
              achievement.icon,
              color: isUnlocked ? AppColors.primaryOrange : Colors.grey,
              size: 28,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            achievement.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isUnlocked ? textPrimary : textSecondary,
            ),
          ),
          if (!isUnlocked) const Text('🔒', style: TextStyle(fontSize: 10)),
        ],
      ),
    );
  }
}
