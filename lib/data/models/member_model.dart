import '../../domain/entities/member.dart';

class MemberModel extends Member {
  MemberModel({
    super.id,
    required super.userId,
    required super.name,
    required super.dob,
    required super.gender,
    required super.relationship,
  });

  factory MemberModel.fromMap(Map<String, dynamic> map) {
    return MemberModel(
      id: map['id'],
      userId: map['userId'],
      name: map['name'],
      dob: map['dob'],
      gender: map['gender'],
      relationship: map['relationship'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'dob': dob,
      'gender': gender,
      'relationship': relationship,
    };
  }
}
