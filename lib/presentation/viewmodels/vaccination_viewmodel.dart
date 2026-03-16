import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/vaccination_record.dart';
import '../../data/repositories/vaccination_repository_impl.dart';
import '../../data/services/notification_service.dart';

class VaccinationViewModel extends ChangeNotifier {
  final repo = VaccinationRepositoryImpl();

  List<VaccinationRecord> records = [];

  Future<void> load({int? memberId}) async {
    records = await repo.getRecords(memberId: memberId);
    if (records.isEmpty && memberId != null) { 
      // check if this is the first time loading for this member
      // we could check a flag, but for now let's just seed if empty for any member initially
      // await seedDemoData(memberId);
      // records = await repo.getRecords(memberId: memberId);
    }
    notifyListeners();
  }

  Future<void> seedDemoData(int memberId) async {
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
        memberId: memberId,
      ),
      VaccinationRecord(
        vaccineName: "Vắc xin Phế cầu (Prevenar 13)",
        dose: 1,
        date: DateFormat('yyyy-MM-dd').format(today.subtract(const Duration(days: 60))),
        reminderDate: DateFormat('yyyy-MM-dd').format(today.add(const Duration(days: 8))),
        location: "Trung tâm Y tế Quận 1",
        note: "Theo dõi phản ứng nhẹ",
        memberId: memberId,
      ),
      VaccinationRecord(
        vaccineName: "Vắc xin Cúm (Vaxigrip Tetra)",
        dose: 1,
        date: DateFormat('yyyy-MM-dd').format(today.subtract(const Duration(days: 365))),
        reminderDate: DateFormat('yyyy-MM-dd').format(today.subtract(const Duration(days: 5))), // This will be Overdue
        location: "Trạm y tế Phường",
        note: "Nên tiêm nhắc hàng năm",
        memberId: memberId,
      ),
    ];

    for (var r in samples) {
      await repo.addRecord(r);
    }
  }

  Future<void> add(VaccinationRecord record) async {
    try {
      final id = await repo.addRecord(record);
      final newRecord = record.copyWith(id: id);
      await NotificationService().scheduleVaccinationReminder(newRecord);
      await load(memberId: record.memberId);
    } catch (e) {
      debugPrint("Error adding record: $e");
      rethrow;
    }
  }

  Future<void> update(VaccinationRecord record) async {
    await repo.updateRecord(record);
    await NotificationService().scheduleVaccinationReminder(record);
    await load(memberId: record.memberId);
  }

  Future<void> delete(int id, {int? memberId}) async {
    await repo.deleteRecord(id);
    await NotificationService().cancelReminder(id);
    await load(memberId: memberId);
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