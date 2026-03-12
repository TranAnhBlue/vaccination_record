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
    }

    if (ageInMonths >= 18) {
      suggestions.add(SuggestedVaccine(name: 'DPT nhắc lại', ageRange: '18 tháng', description: 'Bạch hầu, ho gà, uốn ván mũi 4.', isMandatory: true));
      suggestions.add(SuggestedVaccine(name: 'Sởi-Rubella (MR)', ageRange: '18 tháng', description: 'Phòng sởi và rubella.', isMandatory: true));
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
