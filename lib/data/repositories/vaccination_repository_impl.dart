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
        location: record.location,
        note: record.note,
      ),
    );
  }

  @override
  Future<List<VaccinationRecord>> getRecords() {
    return dao.getAll();
  }

  @override
  Future<void> deleteRecord(int id) {
    return dao.delete(id);
  }
}