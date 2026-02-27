import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/routes/app_routes.dart';
import '../../viewmodels/auth_viewmodel.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  final phoneController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text("Đăng nhập")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.vaccines, size: 60),
            const SizedBox(height: 20),

            const Text(
              "Sổ tiêm chủng cá nhân",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 30),

            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: "Số điện thoại",
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Mật khẩu",
              ),
            ),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.forgot),
                child: const Text("Quên mật khẩu?"),
              ),
            ),

            if (vm.error != null)
              Text(vm.error!,
                  style: const TextStyle(color: Colors.red)),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: vm.loading
                    ? null
                    : () async {
                  final success = await vm.login(
                    phoneController.text,
                    passwordController.text,
                  );

                  if (success && context.mounted) {
                    Navigator.pushReplacementNamed(
                        context, AppRoutes.home);
                  }
                },
                child: vm.loading
                    ? const CircularProgressIndicator()
                    : const Text("Đăng nhập"),
              ),
            ),

            const Spacer(),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Chưa có tài khoản? "),
                GestureDetector(
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.register),
                  child: const Text(
                    "Đăng ký ngay",
                    style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}