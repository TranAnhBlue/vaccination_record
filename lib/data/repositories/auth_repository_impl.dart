import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../local/dao/user_dao.dart';
import '../models/user_model.dart';
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
      name: model.name,
      phone: model.phone,
      password: model.password,
    );
  }

  @override
  Future<void> register(User user) async {
    await dao.insert(
      UserModel(
        name: user.name,
        phone: user.phone,
        password: HashUtil.hash(user.password),
      ),
    );
  }
}