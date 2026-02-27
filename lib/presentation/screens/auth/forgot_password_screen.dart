import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Quên mật khẩu")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              "Nhập số điện thoại để nhận OTP",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),

            const TextField(
              decoration: InputDecoration(labelText: "Số điện thoại"),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.otp),
                child: const Text("Gửi mã"),
              ),
            )
          ],
        ),
      ),
    );
  }
}