import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/vaccination_record.dart';
import '../../data/repositories/vaccination_repository_impl.dart';

class VaccinationViewModel extends ChangeNotifier {
  final repo = VaccinationRepositoryImpl();

  List<VaccinationRecord> records = [];

  Future<void> load() async {
    records = await repo.getRecords();
    if (records.length < 3) { // Ensure at least 3 for demo
      await seedDemoData();
      records = await repo.getRecords();
    }
    notifyListeners();
  }

  Future<void> seedDemoData() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final samples = [
      VaccinationRecord(
        vaccineName: "Vắc xin 6 trong 1 (Hexaxim)",
        dose: 1,
        date: DateFormat('yyyy-MM-dd').format(today.subtract(const Duration(days: 30))),
        reminderDate: DateFormat('yyyy-MM-dd').format(today.add(const Duration(days: 1))),
        location: "VNVC Đà Nẵng",
        note: "Tiêm nhắc lại đúng hạn",
      ),
      VaccinationRecord(
        vaccineName: "Vắc xin Phế cầu (Prevenar 13)",
        dose: 1,
        date: DateFormat('yyyy-MM-dd').format(today.subtract(const Duration(days: 60))),
        reminderDate: DateFormat('yyyy-MM-dd').format(today.add(const Duration(days: 8))),
        location: "Trung tâm Y tế Quận 1",
        note: "Theo dõi phản ứng nhẹ",
      ),
      VaccinationRecord(
        vaccineName: "Vắc xin Cúm (Vaxigrip Tetra)",
        dose: 1,
        date: DateFormat('yyyy-MM-dd').format(today.subtract(const Duration(days: 365))),
        reminderDate: DateFormat('yyyy-MM-dd').format(today.subtract(const Duration(days: 5))), // This will be Overdue
        location: "Trạm y tế Phường",
        note: "Nên tiêm nhắc hàng năm",
      ),
    ];

    for (var r in samples) {
      await repo.addRecord(r);
    }
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