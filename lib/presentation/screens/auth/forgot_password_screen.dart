import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          "Quên mật khẩu",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Lock Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_reset_rounded,
                size: 60,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              "Quên mật khẩu?",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Vui lòng nhập số điện thoại đã đăng ký để bắt đầu quá trình khôi phục tài khoản tiêm chủng của bạn.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF828282),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),

            // Phone Field
            _buildFieldLabel("Số điện thoại"),
            const TextField(
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: "Nhập số điện thoại của bạn",
              ),
            ),
            const SizedBox(height: 24),

            // Note
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info, color: AppTheme.primary, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Chúng tôi sẽ gửi mã OTP để khôi phục mật khẩu.",
                    style: TextStyle(fontSize: 13, color: Colors.blue.shade700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 48),

            // Send Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.otp),
                child: const Text("Gửi mã"),
              ),
            ),

            const SizedBox(height: 40),
            // Help Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Bạn cần trợ giúp? ", style: TextStyle(color: Color(0xFF828282))),
                GestureDetector(
                  onTap: () {},
                  child: const Text(
                    "Liên hệ tổng đài",
                    style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
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