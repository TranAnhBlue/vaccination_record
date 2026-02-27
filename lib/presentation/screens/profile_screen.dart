import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../../core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final user = authVm.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("Hồ sơ"),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage("https://i.pravatar.cc/150?u=anh"),
            ),
            const SizedBox(height: 16),
            Text(user?.name ?? "Trần Đức Anh", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.verified, color: Colors.blue, size: 16),
                const SizedBox(width: 4),
                Text("ID: VN-${user?.phone ?? "12345678"}", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 40),
            _buildSectionTitle("Thông tin cá nhân"),
            const SizedBox(height: 16),
            _buildInfoCard([
              _buildInfoRow(context, Icons.person_outline, "Họ và tên", user?.name ?? "Chưa cập nhật", () {
                _showEditDialog(context, "Họ và tên", user?.name ?? "", (val) {
                  authVm.updateProfile(val, user?.dob ?? "", user?.gender ?? "");
                });
              }),
              const Divider(height: 1),
              _buildInfoRow(context, Icons.calendar_month_outlined, "Ngày sinh", user?.dob.isEmpty == true ? "Chưa cập nhật" : user!.dob, () {
                _showDatePicker(context, user?.dob ?? "", (val) {
                  authVm.updateProfile(user?.name ?? "", val, user?.gender ?? "");
                });
              }),
              const Divider(height: 1),
              _buildInfoRow(context, Icons.wc_outlined, "Giới tính", user?.gender.isEmpty == true ? "Chưa cập nhật" : user!.gender, () {
                _showGenderDropdown(context, user?.gender ?? "", (val) {
                  authVm.updateProfile(user?.name ?? "", user?.dob ?? "", val);
                });
              }),
            ]),
            const SizedBox(height: 32),
            _buildSectionTitle("Cài đặt tài khoản"),
            const SizedBox(height: 16),
            _buildActionCard([
              _buildActionRow(Icons.lock_outline, "Đổi mật khẩu", Colors.blue, () {
                Navigator.pushNamed(context, AppRoutes.changePassword);
              }),
              const Divider(height: 1),
              _buildActionRow(Icons.verified_user_outlined, "Chính sách bảo mật", Colors.blue, () {}),
              const Divider(height: 1),
              _buildActionRow(Icons.logout, "Đăng xuất", Colors.red, () {
                authVm.clearError();
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              }),
            ]),
            const SizedBox(height: 48),
            const Text("Phiên bản ứng dụng 2.4.1", style: TextStyle(color: Colors.grey, fontSize: 12)),
            const Text("© 2026 Personal Vaccination Record", style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: Colors.blue, size: 20),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Color(0xFF828282), fontSize: 12)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
            const Spacer(),
            const Icon(Icons.edit_outlined, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, String title, String initialValue, Function(String) onSave) {
    final controller = TextEditingController(text: initialValue);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Cập nhật $title"),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: "Nhập $title mới",
              errorStyle: const TextStyle(fontSize: 11),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return "Vui lòng không để trống";
              if (title == "Họ và tên" && v.trim().length < 2) return "Tên quá ngắn";
              return null;
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                onSave(controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text("Lưu"),
          ),
        ],
      ),
    );
  }

  Future<void> _showDatePicker(BuildContext context, String initialValue, Function(String) onSave) async {
    DateTime initialDate;
    try {
      if (initialValue.isNotEmpty && initialValue.contains('/')) {
        final parts = initialValue.split('/');
        initialDate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
      } else {
        initialDate = DateTime(2000, 1, 1);
      }
    } catch (e) {
      initialDate = DateTime(2000, 1, 1);
    }
    
    // Ensure initialDate is not in the future
    if (initialDate.isAfter(DateTime.now())) {
      initialDate = DateTime.now();
    }

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: "Chọn ngày sinh",
      confirmText: "Chọn",
      cancelText: "Hủy",
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppTheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      onSave(DateFormat('dd/MM/yyyy').format(date));
    }
  }

  void _showGenderDropdown(BuildContext context, String initialValue, Function(String) onSave) {
    String selected = initialValue.isEmpty ? "Nam" : initialValue;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Chọn giới tính"),
          content: DropdownButtonFormField<String>(
            value: ["Nam", "Nữ", "Khác"].contains(selected) ? selected : "Nam",
            items: ["Nam", "Nữ", "Khác"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (val) {
              if (val != null) setDialogState(() => selected = val);
            },
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
            ElevatedButton(
              onPressed: () {
                onSave(selected);
                Navigator.pop(context);
              },
              child: const Text("Lưu"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildActionRow(IconData icon, String label, Color color, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(label, style: TextStyle(color: label == "Đăng xuất" ? Colors.red : const Color(0xFF333333), fontWeight: FontWeight.w500, fontSize: 14)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
