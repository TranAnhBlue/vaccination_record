import '../../domain/entities/vaccination_record.dart';

class VaccinationRecordModel extends VaccinationRecord {
  VaccinationRecordModel({
    super.id,
    required super.vaccineName,
    required super.dose,
    required super.date,
    required super.location,
    required super.note,
  });

  factory VaccinationRecordModel.fromMap(Map<String, dynamic> map) {
    return VaccinationRecordModel(
      id: map['id'],
      vaccineName: map['vaccineName'],
      dose: map['dose'],
      date: map['date'],
      location: map['location'],
      note: map['note'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vaccineName': vaccineName,
      'dose': dose,
      'date': date,
      'location': location,
      'note': note,
    };
  }
}