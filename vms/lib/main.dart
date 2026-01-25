import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'services/auth_service.dart';
import 'services/location_service.dart';
import 'services/theme_service.dart';
import 'features/splash/splash_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>(create: (_) => AuthService()),
        ChangeNotifierProvider<LocationService>(
          create: (_) => LocationService()..fetchLocation(),
        ),
        ChangeNotifierProvider<ThemeService>(create: (_) => ThemeService()),
      ],
      child: const VendorApp(),
    ),
  );
}

class VendorApp extends StatelessWidget {
  const VendorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return MaterialApp(
          title: 'Vendor Management System',
          // Pass the selected primary color to generate the theme
          theme: AppTheme.lightTheme(themeService.primaryColor),
          darkTheme: AppTheme.darkTheme(themeService.primaryColor),
          themeMode: themeService.themeMode,
          home: const AuthWrapper(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    // Artificial delay for splash screen
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      await context.read<AuthService>().checkAuthStatus();
      setState(() => _showSplash = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return const SplashScreen();
    }

    return Consumer<AuthService>(
      builder: (context, auth, child) {
        if (auth.isAuthenticated) {
          return const DashboardScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
