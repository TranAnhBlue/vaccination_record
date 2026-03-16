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
  final bool isCompleted;

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
    this.isCompleted = false,
  });

  String calculateStatus(DateTime today) {
    if (isCompleted) return "Đã tiêm";

    final injectionDate = DateTime.tryParse(date);
    if (injectionDate != null) {
      final injectionDay = DateTime(injectionDate.year, injectionDate.month, injectionDate.day);
      
      if (injectionDay.isAtSameMomentAs(today)) return "Hôm nay";
      
      if (injectionDay.isBefore(today)) return "Quá hạn";

      final diff = injectionDay.difference(today).inDays;
      if (diff <= 7) return "Sắp đến hạn";
      return "Kế hoạch";
    }

    return "Không xác định";
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