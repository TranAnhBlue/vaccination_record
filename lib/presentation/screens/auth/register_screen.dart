import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {

  final name = TextEditingController();
  final phone = TextEditingController();
  final password = TextEditingController();
  final confirm = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final vm = context.read<AuthViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text("Đăng ký")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: "Họ tên"),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: phone,
              decoration: const InputDecoration(labelText: "Số điện thoại"),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: password,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Mật khẩu"),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: confirm,
              obscureText: true,
              decoration:
              const InputDecoration(labelText: "Xác nhận mật khẩu"),
            ),

            const SizedBox(height: 25),

            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: () async {

                  if (password.text != confirm.text) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Mật khẩu không khớp")),
                    );
                    return;
                  }

                  await vm.register(
                    name.text,
                    phone.text,
                    password.text,
                  );

                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
                child: const Text("Đăng ký"),
              ),
            )
          ],
        ),
      ),
    );
  }
}