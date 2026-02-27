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

  Future<void> update(VaccinationRecord record) async {
    await repo.updateRecord(record);
    await load();
  }

  Future<void> delete(int id) async {
    await repo.deleteRecord(id);
    await load();
  }

  List<VaccinationRecord> get filteredRecords {
    // Basic filtering logic based on dates
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return records.where((r) {
      if (r.reminderDate.isEmpty) return true; // Default if no reminder

      final reminder = DateTime.tryParse(r.reminderDate);
      if (reminder == null) return true;

      // This logic will be refined in the UI
      return true; 
    }).toList();
  }
}