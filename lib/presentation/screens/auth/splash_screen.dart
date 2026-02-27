import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/routes/app_routes.dart';
import '../../../core/constants/session_manager.dart';
import '../../../core/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _progress = 0.0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startLoading();
  }

  void _startLoading() {
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      setState(() {
        if (_progress < 1.0) {
          _progress += 0.02;
        } else {
          _timer?.cancel();
          _checkSession();
        }
      });
    });
  }

  Future<void> _checkSession() async {
    final logged = await SessionManager.isLoggedIn();
    if (!mounted) return;

    if (logged) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background accent circle
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo Container
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.vaccines,
                      size: 60,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  "Sổ tiêm chủng cá\nnhân",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "An toàn • Minh bạch • Kịp thời",
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF828282),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 60),
                // Loading Indicator Text
                const Text(
                  "Đang khởi tạo ứng dụng...",
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF828282),
                  ),
                ),
                const SizedBox(height: 12),
                // Progress Bar
                SizedBox(
                  width: 200,
                  height: 4,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: _progress,
                      backgroundColor: const Color(0xFFE0E0E0),
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Footer
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                const Text(
                  "Cung cấp bởi",
                  style: TextStyle(fontSize: 10, color: Color(0xFF828282)),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.health_and_safety,
                        color: AppTheme.primary, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      "Health Connect",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}