import '../entities/member.dart';
import '../entities/vaccination_record.dart';

// Trạng thái mũi tiêm gợi ý của 1 thành viên
enum VaccineStatus { done, pending, scheduled }

class SuggestedVaccine {
  final String id;          // unique key để track trạng thái
  final String name;
  final String ageRange;
  final String description;
  final bool isMandatory;
  final int minAgeMonths;
  final int maxAgeMonths;   // -1 = no upper limit
  final String category;    // nhóm: 'Sơ sinh', 'Trẻ nhỏ', 'Thiếu niên', 'Người lớn'

  const SuggestedVaccine({
    required this.id,
    required this.name,
    required this.ageRange,
    required this.description,
    required this.minAgeMonths,
    this.maxAgeMonths = -1,
    this.isMandatory = false,
    this.category = '',
  });
}

// Kết quả gợi ý cho 1 thành viên cụ thể
class MemberVaccineSuggestion {
  final Member member;
  final int ageMonths;
  final List<SuggestedVaccineStatus> vaccines;

  MemberVaccineSuggestion({
    required this.member,
    required this.ageMonths,
    required this.vaccines,
  });

  int get doneCount => vaccines.where((v) => v.status == VaccineStatus.done).length;
  int get pendingCount => vaccines.where((v) => v.status == VaccineStatus.pending).length;
  int get scheduledCount => vaccines.where((v) => v.status == VaccineStatus.scheduled).length;
  double get progress => vaccines.isEmpty ? 0 : doneCount / vaccines.length;
}

// Gợi ý + trạng thái của 1 vaccine cho 1 member
class SuggestedVaccineStatus {
  final SuggestedVaccine vaccine;
  final VaccineStatus status;
  final VaccinationRecord? record; // null nếu chưa tiêm

  const SuggestedVaccineStatus({
    required this.vaccine,
    required this.status,
    this.record,
  });
}

class VaccineSuggestionService {
  // ── Lịch tiêm chuẩn Bộ Y tế Việt Nam ──────────────────────────────────
  static const List<SuggestedVaccine> _schedule = [

    // ═══════════════ SƠ SINH (0-1 tháng) ════════════════════════════════
    SuggestedVaccine(
      id: 'bcg',
      name: 'BCG — Phòng lao',
      ageRange: 'Sơ sinh (24-48h đầu)',
      description: 'Tiêm ngay sau sinh, phòng bệnh lao phổi và lao màng não ở trẻ sơ sinh.',
      isMandatory: true, minAgeMonths: 0, maxAgeMonths: 2, category: 'Sơ sinh',
    ),
    SuggestedVaccine(
      id: 'hepb_birth',
      name: 'Viêm gan B — Liều sơ sinh',
      ageRange: 'Trong 24h đầu sau sinh',
      description: 'Ngăn lây truyền viêm gan B từ mẹ sang con. Tiêm càng sớm càng tốt.',
      isMandatory: true, minAgeMonths: 0, maxAgeMonths: 1, category: 'Sơ sinh',
    ),

    // ═══════════════ 2 THÁNG ═════════════════════════════════════════════
    SuggestedVaccine(
      id: 'dpthib_1',
      name: '5 trong 1 (DPT-VGB-Hib) — Mũi 1',
      ageRange: '2 tháng tuổi',
      description: 'Phòng bạch hầu, ho gà, uốn ván, viêm gan B và Hib. Mũi 1/3.',
      isMandatory: true, minAgeMonths: 2, maxAgeMonths: 3, category: 'Trẻ nhỏ',
    ),
    SuggestedVaccine(
      id: 'opv_1',
      name: 'Bại liệt (OPV/IPV) — Mũi 1',
      ageRange: '2 tháng tuổi',
      description: 'Phòng bệnh bại liệt. Mũi 1/3.',
      isMandatory: true, minAgeMonths: 2, maxAgeMonths: 3, category: 'Trẻ nhỏ',
    ),
    SuggestedVaccine(
      id: 'rota_1',
      name: 'Rotavirus — Mũi 1',
      ageRange: '2 tháng tuổi',
      description: 'Phòng tiêu chảy cấp do Rotavirus. Uống 2-3 liều.',
      isMandatory: false, minAgeMonths: 2, maxAgeMonths: 4, category: 'Trẻ nhỏ',
    ),

    // ═══════════════ 3 THÁNG ═════════════════════════════════════════════
    SuggestedVaccine(
      id: 'dpthib_2',
      name: '5 trong 1 (DPT-VGB-Hib) — Mũi 2',
      ageRange: '3 tháng tuổi',
      description: 'Tiếp tục phòng bạch hầu, ho gà, uốn ván, viêm gan B và Hib. Mũi 2/3.',
      isMandatory: true, minAgeMonths: 3, maxAgeMonths: 4, category: 'Trẻ nhỏ',
    ),
    SuggestedVaccine(
      id: 'opv_2',
      name: 'Bại liệt (OPV/IPV) — Mũi 2',
      ageRange: '3 tháng tuổi',
      description: 'Phòng bệnh bại liệt. Mũi 2/3.',
      isMandatory: true, minAgeMonths: 3, maxAgeMonths: 4, category: 'Trẻ nhỏ',
    ),

    // ═══════════════ 4 THÁNG ═════════════════════════════════════════════
    SuggestedVaccine(
      id: 'dpthib_3',
      name: '5 trong 1 (DPT-VGB-Hib) — Mũi 3',
      ageRange: '4 tháng tuổi',
      description: 'Hoàn thành lịch tiêm cơ bản bạch hầu, ho gà, uốn ván, viêm gan B, Hib. Mũi 3/3.',
      isMandatory: true, minAgeMonths: 4, maxAgeMonths: 5, category: 'Trẻ nhỏ',
    ),
    SuggestedVaccine(
      id: 'opv_3',
      name: 'Bại liệt (OPV/IPV) — Mũi 3',
      ageRange: '4 tháng tuổi',
      description: 'Hoàn thành phác đồ phòng bại liệt cơ bản. Mũi 3/3.',
      isMandatory: true, minAgeMonths: 4, maxAgeMonths: 5, category: 'Trẻ nhỏ',
    ),

    // ═══════════════ 6 THÁNG ═════════════════════════════════════════════
    SuggestedVaccine(
      id: 'flu_first',
      name: 'Cúm mùa — Mũi đầu',
      ageRange: 'Từ 6 tháng tuổi (nhắc mỗi năm)',
      description: 'Lần đầu tiêm 2 mũi cách nhau 4 tuần. Sau đó nhắc mỗi năm 1 lần.',
      isMandatory: false, minAgeMonths: 6, maxAgeMonths: 8, category: 'Trẻ nhỏ',
    ),

    // ═══════════════ 9 THÁNG ═════════════════════════════════════════════
    SuggestedVaccine(
      id: 'measles_1',
      name: 'Sởi đơn — Mũi 1',
      ageRange: '9 tháng tuổi',
      description: 'Mũi 1 phòng sởi trong chương trình tiêm chủng mở rộng quốc gia.',
      isMandatory: true, minAgeMonths: 9, maxAgeMonths: 12, category: 'Trẻ nhỏ',
    ),

    // ═══════════════ 12 THÁNG ════════════════════════════════════════════
    SuggestedVaccine(
      id: 'je_1',
      name: 'Viêm não Nhật Bản — Mũi 1',
      ageRange: '12 tháng tuổi',
      description: 'Phòng viêm não Nhật Bản. Tiêm 3 mũi: M1 lúc 12 tháng, M2 sau 1-2 tuần, M3 sau 1 năm.',
      isMandatory: true, minAgeMonths: 12, maxAgeMonths: 18, category: 'Trẻ nhỏ',
    ),
    SuggestedVaccine(
      id: 'varicella',
      name: 'Thủy đậu (Varicella)',
      ageRange: '12-18 tháng tuổi',
      description: 'Phòng bệnh thủy đậu hiệu quả lên đến 98%. 1-2 mũi tuỳ loại vắc-xin.',
      isMandatory: false, minAgeMonths: 12, maxAgeMonths: 18, category: 'Trẻ nhỏ',
    ),
    SuggestedVaccine(
      id: 'hepa_1',
      name: 'Viêm gan A — Mũi 1',
      ageRange: '12-23 tháng tuổi',
      description: 'Phòng viêm gan A. Tiêm 2 mũi cách nhau 6-12 tháng.',
      isMandatory: false, minAgeMonths: 12, maxAgeMonths: 24, category: 'Trẻ nhỏ',
    ),
    SuggestedVaccine(
      id: 'mmr_1',
      name: 'Sởi-Quai bị-Rubella (MMR) — Mũi 1',
      ageRange: '12-15 tháng tuổi',
      description: 'Phòng 3 bệnh trong 1 mũi. Hiệu quả bảo vệ trên 95%.',
      isMandatory: false, minAgeMonths: 12, maxAgeMonths: 18, category: 'Trẻ nhỏ',
    ),

    // ═══════════════ 18 THÁNG ════════════════════════════════════════════
    SuggestedVaccine(
      id: 'dpt_booster',
      name: 'DPT nhắc lại — Mũi 4',
      ageRange: '18 tháng tuổi',
      description: 'Nhắc lại bạch hầu-ho gà-uốn ván. Mũi 4 trong chương trình mở rộng.',
      isMandatory: true, minAgeMonths: 18, maxAgeMonths: 24, category: 'Trẻ nhỏ',
    ),
    SuggestedVaccine(
      id: 'mr_2',
      name: 'Sởi-Rubella (MR) — Mũi 2',
      ageRange: '18 tháng tuổi',
      description: 'Mũi 2 củng cố miễn dịch sởi và rubella trong chương trình mở rộng.',
      isMandatory: true, minAgeMonths: 18, maxAgeMonths: 24, category: 'Trẻ nhỏ',
    ),
    SuggestedVaccine(
      id: 'je_3',
      name: 'Viêm não Nhật Bản — Mũi 3 (nhắc)',
      ageRange: '24-27 tháng tuổi',
      description: 'Mũi nhắc lại sau 1 năm kể từ mũi 2. Hoàn thành phác đồ cơ bản.',
      isMandatory: true, minAgeMonths: 24, maxAgeMonths: 30, category: 'Trẻ nhỏ',
    ),

    // ═══════════════ 4-6 TUỔI ════════════════════════════════════════════
    SuggestedVaccine(
      id: 'mmr_2',
      name: 'MMR — Mũi 2 (nhắc lại)',
      ageRange: '4-6 tuổi',
      description: 'Mũi 2 nhắc lại Sởi-Quai bị-Rubella để tăng cường miễn dịch lâu dài.',
      isMandatory: false, minAgeMonths: 48, maxAgeMonths: 72, category: 'Trẻ em',
    ),
    SuggestedVaccine(
      id: 'flu_annual',
      name: 'Cúm mùa — Nhắc hàng năm',
      ageRange: 'Hàng năm (từ 6 tháng)',
      description: 'Tiêm lại mỗi năm vì virus cúm thay đổi chủng liên tục.',
      isMandatory: false, minAgeMonths: 72, category: 'Trẻ em',
    ),

    // ═══════════════ 9-26 TUỔI ═══════════════════════════════════════════
    SuggestedVaccine(
      id: 'hpv',
      name: 'HPV (Gardasil 4/9)',
      ageRange: '9-26 tuổi (hiệu quả nhất 11-12 tuổi)',
      description: 'Phòng ung thư cổ tử cung và các bệnh do HPV. Tiêm 2-3 mũi. Hiệu quả nhất trước khi có quan hệ tình dục.',
      isMandatory: false, minAgeMonths: 108, maxAgeMonths: 312, category: 'Thiếu niên',
    ),

    // ═══════════════ NGƯỜI LỚN (18+) ═════════════════════════════════════
    SuggestedVaccine(
      id: 'td_adult',
      name: 'Uốn ván-Bạch hầu (Td) — Nhắc mỗi 10 năm',
      ageRange: 'Người lớn',
      description: 'Nhắc lại mỗi 10 năm để duy trì miễn dịch. Đặc biệt quan trọng khi mang thai.',
      isMandatory: false, minAgeMonths: 216, category: 'Người lớn',
    ),
    SuggestedVaccine(
      id: 'hepb_adult',
      name: 'Viêm gan B — Phác đồ người lớn',
      ageRange: 'Người lớn chưa tiêm',
      description: '3 mũi cho người trưởng thành chưa tiêm lúc nhỏ. Phòng ung thư gan.',
      isMandatory: false, minAgeMonths: 216, category: 'Người lớn',
    ),
    SuggestedVaccine(
      id: 'flu_adult',
      name: 'Cúm mùa — Người lớn',
      ageRange: 'Hàng năm',
      description: 'Quan trọng với người cao tuổi, phụ nữ mang thai, người có bệnh nền.',
      isMandatory: false, minAgeMonths: 216, category: 'Người lớn',
    ),
    SuggestedVaccine(
      id: 'ppv23',
      name: 'Phế cầu (PPV23) — Người cao tuổi',
      ageRange: 'Từ 65 tuổi',
      description: 'Phòng viêm phổi, nhiễm trùng huyết do phế cầu. Người có bệnh mạn tính nên tiêm sớm hơn.',
      isMandatory: false, minAgeMonths: 780, category: 'Người lớn',
    ),
  ];

  // ── PUBLIC API ────────────────────────────────────────────────────────

  /// Trả về danh sách gợi ý kèm trạng thái cho 1 thành viên
  MemberVaccineSuggestion getSuggestionsForMember(
      Member member, List<VaccinationRecord> records) {
    final ageMonths = _ageInMonths(member.dob);

    // Lọc vaccine phù hợp độ tuổi
    final ageAppropriate = _schedule.where((v) {
      if (ageMonths < v.minAgeMonths) return false;
      if (v.maxAgeMonths != -1 && ageMonths > v.maxAgeMonths + 6) return false;
      return true;
    }).toList();

    // Gắn trạng thái cho từng vaccine
    final statuses = ageAppropriate.map((vaccine) {
      final matchedRecord = _findRecord(vaccine, records);
      final status = matchedRecord != null
          ? (matchedRecord.isCompleted ? VaccineStatus.done : VaccineStatus.scheduled)
          : VaccineStatus.pending;
      return SuggestedVaccineStatus(
        vaccine: vaccine,
        status: status,
        record: matchedRecord,
      );
    }).toList();

    // Sắp xếp: bắt buộc trước, pending trước done
    statuses.sort((a, b) {
      if (a.status == b.status) {
        if (a.vaccine.isMandatory != b.vaccine.isMandatory) {
          return a.vaccine.isMandatory ? -1 : 1;
        }
        return a.vaccine.minAgeMonths.compareTo(b.vaccine.minAgeMonths);
      }
      const order = {VaccineStatus.pending: 0, VaccineStatus.scheduled: 1, VaccineStatus.done: 2};
      return order[a.status]!.compareTo(order[b.status]!);
    });

    return MemberVaccineSuggestion(
      member: member,
      ageMonths: ageMonths,
      vaccines: statuses,
    );
  }

  // ── HELPERS ───────────────────────────────────────────────────────────

  VaccinationRecord? _findRecord(SuggestedVaccine vaccine, List<VaccinationRecord> records) {
    final key = vaccine.id.toLowerCase();
    final nameParts = vaccine.name.toLowerCase().replaceAll(RegExp(r'\s*[—-].*'), '').trim().split(' ');
    return records.where((r) {
      final rName = r.vaccineName.toLowerCase();
      return nameParts.any((part) => part.length > 3 && rName.contains(part));
    }).firstOrNull;
  }

  int _ageInMonths(String dob) {
    if (dob.isEmpty) return 0;
    try {
      final birth = DateTime.parse(dob);
      final now = DateTime.now();
      return (now.year - birth.year) * 12 + now.month - birth.month;
    } catch (_) { return 0; }
  }

  String getAgeLabel(int months) {
    if (months == 0) return 'Sơ sinh';
    if (months < 12) return '$months tháng tuổi';
    final years = months ~/ 12;
    final rem = months % 12;
    if (rem == 0) return '$years tuổi';
    return '$years tuổi $rem tháng';
  }

  String getAgeLabelFromDob(String dob) => getAgeLabel(_ageInMonths(dob));

  int categoryColorValue(String category) {
    switch (category) {
      case 'Sơ sinh': return 0xFF7B61FF;
      case 'Trẻ nhỏ': return 0xFF0091FF;
      case 'Trẻ em': return 0xFF00C48C;
      case 'Thiếu niên': return 0xFFFF6B6B;
      default: return 0xFF8D8D8D;
    }
  }
}
