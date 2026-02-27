import 'package:flutter/material.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/user.dart';
import '../../core/constants/session_manager.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository repo;

  AuthViewModel(this.repo);

  bool loading = false;
  String? error;
  User? currentUser;

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

    currentUser = user;
    await SessionManager.saveLogin(phone);
    notifyListeners();
    return true;
  }

  Future<void> loadUser() async {
    final phone = await SessionManager.getPhone();
    if (phone != null) {
      currentUser = await repo.getUserDetails(phone);
      notifyListeners();
    }
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    if (currentUser == null) return false;
    
    loading = true;
    error = null;
    notifyListeners();

    try {
      final success = await repo.changePassword(currentUser!.phone, oldPassword, newPassword);
      loading = false;
      if (!success) {
        error = "Mật khẩu cũ không chính xác";
      }
      notifyListeners();
      return success;
    } catch (e) {
      loading = false;
      error = "Lỗi khi đổi mật khẩu";
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile(String name, String dob, String gender) async {
    if (currentUser == null) return false;
    
    loading = true;
    error = null;
    notifyListeners();

    try {
      await repo.updateProfile(currentUser!.phone, name, dob, gender);
      await loadUser(); // Refresh local state
      loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      loading = false;
      error = "Lỗi khi cập nhật hồ sơ";
      notifyListeners();
      return false;
    }
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