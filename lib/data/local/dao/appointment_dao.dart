import '../database_helper.dart';
import '../../models/appointment_model.dart';

class AppointmentDao {
  Future<int> insert(AppointmentModel appointment) async {
    final db = await DatabaseHelper.instance.database;
    final map = appointment.toMap()..remove('id');
    return db.insert('appointments', map);
  }

  Future<List<AppointmentModel>> getByMember(int memberId) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      'appointments',
      where: 'memberId = ?',
      whereArgs: [memberId],
      orderBy: 'appointmentDate ASC, appointmentTime ASC',
    );
    return result.map((m) => AppointmentModel.fromMap(m)).toList();
  }

  Future<List<AppointmentModel>> getByUserId(int userId) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery('''
      SELECT a.* FROM appointments a
      INNER JOIN members m ON a.memberId = m.id
      WHERE m.userId = ?
      ORDER BY a.appointmentDate ASC, a.appointmentTime ASC
    ''', [userId]);
    return result.map((m) => AppointmentModel.fromMap(m)).toList();
  }

  Future<int> update(AppointmentModel appointment) async {
    final db = await DatabaseHelper.instance.database;
    return db.update(
      'appointments',
      appointment.toMap(),
      where: 'id = ?',
      whereArgs: [appointment.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await DatabaseHelper.instance.database;
    return db.delete('appointments', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateStatus(int id, String status) async {
    final db = await DatabaseHelper.instance.database;
    return db.update(
      'appointments',
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
