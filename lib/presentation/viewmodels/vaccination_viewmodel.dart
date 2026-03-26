import 'package:flutter/material.dart';
import '../../domain/entities/vaccination_record.dart';
import '../../data/repositories/vaccination_repository_impl.dart';
import '../../data/services/notification_service.dart';

class VaccinationViewModel extends ChangeNotifier {
  final repo = VaccinationRepositoryImpl();

  List<VaccinationRecord> records = [];
  // Cache: memberId → records (cho suggestions screen)
  final Map<int, List<VaccinationRecord>> _cache = {};
  bool isLoading = false;

  Future<void> load({int? memberId}) async {
    isLoading = true;
    notifyListeners();
    records = await repo.getRecords(memberId: memberId);
    if (memberId != null) {
      _cache[memberId] = List.from(records);
    }
    isLoading = false;
    notifyListeners();
  }

  /// Load tất cả records của 1 user (qua danh sách memberIds)
  Future<void> loadAllForMembers(List<int> memberIds) async {
    for (final id in memberIds) {
      final list = await repo.getRecords(memberId: id);
      _cache[id] = list;
    }
    notifyListeners();
  }

  Future<void> syncAfterHouseholdChanged({
    required List<int> memberIds,
    int? preferredMemberId,
  }) async {
    _cache.removeWhere((id, _) => !memberIds.contains(id));
    if (memberIds.isEmpty) {
      records = [];
      notifyListeners();
      return;
    }
    await loadAllForMembers(memberIds);
    final target = preferredMemberId != null && memberIds.contains(preferredMemberId)
        ? preferredMemberId
        : memberIds.first;
    await load(memberId: target);
  }

  /// Lấy records của 1 member (từ cache hoặc load mới)
  List<VaccinationRecord> recordsForMember(int memberId) {
    return _cache[memberId] ?? [];
  }

  Future<void> add(VaccinationRecord record) async {
    try {
      final id = await repo.addRecord(record);
      final newRecord = record.copyWith(id: id);
      await NotificationService().scheduleVaccinationReminder(newRecord);
      await load(memberId: record.memberId);
      // Cập nhật cache
      if (record.memberId != null) {
        _cache[record.memberId!] = List.from(records);
      }
    } catch (e) {
      debugPrint('Error adding record: $e');
      rethrow;
    }
  }

  Future<void> update(VaccinationRecord record) async {
    await repo.updateRecord(record);
    await NotificationService().scheduleVaccinationReminder(record);
    await load(memberId: record.memberId);
    if (record.memberId != null) {
      _cache[record.memberId!] = List.from(records);
    }
  }

  Future<void> delete(int id, {int? memberId}) async {
    await repo.deleteRecord(id);
    await NotificationService().cancelReminder(id);
    await load(memberId: memberId);
    if (memberId != null) {
      _cache[memberId] = List.from(records);
    }
  }
}
