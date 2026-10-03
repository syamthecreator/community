import 'package:community/features/authentication/presentation/screens/auth_screen.dart';
import 'package:community/features/home/presentation/screens/home_screen.dart';
import 'package:community/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:community/features/profile/presentation/screens/profile_screen.dart';
import 'package:community/features/splash/presentation/screens/splash_sscreen.dart';
import 'package:flutter/material.dart';

class AppRouter {
  AppRouter._();

  static const String splash = '/splash';
  static const String auth = '/auth';
  static const String home = '/home';
  static const String report = '/report';
  static const String notifications = '/notifications';
  static const String profile = '/profile';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case auth:
        return MaterialPageRoute(builder: (_) => const AuthScreen());

      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());

      case notifications:
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            backgroundColor: Colors.white,
            body: NotificationsScreen(onBack: () => Navigator.pop(context)),
          ),
        );

      case profile:
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            backgroundColor: Colors.white,
            body: ProfileScreen(onBack: () => Navigator.pop(context)),
          ),
        );

      default:
        return MaterialPageRoute(builder: (_) => const AuthScreen());
    }
  }
}
