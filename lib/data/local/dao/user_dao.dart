import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../../models/user_model.dart';

class UserDao {
  Future<int> insert(UserModel user) async {
    final db = await DatabaseHelper.instance.database;
    return db.insert("users", user.toMap());
  }

  Future<UserModel?> login(
      String phone, String password) async {

    final db = await DatabaseHelper.instance.database;

    final result = await db.query(
      "users",
      where: "phone=? AND password=?",
      whereArgs: [phone, password],
    );

    if (result.isEmpty) return null;

    return UserModel.fromMap(result.first);
  }

  Future<bool> existsByPhone(String phone) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      "users",
      where: "phone=?",
      whereArgs: [phone],
    );
    return result.isNotEmpty;
  }
}