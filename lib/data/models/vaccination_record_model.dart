import '../../domain/entities/vaccination_record.dart';

class VaccinationRecordModel extends VaccinationRecord {
  VaccinationRecordModel({
    super.id,
    required super.vaccineName,
    required super.date,
    required super.reminderDate,
    super.imagePath,
    required super.location,
    required super.note,
    super.memberId,
    super.isCompleted,
  });

  factory VaccinationRecordModel.fromMap(Map<String, dynamic> map) {
    return VaccinationRecordModel(
      id: map['id'],
      vaccineName: map['vaccineName'],
      date: map['date'],
      reminderDate: map['reminderDate'] ?? "",
      imagePath: map['imagePath'],
      location: map['location'],
      note: map['note'],
      memberId: map['memberId'],
      isCompleted: (map['isCompleted'] ?? 0) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vaccineName': vaccineName,
      'date': date,
      'reminderDate': reminderDate,
      'imagePath': imagePath,
      'location': location,
      'note': note,
      'memberId': memberId,
      'isCompleted': isCompleted ? 1 : 0,
    };
  }
}