import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import '../../utils/app_settings.dart';

class SettingsPanel extends StatefulWidget {
  const SettingsPanel({Key? key}) : super(key: key);

  @override
  State<SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<SettingsPanel> {
  // Read initial values from the singleton
  final _settings = AppSettings.instance;

  bool get _darkMode => _settings.darkMode;
  bool get _largeText => _settings.largeText;
  bool get _highContrast => _settings.highContrast;

  ScaffoldMessengerState? _messenger;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _messenger = ScaffoldMessenger.of(context);
  }

  void _showSnack(String message) {
    _messenger?.showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.48,
      minChildSize: 0.35,
      maxChildSize: 0.65,
      builder: (sheetContext, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            children: [
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
                    color: AppColors.textDark),
              ),
              const SizedBox(height: 24),

              const Text(
                'Izgled',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textGrey),
              ),
              const SizedBox(height: 8),
              _buildToggleTile(
                icon: Icons.dark_mode_outlined,
                title: 'Night mode',
                subtitle: 'Tamna tema za interfejs',
                value: _darkMode,
                onChanged: (val) {
                  setState(() => _settings.darkMode = val);
                  _showSnack(val
                      ? 'Night mode uključen'
                      : 'Night mode isključen');
                },
              ),

              const SizedBox(height: 20),

              const Text(
                'Pristupačnost',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textGrey),
              ),
              const SizedBox(height: 8),
              _buildToggleTile(
                icon: Icons.text_increase,
                title: 'Veći tekst',
                subtitle: 'Povećajte veličinu fonta (120%)',
                value: _largeText,
                onChanged: (val) {
                  setState(() => _settings.largeText = val);
                  _showSnack(
                      val ? 'Veći tekst uključen' : 'Veći tekst isključen');
                },
              ),
              const SizedBox(height: 8),
              _buildToggleTile(
                icon: Icons.contrast,
                title: 'Visoki kontrast',
                subtitle: 'Pojačan kontrast boja',
                value: _highContrast,
                onChanged: (val) {
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