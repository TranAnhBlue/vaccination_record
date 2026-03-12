import '../entities/member.dart';
import '../entities/vaccination_record.dart';

class SuggestedVaccine {
  final String name;
  final String ageRange;
  final String description;
  final bool isMandatory;

  SuggestedVaccine({
    required this.name,
    required this.ageRange,
    required this.description,
    this.isMandatory = false,
  });
}

class VaccineSuggestionService {
  List<SuggestedVaccine> getSuggestions(Member member, List<VaccinationRecord> existingRecords) {
    final ageInMonths = _calculateAgeInMonths(member.dob);
    final suggestions = <SuggestedVaccine>[];

    // MoH Standard Schedule
    if (ageInMonths <= 1) {
      suggestions.add(SuggestedVaccine(name: 'BCG (Lao)', ageRange: 'Sơ sinh', description: 'Phòng bệnh lao, tiêm càng sớm càng tốt.', isMandatory: true));
      suggestions.add(SuggestedVaccine(name: 'Viêm gan B (VGB)', ageRange: 'Sơ sinh', description: 'Tiêm trong 24h đầu sau sinh.', isMandatory: true));
    }

    if (ageInMonths >= 2 && ageInMonths < 5) {
      suggestions.add(SuggestedVaccine(name: '5 trong 1 (DPT-VGB-Hib)', ageRange: '2, 3, 4 tháng', description: 'Bạch hầu, ho gà, uốn ván, viêm gan B, Hib.', isMandatory: true));
      suggestions.add(SuggestedVaccine(name: 'Bại liệt (OPV/IPV)', ageRange: '2, 3, 4 tháng', description: 'Phòng bệnh bại liệt.', isMandatory: true));
    }

    if (ageInMonths >= 9) {
      suggestions.add(SuggestedVaccine(name: 'Sởi', ageRange: '9 tháng', description: 'Mũi 1 phòng bệnh sởi.', isMandatory: true));
    }

    if (ageInMonths >= 12) {
      suggestions.add(SuggestedVaccine(name: 'Viêm não Nhật Bản', ageRange: '12 tháng', description: 'Tiêm mũi 1, mũi 2 sau 1-2 tuần.', isMandatory: true));
      suggestions.add(SuggestedVaccine(name: 'Thủy đậu', ageRange: '12-18 tháng', description: 'Phòng bệnh thủy đậu (Varicella), tiêm 1 mũi.', isMandatory: false));
      suggestions.add(SuggestedVaccine(name: 'Viêm gan A', ageRange: '12-23 tháng', description: 'Phòng bệnh viêm gan A, 2 mũi cách nhau 6 tháng.', isMandatory: false));
    }

    if (ageInMonths >= 18) {
      suggestions.add(SuggestedVaccine(name: 'DPT nhắc lại', ageRange: '18 tháng', description: 'Bạch hầu, ho gà, uốn ván mũi 4.', isMandatory: true));
      suggestions.add(SuggestedVaccine(name: 'Sởi-Rubella (MR)', ageRange: '18 tháng', description: 'Phòng sởi và rubella.', isMandatory: true));
    }

    if (ageInMonths >= 24) {
      suggestions.add(SuggestedVaccine(name: 'Phế cầu khuẩn (PCV)', ageRange: '2 tuổi', description: 'Phòng bệnh do phế cầu như viêm phổi, viêm màng não.', isMandatory: false));
      suggestions.add(SuggestedVaccine(name: 'Cúm mùa', ageRange: '2 tuổi trở lên', description: 'Tiêm nhắc hàng năm. Đặc biệt quan trọng cho trẻ em và người cao tuổi.', isMandatory: false));
    }

    // Adolescent and adult vaccines
    if (ageInMonths >= 108) { // 9 years
      suggestions.add(SuggestedVaccine(name: 'HPV (Gardasil)', ageRange: '9-26 tuổi', description: 'Phòng ung thư cổ tử cung và các bệnh do HPV. Hiệu quả tốt nhất khi tiêm trước khi có quan hệ.', isMandatory: false));
    }

    if (ageInMonths >= 216) { // 18 years
      suggestions.add(SuggestedVaccine(name: 'Uốn ván - Bạch hầu (Td)', ageRange: 'Người lớn', description: 'Nhắc lại mỗi 10 năm để duy trì miễn dịch.', isMandatory: false));
      suggestions.add(SuggestedVaccine(name: 'Viêm gan B', ageRange: 'Người lớn chưa tiêm', description: 'Nếu chưa tiêm khi còn nhỏ, cần tiêm đủ 3 mũi cho người trưởng thành.', isMandatory: false));
    }

    // Filter out already taken vaccines
    return suggestions.where((s) {
      return !existingRecords.any((r) => r.vaccineName.toLowerCase().contains(s.name.toLowerCase().split(' ')[0].toLowerCase()));
    }).toList();
  }

  int _calculateAgeInMonths(String dob) {
    if (dob.isEmpty) return 0;
    try {
      final birthDate = DateTime.parse(dob);
      final now = DateTime.now();
      return (now.year - birthDate.year) * 12 + now.month - birthDate.month;
    } catch (e) {
      return 0;
    }
  }
}
