import '../entities/appointment.dart';
import '../entities/vaccination_record.dart';

/// Tổng hợp số mũi sắp tới trong 7 ngày và trễ hẹn (bản ghi chưa hoàn thành + lịch pending).
class ScheduleHighlights {
  final int upcomingWeekCount;
  final DateTime? nearestDate;
  final int overdueCount;

  const ScheduleHighlights({
    required this.upcomingWeekCount,
    required this.nearestDate,
    required this.overdueCount,
  });
}

/// Mũi chưa tiêm / lịch pending có ngày trong [today .. today+7] (kể cả hôm nay).
/// Trễ hẹn: ngày đã qua so với hôm nay.
ScheduleHighlights computeScheduleHighlights({
  required List<VaccinationRecord> records,
  required List<Appointment> appointments,
  required DateTime today,
}) {
  final todayNorm = DateTime(today.year, today.month, today.day);
  final weekEnd = todayNorm.add(const Duration(days: 7));

  var upcoming = 0;
  var overdue = 0;
  DateTime? nearest;

  void bumpUpcoming(DateTime raw) {
    final d = DateTime(raw.year, raw.month, raw.day);
    if (d.isBefore(todayNorm) || d.isAfter(weekEnd)) return;
    upcoming++;
    if (nearest == null || d.isBefore(nearest!)) {
      nearest = d;
    }
  }

  for (final r in records) {
    if (r.isCompleted) continue;
    final parsed = DateTime.tryParse(r.date);
    if (parsed == null) continue;
    final d = DateTime(parsed.year, parsed.month, parsed.day);
    if (d.isBefore(todayNorm)) {
      overdue++;
    } else {
      bumpUpcoming(parsed);
    }
  }

  for (final a in appointments) {
    if (a.status != 'pending') continue;
    final parsed = DateTime.tryParse(a.appointmentDate);
    if (parsed == null) continue;
    final d = DateTime(parsed.year, parsed.month, parsed.day);
    if (d.isBefore(todayNorm)) {
      overdue++;
    } else {
      bumpUpcoming(parsed);
    }
  }

  return ScheduleHighlights(
    upcomingWeekCount: upcoming,
    nearestDate: nearest,
    overdueCount: overdue,
  );
}
