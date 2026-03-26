import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../local/dao/user_dao.dart';
import '../local/database_helper.dart';
import '../models/user_model.dart';
import '../models/member_model.dart';
import '../../core/constants/hash_util.dart';
import '../../core/utils/phone_util.dart';

class AuthRepositoryImpl implements AuthRepository {
  final UserDao dao;
  AuthRepositoryImpl(this.dao);

  String _phone(String phone) => normalizeVietnamesePhone(phone);

  @override
  Future<User?> login(String phone, String password) async {
    final model = await dao.login(_phone(phone), HashUtil.hash(password));
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
    final u = User(
      name: user.name.trim(),
      phone: _phone(user.phone),
      password: user.password,
      dob: user.dob,
      gender: user.gender,
    );
    // Tạo dữ liệu gói trong transaction để tránh trường hợp tạo user nhưng tạo member mặc định thất bại.
    final db = await DatabaseHelper.instance.database;

    await db.transaction((txn) async {
      final userMap = UserModel(
        name: u.name,
        phone: u.phone,
        password: HashUtil.hash(u.password),
        dob: u.dob,
        gender: u.gender,
      ).toMap()
        ..remove('id');

      final userId = await txn.insert('users', userMap);

      final memberMap = MemberModel(
        userId: userId,
        name: u.name,
        dob: u.dob, // populate dob so suggestions work from day 1
        gender: u.gender,
        relationship: 'Chủ hộ',
      ).toMap()
        ..remove('id');

      await txn.insert('members', memberMap);
    });
  }

  @override
  Future<bool> isPhoneRegistered(String phone) => dao.existsByPhone(_phone(phone));

  @override
  Future<User?> getUserDetails(String phone) async {
    final model = await dao.getUserByPhone(_phone(phone));
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
    if (oldPassword.trim().isEmpty || newPassword.trim().isEmpty) return false;
    final model = await dao.getUserByPhone(_phone(phone));
    if (model == null) return false;
    if (model.password != HashUtil.hash(oldPassword)) return false;
    await dao.updatePassword(_phone(phone), HashUtil.hash(newPassword));
    return true;
  }

  @override
  Future<bool> updateProfile(String phone, String name, String dob, String gender) async {
    if (name.trim().isEmpty) return false;
    if (dob.trim().isNotEmpty && DateTime.tryParse(dob) == null) return false;
    await dao.updateProfile(_phone(phone), name, dob, gender);
    return true;
  }
}
