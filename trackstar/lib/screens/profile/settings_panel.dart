import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import '../../utils/app_settings.dart';

class SettingsPanel extends StatefulWidget {
  const SettingsPanel({Key? key}) : super(key: key);

  @override
  State<SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<SettingsPanel> {
  final _settings = AppSettings.instance;
  ScaffoldMessengerState? _messenger;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _messenger = ScaffoldMessenger.of(context);
  }

  void _showSnack(String msg) => _messenger?.showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 1)));

  @override
  Widget build(BuildContext context) {
    // panel itself must also respond to current dark-mode state
    final isDark  = _settings.darkMode;
    final cardBg  = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final tileBg  = isDark ? const Color(0xFF2A2A2A) : AppColors.backgroundLight;
    final textPrimary   = isDark ? Colors.white : AppColors.textDark;
    final textSecondary = isDark ? Colors.white60 : AppColors.textGrey;

    return DraggableScrollableSheet(
      initialChildSize: 0.48,
      minChildSize: 0.35,
      maxChildSize: 0.65,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: textSecondary.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text('Podešavanja',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textPrimary)),
              const SizedBox(height: 24),

              Text('Izgled',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textSecondary)),
              const SizedBox(height: 8),
              _toggle(
                icon: Icons.dark_mode_outlined,
                title: 'Noćni režim',
                subtitle: 'Tamna tema za interfejs',
                value: _settings.darkMode,
                tileBg: tileBg,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                onChanged: (val) {
                  // update AppSettings which notifies main.dart
                  setState(() => _settings.darkMode = val);
                  _showSnack(val
                      ? 'Noćni režim uključen'
                      : 'Noćni režim isključen');
                },
              ),

              const SizedBox(height: 20),

              // accessibility settings
              Text('Pristupačnost',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textSecondary)),
              const SizedBox(height: 8),
              _toggle(
                icon: Icons.text_increase,
                title: 'Veći tekst',
                subtitle: 'Povećajte veličinu fonta (120%)',
                value: _settings.largeText,
                tileBg: tileBg,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                onChanged: (val) {
                  setState(() => _settings.largeText = val);
                  _showSnack(val
                      ? 'Veći tekst uključen'
                      : 'Veći tekst isključen');
                },
              ),
              const SizedBox(height: 8),
              _toggle(
                icon: Icons.contrast,
                title: 'Visoki kontrast',
                subtitle: 'Pojačan kontrast boja',
                value: _settings.highContrast,
                tileBg: tileBg,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                onChanged: (val) {
                  // main.dart rebuilds the theme
                  setState(() => _settings.highContrast = val);
                  _showSnack(val
                      ? 'Visoki kontrast uključen'
                      : 'Visoki kontrast isključen');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _toggle({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Color tileBg,
    required Color textPrimary,
    required Color textSecondary,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: tileBg,
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
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textPrimary)),
                Text(subtitle,
                    style: TextStyle(fontSize: 12, color: textSecondary)),
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