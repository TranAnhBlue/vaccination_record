import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/appointment_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/household_viewmodel.dart';
import '../viewmodels/vaccination_viewmodel.dart';
import '../../domain/entities/vaccination_record.dart';
import '../../data/repositories/vaccination_repository_impl.dart';
import '../../data/services/notification_service.dart';

/// Đồng bộ lịch hẹn + toàn bộ cache lịch sử tiêm theo hộ hiện tại.
/// Gọi sau khi: đặt/hủy/hoàn thành lịch, thêm/sửa/xóa mũi tiêm, đánh dấu từ gợi ý, v.v.
///
/// Cần [HouseholdViewModel.loadMembers] đã chạy (có [HouseholdViewModel.members])
/// trước khi gọi, trừ khi chỉ cần tải lại lịch hẹn theo user.
Future<void> syncUserMedicalData(BuildContext context) async {
  final auth = context.read<AuthViewModel>();
  final uid = auth.currentUser?.id;
  if (uid == null) return;

  final h = context.read<HouseholdViewModel>();
  final vac = context.read<VaccinationViewModel>();
  final appt = context.read<AppointmentViewModel>();

  await appt.load(userId: uid);
  if (!context.mounted) return;

  final memberIds = h.members.map((m) => m.id!).toList();
  await vac.syncAfterHouseholdChanged(
    memberIds: memberIds,
    preferredMemberId: h.selectedMember?.id,
  );

  // Nếu một lịch hẹn pending còn trong vòng 7 ngày,
  // đưa nó vào `vaccination_records` (isCompleted=false) để hiển thị trong "Lịch sử tiêm chủng".
  final changed = await _syncPendingAppointmentsIntoHistory(vac: vac, appt: appt);
  if (changed && context.mounted) {
    // Refresh cache/preferred view sau khi insert/delete trực tiếp qua Repository.
    await vac.syncAfterHouseholdChanged(
      memberIds: memberIds,
      preferredMemberId: h.selectedMember?.id,
    );
  }
}

String _normalizeVaccineLabel(String s) {
  return s.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
}

Future<bool> _syncPendingAppointmentsIntoHistory({
  required VaccinationViewModel vac,
  required AppointmentViewModel appt,
}) async {
  final now = DateTime.now();
  final todayNorm = DateTime(now.year, now.month, now.day);
  final weekEnd = todayNorm.add(const Duration(days: 7));

  // Dùng suffix trong note để phân biệt record tạo từ luồng "sắp tới"
  // với record do người dùng tự thêm.
  const pendingAutoNoteSuffix = ' (tự động pending)';

  final repo = VaccinationRepositoryImpl();
  final notification = NotificationService();
  var changed = false;

  // 1) Nếu lịch hẹn đã huỷ, xoá các record pending tự động tương ứng.
  final cancelled = appt.appointments.where((a) => a.status == 'cancelled');
  for (final a in cancelled) {
    final records = vac.recordsForMember(a.memberId);
    final norm = _normalizeVaccineLabel(a.vaccineName);

    final toDelete = records.where((r) {
      if (r.id == null) return false;
      if (r.isCompleted) return false;
      if (r.date != a.appointmentDate) return false;
      if (_normalizeVaccineLabel(r.vaccineName) != norm) return false;
      // Chỉ xoá record do luồng tự động tạo.
      if (!r.note.contains('Ghi nhận từ lịch hẹn #${a.id ?? "?"}')) {
        return false;
      }
      if (!r.note.contains(pendingAutoNoteSuffix)) return false;
      return true;
    }).toList();

    for (final r in toDelete) {
      await repo.deleteRecord(r.id!);
      await notification.cancelReminder(r.id!);
      changed = true;
    }
  }

  // 2) Tạo record isCompleted=false cho appointment pending trong vòng 7 ngày.
  final pending = appt.appointments.where((a) => a.status == 'pending');
  for (final a in pending) {
    final parsed = DateTime.tryParse(a.appointmentDate);
    if (parsed == null) continue;
    final day = DateTime(parsed.year, parsed.month, parsed.day);

    // "còn 1 tuần" => [today .. today+7]
    if (day.isBefore(todayNorm) || day.isAfter(weekEnd)) continue;

    final records = vac.recordsForMember(a.memberId);
    final norm = _normalizeVaccineLabel(a.vaccineName);

    final exists = records.any((r) {
      if (r.id == null) return false;
      if (r.date != a.appointmentDate) return false;
      return _normalizeVaccineLabel(r.vaccineName) == norm;
    });
    if (exists) continue;

    final record = VaccinationRecord(
      vaccineName: a.vaccineName,
      date: a.appointmentDate,
      reminderDate: a.appointmentDate,
      location: a.center,
      note: 'Ghi nhận từ lịch hẹn #${a.id ?? "?"}$pendingAutoNoteSuffix',
      memberId: a.memberId,
      isCompleted: false,
    );

    final newId = await repo.addRecord(record);
    await notification.scheduleVaccinationReminder(record.copyWith(id: newId));
    changed = true;
  }

  return changed;
}
