class Vaccine {
  final String name;
  final String description;
  final String disease;

  const Vaccine({
    required this.name,
    required this.description,
    required this.disease,
  });
}

const List<Vaccine> commonVaccines = [
  Vaccine(
    name: "Vắc xin 6 trong 1 (Infanrix Hexa / Hexaxim)",
    disease: "Bạch hầu, ho gà, uốn ván, bại liệt, viêm gan B, Hib",
    description: "Phòng 6 bệnh truyền nhiễm nguy hiểm ở trẻ em.",
  ),
  Vaccine(
    name: "Vắc xin Phế cầu (Synflorix / Prevenar 13)",
    disease: "Viêm phổi, viêm màng não, viêm tai giữa do phế cầu",
    description: "Phòng các bệnh do vi khuẩn phế cầu gây ra.",
  ),
  Vaccine(
    name: "Vắc xin Rota (Rotarix / Rotateq / Rotavin)",
    disease: "Tiêu chảy cấp do virus Rota",
    description: "Vắc xin dạng uống phòng tiêu chảy cấp.",
  ),
  Vaccine(
    name: "Vắc xin Sởi - Quai bị - Rubella (MMR II / Priorix)",
    disease: "Sởi, Quai bị, Rubella",
    description: "Kết hợp phòng 3 bệnh truyền nhiễm phổ biến.",
  ),
  Vaccine(
    name: "Vắc xin Thủy đậu (Varivax / Varilrix)",
    disease: "Thủy đậu (Trái rạ)",
    description: "Phòng bệnh thủy đậu và các biến chứng.",
  ),
  Vaccine(
    name: "Vắc xin Viêm não Nhật Bản (Imojev / Jevax)",
    disease: "Viêm não Nhật Bản",
    description: "Phòng bệnh viêm não lây truyền qua muỗi.",
  ),
  Vaccine(
    name: "Vắc xin Cúm (Vaxigrip Tetra / Influvac Tetra)",
    disease: "Cúm mùa",
    description: "Phòng các chủng virus cúm A và B hàng năm.",
  ),
  Vaccine(
    name: "Vắc xin Ung thư cổ tử cung (Gardasil / Gardasil 9)",
    disease: "Ung thư cổ tử cung, sùi mào gà do HPV",
    description: "Phòng virus HPV gây ung thư và các bệnh sinh dục.",
  ),
  Vaccine(
    name: "Vắc xin Dại (Verorab / Abhayrab)",
    disease: "Bệnh Dại",
    description: "Dùng để dự phòng trước hoặc sau khi bị động vật cắn.",
  ),
  Vaccine(
    name: "Vắc xin Viêm gan A + B (Twinrix)",
    disease: "Viêm gan A và Viêm gan B",
    description: "Phòng hai loại virus viêm gan phổ biến.",
  ),
  Vaccine(
    name: "Vắc xin Não mô cầu ACYW (Menactra)",
    disease: "Viêm màng não do não mô cầu khuẩn",
    description: "Phòng các chủng não mô cầu A, C, Y, W-135.",
  ),
  Vaccine(
    name: "Vắc xin Lao (BCG)",
    disease: "Lao",
    description: "Thường tiêm trong tháng đầu sau sinh.",
  ),
];
