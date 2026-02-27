import 'package:flutter/material.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/user.dart';
import '../../core/constants/session_manager.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository repo;

  AuthViewModel(this.repo);

  bool loading = false;
  String? error;

  Future<bool> login(String phone, String password) async {
    loading = true;
    error = null;
    notifyListeners();

    final user = await repo.login(phone, password);

    loading = false;

    if (user == null) {
      error = "Sai tài khoản hoặc mật khẩu";
      notifyListeners();
      return false;
    }

    await SessionManager.saveLogin();
    notifyListeners();
    return true;
  }

  Future<void> register(
      String name, String phone, String password) async {
    await repo.register(
      User(name: name, phone: phone, password: password),
    );
  }
}