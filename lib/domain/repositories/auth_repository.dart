import '../entities/user.dart';

abstract class AuthRepository {
  Future<User?> login(String phone, String password);
  Future<void> register(User user);
  Future<bool> isPhoneRegistered(String phone);
  Future<User?> getUserDetails(String phone);
  Future<bool> changePassword(String phone, String oldPassword, String newPassword);
  Future<bool> updateProfile(String phone, String name, String dob, String gender);
}