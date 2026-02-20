import 'package:flutter/material.dart';
import 'package:trackstar/screens/profile/settings_panel.dart';
import '../../utils/colors.dart';
import '../auth/login_screen.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../services/database_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final int _currentUserId = 1;

  int _totalActivities = 0;
  double _totalDistance = 0.0;
  int _totalDuration = 0;

  File? _profileImage;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await DatabaseService.instance.getUserStats(_currentUserId);
      setState(() {
        _totalActivities = stats['totalActivities'] as int;
        _totalDistance = stats['totalDistance'] as double;
        _totalDuration = stats['totalDuration'] as int;
      });
    } catch (e) {
      print('Error loading profile stats: $e');
    }
  }

  String _formatTotalDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  Future<void> _pickProfileImage() async {
    final source = await showModalBottomSheet<ImageSource>(
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
          children: [
            const Text(
              'Promenite profilnu sliku',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
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
                  borderRadius: BorderRadius.circular(10),
                ),
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
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.delete, color: Colors.red),
                ),
                title: const Text('Uklonite sliku'),
                onTap: () {
                  setState(() => _profileImage = null);
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
        setState(() {
          _profileImage = File(picked.path);
        });
      }
    }
  }

  // open settings in profile
  void _openSettingsDrawer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SettingsPanel(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Profil',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon:
                const Icon(Icons.settings_outlined, color: AppColors.textDark),
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
              // Profile header
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Profile picture with edit button
                    Stack(
                      children: [
                        GestureDetector(
                          onTap: _pickProfileImage,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primaryOrange.withOpacity(0.1),
                              border: Border.all(
                                color: AppColors.primaryOrange,
                                width: 3,
                              ),
                              image: _profileImage != null
                                  ? DecorationImage(
                                      image: FileImage(_profileImage!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: _profileImage == null
                                ? const Icon(
                                    Icons.person,
                                    size: 50,
                                    color: AppColors.primaryOrange,
                                  )
                                : null,
                          ),
                        ),
                        // Edit mini-button
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickProfileImage,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.primaryOrange,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.edit,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Korisnik',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'user@example.com',
                      style: TextStyle(fontSize: 14, color: AppColors.textGrey),
                    ),
                    const SizedBox(height: 24),
                    // Dynamic stats row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatColumn('$_totalActivities', 'Aktivnosti'),
                        Container(
                          height: 40,
                          width: 1,
                          color: AppColors.textGrey.withOpacity(0.2),
                        ),
                        _buildStatColumn(
                          '${_totalDistance.toStringAsFixed(1)} km',
                          'Ukupna distanca',
                        ),
                        Container(
                          height: 40,
                          width: 1,
                          color: AppColors.textGrey.withOpacity(0.2),
                        ),
                        _buildStatColumn(
                          _formatTotalDuration(_totalDuration),
                          'Vreme',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Achievements section
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dostignuća',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildAchievements(),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Menu items
              Container(
                color: Colors.white,
                child: Column(
                  children: [
                    _buildSettingsItem(
                      icon: Icons.edit_outlined,
                      title: 'Uredi profil',
                      onTap: () {
                        // TODO: navigate to edit profile
                      },
                    ),
                    _buildDivider(),
                    _buildSettingsItem(
                      icon: Icons.history,
                      title: 'Istorija aktivnosti',
                      onTap: () {
                        // TODO: navigate to activity history
                      },
                    ),
                    _buildDivider(),
                    _buildSettingsItem(
                      icon: Icons.star_outline,
                      title: 'Omiljene rute',
                      onTap: () {
                        // TODO: navigate to favorite routes
                      },
                    ),
                    _buildDivider(),
                    _buildSettingsItem(
                      icon: Icons.notifications_outlined,
                      title: 'Obaveštenja',
                      onTap: () {
                        // TODO: navigate to notifications settings
                      },
                    ),
                    _buildDivider(),
                    _buildSettingsItem(
                      icon: Icons.help_outline,
                      title: 'Pomoć i podrška',
                      onTap: () {
                        // TODO: navigate to help
                      },
                    ),
                    _buildDivider(),
                    _buildSettingsItem(
                      icon: Icons.logout,
                      title: 'Odjavi se',
                      titleColor: Colors.red,
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

  Widget _buildAchievements() {
    final achievements = <Map<String, dynamic>>[
      {
        'icon': Icons.directions_walk,
        'title': 'Prva šetnja',
        'desc': 'Završite prvu aktivnost',
        'unlocked': _totalActivities >= 1,
      },
      {
        'icon': Icons.local_fire_department,
        'title': '5 aktivnosti',
        'desc': 'Završite 5 aktivnosti',
        'unlocked': _totalActivities >= 5,
      },
      {
        'icon': Icons.terrain,
        'title': '10 km',
        'desc': 'Ukupno pređite 10 km',
        'unlocked': _totalDistance >= 10.0,
      },
      {
        'icon': Icons.emoji_events,
        'title': 'Maraton',
        'desc': 'Ukupno pređite 42 km',
        'unlocked': _totalDistance >= 42.0,
      },
    ];

    final unlocked = achievements.where((a) => a['unlocked'] == true).length;

    if (unlocked == 0) {
      return Center(
        child: Column(
          children: [
            Icon(Icons.emoji_events_outlined,
                size: 60, color: AppColors.textGrey.withOpacity(0.3)),
            const SizedBox(height: 8),
            Text('Nema dostignuća',
                style: TextStyle(fontSize: 14, color: AppColors.textGrey)),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: achievements
          .where((a) => a['unlocked'] == true)
          .map((a) => _buildAchievementBadge(
                icon: a['icon'],
                title: a['title'],
              ))
          .toList(),
    );
  }

  Widget _buildAchievementBadge(
      {required IconData icon, required String title}) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.primaryOrange.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primaryOrange.withOpacity(0.5)),
          ),
          child: Icon(icon, color: AppColors.primaryOrange, size: 28),
        ),
        const SizedBox(height: 4),
        Text(title,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark)),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
      ],
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? titleColor,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.textDark),
      title: Text(title,
          style: TextStyle(
              fontSize: 16, color: titleColor ?? AppColors.textDark)),
      trailing: Icon(Icons.arrow_forward_ios,
          size: 16, color: AppColors.textGrey),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: AppColors.textGrey.withOpacity(0.1),
      indent: 56,
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Odjavi se'),
        content: const Text('Da li ste sigurni da želite da se odjavite?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Otkaži'),
          ),
          TextButton(
            onPressed: () {
              // add clear user session/data later
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text(
              'Odjavi se',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}