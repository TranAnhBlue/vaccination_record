import 'package:flutter/cupertino.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../local/dao/user_dao.dart';
import '../local/dao/member_dao.dart';
import '../models/user_model.dart';
import '../models/member_model.dart';
import '../../core/constants/hash_util.dart';

class AuthRepositoryImpl implements AuthRepository {
  final UserDao dao;
  AuthRepositoryImpl(this.dao);

  @override
  Future<User?> login(String phone, String password) async {
    final model = await dao.login(phone, HashUtil.hash(password));
    if (model == null) return null;
    return User(
      id: model.id,
      name: model.name,
      phone: model.phone,
      password: model.password,
      dob: model.dob,
      gender: model.gender,
    );
  }

  @override
  Future<void> register(User user) async {
    // 1. Insert user with dob & gender
    final userId = await dao.insert(
      UserModel(
        name: user.name,
        phone: user.phone,
        password: HashUtil.hash(user.password),
        dob: user.dob,
        gender: user.gender,
      ),
    );

    // 2. Auto-create "Chủ hộ" member — populate dob & gender immediately
    try {
      final memberDao = MemberDao();
      await memberDao.insert(MemberModel(
        userId: userId,
        name: user.name,
        dob: user.dob,       // ← pass actual dob so suggestions work from day 1
        gender: user.gender, // ← pass actual gender
        relationship: 'Chủ hộ',
      ));
    } catch (e) {
      debugPrint('Failed to create default member: $e');
    }
  }

  @override
  Future<bool> isPhoneRegistered(String phone) => dao.existsByPhone(phone);

  @override
  Future<User?> getUserDetails(String phone) async {
    final model = await dao.getUserByPhone(phone);
    if (model == null) return null;
    return User(
      id: model.id,
      name: model.name,
      phone: model.phone,
      password: model.password,
      dob: model.dob,
      gender: model.gender,
    );
  }

  @override
  Future<bool> changePassword(String phone, String oldPassword, String newPassword) async {
    final model = await dao.getUserByPhone(phone);
    if (model == null) return false;
    if (model.password != HashUtil.hash(oldPassword)) return false;
    await dao.updatePassword(phone, HashUtil.hash(newPassword));
    return true;
  }

  @override
  Future<bool> updateProfile(String phone, String name, String dob, String gender) async {
    await dao.updateProfile(phone, name, dob, gender);
    return true;
  }
}
