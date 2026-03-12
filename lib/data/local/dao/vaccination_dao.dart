import '../database_helper.dart';
import '../../models/vaccination_record_model.dart';

class VaccinationDao {
  Future<int> insert(VaccinationRecordModel record) async {
    final db = await DatabaseHelper.instance.database;
    return db.insert('vaccination_records', record.toMap());
  }

  Future<List<VaccinationRecordModel>> getAllByMember(int? memberId) async {
    final db = await DatabaseHelper.instance.database;

    final result = await db.query(
      'vaccination_records',
      where: memberId != null ? 'memberId = ?' : null,
      whereArgs: memberId != null ? [memberId] : null,
      orderBy: 'date DESC',
    );

    return result.map((e) => VaccinationRecordModel.fromMap(e)).toList();
  }

  Future<void> update(VaccinationRecordModel record) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'vaccination_records',
      record.toMap(),
      where: 'id=?',
      whereArgs: [record.id],
    );
  }

  Future<void> delete(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(
      'vaccination_records',
      where: 'id=?',
      whereArgs: [id],
    );
  }
}