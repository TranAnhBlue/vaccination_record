import '../../domain/entities/appointment.dart';

class AppointmentModel extends Appointment {
  AppointmentModel({
    super.id,
    required super.memberId,
    required super.vaccineName,
    required super.center,
    required super.appointmentDate,
    required super.appointmentTime,
    super.note,
    super.status,
    required super.createdAt,
  });

  factory AppointmentModel.fromMap(Map<String, dynamic> map) {
    return AppointmentModel(
      id: map['id'],
      memberId: map['memberId'] as int,
      vaccineName: map['vaccineName'] ?? '',
      center: map['center'] ?? '',
      appointmentDate: map['appointmentDate'] ?? '',
      appointmentTime: map['appointmentTime'] ?? '',
      note: map['note'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: map['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'memberId': memberId,
    'vaccineName': vaccineName,
    'center': center,
    'appointmentDate': appointmentDate,
    'appointmentTime': appointmentTime,
    'note': note,
    'status': status,
    'createdAt': createdAt,
  };
}
