import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/vaccination_record.dart';
import '../viewmodels/vaccination_viewmodel.dart';
import '../viewmodels/household_viewmodel.dart';
import '../viewmodels/settings_viewmodel.dart';
import '../../core/theme/app_theme.dart';

class ReminderScreen extends StatefulWidget {
  final VoidCallback? onSeeAll;
  const ReminderScreen({super.key, this.onSeeAll});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<VaccinationViewModel>();
    final householdVm = context.watch<HouseholdViewModel>();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    /// ===== FILTER UPCOMING =====
    final upcoming = vm.records.where((r) {
      final status = _calculateStatus(r, today);
      return status == "Hôm nay" ||
          status == "Sắp đến hạn" ||
          status == "Sắp tới";
    }).toList();

    /// ===== SORT BY REMINDER DATE =====
    upcoming.sort((a, b) {
      final dateA =
          DateTime.tryParse(a.reminderDate) ?? DateTime(9999);
      final dateB =
          DateTime.tryParse(b.reminderDate) ?? DateTime(9999);
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
            _buildGeneralSettings(context),
            const SizedBox(height: 32),

            /// HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Lịch tiêm sắp tới",
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (upcoming.length > 3)
                  TextButton(
                    onPressed: widget.onSeeAll,
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

            const SizedBox(height: 16),

            if (upcoming.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Text(
                    "Hôm nay chưa có lịch tiêm mới",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...upcoming.map(
                    (r) => _buildReminderCard(context, r, today, householdVm),
              ),
          ],
        ),
      ),
    );
  }

  /// ================= SETTINGS =================
  Widget _buildGeneralSettings(BuildContext context) {
    final settingsVm = context.watch<SettingsViewModel>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Cài đặt chung",
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF828282)),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F7FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.notifications_active,
                    color: AppTheme.primary),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Thông báo ứng dụng",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                    Text(
                      "Nhận thông báo đẩy trên điện thoại",
                      style: TextStyle(
                          color: Color(0xFF828282), fontSize: 12),
                    ),
                  ],
                ),
              ),
              Switch(
                value: settingsVm.notificationsEnabled,
                onChanged: (val) => settingsVm.setNotificationsEnabled(val),
                activeColor: Colors.white,
                activeTrackColor: AppTheme.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// ================= CARD =================
  Widget _buildReminderCard(BuildContext context,
      VaccinationRecord r,
      DateTime today,
      HouseholdViewModel householdVm) {
    final reminderDate = DateTime.tryParse(r.reminderDate);
    final status = _calculateStatus(r, today);
    final memberName = r.memberId != null
        ? householdVm.members.where((m) => m.id == r.memberId).map((m) => m.name).firstOrNull
        : null;

    Color statusColor;
    switch (status) {
      case "Quá hạn":
        statusColor = AppTheme.danger;
        break;
      case "Sắp đến hạn":
        statusColor = AppTheme.warning;
        break;
      case "Hôm nay":
        statusColor = Colors.orange;
        break;
      default:
        statusColor = AppTheme.primary;
    }

    final displayDate =
        reminderDate ?? DateTime.tryParse(r.date);

    final diff =
        displayDate
            ?.difference(today)
            .inDays ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (memberName != null) ...[
            Row(
              children: [
                CircleAvatar(
                  radius: 10,
                  backgroundColor: AppTheme.primary.withOpacity(0.15),
                  child: Text(memberName[0], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                ),
                const SizedBox(width: 6),
                Text(memberName, style: const TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 10),
          ],

          /// STATUS
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              ),
              Icon(Icons.vaccines,
                  color: statusColor, size: 24),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            "${r.vaccineName} (Mũi ${r.dose})",
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 18),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              const Icon(Icons.calendar_today,
                  size: 14, color: Color(0xFF828282)),
              const SizedBox(width: 8),
              if (displayDate != null)
                Text(
                  diff == 0
                      ? "Hôm nay, ${DateFormat('dd/MM/yyyy').format(
                      displayDate)}"
                      : diff < 0
                      ? "${DateFormat('dd/MM/yyyy').format(
                      displayDate)} (Quá ${diff.abs()} ngày)"
                      : "${DateFormat('dd/MM/yyyy').format(
                      displayDate)} (Còn $diff ngày)",
                  style: const TextStyle(
                      color: Color(0xFF828282),
                      fontSize: 13),
                )
              else
                const Text("Chưa xác định ngày"),
            ],
          ),

          const SizedBox(height: 4),

          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 14, color: Color(0xFF828282)),
              const SizedBox(width: 8),
              Text(r.location,
                  style: const TextStyle(
                      color: Color(0xFF828282),
                      fontSize: 13)),
            ],
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () =>
                  Navigator.pushNamed(
                      context, "/detail",
                      arguments: r),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Chi tiết",
                style: TextStyle(
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ================= STATUS LOGIC =================
  String _calculateStatus(VaccinationRecord r,
      DateTime today,) {
    if (r.reminderDate.isEmpty) {
      return "Đã tiêm";
    }

    DateTime? reminder;

    /// ✅ parse dd/MM/yyyy
    try {
      reminder = DateFormat('dd/MM/yyyy')
          .parseStrict(r.reminderDate);
    } catch (_) {
      reminder = DateTime.tryParse(r.reminderDate);
    }

    if (reminder == null) {
      return "Đã tiêm";
    }

    final reminderDay =
    DateTime(reminder.year, reminder.month, reminder.day);

    final diff = reminderDay
        .difference(today)
        .inDays;

    if (diff < 0) return "Quá hạn";
    if (diff == 0) return "Hôm nay";
    if (diff <= 3) return "Sắp đến hạn";

    return "Sắp tới";
  }
}