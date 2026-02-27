import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
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
          "Xác thực OTP",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Shield Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified_user_rounded,
                size: 60,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              "Nhập mã xác thực",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Vui lòng nhập mã OTP đã được gửi đến :",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF828282),
              ),
            ),
            const SizedBox(height: 48),

            // OTP Input
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                6,
                (index) => Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.shade300,
                        width: 2,
                      ),
                    ),
                  ),
                  child: const TextField(
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    decoration: InputDecoration(
                      counterText: "",
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      fillColor: Colors.transparent,
                    ),
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Timer
            const Text(
              "Bạn chưa nhận được mã?",
              style: TextStyle(fontSize: 13, color: Color(0xFF828282)),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTimeUnit("01", "Phút"),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(":", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                ),
                _buildTimeUnit("59", "Giây"),
              ],
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {},
              child: const Text(
                "Gửi lại mã ngay",
                style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 40),

            // Confirm Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {},
                child: const Text("Xác nhận"),
              ),
            ),

            const SizedBox(height: 40),
            // Footer
            Column(
              children: [
                const Icon(Icons.add_moderator, color: Color(0xFF333333)),
                const SizedBox(height: 8),
                const Text(
                  "Hệ thống quản lý tiêm chủng quốc gia",
                  style: TextStyle(fontSize: 11, color: Color(0xFF828282)),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeUnit(String value, String unit) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
          ),
        ),
        const SizedBox(height: 4),
        Text(unit, style: const TextStyle(fontSize: 10, color: Color(0xFF828282))),
      ],
    );
  }
}