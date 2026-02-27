class VaccinationRecord {
  final int? id;
  final String vaccineName;
  final int dose;
  final String date;
  final String reminderDate;
  final String? imagePath;
  final String location;
  final String note;

  VaccinationRecord({
    this.id,
    required this.vaccineName,
    required this.dose,
    required this.date,
    required this.reminderDate,
    this.imagePath,
    required this.location,
    required this.note,
  });
}