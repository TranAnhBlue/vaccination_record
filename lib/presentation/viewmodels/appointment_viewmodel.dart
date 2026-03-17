import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/appointment.dart';
import '../../data/local/dao/appointment_dao.dart';
import '../../data/models/appointment_model.dart';

class AppointmentViewModel extends ChangeNotifier {
  final _dao = AppointmentDao();

  List<Appointment> appointments = [];
  bool loading = false;
  String? error;

  Future<void> load({int? memberId, int? userId}) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      if (userId != null) {
        appointments = await _dao.getByUserId(userId);
      } else if (memberId != null) {
        appointments = await _dao.getByMember(memberId);
      }
    } catch (e) {
      error = 'Không thể tải lịch hẹn: $e';
    }
    loading = false;
    notifyListeners();
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
      loading = false;
      notifyListeners();
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
    final idx = appointments.indexWhere((a) => a.id == id);
    if (idx >= 0) {
      appointments[idx] = appointments[idx].copyWith(status: 'cancelled');
      notifyListeners();
    }
  }

  Future<void> completeAppointment(int id) async {
    await _dao.updateStatus(id, 'completed');
    final idx = appointments.indexWhere((a) => a.id == id);
    if (idx >= 0) {
      appointments[idx] = appointments[idx].copyWith(status: 'completed');
      notifyListeners();
    }
  }

  Future<void> deleteAppointment(int id) async {
    await _dao.delete(id);
    appointments.removeWhere((a) => a.id == id);
    notifyListeners();
  }

  List<Appointment> get pending =>
      appointments.where((a) => a.status == 'pending').toList();
  List<Appointment> get upcoming =>
      appointments.where((a) => a.status == 'pending' &&
          DateTime.tryParse(a.appointmentDate)?.isAfter(DateTime.now().subtract(const Duration(days: 1))) == true).toList();
  List<Appointment> get past =>
      appointments.where((a) => a.status == 'completed' || a.status == 'cancelled').toList();
}
