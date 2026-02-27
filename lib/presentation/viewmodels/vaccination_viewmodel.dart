import 'package:flutter/material.dart';
import '../../domain/entities/vaccination_record.dart';
import '../../data/repositories/vaccination_repository_impl.dart';

class VaccinationViewModel extends ChangeNotifier {
  final repo = VaccinationRepositoryImpl();

  List<VaccinationRecord> records = [];

  Future<void> load() async {
    records = await repo.getRecords();
    notifyListeners();
  }

  Future<void> add(VaccinationRecord record) async {
    await repo.addRecord(record);
    await load();
  }

  Future<void> delete(int id) async {
    await repo.deleteRecord(id);
    await load();
  }
}