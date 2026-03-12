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
}
