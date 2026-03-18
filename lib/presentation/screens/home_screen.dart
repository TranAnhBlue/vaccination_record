import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/routes/app_routes.dart';
import '../../data/services/ai_service.dart';
import '../viewmodels/vaccination_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0; // Start at Home Overview
  String selectedFilter = "Tất cả";
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String _aiInsight = "Đang tải phân tích từ AI...";
  bool _isInsightLoaded = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final authVm = context.read<AuthViewModel>();
      if (authVm.currentUser != null) {
        context.read<AppointmentViewModel>().load(userId: authVm.currentUser!.id);
        context.read<HouseholdViewModel>().loadMembers(authVm.currentUser!.id!).then((_) {
          final householdVm = context.read<HouseholdViewModel>();
          final memberIds = householdVm.members.map((m) => m.id).whereType<int>().toList();
          // Preload tất cả records vào cache (cho suggestions screen)
          context.read<VaccinationViewModel>().loadAllForMembers(memberIds);
          if (householdVm.selectedMember != null) {
            context.read<VaccinationViewModel>().load(memberId: householdVm.selectedMember!.id).then((_) {
              _fetchAIInsights();
            });
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<VaccinationViewModel>();
    final householdVm = context.watch<HouseholdViewModel>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            if (_currentIndex == 0) _buildOverview(vm, householdVm),
            if (_currentIndex == 1) _buildVaccinationHistory(vm, householdVm),
            if (_currentIndex == 2) const Expanded(child: AIScreen()),
            if (_currentIndex == 3) Expanded(child: ReminderScreen(onSeeAll: () => setState(() => _currentIndex = 1))),
            if (_currentIndex == 4) const Expanded(child: ProfileScreen()),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _currentIndex == 1
          ? FloatingActionButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddRecordScreen())),
              backgroundColor: AppTheme.primary,
              shape: const CircleBorder(),
              child: const Icon(Icons.add, color: Colors.white, size: 30),
            )
          : null,
    );
  }

  // --- OVERVIEW SECTION (Screen 1 in Design) ---
  Widget _buildOverview(VaccinationViewModel vm, HouseholdViewModel householdVm) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    int overdue = 0;
    int upcomingCount = 0;
    int completedCount = 0;
    VaccinationRecord? nextRecord;

    for (var r in vm.records) {
      if (r.isCompleted) {
        completedCount++;
        continue;
      }
      final s = r.calculateStatus(today);
      if (s == "Quá hạn") overdue++;
      if (s == "Sắp đến hạn" || s == "Hôm nay") {
        upcomingCount++;
        if (nextRecord == null) {
          nextRecord = r;
        } else {
          final currentNext = DateTime.tryParse(nextRecord.reminderDate);
          final thisRecord = DateTime.tryParse(r.reminderDate);
          if (currentNext != null && thisRecord != null && thisRecord.isBefore(currentNext)) {
            nextRecord = r;
          }
        }
      }
    }

    final suggestionService = VaccineSuggestionService();
    int recommended = 0;
    int extraCount = 0;
    if (householdVm.selectedMember != null) {
      final memberRecords = vm.recordsForMember(householdVm.selectedMember!.id!);
      final suggestions = suggestionService.getSuggestionsForMember(householdVm.selectedMember!, memberRecords);
      recommended = suggestions.vaccines.length;
      extraCount = suggestions.extraCount;
    }
    if (recommended == 0) recommended = 14; // Fallback

    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(householdVm),
            const SizedBox(height: 24),
            _buildMemberSwitcher(householdVm),
            const SizedBox(height: 24),
            _buildUrgentWarning(vm.records, today),
            _buildHealthStatusCard(completedCount, recommended, extraCount),
            const SizedBox(height: 24),

            // --- AI INSIGHT SECTION ---
            _buildAIInsightCard(),
            const SizedBox(height: 24),

            // --- QUICK LINKS SECTION ---
            _buildQuickLinks(),
            const SizedBox(height: 24),
            _buildQuickStats(upcomingCount, overdue, nextRecord),
            const SizedBox(height: 24),
            _buildFamilyOverviewCard(householdVm),
            const SizedBox(height: 24),
            _buildAppointmentSummary(),
            const SizedBox(height: 32),
            _buildSectionHeader("Lời nhắc tiêm chủng", "Xem lịch", onTap: () => setState(() => _currentIndex = 3)),
            const SizedBox(height: 16),
            _buildReminderList(vm.records, today),
            const SizedBox(height: 32),
            _buildMedicalKnowledge(),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SuggestionsScreen())),
                icon: const Icon(Icons.lightbulb_outline, color: Colors.white),
                label: const Text("Xem gợi ý tiêm chủng theo độ tuổi", style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentSummary() {
    final apptVm = context.read<AppointmentViewModel>();
    final upcoming = apptVm.upcoming;
    if (upcoming.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event_available, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              const Text("Lịch hẹn sắp tới", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _currentIndex = 3),
                child: const Text("Xem tất cả", style: TextStyle(color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...upcoming.take(2).map((a) {
            final d = DateTime.tryParse(a.appointmentDate);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(d != null ? d.day.toString() : '--', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange)),
                      Text(d != null ? 'Th\${d.month}' : '--', style: const TextStyle(fontSize: 9, color: Colors.orange, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(a.vaccineName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text('\${a.appointmentTime} · \${a.center}', style: const TextStyle(color: Colors.grey, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ])),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

    Widget _buildFamilyOverviewCard(HouseholdViewModel householdVm) {
    if (householdVm.members.length <= 1) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.family_restroom, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              const Text("Thành viên gia đình", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Spacer(),
              Text("${householdVm.members.length} người", style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 16),
          ...householdVm.members.map((m) {
            final isSelected = householdVm.selectedMember?.id == m.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: isSelected ? AppTheme.primary.withOpacity(0.2) : Colors.grey.shade100,
                    child: Text(
                      m.name.isNotEmpty ? m.name[0].toUpperCase() : "?",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? AppTheme.primary : Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(m.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            Text(m.relationship, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                          ],
                        ),
                        if (isSelected) ...[
                          const SizedBox(height: 4),
                          const Text("Đang xem", style: TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
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

  Widget _buildMemberSwitcher(HouseholdViewModel householdVm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Thành viên gia đình", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 12),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: householdVm.members.length + 1,
            itemBuilder: (context, index) {
              if (index == householdVm.members.length) {
                return _buildAddMemberButton();
              }
              final member = householdVm.members[index];
              final isSelected = householdVm.selectedMember?.id == member.id;
              
              return GestureDetector(
                onTap: () {
                  householdVm.selectMember(member);
                  context.read<VaccinationViewModel>().load(memberId: member.id);
                },
                onLongPress: () {
                  Navigator.pushNamed(context, AppRoutes.editMember, arguments: member).then((_) {
                    final authVm = context.read<AuthViewModel>();
                    if (authVm.currentUser != null) {
                      householdVm.loadMembers(authVm.currentUser!.id!);
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
                            color: isSelected ? AppTheme.primary : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 25,
                          backgroundColor: Colors.blue.shade100,
                          child: Text(member.name[0], style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        member.relationship == "Chủ hộ" ? "Tôi" : member.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? AppTheme.primary : Colors.black87,
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

  Widget _buildAddMemberButton() {
    return GestureDetector(
      onTap: () {
        final authVm = context.read<AuthViewModel>();
        Navigator.pushNamed(context, AppRoutes.addMember).then((_) {
          if (authVm.currentUser != null) {
            context.read<HouseholdViewModel>().loadMembers(authVm.currentUser!.id!).then((_) {
              final hVm = context.read<HouseholdViewModel>();
              if (hVm.selectedMember != null) {
                context.read<VaccinationViewModel>().load(memberId: hVm.selectedMember!.id);
              }
            });
          }
        });
      },
      child: SizedBox(
        width: 70,
        child: Column(
          children: [
            Container(
              height: 54,
              width: 54,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300, style: BorderStyle.none),
              ),
              child: const Icon(Icons.add, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text("Thêm mới", style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(HouseholdViewModel householdVm) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Sổ tiêm chủng gia đình,", style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text(householdVm.selectedMember?.name ?? "Đang tải...", style: Theme.of(context).textTheme.displayMedium),
          ],
        ),
        Row(
          children: [
            _buildIconButton(Icons.notifications_none),
            const SizedBox(width: 12),
            const CircleAvatar(
              radius: 20,
              backgroundImage: NetworkImage("https://i.pravatar.cc/150?u=family"),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIconButton(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Icon(icon, color: Colors.black54, size: 22),
    );
  }

  Widget _buildHealthStatusCard(int completed, int recommended, int extra) {
    // Logic: If completed >= recommended, it's 100%.
    double percent = recommended > 0 ? (completed / recommended).clamp(0, 1) * 100 : 0;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary, AppTheme.primary.withBlue(250)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.health_and_safety,
              size: 150,
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Tiến độ tiêm chủng",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Chỉ số an toàn: ${percent.toInt()}%",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 60,
                    width: 60,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: percent / 100,
                            color: Colors.white,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            strokeWidth: 4,
                          ),
                          Text(
                            "${percent.toInt()}%",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "$completed",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
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
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "+$extra mũi tự nguyện",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const Text(
                "Mũi tiêm đã hoàn thành trên tổng số khuyến nghị",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(int upcomingCount, int overdue, VaccinationRecord? nextRecord) {
    String nextDateStr = "---";
    if (nextRecord != null) {
      final date = DateTime.tryParse(nextRecord.reminderDate);
      if (date != null) {
        nextDateStr = DateFormat('dd ').format(date) + "Th${date.month}";
      }
    }

    return Row(
      children: [
        Expanded(
          child: _buildStatTile(
            "Sắp tới",
            nextDateStr,
            Icons.calendar_today,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatTile(
            "Trễ hẹn",
            "$overdue mũi",
            Icons.error_outline,
            Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildStatTile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReminderList(List<VaccinationRecord> records, DateTime today) {
    final upcoming = records.where((r) => _calculateStatus(r, today) == "Sắp đến hạn").toList();
    
    if (upcoming.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: const Center(child: Text("Hôm nay chưa có lịch tiêm mới", style: TextStyle(color: Colors.grey))),
      );
    }

    return Column(
      children: upcoming.take(3).map((r) => _buildReminderItem(r)).toList(),
    );
  }

  Widget _buildReminderItem(VaccinationRecord r) {
    DateTime? reminderDate = DateTime.tryParse(r.reminderDate);
    String day = reminderDate != null ? reminderDate.day.toString() : "--";
    String month = reminderDate != null ? "Th${reminderDate.month}" : "???";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(12)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(month.toUpperCase(), style: const TextStyle(fontSize: 10, color: Color(0xFF828282), fontWeight: FontWeight.bold)),
                Text(day, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.vaccineName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1F1F1F))),
                const SizedBox(height: 2),
                Text("Nhắc lại hàng năm • ${r.location}", style: const TextStyle(color: Color(0xFF828282), fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Color(0xFFBDBDBD), size: 20),
        ],
      ),
    );
  }

  Widget _buildMedicalKnowledge() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Kiến thức y khoa", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                const Text(
                  "Tại sao cần tiêm nhắc lại vắc xin cúm mỗi năm?",
                  style: TextStyle(color: Color(0xFF4B6B9C), fontSize: 13),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                  child: const Text("Tìm hiểu ngay", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.lightbulb, color: Colors.blue, size: 28),
          ),
        ],
      ),
    );
  }

  // --- HISTORY SECTION (Screen 2 & 3 in Design) ---
  Widget _buildVaccinationHistory(VaccinationViewModel vm, HouseholdViewModel householdVm) {
    final filteredRecords = _getFilteredRecords(vm.records);

    return Expanded(
      child: Column(
        children: [
          _buildAppHeader("Lịch sử tiêm chủng - ${householdVm.selectedMember?.name ?? ''}"),
          _buildFilterChips(),
          Expanded(
            child: filteredRecords.isEmpty ? _buildEmptyState() : _buildHistoryList(filteredRecords),
          ),
        ],
      ),
    );
  }

  Widget _buildAppHeader(String title) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 32), 
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              _buildIconButton(Icons.notifications_none),
            ],
          ),
          const SizedBox(height: 16),
          _buildSearchBar(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
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
                  })
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
        padding: const EdgeInsets.symmetric(horizontal: 24),
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
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              side: BorderSide(color: isSelected ? AppTheme.primary : Colors.grey.shade200),
              showCheckmark: false,
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Use generated doctor illustration here if possible, or placeholder
          Image.asset(
            "assets/images/doctor_illustration.png", // We'll need to move the generated image here
            width: 200,
            height: 200,
            errorBuilder: (_, __, ___) => const Icon(Icons.vaccines, size: 150, color: Color(0xFFE0E0E0)),
          ),
          const SizedBox(height: 32),
          const Text("Bạn chưa có mũi tiêm nào", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              "Hãy thêm mũi tiêm đầu tiên để theo dõi lịch tiêm chủng và bảo vệ sức khỏe của bạn.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, height: 1.5),
            ),
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: 240,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddRecordScreen())),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text("Thêm mũi tiêm"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(List<VaccinationRecord> records) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Group records by year
    Map<String, List<VaccinationRecord>> grouped = {};
    for (var r in records) {
      DateTime date = DateTime.parse(r.date);
      String year = "Năm ${date.year}";
      grouped.putIfAbsent(year, () => []).add(r);
    }
    
    var sortedYears = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: sortedYears.length,
      itemBuilder: (context, index) {
        String year = sortedYears[index];
        List<VaccinationRecord> yearRecords = grouped[year]!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  year,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF828282)),
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
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, AppRoutes.detail, arguments: r),
        borderRadius: BorderRadius.circular(20),
        child: Row(
          children: [
            // Checkbox for quick completion
            InkWell(
              onTap: () {
                final vm = context.read<VaccinationViewModel>();
                vm.update(r.copyWith(isCompleted: !r.isCompleted));
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone ? AppTheme.success.withOpacity(0.1) : Colors.grey.shade100,
                  border: Border.all(color: isDone ? AppTheme.success : Colors.grey.shade300),
                ),
                child: Icon(
                  isDone ? Icons.check : Icons.circle, 
                  color: isDone ? AppTheme.success : Colors.grey.shade300, 
                  size: 20
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          r.vaccineName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold, 
                            fontSize: 16, 
                            color: isDone ? Colors.grey : const Color(0xFF1F1F1F),
                            decoration: isDone ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                      _buildStatusTag(status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Mũi ${r.dose} • ${DateFormat('dd/MM/yyyy').format(DateTime.parse(r.date))}",
                    style: const TextStyle(color: Color(0xFF828282), fontSize: 12)
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  // --- UTILS ---
  Widget _buildSectionHeader(String title, String action, {VoidCallback? onTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        GestureDetector(
          onTap: onTap,
          child: Text(action, style: const TextStyle(color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildStatusTag(String status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case "Quá hạn": return AppTheme.danger;
      case "Sắp đến hạn": return AppTheme.warning;
      case "Hôm nay": return Colors.orange;
      case "Đã tiêm": return AppTheme.success;
      default: return AppTheme.primary;
    }
  }

  Widget _buildUrgentWarning(List<VaccinationRecord> records, DateTime today) {
    final urgentRecords = records.where((r) => _calculateStatus(r, today) == "Quá hạn").toList();
    
    if (urgentRecords.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.danger.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: AppTheme.danger, shape: BoxShape.circle),
                child: const Icon(Icons.priority_high, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "Thông báo khẩn cấp",
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.danger, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...urgentRecords.take(2).map((r) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const SizedBox(width: 36),
                Expanded(
                  child: Text(
                    "Mũi tiêm ${r.vaccineName} đã đến hạn hoặc sắp quá hạn. Vui lòng thực hiện tiêm chủng ngay.",
                    style: const TextStyle(color: Color(0xFFC53030), fontSize: 13, height: 1.4),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Future<void> _fetchAIInsights() async {
    if (!mounted || _isInsightLoaded) return;
    
    final vm = context.read<VaccinationViewModel>();
    final householdVm = context.read<HouseholdViewModel>();
    
    if (vm.records.isEmpty) {
      if (mounted) setState(() => _aiInsight = "Hãy thêm mũi tiêm để AI có thể đưa ra phân tích cho gia đình bạn.");
      return;
    }

    final summary = vm.records.map((r) {
      final member = householdVm.members.where((m) => m.id == r.memberId).map((m) => m.name).firstOrNull ?? "Ẩn danh";
      return "- $member: ${r.vaccineName} (Mũi ${r.dose}) - Ngày: ${r.date}";
    }).join("\n");

    try {
      final insights = await AIService().getFamilyInsights(summary);
      if (mounted) {
        setState(() {
          _aiInsight = insights;
          _isInsightLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _aiInsight = "Không thể kết nối với trí tuệ nhân tạo lúc này.");
    }
  }

  Widget _buildAIInsightCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFFF0F7FF), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFCCE3FF).withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome, color: AppTheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                "Phân tích Gia đình AI",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _aiInsight,
            style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => setState(() => _currentIndex = 2), // Go to AI tab
            icon: const Icon(Icons.arrow_forward, size: 16),
            label: const Text("Hỏi kỹ hơn", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickLinks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Công cụ hỗ trợ", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildLinkCard(
              "Cẩm nang\nVắc-xin", 
              Icons.menu_book_rounded, 
              Colors.orange, 
              () => Navigator.pushNamed(context, AppRoutes.knowledge)
            ),
            const SizedBox(width: 16),
            _buildLinkCard(
              "Đặt lịch\ntiêm chủng", 
              Icons.event_available_rounded, 
              Colors.green, 
              () => Navigator.pushNamed(context, AppRoutes.booking)
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLinkCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, height: 1.3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _calculateStatus(VaccinationRecord r, DateTime today) {
    return r.calculateStatus(today);
  }

  List<VaccinationRecord> _getFilteredRecords(List<VaccinationRecord> all) {
    var filtered = all;
    
    // Search query filter
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
    
    return filtered.where((r) => _calculateStatus(r, today) == selectedFilter).toList();
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontSize: 10),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: "Trang chủ"),
          BottomNavigationBarItem(icon: Icon(Icons.access_time_outlined), activeIcon: Icon(Icons.access_time_filled), label: "Lịch sử"),
          BottomNavigationBarItem(icon: Icon(Icons.auto_awesome_outlined), activeIcon: Icon(Icons.auto_awesome), label: "Trợ lý AI"),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), activeIcon: Icon(Icons.calendar_today), label: "Lịch hẹn"),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: "Hồ sơ"),
        ],
      ),
    );
  }
}
