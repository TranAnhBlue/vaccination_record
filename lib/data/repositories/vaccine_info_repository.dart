import '../../domain/entities/vaccine_info.dart';

class VaccineInfoRepository {
  List<VaccineInfo> getAllVaccines() {
    return [
      VaccineInfo(
        name: "Vắc xin 6 trong 1 (Hexaxim/Infanrix IPV Hib)",
        category: "Trẻ em",
        description: "Phòng 6 bệnh: Bạch hầu, Ho gà, Uốn ván, Bại liệt, Viêm gan B và các bệnh do vi khuẩn Hib.",
        sideEffects: "Sưng đau tại chỗ tiêm, sốt nhẹ, quấy khóc. Thường tự hết sau 24-48 giờ.",
        schedule: "2, 3, 4 tháng tuổi và nhắc lại lúc 16-18 tháng tuổi.",
        icon: "💉",
      ),
      VaccineInfo(
        name: "Vắc xin Phế cầu (Prevenar 13/Synflorix)",
        category: "Mọi lứa tuổi",
        description: "Phòng các bệnh do vi khuẩn phế cầu gây ra như viêm phổi, viêm màng não, viêm tai giữa.",
        sideEffects: "Sốt, đau tại chỗ tiêm, chán ăn.",
        schedule: "Trẻ em: 2, 4, 6, 12 tháng. Người lớn: Tiêm 1 mũi duy nhất.",
        icon: "🛡️",
      ),
      VaccineInfo(
        name: "Vắc xin Sởi - Quai bị - Rubella (MMR II)",
        category: "Trẻ em & Người lớn",
        description: "Phòng 3 bệnh truyền nhiễm nguy hiểm là Sởi, Quai bị và Rubella.",
        sideEffects: "Sốt nhẹ, phát ban nhẹ sau 5-12 ngày tiêm.",
        schedule: "Mũi 1 lúc 12 tháng, mũi 2 lúc 4-6 tuổi.",
        icon: "🍎",
      ),
      VaccineInfo(
        name: "Vắc xin Cúm (Vaxigrip Tetra/Influvac Tetra)",
        category: "Mọi lứa tuổi",
        description: "Phòng ngừa các chủng virus cúm mùa phổ biến (A/H1N1, A/H3N2, và 2 chủng cúm B).",
        sideEffects: "Đau cơ, sốt nhẹ, mệt mỏi.",
        schedule: "Tiêm nhắc lại hàng năm.",
        icon: "🤒",
      ),
      VaccineInfo(
        name: "Vắc xin HPV (Gardasil 9)",
        category: "9 - 45 tuổi",
        description: "Phòng ung thư cổ tử cung, ung thư hậu môn, mụn cóc sinh dục do virus HPV.",
        sideEffects: "Sưng đau chỗ tiêm, nhức đầu, chóng mặt.",
        schedule: "9-14 tuổi: 2 mũi. 15-45 tuổi: 3 mũi (0-2-6 tháng).",
        icon: "🧬",
      ),
      VaccineInfo(
        name: "Vắc xin Viêm gan B",
        category: "Mọi lứa tuổi",
        description: "Phòng ngừa bệnh viêm gan B và các biến chứng như xơ gan, ung thư gan.",
        sideEffects: "Đau chỗ tiêm, mệt mỏi.",
        schedule: "Sơ sinh: 24h đầu. Sau đó theo lịch tiêm chủng mở rộng.",
        icon: "🧬",
      ),
    ];
  }
}
