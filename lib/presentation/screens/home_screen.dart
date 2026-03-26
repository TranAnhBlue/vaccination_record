import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/routes/app_routes.dart';
import '../viewmodels/vaccination_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../../domain/entities/appointment.dart';
import '../../domain/entities/vaccination_record.dart';
import '../../core/theme/app_theme.dart';
import 'add_record_screen.dart';
import 'reminder_screen.dart';
import 'profile_screen.dart';
import 'ai/ai_screen.dart';
import '../viewmodels/household_viewmodel.dart';
import 'suggestions_screen.dart';
import '../../domain/services/vaccine_suggestion_service.dart';
import '../viewmodels/appointment_viewmodel.dart';
import '../sync/user_medical_data_sync.dart';
import '../../domain/services/schedule_highlight_service.dart';
import '../widgets/app_section_card.dart';
import '../widgets/appointment_date_badge.dart';
import '../widgets/dashboard_stat_tiles.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String selectedFilter = "Tất cả";
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      if (!mounted) return;
      final authVm = context.read<AuthViewModel>();
      final householdVm = context.read<HouseholdViewModel>();
      final uid = authVm.currentUser?.id;
      if (uid == null) return;
      await householdVm.loadMembers(uid);
      if (!mounted) return;
      await syncUserMedicalData(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<VaccinationViewModel>();
    final householdVm = context.watch<HouseholdViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FC),
      body: SafeArea(
        child: Column(
          children: [
            if (_currentIndex == 0) _buildOverview(vm, householdVm),
            if (_currentIndex == 1) _buildVaccinationHistory(vm, householdVm),
            if (_currentIndex == 2) const Expanded(child: AIScreen()),
            if (_currentIndex == 3)
              Expanded(
                child: ReminderScreen(
                  onSeeAll: () => setState(() => _currentIndex = 1),
                ),
              ),
            if (_currentIndex == 4) const Expanded(child: ProfileScreen()),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _currentIndex == 1
          ? FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddRecordScreen()),
        ),
        backgroundColor: AppTheme.primary,
        elevation: 6,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      )
          : null,
    );
  }

  Widget _buildOverview(
      VaccinationViewModel vm,
      HouseholdViewModel householdVm,
      ) {
    final apptVm = context.watch<AppointmentViewModel>();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int completedCount = 0;
    for (var r in vm.records) {
      if (r.isCompleted) completedCount++;
    }

    final sel = householdVm.selectedMember;
    final memberAppointments = sel?.id != null
        ? apptVm.appointmentsForMember(sel!.id!)
        : <Appointment>[];

    final recordsForSchedule = sel?.id != null
        ? vm.recordsForMember(sel!.id!)
        : vm.records;

    final scheduleHi = computeScheduleHighlights(
      records: recordsForSchedule,
      appointments: memberAppointments,
      today: today,
    );

    final suggestionService = VaccineSuggestionService();
    MemberVaccineSuggestion? memberSuggestion;
    int extraCount = 0;

    if (householdVm.selectedMember != null) {
      final mid = householdVm.selectedMember!.id!;
      final memberRecords = vm.recordsForMember(mid);
      final memberAppts = apptVm.pendingForMember(mid);
      memberSuggestion = suggestionService.getSuggestionsForMember(
        householdVm.selectedMember!,
        memberRecords,
        appointments: memberAppts,
      );
      extraCount = memberSuggestion.extraCount;
    }

    var recommendedTotal = memberSuggestion?.vaccines.length ?? 0;
    if (recommendedTotal == 0) recommendedTotal = 14;

    final completedForCard = (memberSuggestion != null &&
            memberSuggestion.vaccines.isNotEmpty)
        ? memberSuggestion.doneCount
        : completedCount;

    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(householdVm),
            const SizedBox(height: 22),
            _buildMemberSwitcher(householdVm),
            const SizedBox(height: 20),
            _buildUrgentWarning(vm.records, today),
            _buildHealthStatusCard(
              completedForCard,
              recommendedTotal,
              extraCount,
              memberSuggestion,
            ),
            const SizedBox(height: 20),
            _buildQuickLinks(),
            const SizedBox(height: 20),
            DashboardStatRow(
              upcomingWeekCount: scheduleHi.upcomingWeekCount,
              nearestDate: scheduleHi.nearestDate,
              overdueCount: scheduleHi.overdueCount,
            ),
            const SizedBox(height: 20),
            _buildFamilyOverviewCard(householdVm),
            const SizedBox(height: 20),
            _buildAppointmentSummary(),
            const SizedBox(height: 24),
            _buildSectionHeader(
              "Lời nhắc tiêm chủng",
              "Xem lịch",
              onTap: () => setState(() => _currentIndex = 3),
            ),
            const SizedBox(height: 14),
            _buildReminderList(vm.records, today),
            const SizedBox(height: 24),
            _buildMedicalKnowledge(),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SuggestionsScreen()),
                ),
                icon: const Icon(Icons.lightbulb_outline, color: Colors.white),
                label: const Text(
                  "Xem gợi ý tiêm chủng theo độ tuổi",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(HouseholdViewModel householdVm) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2F80ED), Color(0xFF56CCF2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2F80ED).withOpacity(0.22),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Sổ tiêm chủng gia đình",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  householdVm.selectedMember?.name ?? "Đang tải...",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    householdVm.selectedMember?.relationship ?? "Thành viên",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              _buildTopIconButton(Icons.notifications_none),
              const SizedBox(height: 12),
              CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.primary.withOpacity(0.12),
                child: Text(
                  (householdVm.selectedMember?.name.isNotEmpty == true)
                      ? householdVm.selectedMember!.name[0].toUpperCase()
                      : "?",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopIconButton(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }

  Widget _buildMemberSwitcher(HouseholdViewModel householdVm) {
    final homeCtx = context;
    final sortedMembers = [...householdVm.members]
      ..sort((a, b) {
        if (a.relationship == "Chủ hộ" && b.relationship != "Chủ hộ") return -1;
        if (a.relationship != "Chủ hộ" && b.relationship == "Chủ hộ") return 1;
        return 0;
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Thành viên gia đình",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: sortedMembers.length + 1,
            itemBuilder: (itemContext, index) {
              if (index == sortedMembers.length) {
                return _buildAddMemberButton(homeCtx);
              }

              final member = sortedMembers[index];
              final isSelected = householdVm.selectedMember?.id == member.id;

              return GestureDetector(
                onTap: () {
                  householdVm.selectMember(member);
                  homeCtx.read<VaccinationViewModel>().load(memberId: member.id);
                },
                onLongPress: () {
                  Navigator.pushNamed(
                    homeCtx,
                    AppRoutes.editMember,
                    arguments: member,
                  ).then((_) async {
                    if (!mounted || !homeCtx.mounted) return;
                    final authVm = homeCtx.read<AuthViewModel>();
                    if (authVm.currentUser != null) {
                      await householdVm.loadMembers(authVm.currentUser!.id!);
                      if (!mounted || !homeCtx.mounted) return;
                      await syncUserMedicalData(homeCtx);
                    }
                  });
                },
                child: Container(
                  width: 70,
                  margin: const EdgeInsets.only(right: 16),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primary
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 25,
                          backgroundColor: Colors.blue.shade100,
                          child: Text(
                            member.name[0],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        member.relationship == "Chủ hộ" ? "Tôi" : member.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                          color:
                          isSelected ? AppTheme.primary : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAddMemberButton(BuildContext homeCtx) {
    return GestureDetector(
      onTap: () {
        final authVm = homeCtx.read<AuthViewModel>();
        Navigator.pushNamed(homeCtx, AppRoutes.addMember).then((_) async {
          if (!mounted || !homeCtx.mounted) return;
          if (authVm.currentUser != null) {
            await homeCtx
                .read<HouseholdViewModel>()
                .loadMembers(authVm.currentUser!.id!);
            if (!mounted || !homeCtx.mounted) return;
            await syncUserMedicalData(homeCtx);
          }
        });
      },
      child: SizedBox(
        width: 76,
        child: Column(
          children: [
            Container(
              height: 58,
              width: 58,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.add, color: Colors.grey),
            ),
            const SizedBox(height: 6),
            const Text(
              "Thêm mới",
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUrgentWarning(List<VaccinationRecord> records, DateTime today) {
    final urgentRecords =
    records.where((r) => _calculateStatus(r, today) == "Quá hạn").toList();

    if (urgentRecords.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade50, Colors.orange.shade50],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppTheme.danger,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.priority_high,
                    color: Colors.white, size: 16),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "Thông báo khẩn cấp",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.danger,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...urgentRecords.take(2).map(
                (r) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(width: 36),
                  Expanded(
                    child: Text(
                      "Mũi tiêm ${r.vaccineName} đã đến hạn hoặc sắp quá hạn. Vui lòng thực hiện tiêm chủng ngay.",
                      style: const TextStyle(
                        color: Color(0xFFC53030),
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _shortVaccineDisplayName(String name) {
    final t = name.split(RegExp(r'\s*[—-]\s*')).first.trim();
    if (t.length <= 44) return t;
    return '${t.substring(0, 41)}…';
  }

  Widget _buildHealthStatusCard(
    int completed,
    int recommended,
    int extra,
    MemberVaccineSuggestion? suggestion,
  ) {
    final percent =
        recommended > 0 ? (completed / recommended).clamp(0, 1) * 100 : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2F80ED), Color(0xFF56CCF2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2F80ED).withOpacity(0.28),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            bottom: -18,
            child: Icon(
              Icons.health_and_safety_rounded,
              size: 150,
              color: Colors.white.withOpacity(0.09),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      "Tiến độ tiêm chủng",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    width: 66,
                    height: 66,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.16),
                      shape: BoxShape.circle,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: percent / 100,
                          color: Colors.white,
                          backgroundColor: Colors.white.withOpacity(0.25),
                          strokeWidth: 4.2,
                        ),
                        Text(
                          "${percent.toInt()}%",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                "Chỉ số an toàn: ${percent.toInt()}%",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "$completed",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    " / $recommended",
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (extra > 0) ...[
                    const SizedBox(width: 10),
                    Tooltip(
                      message:
                          'Số mũi đã tiêm nhưng không ghép được với một mục trong '
                          'lịch gợi ý (tên ghi khác, vaccine ngoài danh mục, hoặc '
                          'trùng không khớp). Không nhất thiết là mũi “tự nguyện”.',
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          "+$extra ngoài lịch gợi ý",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const Text(
                "Mũi tiêm đã hoàn thành trên tổng số khuyến nghị (theo lịch gợi ý độ tuổi)",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (suggestion != null && suggestion.vaccines.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  "Gồm các mũi:",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                ...suggestion.vaccines.take(6).map((s) {
                  final done = s.status == VaccineStatus.done;
                  final pending = s.status == VaccineStatus.pending;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Icon(
                            done
                                ? Icons.check_circle_rounded
                                : pending
                                    ? Icons.circle_outlined
                                    : Icons.schedule_rounded,
                            size: 15,
                            color: done
                                ? const Color(0xFFB9FBC0)
                                : Colors.white70,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _shortVaccineDisplayName(s.vaccine.name),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              height: 1.35,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          done
                              ? 'Đã tiêm'
                              : pending
                                  ? 'Chưa'
                                  : 'Hẹn',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                if (suggestion.vaccines.length > 6)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '… và ${suggestion.vaccines.length - 6} mũi khác',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SuggestionsScreen(),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Xem đầy đủ từng loại & mô tả',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white70,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickLinks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Công cụ hỗ trợ",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _buildLinkCard(
              "Cẩm nang\nVắc-xin",
              Icons.menu_book_rounded,
              Colors.orange,
                  () => Navigator.pushNamed(context, AppRoutes.knowledge),
            ),
            const SizedBox(width: 14),
            _buildLinkCard(
              "Đặt lịch\ntiêm chủng",
              Icons.event_available_rounded,
              Colors.green,
                  () => Navigator.pushNamed(context, AppRoutes.booking),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLinkCard(
      String title,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.035),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFamilyOverviewCard(HouseholdViewModel householdVm) {
    if (householdVm.members.length <= 1) return const SizedBox.shrink();

    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.family_restroom,
                  color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                "Thành viên gia đình",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Spacer(),
              Text(
                "${householdVm.members.length} người",
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...householdVm.members.map((m) {
            final isSelected = householdVm.selectedMember?.id == m.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFF3F8FF)
                      : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: isSelected
                          ? AppTheme.primary.withOpacity(0.18)
                          : Colors.grey.shade200,
                      child: Text(
                        m.name.isNotEmpty ? m.name[0].toUpperCase() : "?",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? AppTheme.primary
                              : Colors.grey.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        m.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                    Text(
                      m.relationship,
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.check_circle,
                          color: AppTheme.primary, size: 16),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAppointmentSummary() {
    final householdVm = context.watch<HouseholdViewModel>();
    final apptVm = context.watch<AppointmentViewModel>();
    final mid = householdVm.selectedMember?.id;
    if (mid == null) return const SizedBox.shrink();
    final upcoming = List<Appointment>.from(apptVm.upcomingForMember(mid))
      ..sort((a, b) {
        final da = DateTime.tryParse(a.appointmentDate);
        final db = DateTime.tryParse(b.appointmentDate);
        if (da == null || db == null) return 0;
        return da.compareTo(db);
      });
    if (upcoming.isEmpty) return const SizedBox.shrink();

    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event_available,
                  color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              const Text(
                "Lịch hẹn sắp tới",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _currentIndex = 3),
                child: const Text(
                  "Xem tất cả",
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...upcoming.take(2).map((a) {
            final d = DateTime.tryParse(a.appointmentDate);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  AppointmentDateBadge(
                    date: d,
                    accentColor: Colors.orange,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.vaccineName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${a.appointmentTime} · ${a.center}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 11.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildReminderList(List<VaccinationRecord> records, DateTime today) {
    final upcoming =
    records.where((r) => _calculateStatus(r, today) == "Sắp đến hạn").toList();

    if (upcoming.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            "Hôm nay chưa có lịch tiêm mới",
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      children: upcoming.take(3).map((r) => _buildReminderItem(r)).toList(),
    );
  }

  Widget _buildReminderItem(VaccinationRecord r) {
    final reminderDate = DateTime.tryParse(r.reminderDate);
    final day = reminderDate != null ? reminderDate.day.toString() : "--";
    final month = reminderDate != null ? "Th${reminderDate.month}" : "???";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  month.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF828282),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  day,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.vaccineName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF1F1F1F),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Nhắc lại hàng năm • ${r.location}",
                  style: const TextStyle(
                    color: Color(0xFF828282),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right,
              color: Color(0xFFBDBDBD), size: 20),
        ],
      ),
    );
  }

  Widget _buildMedicalKnowledge() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFFEFF6FF), Colors.white],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD8E7FF)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Kiến thức y khoa",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Tại sao cần tiêm nhắc lại vắc xin cúm mỗi năm?",
                  style: TextStyle(
                    color: Color(0xFF4B6B9C),
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                  ),
                  child: const Text(
                    "Tìm hiểu ngay",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.lightbulb,
                color: Colors.blue, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildVaccinationHistory(
      VaccinationViewModel vm,
      HouseholdViewModel householdVm,
      ) {
    final filteredRecords = _getFilteredRecords(vm.records);

    return Expanded(
      child: Column(
        children: [
          _buildAppHeader(
            'Lịch sử tiêm chủng',
            memberName: householdVm.selectedMember?.name,
          ),
          _buildFilterChips(),
          Expanded(
            child: filteredRecords.isEmpty
                ? _buildEmptyState()
                : _buildHistoryList(filteredRecords),
          ),
        ],
      ),
    );
  }

  Widget _buildAppHeader(String title, {String? memberName}) {
    final sub = memberName?.trim();
    final hasMember = sub != null && sub.isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(width: 42),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (hasMember) ...[
                      const SizedBox(height: 4),
                      Text(
                        sub,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.notifications_none),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildSearchBar(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F6FA),
        borderRadius: BorderRadius.circular(18),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val),
        decoration: InputDecoration(
          hintText: "Tìm kiếm vắc xin, địa điểm...",
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear, size: 18),
            onPressed: () {
              _searchController.clear();
              setState(() => _searchQuery = "");
            },
          )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ["Tất cả", "Đã tiêm", "Sắp đến hạn", "Quá hạn"];

    return Container(
      height: 60,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = selectedFilter == filter;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (val) {
                if (val) setState(() => selectedFilter = filter);
              },
              selectedColor: AppTheme.primary,
              backgroundColor: const Color(0xFFF8FAFC),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              side: BorderSide(
                color: isSelected ? AppTheme.primary : Colors.grey.shade200,
              ),
              showCheckmark: false,
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.vaccines_rounded,
              size: 110,
              color: Color(0xFFD1D5DB),
            ),
            const SizedBox(height: 24),
            const Text(
              "Bạn chưa có mũi tiêm nào",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            const Text(
              "Hãy thêm mũi tiêm đầu tiên để theo dõi lịch tiêm chủng và bảo vệ sức khỏe của bạn.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, height: 1.5),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 230,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddRecordScreen()),
                ),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text("Thêm mũi tiêm"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList(List<VaccinationRecord> records) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    Map<String, List<VaccinationRecord>> grouped = {};
    for (var r in records) {
      final date = DateTime.parse(r.date);
      final year = "Năm ${date.year}";
      grouped.putIfAbsent(year, () => []).add(r);
    }

    final sortedYears = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: sortedYears.length,
      itemBuilder: (context, index) {
        final year = sortedYears[index];
        final yearRecords = grouped[year]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Center(
                child: Text(
                  year,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF828282),
                  ),
                ),
              ),
            ),
            ...yearRecords.map((r) => _buildHistoryItem(r, today)).toList(),
          ],
        );
      },
    );
  }

  Widget _buildHistoryItem(VaccinationRecord r, DateTime today) {
    final status = r.calculateStatus(today);
    final isDone = r.isCompleted;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, AppRoutes.detail, arguments: r),
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              InkWell(
                onTap: () {
                  final vm = context.read<VaccinationViewModel>();
                  vm.update(r.copyWith(isCompleted: !r.isCompleted));
                },
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone
                        ? AppTheme.success.withOpacity(0.12)
                        : Colors.grey.shade100,
                    border: Border.all(
                      color: isDone ? AppTheme.success : Colors.grey.shade300,
                    ),
                  ),
                  child: Icon(
                    isDone ? Icons.check : Icons.circle,
                    color: isDone ? AppTheme.success : Colors.grey.shade300,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            r.vaccineName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15.5,
                              color: isDone
                                  ? Colors.grey
                                  : const Color(0xFF1F1F1F),
                              decoration:
                              isDone ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildStatusTag(status),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      DateFormat('dd/MM/yyyy').format(DateTime.parse(r.date)),
                      style: const TextStyle(
                        color: Color(0xFF828282),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
      String title,
      String action, {
        VoidCallback? onTap,
      }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Text(
            action,
            style: const TextStyle(
              color: AppTheme.primary,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusTag(String status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case "Quá hạn":
        return AppTheme.danger;
      case "Sắp đến hạn":
        return AppTheme.warning;
      case "Hôm nay":
        return Colors.orange;
      case "Đã tiêm":
        return AppTheme.success;
      default:
        return AppTheme.primary;
    }
  }

  String _calculateStatus(VaccinationRecord r, DateTime today) {
    return r.calculateStatus(today);
  }

  List<VaccinationRecord> _getFilteredRecords(List<VaccinationRecord> all) {
    var filtered = all;

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((r) {
        return r.vaccineName.toLowerCase().contains(query) ||
            r.location.toLowerCase().contains(query) ||
            r.note.toLowerCase().contains(query);
      }).toList();
    }

    if (selectedFilter == "Tất cả") return filtered;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return filtered
        .where((r) => _calculateStatus(r, today) == selectedFilter)
        .toList();
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        elevation: 0,
        selectedLabelStyle:
        const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontSize: 10),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: "Trang chủ",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time_outlined),
            activeIcon: Icon(Icons.access_time_filled),
            label: "Lịch sử",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome_outlined),
            activeIcon: Icon(Icons.auto_awesome),
            label: "Trợ lý AI",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: "Lịch hẹn",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: "Hồ sơ",
          ),
        ],
      ),
    );
  }
}