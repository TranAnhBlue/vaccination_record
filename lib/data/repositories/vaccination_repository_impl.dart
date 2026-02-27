import '../../domain/entities/vaccination_record.dart';
import '../../domain/repositories/vaccination_repository.dart';
import '../local/dao/vaccination_dao.dart';
import '../models/vaccination_record_model.dart';

class VaccinationRepositoryImpl implements VaccinationRepository {
  final dao = VaccinationDao();

  @override
  Future<void> addRecord(VaccinationRecord record) async {
    await dao.insert(
      VaccinationRecordModel(
        vaccineName: record.vaccineName,
        dose: record.dose,
        date: record.date,
        reminderDate: record.reminderDate,
        imagePath: record.imagePath,
        location: record.location,
        note: record.note,
      ),
    );
  }

  @override
  Future<void> updateRecord(VaccinationRecord record) async {
    await dao.update(
      VaccinationRecordModel(
        id: record.id,
        vaccineName: record.vaccineName,
        dose: record.dose,
        date: record.date,
        reminderDate: record.reminderDate,
        imagePath: record.imagePath,
        location: record.location,
        note: record.note,
      ),
    );
  }

  @override
  Future<List<VaccinationRecord>> getRecords() async {
    final models = await dao.getAll();
    return models.map((e) => e as VaccinationRecord).toList();
  }

  @override
  Future<void> deleteRecord(int id) {
    return dao.delete(id);
  }
}