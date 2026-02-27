import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/vaccination_record.dart';
import '../../core/theme/app_theme.dart';
import '../viewmodels/vaccination_viewmodel.dart';
import 'edit_record_screen.dart';

class VaccinationDetailScreen extends StatelessWidget {
  final VaccinationRecord initialRecord;

  const VaccinationDetailScreen({super.key, required this.initialRecord});

  @override
  Widget build(BuildContext context) {
    // Watch for changes in the ViewModel
    final vm = context.watch<VaccinationViewModel>();
    
    // Find the latest version of this record
    final VaccinationRecord record = vm.records.firstWhere(
      (r) => r.id == initialRecord.id,
      orElse: () => initialRecord,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Chi tiết tiêm chủng",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(record),
            const SizedBox(height: 32),
            const Text(
              "Thông tin mũi tiêm",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F1F1F)),
            ),
            const SizedBox(height: 16),
            _buildInfoList(record),
            const SizedBox(height: 32),
            const Text(
              "Hình ảnh chứng nhận",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F1F1F)),
            ),
            const SizedBox(height: 16),
            _buildImageAttachment(record),
            const SizedBox(height: 48),
            _buildActionButtons(context, record),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(VaccinationRecord record) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    String status = "Đã tiêm";
    Color statusColor = AppTheme.success;
    IconData statusIcon = Icons.check;

    // 1. Check if the current injection is in the future
    final injectionDate = DateTime.tryParse(record.date);
    if (injectionDate != null && injectionDate.isAfter(today)) {
      final diff = injectionDate.difference(today).inDays;
      if (diff < 3) {
        status = "Quá hạn";
        statusColor = AppTheme.danger;
        statusIcon = Icons.priority_high;
      } else {
        status = "Sắp đến hạn";
        statusColor = AppTheme.warning;
        statusIcon = Icons.calendar_today;
      }
    } 
    // 2. Check the reminder date for the next dose
    else if (record.reminderDate.isNotEmpty) {
      final reminder = DateTime.tryParse(record.reminderDate);
      if (reminder != null) {
        if (reminder.isBefore(today)) {
          status = "Quá hạn";
          statusColor = AppTheme.danger;
          statusIcon = Icons.priority_high;
        } else {
          final diff = reminder.difference(today).inDays;
          if (diff < 3) {
            status = "Quá hạn";
            statusColor = AppTheme.danger;
            statusIcon = Icons.priority_high;
          } else if (diff < 7) {
            status = "Sắp đến hạn";
            statusColor = AppTheme.warning;
            statusIcon = Icons.notification_important;
          }
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      status,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: statusColor),
                    ),
                    if (status == "Quá hạn") ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppTheme.danger, borderRadius: BorderRadius.circular(4)),
                        child: const Text("KHẨN CẤP", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
                Text(
                  "Mũi ${record.dose} - ${record.vaccineName}",
                  style: const TextStyle(color: Color(0xFF828282), fontSize: 13),
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.vaccines_outlined, "Loại vắc xin", record.vaccineName),
          _divider(),
          _buildInfoRow(Icons.numbers_outlined, "Mũi số", record.dose.toString()),
          _divider(),
          _buildInfoRow(Icons.calendar_month_outlined, "Ngày tiêm", DateFormat('dd/MM/yyyy').format(DateTime.parse(record.date))),
          _divider(),
          _buildInfoRow(Icons.location_on_outlined, "Địa điểm", record.location),
          _divider(),
          _buildInfoRow(Icons.bubble_chart_outlined, "Phản ứng sau tiêm", record.note.isEmpty ? "Không có" : record.note),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF828282), size: 22),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(color: Color(0xFF828282), fontSize: 14)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1F1F1F)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(height: 1, color: Color(0xFFF1F5F9), indent: 56);

  Widget _buildImageAttachment(VaccinationRecord record) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: record.imagePath == null || record.imagePath!.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_outlined, color: Color(0xFFBDBDBD), size: 48),
                    SizedBox(height: 8),
                    Text("Chưa có hình ảnh chứng nhận", style: TextStyle(color: Color(0xFFBDBDBD), fontSize: 13)),
                  ],
                ),
              )
            : Image.file(File(record.imagePath!), fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, VaccinationRecord record) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditRecordScreen(record: record))),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Chỉnh sửa thông tin", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed: () => _showDeleteConfirmation(context, record),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.danger,
              side: const BorderSide(color: Color(0xFFFFECEC)),
              backgroundColor: const Color(0xFFFFECEC),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Xóa mũi tiêm", style: TextStyle(fontWeight: FontWeight.bold)),
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(color: Color(0xFFFFFBFA), shape: BoxShape.circle),
              child: const Icon(Icons.delete_outline, color: AppTheme.danger, size: 40),
            ),
            const SizedBox(height: 24),
            const Text(
              "Xác nhận xóa mũi tiêm",
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF1B1B1B)),
            ),
            const SizedBox(height: 12),
            const Text(
              "Bạn có chắc chắn muốn xóa mũi tiêm này không? Hành động này không thể hoàn tác.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF828282), fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  await context.read<VaccinationViewModel>().delete(record.id!);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Đã xóa mũi tiêm thành công"), backgroundColor: AppTheme.success),
                    );
                    Navigator.pop(ctx); // Close dialog
                    Navigator.pop(context); // Close detail screen
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.danger,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Xác nhận xóa", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Hủy bỏ", style: TextStyle(color: Color(0xFF828282), fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
