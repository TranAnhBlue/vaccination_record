class User {
  final int? id;
  final String name;
  final String phone;
  final String password;
  final String dob;
  final String gender;

  User({
    this.id,
    required this.name,
    required this.phone,
    required this.password,
    this.dob = "",
    this.gender = "",
  });
}