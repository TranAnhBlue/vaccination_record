import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/routes/app_routes.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../core/theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Đăng nhập",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            // Logo
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.vaccines,
                size: 60,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Sổ tiêm chủng cá nhân",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Bảo vệ sức khỏe cộng đồng",
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF828282),
              ),
            ),
            const SizedBox(height: 40),

            // Phone Field
            _buildFieldLabel("Số điện thoại"),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: "Nhập số điện thoại",
              ),
            ),
            const SizedBox(height: 20),

            // Password Field
            _buildFieldLabel("Mật khẩu"),
            TextField(
              controller: passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                hintText: "Nhập mật khẩu",
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),

            // Forgot Password
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.forgot),
                child: const Text(
                  "Quên mật khẩu?",
                  style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            if (vm.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(vm.error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
              ),

            // Login Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: vm.loading
                    ? null
                    : () async {
                        final success = await vm.login(
                          phoneController.text,
                          passwordController.text,
                        );
                        if (success && context.mounted) {
                          Navigator.pushReplacementNamed(context, AppRoutes.home);
                        }
                      },
                child: vm.loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text("Đăng nhập"),
              ),
            ),

            const SizedBox(height: 24),
            // Social Login Divider
            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey.shade300)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    "Hoặc đăng nhập bằng",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ),
                Expanded(child: Divider(color: Colors.grey.shade300)),
              ],
            ),
            const SizedBox(height: 24),

            // Fingerprint icon
            GestureDetector(
              onTap: () {
                // Biometric auth placeholder
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Tính năng sinh trắc học đang phát triển")),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Icon(Icons.fingerprint, size: 40, color: Color(0xFF4F4F4F)),
              ),
            ),

            const SizedBox(height: 40),
            // Register Link
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Chưa có tài khoản? ", style: TextStyle(color: Color(0xFF828282))),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, AppRoutes.register),
                  child: const Text(
                    "Đăng ký ngay",
                    style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 4),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF333333)),
        ),
      ),
    );
  }
}