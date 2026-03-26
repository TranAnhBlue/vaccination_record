import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/user.dart';
import '../../core/constants/session_manager.dart';
import '../../core/utils/error_message_util.dart';

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

    try {
      final user = await repo.login(phone, password);
      loading = false;

      if (user == null) {
        error =
            'Sai số điện thoại hoặc mật khẩu — không tìm thấy tài khoản hoặc mật khẩu không đúng.';
        notifyListeners();
        return false;
      }

      currentUser = user;
      await SessionManager.saveLogin(phone);
      notifyListeners();
      return true;
    } catch (e, stack) {
      debugPrint('LOGIN_ERROR: $e\n$stack');
      loading = false;
      error =
          'Đăng nhập không thành công. Nguyên nhân: ${readableTechnicalCause(e)}';
      notifyListeners();
      return false;
    }
  }

  Future<void> loadUser() async {
    final phone = await SessionManager.getPhone();
    if (phone != null) {
      currentUser = await repo.getUserDetails(phone);
      notifyListeners();
    }
  }

  Future<bool> register(
    String name,
    String phone,
    String password, {
    String dob = '',
    String gender = '',
  }) async {
    if (name.isEmpty || phone.isEmpty || password.isEmpty) {
      error = 'Vui lòng nhập đầy đủ thông tin';
      notifyListeners();
      return false;
    }

    loading = true;
    error = null;
    notifyListeners();

    try {
      final exists = await repo.isPhoneRegistered(phone);
      if (exists) {
        loading = false;
        error = 'Số điện thoại này đã được đăng ký';
        notifyListeners();
        return false;
      }

      await repo.register(
        User(name: name, phone: phone, password: password, dob: dob, gender: gender),
      );

      loading = false;
      notifyListeners();
      return true;
    } catch (e, stack) {
      debugPrint('REGISTRATION_ERROR: $e\n$stack');
      loading = false;
      error = _registerFailureMessage(e);
      notifyListeners();
      return false;
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
      if (!success) error = 'Mật khẩu cũ không chính xác';
      notifyListeners();
      return success;
    } catch (e, stack) {
      debugPrint('CHANGE_PASSWORD_ERROR: $e\n$stack');
      loading = false;
      error =
          'Đổi mật khẩu không thành công. Nguyên nhân: ${readableTechnicalCause(e)}';
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
      await loadUser();
      loading = false;
      notifyListeners();
      return true;
    } catch (e, stack) {
      debugPrint('UPDATE_PROFILE_ERROR: $e\n$stack');
      loading = false;
      error =
          'Cập nhật hồ sơ không thành công. Nguyên nhân: ${readableTechnicalCause(e)}';
      notifyListeners();
      return false;
    }
  }

  void logout() {
    currentUser = null;
    SessionManager.clearLogin();
    notifyListeners();
  }

  /// Gom toàn bộ chuỗi lỗi có thể có trên Android/iOS/FFI — đôi khi không phải [DatabaseException] rõ ràng.
  static String _flattenErrorText(Object e) {
    final parts = <String>[e.toString()];
    if (e is PlatformException) {
      if (e.message != null) parts.add(e.message!);
      if (e.details != null) parts.add(e.details.toString());
    }
    return parts.join(' ').toLowerCase();
  }

  /// Trùng SĐT: SQLite / plugin có nhiều biến thể thông điệp (kể cả [PlatformException] chưa bọc).
  static bool _isDuplicatePhoneDbText(String lower) {
    if (lower.contains('sqlite_constraint_unique')) return true;
    if (lower.contains('constraint_unique')) return true;
    if (RegExp(r'\b2067\b').hasMatch(lower)) return true;
    if (lower.contains('unique') &&
        lower.contains('constraint') &&
        (lower.contains('phone') || lower.contains('users'))) {
      return true;
    }
    return false;
  }

  static String _registerFailureMessage(Object e) {
    final lower = _flattenErrorText(e);

    if (_isDuplicatePhoneDbText(lower)) {
      return 'Số điện thoại này đã được đăng ký';
    }

    if (e is DatabaseException) {
      final dex = e;
      if (dex.isUniqueConstraintError()) {
        return 'Số điện thoại này đã được đăng ký';
      }
      int? code;
      try {
        code = dex.getResultCode();
      } catch (_) {}
      if (code == 2067) {
        return 'Số điện thoại này đã được đăng ký';
      }
      if (dex.isNotNullConstraintError()) {
        return 'Thiếu thông tin bắt buộc. Vui lòng kiểm tra lại biểu mẫu.';
      }
    }

    if (lower.contains('foreign key')) {
      return 'Lỗi cơ sở dữ liệu cục bộ. Hãy đóng app và thử lại, hoặc xóa dữ liệu ứng dụng.';
    }
    if (lower.contains('readonly') || lower.contains('open_failed')) {
      return 'Không ghi được dữ liệu cục bộ. Kiểm tra dung lượng và quyền lưu trữ.';
    }
    if (lower.contains('database is locked') || lower.contains('sqlite_busy')) {
      return 'Cơ sở dữ liệu đang bận. Vui lòng thử lại sau vài giây.';
    }

    return 'Đăng ký không thành công. Nguyên nhân: ${readableTechnicalCause(e)}';
  }
}
