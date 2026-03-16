import 'package:flutter/material.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/auth/forgot_password_screen.dart';
import '../../presentation/screens/auth/otp_screen.dart';
import '../../presentation/screens/auth/splash_screen.dart';
import '../../presentation/screens/home_screen.dart';
import '../../presentation/screens/vaccination_detail_screen.dart';
import '../../presentation/screens/reminder_screen.dart';
import '../../presentation/screens/profile_screen.dart';
import '../../presentation/screens/ai/ai_screen.dart';
import '../../presentation/screens/change_password_screen.dart';
import '../../presentation/screens/family/add_member_screen.dart';
import '../../presentation/screens/family/edit_member_screen.dart';
import '../../presentation/screens/knowledge/knowledge_base_screen.dart';
import '../../domain/entities/vaccination_record.dart';
import '../../domain/entities/member.dart';
import 'app_routes.dart';

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case AppRoutes.ai:
      return MaterialPageRoute(builder: (_) => const AIScreen());

    case AppRoutes.login:
      return MaterialPageRoute(builder: (_) => const LoginScreen());

    case AppRoutes.register:
      return MaterialPageRoute(builder: (_) => const RegisterScreen());

    case AppRoutes.home:
      return MaterialPageRoute(builder: (_) => const HomeScreen());

    case AppRoutes.detail:
      final record = settings.arguments as VaccinationRecord;
      return MaterialPageRoute(builder: (_) => VaccinationDetailScreen(initialRecord: record));

    case AppRoutes.forgot:
      return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());

    case AppRoutes.otp:
      return MaterialPageRoute(builder: (_) => const OtpScreen());

    case AppRoutes.reminders:
      return MaterialPageRoute(builder: (_) => const ReminderScreen());

    case AppRoutes.profile:
      return MaterialPageRoute(builder: (_) => const ProfileScreen());

    case AppRoutes.changePassword:
      return MaterialPageRoute(builder: (_) => const ChangePasswordScreen());
      
    case AppRoutes.addMember:
      return MaterialPageRoute(builder: (_) => const AddMemberScreen());
      
    case AppRoutes.editMember:
      final member = settings.arguments as Member;
      return MaterialPageRoute(builder: (_) => EditMemberScreen(member: member));

    case AppRoutes.knowledge:
      return MaterialPageRoute(builder: (_) => const KnowledgeBaseScreen());

    default:
      return MaterialPageRoute(builder: (_) => const SplashScreen());
  }
}