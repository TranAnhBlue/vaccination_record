import 'package:flutter/material.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/user.dart';
import '../../core/constants/session_manager.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository repo;

  AuthViewModel(this.repo);

  bool loading = false;
  String? error;

  void clearError() {
    error = null;
    notifyListeners();
  }

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

  Future<bool> register(
      String name, String phone, String password) async {
    if (name.isEmpty || phone.isEmpty || password.isEmpty) {
      error = "Vui lòng nhập đầy đủ thông tin";
      notifyListeners();
      return false;
    }

    loading = true;
    error = null;
    notifyListeners();

    try {
      // 1. Check if phone exists explicitly first
      final exists = await repo.isPhoneRegistered(phone);
      if (exists) {
        loading = false;
        error = "Số điện thoại này đã được đăng ký";
        notifyListeners();
        return false;
      }

      // 2. Perform registration
      await repo.register(
        User(name: name, phone: phone, password: password),
      );
      
      loading = false;
      notifyListeners();
      return true;
    } catch (e, stack) {
      debugPrint("REGISTRATION_ERROR: $e");
      debugPrint("STACKTRACE: $stack");
      loading = false;
      error = "Đăng ký thất bại. Lỗi: ${e.toString().split(':').last.trim()}";
      notifyListeners();
      return false;
    }
  }
}