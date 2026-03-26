import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/appointment.dart';
import '../../domain/entities/vaccination_record.dart';
import '../../data/local/dao/appointment_dao.dart';
import '../../data/models/appointment_model.dart';
import '../../data/repositories/vaccination_repository_impl.dart';

class AppointmentViewModel extends ChangeNotifier {
  final _dao = AppointmentDao();

  List<Appointment> appointments = [];
  bool loading = false;
  String? error;

  Map<String, int?>? _lastLoadParams;

  Future<void> _reload() async {
    if (_lastLoadParams != null) {
      await load(
        memberId: _lastLoadParams!['memberId'],
        userId: _lastLoadParams!['userId'],
      );
    }
  }

  Future<void> load({int? memberId, int? userId}) async {
    _lastLoadParams = {'memberId': memberId, 'userId': userId};
    loading = true;
    error = null;
    notifyListeners();
    try {
      if (userId != null) {
        appointments = await _dao.getByUserId(userId);
      } else if (memberId != null) {
        appointments = await _dao.getByMember(memberId);
      }
      // Force a new list reference for better reactivity
      appointments = List.from(appointments);
      if (userId != null) {
        await _backfillVaccinationHistoryFromCompletedAppointments();
      }
    } catch (e) {
      error = 'Không thể tải lịch hẹn: $e';
    }
    loading = false;
    notifyListeners();
  }

  /// Khôi phục lịch sử tiêm cho các hẹn đã [completed] trước khi có logic đồng bộ (idempotent).
  Future<void> _backfillVaccinationHistoryFromCompletedAppointments() async {
    for (final a in appointments) {
      if (a.status == 'completed') {
        await _syncCompletedAppointmentToVaccinationHistory(a);
      }
    }
  }

  Future<bool> addAppointment({
    required int memberId,
    required String vaccineName,
    required String center,
    required DateTime date,
    required TimeOfDay time,
    String note = '',
  }) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final model = AppointmentModel(
        memberId: memberId,
        vaccineName: vaccineName,
        center: center,
        appointmentDate: DateFormat('yyyy-MM-dd').format(date),
        appointmentTime: '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
        note: note,
        status: 'pending',
        createdAt: DateTime.now().toIso8601String(),
      );
      await _dao.insert(model);
      await _reload();
      return true;
    } catch (e) {
      loading = false;
      error = 'Lỗi đặt lịch: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> cancelAppointment(int id) async {
    await _dao.updateStatus(id, 'cancelled');
    // Force immediate local update for responsiveness
    final idx = appointments.indexWhere((a) => a.id == id);
    if (idx >= 0) {
      appointments[idx] = appointments[idx].copyWith(status: 'cancelled');
      appointments = List.from(appointments);
      notifyListeners();
    }
    // Then reload from DB to be 100% sure
    await _reload();
  }

  /// Trả về [memberId] của hẹn đã xử lý (để UI đồng bộ dữ liệu tiêm chủng nếu cần).
  Future<int?> completeAppointment(int id) async {
    var idx = appointments.indexWhere((a) => a.id == id);
    if (idx < 0) {
      await _reload();
      idx = appointments.indexWhere((a) => a.id == id);
    }
    if (idx < 0) return null;

    final apt = appointments[idx];
    if (apt.status == 'completed') {
      await _syncCompletedAppointmentToVaccinationHistory(apt);
      await _reload();
      return apt.memberId;
    }

    await _dao.updateStatus(id, 'completed');
    await _syncCompletedAppointmentToVaccinationHistory(apt);

    final j = appointments.indexWhere((a) => a.id == id);
    if (j >= 0) {
      appointments[j] = appointments[j].copyWith(status: 'completed');
      appointments = List.from(appointments);
      notifyListeners();
    }
    await _reload();
    return apt.memberId;
  }

  Future<void> _syncCompletedAppointmentToVaccinationHistory(Appointment apt) async {
    final repo = VaccinationRepositoryImpl();
    final existing = await repo.getRecords(memberId: apt.memberId);
    final norm = _normalizeVaccineLabel(apt.vaccineName);
    final matched = existing.where(
      (r) =>
          r.date == apt.appointmentDate &&
          _normalizeVaccineLabel(r.vaccineName) == norm,
    );

    // Nếu record đã được tạo từ luồng "sắp tới" (isCompleted=false),
    // thì khi người dùng xác nhận "Đã tiêm" cần cập nhật trạng thái thay vì bỏ qua.
    if (matched.isNotEmpty) {
      final record = matched.first;
      if (record.isCompleted) return;

      final noteParts = <String>[
        if (apt.note.isNotEmpty) apt.note,
        if (apt.id != null) 'Ghi nhận từ lịch hẹn #${apt.id}',
      ];

      await repo.updateRecord(
        record.copyWith(
          // Giữ nguyên dose vì record này đã được tạo từ luồng "pending".
          reminderDate: apt.appointmentDate,
          location: apt.center,
          note: noteParts.join('\n'),
          isCompleted: true,
        ),
      );
      return;
    }

    final noteParts = <String>[
      if (apt.note.isNotEmpty) apt.note,
      if (apt.id != null) 'Ghi nhận từ lịch hẹn #${apt.id}',
    ];

    await repo.addRecord(
      VaccinationRecord(
        vaccineName: apt.vaccineName,
        date: apt.appointmentDate,
        reminderDate: apt.appointmentDate,
        location: apt.center,
        note: noteParts.join('\n'),
        memberId: apt.memberId,
        isCompleted: true,
      ),
    );
  }

  String _normalizeVaccineLabel(String s) {
    return s.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  Future<void> deleteAppointment(int id) async {
    await _dao.delete(id);
    await _reload();
  }

  List<Appointment> get pending =>
      appointments.where((a) => a.status == 'pending').toList();
  List<Appointment> get upcoming =>
      appointments.where((a) => a.status == 'pending' &&
          DateTime.tryParse(a.appointmentDate)?.isAfter(DateTime.now().subtract(const Duration(days: 1))) == true).toList();
  List<Appointment> get past =>
      appointments.where((a) => a.status == 'completed' || a.status == 'cancelled').toList();

  /// Tất cả lịch hẹn của một thành viên (đồng bộ luồng lọc với gợi ý / trang chủ).
  List<Appointment> appointmentsForMember(int memberId) =>
      appointments.where((a) => a.memberId == memberId).toList();

  List<Appointment> pendingForMember(int memberId) => appointments
      .where((a) => a.memberId == memberId && a.status == 'pending')
      .toList();

  /// Pending, ngày hẹn sau “hôm qua” — cùng quy tắc với [upcoming] nhưng theo thành viên.
  List<Appointment> upcomingForMember(int memberId) {
    final cutoff = DateTime.now().subtract(const Duration(days: 1));
    return appointments
        .where((a) =>
            a.memberId == memberId &&
            a.status == 'pending' &&
            DateTime.tryParse(a.appointmentDate)?.isAfter(cutoff) == true)
        .toList();
  }
}
