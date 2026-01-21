import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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
            icon: const Icon(Icons.settings_outlined, color: AppColors.textDark),
            onPressed: () {
              // TODO: Navigate to settings
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Profile picture
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryOrange.withOpacity(0.1),
                      border: Border.all(
                        color: AppColors.primaryOrange,
                        width: 3,
                      ),
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 50,
                      color: AppColors.primaryOrange,
                    ),
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
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textGrey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Stats row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatColumn('0', 'Aktivnosti'),
                      Container(
                        height: 40,
                        width: 1,
                        color: AppColors.textGrey.withOpacity(0.2),
                      ),
                      _buildStatColumn('0 km', 'Ukupna distanca'),
                      Container(
                        height: 40,
                        width: 1,
                        color: AppColors.textGrey.withOpacity(0.2),
                      ),
                      _buildStatColumn('0h', 'Vreme'),
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
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.emoji_events_outlined,
                          size: 60,
                          color: AppColors.textGrey.withOpacity(0.3),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Nema dostignuća',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Settings section
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  _buildSettingsItem(
                    icon: Icons.edit_outlined,
                    title: 'Uredi profil',
                    onTap: () {
                      // TODO: Navigate to edit profile
                    },
                  ),
                  _buildDivider(),
                  _buildSettingsItem(
                    icon: Icons.history,
                    title: 'Istorija aktivnosti',
                    onTap: () {
                      // TODO: Navigate to activity history
                    },
                  ),
                  _buildDivider(),
                  _buildSettingsItem(
                    icon: Icons.star_outline,
                    title: 'Omiljene rute',
                    onTap: () {
                      // TODO: Navigate to favorite routes
                    },
                  ),
                  _buildDivider(),
                  _buildSettingsItem(
                    icon: Icons.notifications_outlined,
                    title: 'Obaveštenja',
                    onTap: () {
                      // TODO: Navigate to notifications settings
                    },
                  ),
                  _buildDivider(),
                  _buildSettingsItem(
                    icon: Icons.help_outline,
                    title: 'Pomoć i podrška',
                    onTap: () {
                      // TODO: Navigate to help
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
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 4),
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

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? titleColor,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? AppColors.textDark,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          color: titleColor ?? AppColors.textDark,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: AppColors.textGrey,
      ),
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
              // TODO: Clear user session/data
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