import 'package:flutter/material.dart';
import '../../utils/colors.dart';

class SettingsPanel extends StatefulWidget {
  const SettingsPanel({Key? key}) : super(key: key);

  @override
  State<SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<SettingsPanel> {
  bool _darkMode = false;
  bool _largeText = false;
  bool _highContrast = false;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.45,
      minChildSize: 0.3,
      maxChildSize: 0.6,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'Podešavanja',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 24),

              // ── Night mode ──
              const Text(
                'Izgled',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textGrey,
                ),
              ),
              const SizedBox(height: 8),
              _buildToggleTile(
                icon: Icons.dark_mode_outlined,
                title: 'Noćni režim',
                subtitle: 'Tamna tema za interfejs',
                value: _darkMode,
                onChanged: (val) {
                  setState(() => _darkMode = val);
                  // TODO: hook into ThemeNotifier
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(val
                          ? 'Noćni režim uključen'
                          : 'Noćni režim isključen'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // ── Accessibility ──
              const Text(
                'Pristupačnost',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textGrey,
                ),
              ),
              const SizedBox(height: 8),
              _buildToggleTile(
                icon: Icons.text_increase,
                title: 'Veći tekst',
                subtitle: 'Povećajte veličinu fonta',
                value: _largeText,
                onChanged: (val) {
                  setState(() => _largeText = val);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(val
                          ? 'Veći tekst uključen'
                          : 'Veći tekst isključen'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              _buildToggleTile(
                icon: Icons.contrast,
                title: 'Visoki kontrast',
                subtitle: 'Pojačan kontrast boja',
                value: _highContrast,
                onChanged: (val) {
                  setState(() => _highContrast = val);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(val
                          ? 'Visoki kontrast uključen'
                          : 'Visoki kontrast isključen'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primaryOrange, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark)),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textGrey)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primaryOrange,
          ),
        ],
      ),
    );
  }
}
