class Member {
  final int? id;
  final int userId; // The owner of the household
  final String name;
  final String dob;
  final String gender;
  final String relationship;

  Member({
    this.id,
    required this.userId,
    required this.name,
    required this.dob,
    required this.gender,
    required this.relationship,
  });

  Member copyWith({
    int? id,
    int? userId,
    String? name,
    String? dob,
    String? gender,
    String? relationship,
  }) {
    return Member(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      relationship: relationship ?? this.relationship,
    );
  }
}
