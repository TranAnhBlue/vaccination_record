class Appointment {
  final int? id;
  final int memberId;
  final String vaccineName;
  final String center;
  final String appointmentDate;  // yyyy-MM-dd
  final String appointmentTime;  // HH:mm
  final String note;
  final String status; // pending | confirmed | cancelled | completed
  final String createdAt;

  const Appointment({
    this.id,
    required this.memberId,
    required this.vaccineName,
    required this.center,
    required this.appointmentDate,
    required this.appointmentTime,
    this.note = '',
    this.status = 'pending',
    required this.createdAt,
  });

  Appointment copyWith({
    int? id,
    int? memberId,
    String? vaccineName,
    String? center,
    String? appointmentDate,
    String? appointmentTime,
    String? note,
    String? status,
    String? createdAt,
  }) {
    return Appointment(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      vaccineName: vaccineName ?? this.vaccineName,
      center: center ?? this.center,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      appointmentTime: appointmentTime ?? this.appointmentTime,
      note: note ?? this.note,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  DateTime get dateTime {
    final parts = appointmentTime.split(':');
    final d = DateTime.tryParse(appointmentDate) ?? DateTime.now();
    return DateTime(d.year, d.month, d.day,
        int.tryParse(parts[0]) ?? 9, int.tryParse(parts[1]) ?? 0);
  }
}
