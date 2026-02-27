import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/routes/app_routes.dart';
import '../viewmodels/vaccination_viewmodel.dart';
import '../../domain/entities/vaccination_record.dart';
import '../../core/theme/app_theme.dart';
import 'add_record_screen.dart';
import 'edit_record_screen.dart';
import '../viewmodels/auth_viewmodel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0; // Start at Home Overview
  String selectedFilter = "Tất cả";

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<VaccinationViewModel>().load());
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<VaccinationViewModel>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            if (_currentIndex == 0) _buildOverview(vm),
            if (_currentIndex == 1) _buildVaccinationHistory(vm),
            if (_currentIndex == 2) const Center(child: Text("Tính năng đang phát triển")),
            if (_currentIndex == 3) const Center(child: Text("Hồ sơ người dùng")),
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
  Widget _buildOverview(VaccinationViewModel vm) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    int overdue = 0;
    int upcoming = 0;
    for (var r in vm.records) {
      final s = _calculateStatus(r, today);
      if (s == "Quá hạn") overdue++;
      if (s == "Sắp đến hạn") upcoming++;
    }

    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildHealthStatusCard(vm.records.length),
            const SizedBox(height: 20),
            _buildQuickStats(upcoming, overdue),
            const SizedBox(height: 32),
            _buildSectionHeader("Lời nhắc tiêm chủng", "Xem lịch"),
            const SizedBox(height: 16),
            _buildReminderList(vm.records, today),
            const SizedBox(height: 32),
            _buildMedicalKnowledge(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Chào buổi sáng,", style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text("Trần Đức Anh", style: Theme.of(context).textTheme.displayMedium),
          ],
        ),
        Row(
          children: [
            _buildIconButton(Icons.notifications_none),
            const SizedBox(width: 12),
            const CircleAvatar(
              radius: 20,
              backgroundImage: NetworkImage("https://i.pravatar.cc/150?u=anh"),
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

  Widget _buildHealthStatusCard(int total) {
    // Logic: If total >= 14 (recommended), it's 100%.
    int recommended = 14;
    double percent = (total / recommended * 100).clamp(0, 100);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF007BFF),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: const Color(0xFF007BFF).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Trạng thái sức khỏe", style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text("Đã bảo vệ ${percent.toInt()}%", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.verified_user, color: Colors.white, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            "$total/$recommended",
            style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 1),
          ),
          const Text("Tổng mũi tiêm khuyến nghị", style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildQuickStats(int upcoming, int overdue) {
    return Row(
      children: [
        Expanded(
          child: _buildStatTile(
            "Sắp tới",
            upcoming > 0 ? "12 Th11" : "---", // Mock date from UI
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
      children: upcoming.map((r) => _buildReminderItem(r)).toList(),
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
  Widget _buildVaccinationHistory(VaccinationViewModel vm) {
    final filteredRecords = _getFilteredRecords(vm.records);

    return Expanded(
      child: Column(
        children: [
          _buildAppHeader("Lịch sử tiêm chủng"),
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 24), // Placeholder for back button if needed
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          _buildIconButton(Icons.notifications_none),
        ],
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
    final status = _calculateStatus(r, today);
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.detail, arguments: r),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getStatusColor(status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.vaccines, color: _getStatusColor(status), size: 24),
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
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1F1F1F)),
                        ),
                      ),
                      _buildStatusTag(status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text("Vaxigrip Tetra", style: TextStyle(color: Color(0xFF828282), fontSize: 12)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.calendar_month, size: 14, color: Color(0xFF828282)),
                      const SizedBox(width: 4),
                      Text(DateFormat('dd/MM/yyyy').format(DateTime.parse(r.date)), style: const TextStyle(fontSize: 13, color: Color(0xFF828282))),
                      const SizedBox(width: 16),
                      const Icon(Icons.numbers, size: 14, color: Color(0xFF828282)),
                      const SizedBox(width: 4),
                      Text("Mũi ${r.dose}", style: const TextStyle(fontSize: 13, color: Color(0xFF828282))),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- UTILS ---
  Widget _buildSectionHeader(String title, String action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(action, style: const TextStyle(color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.bold)),
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
      case "Đã tiêm": return AppTheme.success;
      default: return AppTheme.primary;
    }
  }

  String _calculateStatus(VaccinationRecord r, DateTime today) {
    if (r.reminderDate.isEmpty) return "Đã tiêm";
    final reminder = DateTime.tryParse(r.reminderDate);
    if (reminder == null) return "Đã tiêm";
    if (reminder.isBefore(today)) return "Quá hạn";
    if (reminder.isBefore(today.add(const Duration(days: 7)))) return "Sắp đến hạn";
    return "Đã tiêm";
  }

  List<VaccinationRecord> _getFilteredRecords(List<VaccinationRecord> all) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (selectedFilter == "Tất cả") return all;
    return all.where((r) => _calculateStatus(r, today) == selectedFilter).toList();
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
          BottomNavigationBarItem(icon: Icon(Icons.access_time), activeIcon: Icon(Icons.access_time_filled), label: "Lịch sử"),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), activeIcon: Icon(Icons.calendar_today), label: "Lịch hẹn"),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: "Hồ sơ"),
        ],
      ),
    );
  }
}
