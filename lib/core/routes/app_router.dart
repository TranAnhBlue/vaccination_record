import 'package:flutter/material.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/auth/forgot_password_screen.dart';
import '../../presentation/screens/auth/otp_screen.dart';
import '../../presentation/screens/auth/splash_screen.dart';
import 'app_routes.dart';

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case AppRoutes.login:
      return MaterialPageRoute(builder: (_) => const LoginScreen());

    case AppRoutes.register:
      return MaterialPageRoute(builder: (_) => const RegisterScreen());

    case AppRoutes.forgot:
      return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());

    case AppRoutes.otp:
      return MaterialPageRoute(builder: (_) => const OtpScreen());

    default:
      return MaterialPageRoute(builder: (_) => const SplashScreen());
  }
}