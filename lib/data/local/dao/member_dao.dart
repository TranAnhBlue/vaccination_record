import '../database_helper.dart';
import '../../models/member_model.dart';

class MemberDao {
  Future<int> insert(MemberModel member) async {
    final db = await DatabaseHelper.instance.database;
    return db.insert('members', member.toMap());
  }

  Future<List<MemberModel>> getAllForUser(int userId) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      'members',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'relationship DESC, name ASC',
    );
    return result.map((e) => MemberModel.fromMap(e)).toList();
  }

  Future<int> update(MemberModel member) async {
    final db = await DatabaseHelper.instance.database;
    return db.update(
      'members',
      member.toMap(),
      where: 'id = ?',
      whereArgs: [member.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await DatabaseHelper.instance.database;
    return db.delete(
      'members',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
