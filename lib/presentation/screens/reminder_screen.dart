import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../viewmodels/vaccination_viewmodel.dart';
import '../../core/theme/app_theme.dart';
import '../screens/vaccination_detail_screen.dart';

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<VaccinationViewModel>();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final upcoming = vm.records.where((r) {
      if (r.reminderDate.isEmpty) return false;
      final date = DateTime.tryParse(r.reminderDate);
      return date != null && (date.isAfter(today) || date.isAtSameMomentAs(today));
    }).toList();

    // Sort by reminder date
    upcoming.sort((a, b) {
      final dateA = DateTime.tryParse(a.reminderDate) ?? DateTime(9999);
      final dateB = DateTime.tryParse(b.reminderDate) ?? DateTime(9999);
      return dateA.compareTo(dateB);
    });

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("Lịch hẹn"),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGeneralSettings(),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Lịch tiêm sắp tới", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                if (upcoming.length > 3)
                  TextButton(
                    onPressed: () => setState(() => _showAll = !_showAll),
                    child: Text(
                      _showAll ? "Thu gọn" : "Xem tất cả",
                      style: const TextStyle(color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (upcoming.isEmpty)
              const Center(child: Padding(
                padding: EdgeInsets.all(40.0),
                child: Text("Hôm nay chưa có lịch tiêm mới", style: TextStyle(color: Colors.grey)),
              ))
            else
              ...(_showAll ? upcoming : upcoming.take(3)).map((r) => _buildReminderCard(context, r, today)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Cài đặt chung", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF828282))),
        const SizedBox(height: 16),
        Container(
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
                decoration: BoxDecoration(color: const Color(0xFFF0F7FF), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.notifications_active, color: AppTheme.primary, size: 24),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Thông báo ứng dụng", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text("Nhận thông báo đẩy trên điện thoại", style: TextStyle(color: Color(0xFF828282), fontSize: 12)),
                  ],
                ),
              ),
              Switch(
                value: true,
                onChanged: (v) {},
                activeColor: Colors.white,
                activeTrackColor: AppTheme.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReminderCard(BuildContext context, dynamic r, DateTime today) {
    final reminderDateStr = r.reminderDate;
    final reminderDate = DateTime.tryParse(reminderDateStr);
    final diff = reminderDate?.difference(today).inDays ?? 0;
    
    String status = "Sắp tới";
    Color statusColor = AppTheme.primary;
    if (diff == 0) {
      status = "Đã đến hạn";
      statusColor = AppTheme.primary;
    } else if (diff < 0) {
      status = "Quá hạn";
      statusColor = AppTheme.danger;
    } else if (diff <= 7) {
      status = "Sắp đến hạn";
      statusColor = Colors.orange;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
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
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              Icon(Icons.vaccines, color: statusColor, size: 24),
            ],
          ),
          const SizedBox(height: 12),
          Text("${r.vaccineName} (Mũi ${r.dose})", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 14, color: Color(0xFF828282)),
              const SizedBox(width: 8),
              Text(
                diff == 0 ? "Hôm nay, ${DateFormat('dd/MM/yyyy').format(reminderDate!)}" : 
                "${DateFormat('dd/MM/yyyy').format(reminderDate!)} (Còn $diff ngày)",
                style: const TextStyle(color: Color(0xFF828282), fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF828282)),
              const SizedBox(width: 8),
              Text(r.location, style: const TextStyle(color: Color(0xFF828282), fontSize: 13)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, "/detail", arguments: r),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Chi tiết", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }
}
