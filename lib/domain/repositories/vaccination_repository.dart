import '../entities/vaccination_record.dart';

abstract class VaccinationRepository {
  Future<List<VaccinationRecord>> getRecords({int? memberId});
  Future<int> addRecord(VaccinationRecord record);
  Future<void> updateRecord(VaccinationRecord record);
  Future<void> deleteRecord(int id);
}