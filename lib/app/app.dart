import 'package:community/features/authentication/provider/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_router.dart';

class CommunityApp extends StatelessWidget {
  const CommunityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const _CommunityApp(),
    );
  }
}

class _CommunityApp extends StatelessWidget {
  const _CommunityApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Community App',
      debugShowCheckedModeBanner: false,
      initialRoute: AppRouter.home,
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}
