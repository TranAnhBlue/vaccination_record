import '../entities/user.dart';

abstract class AuthRepository {
  Future<User?> login(String phone, String password);
  Future<void> register(User user);
  Future<bool> isPhoneRegistered(String phone);
}