import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/services/vaccine_suggestion_service.dart';
import '../viewmodels/household_viewmodel.dart';
import '../viewmodels/vaccination_viewmodel.dart';
import '../../core/theme/app_theme.dart';
import 'add_record_screen.dart';
import '../../domain/entities/vaccination_record.dart';
import '../../domain/entities/member.dart';
import 'package:intl/intl.dart';

class SuggestionsScreen extends StatelessWidget {
  const SuggestionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final householdVm = context.watch<HouseholdViewModel>();
    final vaccinationVm = context.watch<VaccinationViewModel>();
    final suggestionService = VaccineSuggestionService();

    final selectedMember = householdVm.selectedMember;
    if (selectedMember == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final suggestions = suggestionService.getSuggestions(selectedMember, vaccinationVm.records);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("Gợi ý tiêm chủng", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            color: Colors.white,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppTheme.primary.withOpacity(0.1),
                  child: Text(selectedMember.name[0], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(selectedMember.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text("Độ tuổi: ${_getAgeString(selectedMember.dob)}", style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: suggestions.isEmpty
                ? _buildAllCaughtUp()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: suggestions.length,
                    itemBuilder: (context, index) {
                      final s = suggestions[index];
                      return _buildSuggestionItem(context, s, selectedMember);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _getAgeString(String dob) {
    if (dob.isEmpty) return "Chưa cập nhật";
    final birth = DateTime.tryParse(dob);
    if (birth == null) return "Chưa cập nhật";
    final now = DateTime.now();
    final months = (now.year - birth.year) * 12 + now.month - birth.month;
    if (months < 12) return "$months tháng tuổi";
    return "${(months / 12).floor()} tuổi";
  }

  Widget _buildSuggestionItem(BuildContext context, SuggestedVaccine s, Member selectedMember) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(s.ageRange, style: const TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              if (s.isMandatory)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Text("Bắt buộc", style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(s.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(s.description, style: const TextStyle(color: Colors.grey, fontSize: 14, height: 1.4)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _handleQuickAdd(context, s, selectedMember),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text("Xác nhận đã tiêm", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddRecordScreen(
                        initialVaccineName: s.name,
                        initialDose: 1,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.edit_note, color: AppTheme.primary),
                tooltip: "Chỉnh sửa thông tin trước khi thêm",
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleQuickAdd(BuildContext context, SuggestedVaccine s, var member) async {
    final vm = context.read<VaccinationViewModel>();
    final now = DateTime.now();
    
    try {
      await vm.add(VaccinationRecord(
        vaccineName: s.name,
        dose: 1,
        date: DateFormat('yyyy-MM-dd').format(now),
        reminderDate: "", // Can be updated later
        location: "Trạm y tế địa phương",
        note: "Thêm nhanh từ gợi ý",
        memberId: member.id,
      ));
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Đã thêm '${s.name}' vào hồ sơ của ${member.name}"),
            backgroundColor: AppTheme.success,
            action: SnackBarAction(
              label: "XEM",
              textColor: Colors.white,
              onPressed: () => Navigator.pop(context),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi: $e"), backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  Widget _buildAllCaughtUp() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 80, color: Colors.green.shade200),
          const SizedBox(height: 24),
          const Text("Đã hoàn thành các mũi cơ bản", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Dựa trên độ tuổi và lịch sử tiêm chủng", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
