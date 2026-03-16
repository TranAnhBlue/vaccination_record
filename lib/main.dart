import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vaccination_record/presentation/viewmodels/ai_viewmodel.dart';

import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_routes.dart';

import 'data/local/dao/user_dao.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'presentation/viewmodels/auth_viewmodel.dart';
import 'presentation/viewmodels/vaccination_viewmodel.dart';
import 'presentation/viewmodels/household_viewmodel.dart';
import 'presentation/viewmodels/settings_viewmodel.dart';
import 'data/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final notificationService = NotificationService();
  await notificationService.init();
  await notificationService.requestPermissions();

  /// Dependency Injection
  final repo = AuthRepositoryImpl(UserDao());

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthViewModel(repo),
        ),
        ChangeNotifierProvider(
          create: (_) => VaccinationViewModel()..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => AIViewModel(),
        ),
        ChangeNotifierProvider(
          create: (_) => HouseholdViewModel(),
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsViewModel(),
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