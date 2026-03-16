class VaccinationRecord {
  final int? id;
  final String vaccineName;
  final int dose;
  final String date;
  final String reminderDate;
  final String? imagePath;
  final String location;
  final String note;
  final int? memberId;

  VaccinationRecord({
    this.id,
    required this.vaccineName,
    required this.dose,
    required this.date,
    required this.reminderDate,
    this.imagePath,
    required this.location,
    required this.note,
    this.memberId,
  });

  String calculateStatus(DateTime today) {
    final injectionDate = DateTime.tryParse(date);
    if (injectionDate != null && injectionDate.isAfter(today)) {
      final diff = injectionDate.difference(today).inDays;
      if (diff < 3) return "Quá hạn";
      return "Sắp đến hạn";
    }

    if (reminderDate.isNotEmpty) {
      final reminder = DateTime.tryParse(reminderDate);
      if (reminder != null) {
        if (reminder.isBefore(today)) return "Quá hạn";

        final diff = reminder.difference(today).inDays;
        if (diff < 3) return "Quá hạn";
        if (diff < 7) return "Sắp đến hạn";
      }
    }

    return "Đã tiêm";
  }

  bool get isOverdue {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return calculateStatus(today) == "Quá hạn";
  }

  bool get isUpcoming {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return calculateStatus(today) == "Sắp đến hạn";
  }
}