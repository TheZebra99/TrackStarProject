import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:trackstar/screens/profile/activity_history_screen.dart';
import 'package:trackstar/screens/profile/achievements_screen.dart';
import 'package:trackstar/screens/profile/edit_profile_screen.dart';
import 'package:trackstar/screens/profile/favorite_routes_screen.dart';
import 'package:trackstar/screens/profile/settings_panel.dart';
import '../../utils/colors.dart';
import '../../utils/app_settings.dart';
import '../auth/login_screen.dart';
import '../../services/database_service.dart';
import '../../services/user_session.dart';
import '../../models/achievement.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _totalActivities = 0;
  double _totalDistance = 0.0;
  int _totalDuration = 0;
  double _maxSingleDistance = 0.0;

  File? _profileImage;
  final ImagePicker _imagePicker = ImagePicker();

  // Per-user image key so switching accounts clears the picture
  String get _imgKey => 'profile_image_path_${UserSession.instance.userId}';

  @override
  void initState() {
    super.initState();
    _loadStats();
    _loadSavedImage();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await DatabaseService.instance
          .getUserStats(UserSession.instance.userId);
      setState(() {
        _totalActivities   = stats['totalActivities']   as int;
        _totalDistance     = stats['totalDistance']     as double;
        _totalDuration     = stats['totalDuration']     as int;
        _maxSingleDistance = stats['maxSingleDistance'] as double;
      });
    } catch (e) {
      debugPrint('Error loading profile stats: $e');
    }
  }

  Future<void> _loadSavedImage() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_imgKey);
    if (path != null && File(path).existsSync()) {
      setState(() => _profileImage = File(path));
    } else {
      setState(() => _profileImage = null);
    }
  }

  Future<void> _saveImagePath(String? path) async {
    final prefs = await SharedPreferences.getInstance();
    if (path == null) {
      await prefs.remove(_imgKey);
    } else {
      await prefs.setString(_imgKey, path);
    }
  }

  String _formatTotalDuration(int seconds) {
    final hours   = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    return hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';
  }

  Future<void> _pickProfileImage() async {
    final isDark = AppSettings.instance.darkMode;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Promenite profilnu sliku',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textDark)),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: AppColors.primaryOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.camera_alt,
                    color: AppColors.primaryOrange),
              ),
              title: const Text('Kamera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: AppColors.accentBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.photo_library,
                    color: AppColors.accentBlue),
              ),
              title: const Text('Galerija'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            if (_profileImage != null)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.delete, color: Colors.red),
                ),
                title: const Text('Uklonite sliku'),
                onTap: () {
                  setState(() => _profileImage = null);
                  _saveImagePath(null);
                  Navigator.pop(context);
                },
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );

    if (source != null) {
      final XFile? picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() => _profileImage = File(picked.path));
        await _saveImagePath(picked.path);
      }
    }
  }

  void _openSettingsDrawer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SettingsPanel(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark        = AppSettings.instance.darkMode;
    final bgColor       = isDark ? const Color(0xFF121212) : AppColors.backgroundLight;
    final cardBg        = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textPrimary   = isDark ? Colors.white : AppColors.textDark;
    final textSecondary = isDark ? Colors.white60 : AppColors.textGrey;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        title: Text('Profil',
            style: TextStyle(
                color: textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: textPrimary),
            onPressed: _openSettingsDrawer,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              Container(
                color: cardBg,
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        GestureDetector(
                          onTap: _pickProfileImage,
                          child: Container(
                            width: 100, height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primaryOrange.withOpacity(0.1),
                              border: Border.all(
                                  color: AppColors.primaryOrange, width: 3),
                              image: _profileImage != null
                                  ? DecorationImage(
                                      image: FileImage(_profileImage!),
                                      fit: BoxFit.cover)
                                  : null,
                            ),
                            child: _profileImage == null
                                ? const Icon(Icons.person,
                                    size: 50,
                                    color: AppColors.primaryOrange)
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 0, right: 0,
                          child: GestureDetector(
                            onTap: _pickProfileImage,
                            child: Container(
                              width: 32, height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.primaryOrange,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.edit,
                                  size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(UserSession.instance.displayName,
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: textPrimary)),
                    const SizedBox(height: 4),
                    Text(UserSession.instance.email,
                        style:
                            TextStyle(fontSize: 14, color: textSecondary)),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatColumn('$_totalActivities',
                            'Aktivnosti', textPrimary, textSecondary),
                        Container(
                            height: 40,
                            width: 1,
                            color: textSecondary.withOpacity(0.2)),
                        _buildStatColumn(
                            '${_totalDistance.toStringAsFixed(1)} km',
                            'Ukupna distanca',
                            textPrimary, textSecondary),
                        Container(
                            height: 40,
                            width: 1,
                            color: textSecondary.withOpacity(0.2)),
                        _buildStatColumn(
                            _formatTotalDuration(_totalDuration),
                            'Vreme',
                            textPrimary, textSecondary),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Achievements preview
              Container(
                color: cardBg,
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Dostignuća',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textPrimary)),
                        // "Vidi sve" navigates to AchievementsScreen
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AchievementsScreen(
                                totalActivities: _totalActivities,
                                totalDistance: _totalDistance,
                                maxSingleDistance: _maxSingleDistance,
                              ),
                            ),
                          ),
                          child: const Text('Vidi sve',
                              style: TextStyle(
                                  color: AppColors.primaryOrange)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildAchievementsPreview(textSecondary, textPrimary),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Container(
                color: cardBg,
                child: Column(
                  children: [
                    _buildMenuItem(
                      icon: Icons.edit_outlined,
                      title: 'Uredi profil',
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const EditProfileScreen()),
                      ).then((changed) {
                        if (changed == true) setState(() {});
                      }),
                    ),
                    _buildDivider(textSecondary),
                    _buildMenuItem(
                      icon: Icons.history,
                      title: 'Istorija aktivnosti',
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ActivityHistoryScreen()),
                      ).then((_) => _loadStats()),
                    ),
                    _buildDivider(textSecondary),
                    _buildMenuItem(
                      icon: Icons.star_outline,
                      title: 'Omiljene rute',
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const FavoriteRoutesScreen())),
                    ),
                    _buildDivider(textSecondary),
                    _buildMenuItem(
                      icon: Icons.help_outline,
                      title: 'Pomoć i podrška',
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      onTap: () =>
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Dolazi uskoro'),
                                  duration: Duration(seconds: 1))),
                    ),
                    _buildDivider(textSecondary),
                    _buildMenuItem(
                      icon: Icons.logout,
                      title: 'Odjavi se',
                      textPrimary: Colors.red,
                      textSecondary: textSecondary,
                      iconColor: Colors.red,
                      onTap: _handleLogout,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // Achievements preview
  Widget _buildAchievementsPreview(Color textSecondary, Color textPrimary) {
    final unlocked = allAchievements
        .where((a) =>
            a.isUnlocked(_totalActivities, _totalDistance, _maxSingleDistance))
        .take(4)
        .toList();

    if (unlocked.isEmpty) {
      return Column(
        children: [
          Icon(Icons.emoji_events_outlined,
              size: 60, color: textSecondary.withOpacity(0.3)),
          const SizedBox(height: 8),
          Text('Nema dostignuća',
              style: TextStyle(fontSize: 14, color: textSecondary)),
        ],
      );
    }

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.center,
      children: unlocked.map((a) => _buildBadge(a, textPrimary)).toList(),
    );
  }

  Widget _buildBadge(Achievement a, Color textPrimary) {
    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Row(children: [
            Icon(a.icon, color: AppColors.primaryOrange),
            const SizedBox(width: 8),
            Text(a.title),
          ]),
          content: Text(a.description),
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
            width: 60, height: 60,
            decoration: BoxDecoration(
              color: AppColors.primaryOrange.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                  color: AppColors.primaryOrange.withOpacity(0.5)),
            ),
            child: Icon(a.icon, color: AppColors.primaryOrange, size: 28),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 72,
            child: Text(a.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: textPrimary)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(
      String value, String label, Color primary, Color secondary) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: primary)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: secondary)),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required Color textPrimary,
    required Color textSecondary,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? textPrimary),
      title: Text(title, style: TextStyle(fontSize: 16, color: textPrimary)),
      trailing:
          Icon(Icons.arrow_forward_ios, size: 16, color: textSecondary),
      onTap: onTap,
    );
  }

  Widget _buildDivider(Color textSecondary) => Divider(
      height: 1,
      thickness: 1,
      color: textSecondary.withOpacity(0.1),
      indent: 56);

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Odjavi se'),
        content:
            const Text('Da li ste sigurni da želite da se odjavite?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Otkaži')),
          TextButton(
            onPressed: () {
              UserSession.instance.clearUser();
              AppSettings.instance.resetToDefaults(); // reset night mode and accesibility settings
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Odjavi se',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}