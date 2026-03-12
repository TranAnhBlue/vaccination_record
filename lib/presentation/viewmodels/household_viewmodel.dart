import 'package:flutter/material.dart';
import '../../domain/entities/member.dart';
import '../../data/local/dao/member_dao.dart';
import '../../data/models/member_model.dart';
import '../../core/constants/session_manager.dart';

class HouseholdViewModel extends ChangeNotifier {
  final memberDao = MemberDao();
  List<Member> members = [];
  Member? selectedMember;
  bool isLoading = false;

  Future<void> loadMembers(int userId) async {
    isLoading = true;
    notifyListeners();
    
    final models = await memberDao.getAllForUser(userId);
    members = models.cast<Member>();
    
    if (members.isNotEmpty && selectedMember == null) {
      selectedMember = members.first;
    }
    
    isLoading = false;
    notifyListeners();
  }

  void selectMember(Member member) {
    selectedMember = member;
    notifyListeners();
  }

  Future<void> addMember(Member member) async {
    await memberDao.insert(MemberModel(
      userId: member.userId,
      name: member.name,
      dob: member.dob,
      gender: member.gender,
      relationship: member.relationship,
    ));
    await loadMembers(member.userId);
  }

  Future<void> updateMember(Member member) async {
    await memberDao.update(MemberModel(
      id: member.id,
      userId: member.userId,
      name: member.name,
      dob: member.dob,
      gender: member.gender,
      relationship: member.relationship,
    ));
    final userId = member.userId;
    if (selectedMember?.id == member.id) {
      selectedMember = member;
    }
    await loadMembers(userId);
  }

  Future<void> deleteMember(int id) async {
    await memberDao.delete(id);
    final userId = members.firstWhere((m) => m.id == id, orElse: () => members.first).userId;
    if (selectedMember?.id == id) {
      selectedMember = null;
    }
    await loadMembers(userId);
  }
}
