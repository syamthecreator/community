import 'package:community/features/authentication/provider/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app_router.dart';

import 'package:community/core/network/connectivity_service.dart';
import 'package:community/core/widgets/no_internet_screen.dart';

class CommunityApp extends StatelessWidget {
  const CommunityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ConnectivityService()),
      ],
      child: const _CommunityApp(),
    );
  }
}

class _CommunityApp extends StatelessWidget {
  const _CommunityApp();

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: MaterialApp(
        title: 'Community App',
        debugShowCheckedModeBanner: false,
        initialRoute: AppRouter.splash,
        onGenerateRoute: AppRouter.generateRoute,
        builder: (context, child) {
          final online = context.select<ConnectivityService, bool>(
            (s) => s.isOnline,
          );
          return Stack(
            children: [
              child ?? const SizedBox.shrink(),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: online
                    ? const SizedBox.shrink(key: ValueKey('online'))
                    : const NoInternetScreen(key: ValueKey('offline')),
              ),
            ],
          );
        },
      ),
    );
  }
}
