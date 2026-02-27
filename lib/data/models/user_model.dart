import '../../domain/entities/user.dart';

class UserModel extends User {
  UserModel({
    super.id,
    required super.name,
    required super.phone,
    required super.password,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      password: map['password'],
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'phone': phone,
    'password': password,
  };
}