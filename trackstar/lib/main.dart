import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';
import 'utils/colors.dart';
import 'utils/app_settings.dart';

void main() {
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
    return MediaQuery(
      data: MediaQueryData(
        textScaler: TextScaler.linear(_settings.textScaleFactor),
      ),
      child: MaterialApp(
        title: 'TrackStar',
        debugShowCheckedModeBanner: false,
        themeMode: _settings.themeMode,
        theme: ThemeData(
          primarySwatch: Colors.orange,
          useMaterial3: true,
          scaffoldBackgroundColor: AppColors.backgroundLight,
          colorScheme: ColorScheme.light(
            primary: AppColors.primaryOrange,
            secondary: AppColors.accentBlue,
            onSurface: _settings.highContrast ? Colors.black : AppColors.textDark,
          ),
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
          ),
        ),
        darkTheme: ThemeData(
          primarySwatch: Colors.orange,
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF121212),
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primaryOrange,
            secondary: AppColors.accentBlue,
            surface: Color(0xFF1E1E1E),
            onSurface: Colors.white,
          ),
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
            backgroundColor: Color(0xFF1E1E1E),
            foregroundColor: Colors.white,
          ),
        ),
        home: const LoginScreen(),
      ),
    );
  }
}