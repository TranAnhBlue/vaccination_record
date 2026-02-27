import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_routes.dart';

import 'data/local/dao/user_dao.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'presentation/viewmodels/auth_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// Dependency Injection
  final repo = AuthRepositoryImpl(UserDao());

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthViewModel(repo),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Vaccination Record",
      debugShowCheckedModeBanner: false,

      /// Theme
      theme: AppTheme.lightTheme,

      /// START FROM SPLASH
      initialRoute: AppRoutes.splash,

      /// Router
      onGenerateRoute: generateRoute,
    );
  }
}