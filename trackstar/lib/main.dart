import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';
import 'utils/colors.dart';
import 'utils/app_settings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TrackStarApp());
}

class TrackStarApp extends StatefulWidget {
  const TrackStarApp({Key? key}) : super(key: key);

  @override
  State<TrackStarApp> createState() => _TrackStarAppState();
}

class _TrackStarAppState extends State<TrackStarApp> {
  final _settings = AppSettings.instance;

  @override
  void initState() {
    super.initState();
    _settings.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    // high-contrast accesibility setting adjusts text colours in the theme
    final hc = _settings.highContrast;

    return MediaQuery(
      data: MediaQueryData(
        textScaler: TextScaler.linear(_settings.textScaleFactor),
      ),
      child: MaterialApp(
        title: 'TrackStar',
        debugShowCheckedModeBanner: false,
        themeMode: _settings.themeMode,

        // light theme
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: AppColors.backgroundLight,
          cardColor: Colors.white,
          colorScheme: ColorScheme.light(
            primary: AppColors.primaryOrange,
            secondary: AppColors.accentBlue,
            surface: Colors.white,
            onSurface: hc ? Colors.black : AppColors.textDark,
            onSurfaceVariant: hc ? Colors.black87 : AppColors.textGrey,
          ),
          appBarTheme: AppBarTheme(
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: hc ? Colors.black : AppColors.textDark,
            titleTextStyle: TextStyle(
              color: hc ? Colors.black : AppColors.textDark,
              fontSize: 20,
              fontWeight: hc ? FontWeight.w900 : FontWeight.bold,
            ),
          ),
          textTheme: TextTheme(
            bodyMedium: TextStyle(
              color: hc ? Colors.black : AppColors.textDark,
              fontWeight: hc ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          dividerTheme: DividerThemeData(
            thickness: hc ? 2 : 1,
            color: hc ? Colors.black26 : AppColors.textGrey.withOpacity(0.2),
          ),
        ),

        // dark theme
        darkTheme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF121212),
          cardColor: const Color(0xFF1E1E1E),
          colorScheme: ColorScheme.dark(
            primary: AppColors.primaryOrange,
            secondary: AppColors.accentBlue,
            surface: const Color(0xFF1E1E1E),
            onSurface: hc ? Colors.white : Colors.white,
            onSurfaceVariant: hc ? Colors.white : Colors.white60,
          ),
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
            backgroundColor: Color(0xFF1E1E1E),
            foregroundColor: Colors.white,
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          dividerTheme: DividerThemeData(
            thickness: hc ? 2 : 1,
            color: hc ? Colors.white24 : Colors.white12,
          ),
        ),

        home: const LoginScreen(),
      ),
    );
  }
}