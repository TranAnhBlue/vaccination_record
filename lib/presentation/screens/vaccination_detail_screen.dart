import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/vaccination_record.dart';
import '../../core/theme/app_theme.dart';
import '../viewmodels/vaccination_viewmodel.dart';
import '../viewmodels/household_viewmodel.dart';
import '../sync/user_medical_data_sync.dart';
import '../widgets/certificate_card.dart';
import 'edit_record_screen.dart';

class VaccinationDetailScreen extends StatelessWidget {
  final VaccinationRecord initialRecord;

  const VaccinationDetailScreen({
    super.key,
    required this.initialRecord,
  });

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<VaccinationViewModel>();
    final householdVm = context.watch<HouseholdViewModel>();

    final VaccinationRecord record = vm.records.firstWhere(
          (r) => r.id == initialRecord.id,
      orElse: () => initialRecord,
    );

    final matchedMembers =
    householdVm.members.where((m) => m.id == record.memberId).toList();
    final memberName =
    matchedMembers.isNotEmpty ? matchedMembers.first.name : "Người dùng";

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.black87,
              size: 18,
            ),
          ),
        ),
        title: const Text(
          "Chi tiết tiêm chủng",
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(record),
            if (record.calculateStatus(_todayOnly()) == "Đã tiêm") ...[
              const SizedBox(height: 20),
              CertificateCard(record: record, memberName: memberName),
            ],
            const SizedBox(height: 24),
            _buildSectionTitle("Thông tin mũi tiêm"),
            const SizedBox(height: 12),
            _buildInfoList(record),
            const SizedBox(height: 24),
            _buildSectionTitle("Hình ảnh chứng nhận"),
            const SizedBox(height: 12),
            _buildImageAttachment(record),
            const SizedBox(height: 28),
            _buildActionButtons(context, record),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  DateTime _todayOnly() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: Color(0xFF111827),
      ),
    );
  }

  Widget _buildStatusCard(VaccinationRecord record) {
    final status = record.calculateStatus(_todayOnly());

    Color statusColor;
    IconData statusIcon;
    List<Color> gradient;

    switch (status) {
      case "Quá hạn":
        statusColor = AppTheme.danger;
        statusIcon = Icons.priority_high_rounded;
        gradient = [const Color(0xFFFF6B6B), const Color(0xFFFF8E8E)];
        break;
      case "Hôm nay":
        statusColor = Colors.orange;
        statusIcon = Icons.today_rounded;
        gradient = [const Color(0xFFF59E0B), const Color(0xFFFBBF24)];
        break;
      case "Sắp đến hạn":
        statusColor = AppTheme.warning;
        statusIcon = Icons.notifications_active_rounded;
        gradient = [const Color(0xFFF59E0B), const Color(0xFFFCD34D)];
        break;
      case "Sắp tới":
        statusColor = AppTheme.primary;
        statusIcon = Icons.calendar_today_rounded;
        gradient = [const Color(0xFF2F80ED), const Color(0xFF56CCF2)];
        break;
      default:
        statusColor = AppTheme.success;
        statusIcon = Icons.verified_rounded;
        gradient = [const Color(0xFF22C55E), const Color(0xFF4ADE80)];
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(statusIcon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      status,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                    if (status == "Quá hạn") ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          "KHẨN CẤP",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  record.vaccineName,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13.5,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoList(VaccinationRecord record) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow(
            Icons.vaccines_outlined,
            "Loại vắc xin",
            record.vaccineName,
          ),
          _divider(),
          _buildInfoRow(
            Icons.calendar_month_rounded,
            "Ngày tiêm",
            DateFormat('dd/MM/yyyy').format(DateTime.parse(record.date)),
          ),
          _divider(),
          _buildInfoRow(
            Icons.location_on_outlined,
            "Địa điểm",
            record.location.isEmpty ? "Chưa cập nhật" : record.location,
          ),
          _divider(),
          _buildInfoRow(
            Icons.medical_information_outlined,
            "Phản ứng sau tiêm",
            record.note.isEmpty ? "Không có" : record.note,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                    color: Color(0xFF111827),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return const Divider(
      height: 1,
      color: Color(0xFFF1F5F9),
      indent: 16,
      endIndent: 16,
    );
  }

  Widget _buildImageAttachment(VaccinationRecord record) {
    final hasImage =
        record.imagePath != null && record.imagePath!.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: hasImage
            ? Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              File(record.imagePath!),
              fit: BoxFit.cover,
            ),
            Positioned(
              right: 12,
              top: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.image_outlined,
                      color: Colors.white,
                      size: 14,
                    ),
                    SizedBox(width: 6),
                    Text(
                      "Chứng nhận",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        )
            : Container(
          color: const Color(0xFFF8FAFC),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image_not_supported_outlined,
                  color: Color(0xFFBDBDBD),
                  size: 48,
                ),
                SizedBox(height: 10),
                Text(
                  "Chưa có hình ảnh chứng nhận",
                  style: TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, VaccinationRecord record) {
    final vm = context.read<VaccinationViewModel>();

    return Column(
      children: [
        if (!record.isCompleted) ...[
          SizedBox(
            width: double.infinity,
            height: 54,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF22C55E), Color(0xFF4ADE80)],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.success.withOpacity(0.22),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  vm.update(record.copyWith(isCompleted: true));
                },
                icon: const Icon(
                  Icons.check_circle_outline_rounded,
                  color: Colors.white,
                ),
                label: const Text(
                  "Xác nhận đã tiêm",
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
        SizedBox(
          width: double.infinity,
          height: 54,
          child: OutlinedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EditRecordScreen(record: record),
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primary,
              side: BorderSide(color: AppTheme.primary.withOpacity(0.35)),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: const Text(
              "Chỉnh sửa thông tin",
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: TextButton(
            onPressed: () => _showDeleteConfirmation(context, record),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.danger,
            ),
            child: const Text(
              "Xóa mũi tiêm",
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(BuildContext context, VaccinationRecord record) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: Color(0xFFFFF1F2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: AppTheme.danger,
                size: 36,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              "Xác nhận xóa mũi tiêm",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Bạn có chắc chắn muốn xóa mũi tiêm này không? Hành động này không thể hoàn tác.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF828282),
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  await context.read<VaccinationViewModel>().delete(
                        record.id!,
                        memberId: record.memberId,
                      );
                  if (!context.mounted) return;
                  await syncUserMedicalData(context);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Đã xóa mũi tiêm thành công"),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.danger,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  "Xác nhận xóa",
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  "Hủy bỏ",
                  style: TextStyle(
                    color: Color(0xFF828282),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}