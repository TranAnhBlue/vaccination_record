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
    final hashed = HashUtil.hash(password);

    final model = await dao.login(phone, hashed);

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
    final userId = await dao.insert(
      UserModel(
        name: user.name,
        phone: user.phone,
        password: HashUtil.hash(user.password),
      ),
    );

    // Automatically create a default member for the new user
    try {
      final memberDao = MemberDao();
      await memberDao.insert(MemberModel(
        userId: userId,
        name: user.name,
        dob: "",
        gender: "",
        relationship: 'Chủ hộ',
      ));
    } catch (e) {
      debugPrint("Failed to create default member on registration: $e");
    }
  }

  @override
  Future<bool> isPhoneRegistered(String phone) async {
    return dao.existsByPhone(phone);
  }

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

    final oldHashed = HashUtil.hash(oldPassword);
    debugPrint("DEBUG_PASS: input_old=$oldPassword, hashed=$oldHashed, stored=${model.password}");
    if (model.password != oldHashed) return false;

    final newHashed = HashUtil.hash(newPassword);
    await dao.updatePassword(phone, newHashed);
    return true;
  }

  @override
  Future<bool> updateProfile(String phone, String name, String dob, String gender) async {
    await dao.updateProfile(phone, name, dob, gender);
    return true;
  }
}