import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/household_viewmodel.dart';
import '../../core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final user = authVm.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FC),
      appBar: AppBar(
        title: const Text(
          "Hồ sơ",
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Column(
          children: [
            _buildProfileHero(user?.name, user?.phone),
            const SizedBox(height: 24),
            _buildSectionTitle("Thông tin cá nhân"),
            const SizedBox(height: 12),
            _buildInfoCard([
              _buildInfoRow(
                context,
                Icons.person_outline_rounded,
                "Họ và tên",
                user?.name ?? "Chưa cập nhật",
                    () async {
                  _showEditDialog(
                    context,
                    "Họ và tên",
                    user?.name ?? "",
                        (val) async {
                      await authVm.updateProfile(
                        val,
                        user?.dob ?? "",
                        user?.gender ?? "",
                      );
                      if (context.mounted) {
                        _syncWithHousehold(
                          context,
                          val,
                          user?.dob,
                          user?.gender,
                        );
                      }
                    },
                  );
                },
              ),
              const Divider(height: 1),
              _buildInfoRow(
                context,
                Icons.calendar_month_rounded,
                "Ngày sinh",
                _formatDob(user?.dob),
                    () {
                  _showDatePicker(context, user?.dob ?? "", (val) async {
                    await authVm.updateProfile(
                      user?.name ?? "",
                      val,
                      user?.gender ?? "",
                    );
                    if (context.mounted) {
                      _syncWithHousehold(
                        context,
                        user?.name,
                        val,
                        user?.gender,
                      );
                    }
                  });
                },
              ),
              const Divider(height: 1),
              _buildInfoRow(
                context,
                Icons.wc_rounded,
                "Giới tính",
                user?.gender.isEmpty == true ? "Chưa cập nhật" : user!.gender,
                    () {
                  _showGenderDropdown(context, user?.gender ?? "", (val) async {
                    await authVm.updateProfile(
                      user?.name ?? "",
                      user?.dob ?? "",
                      val,
                    );
                    if (context.mounted) {
                      _syncWithHousehold(
                        context,
                        user?.name,
                        user?.dob,
                        val,
                      );
                    }
                  });
                },
              ),
            ]),
            const SizedBox(height: 24),
            _buildSectionTitle("Quản lý gia đình"),
            const SizedBox(height: 12),
            _buildFamilySection(context),
            const SizedBox(height: 24),
            _buildSectionTitle("Cài đặt tài khoản"),
            const SizedBox(height: 12),
            _buildActionCard([
              _buildActionRow(
                Icons.lock_outline_rounded,
                "Đổi mật khẩu",
                Colors.blue,
                    () {
                  Navigator.pushNamed(context, AppRoutes.changePassword);
                },
              ),
              const Divider(height: 1),
              _buildActionRow(
                Icons.verified_user_outlined,
                "Chính sách bảo mật",
                Colors.indigo,
                    () {},
              ),
              const Divider(height: 1),
              _buildActionRow(
                Icons.logout_rounded,
                "Đăng xuất",
                Colors.red,
                    () {
                  authVm.clearError();
                  Navigator.pushReplacementNamed(context, AppRoutes.login);
                },
              ),
            ]),
            const SizedBox(height: 30),
            const Text(
              "Phiên bản ứng dụng 2.4.1",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 4),
            const Text(
              "© 2026 Personal Vaccination Record",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHero(String? name, String? phone) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
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
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 42,
            backgroundColor: Colors.white,
            child: CircleAvatar(
              radius: 39,
              backgroundImage: NetworkImage("https://i.pravatar.cc/150?u=anh"),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            name ?? "Chưa cập nhật",
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified, color: Colors.white, size: 15),
                const SizedBox(width: 6),
                Text(
                  "ID: VN-${phone ?? "12345678"}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: Color(0xFF111827),
        ),
      ),
    );
  }

  Widget _buildFamilySection(BuildContext context) {
    final householdVm = context.watch<HouseholdViewModel>();
    final members = [...householdVm.members]
      ..sort((a, b) {
        if (a.relationship == "Chủ hộ" && b.relationship != "Chủ hộ") return -1;
        if (a.relationship != "Chủ hộ" && b.relationship == "Chủ hộ") return 1;
        return 0;
      });

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
          ...members.map(
                (m) => Column(
              children: [
                ListTile(
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: CircleAvatar(
                    radius: 22,
                    backgroundColor: AppTheme.primary.withOpacity(0.12),
                    child: Text(
                      m.name.isNotEmpty ? m.name[0].toUpperCase() : "?",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  title: Text(
                    m.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                    ),
                  ),
                  subtitle: Text(
                    m.relationship,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.editMember,
                    arguments: m,
                  ),
                ),
                if (m != members.last) const Divider(height: 1, indent: 16),
              ],
            ),
          ),
          const Divider(height: 1, indent: 16),
          ListTile(
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: const CircleAvatar(
              radius: 22,
              backgroundColor: Color(0xFFF3F4F6),
              child: Icon(Icons.add, color: Colors.grey),
            ),
            title: const Text(
              "Thêm thành viên mới",
              style: TextStyle(
                color: Color(0xFF374151),
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () => Navigator.pushNamed(context, AppRoutes.addMember),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
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
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(
      BuildContext context,
      IconData icon,
      String label,
      String value,
      VoidCallback onTap,
      ) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
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
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Color(0xFF111827),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.edit_outlined, color: Colors.grey, size: 18),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(
      BuildContext context,
      String title,
      String initialValue,
      Function(String) onSave,
      ) {
    final controller = TextEditingController(text: initialValue);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(
          "Cập nhật $title",
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: "Nhập $title mới",
              errorStyle: const TextStyle(fontSize: 11),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return "Vui lòng không để trống";
              }
              if (title == "Họ và tên" && v.trim().length < 2) {
                return "Tên quá ngắn";
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
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

  void _syncWithHousehold(
      BuildContext context,
      String? name,
      String? dob,
      String? gender,
      ) {
    final householdVm = context.read<HouseholdViewModel>();
    try {
      final mainMember =
      householdVm.members.firstWhere((m) => m.relationship == "Chủ hộ");
      householdVm.updateMember(
        mainMember.copyWith(
          name: name,
          dob: dob,
          gender: gender,
        ),
      );
    } catch (_) {}
  }

  Future<void> _showDatePicker(
      BuildContext context,
      String initialValue,
      Function(String) onSave,
      ) async {
    DateTime initialDate;

    try {
      if (initialValue.isNotEmpty) {
        if (initialValue.contains('/')) {
          initialDate = DateFormat('dd/MM/yyyy').parseStrict(initialValue);
        } else if (initialValue.contains('-')) {
          initialDate = DateTime.parse(initialValue);
        } else {
          initialDate = DateTime(2000, 1, 1);
        }
      } else {
        initialDate = DateTime(2000, 1, 1);
      }
    } catch (_) {
      initialDate = DateTime(2000, 1, 1);
    }

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
      onSave(DateFormat('yyyy-MM-dd').format(date));
    }
  }

  void _showGenderDropdown(
      BuildContext context,
      String initialValue,
      Function(String) onSave,
      ) {
    String selected = initialValue.isEmpty ? "Nam" : initialValue;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            "Chọn giới tính",
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: DropdownButtonFormField<String>(
            value: ["Nam", "Nữ", "Khác"].contains(selected) ? selected : "Nam",
            items: ["Nam", "Nữ", "Khác"]
                .map(
                  (e) => DropdownMenuItem(
                value: e,
                child: Text(e),
              ),
            )
                .toList(),
            onChanged: (val) {
              if (val != null) {
                setDialogState(() => selected = val);
              }
            },
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Hủy"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
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
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildActionRow(
      IconData icon,
      String label,
      Color color,
      VoidCallback onTap,
      ) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: label == "Đăng xuất" ? Colors.red : const Color(0xFF111827),
          fontWeight: FontWeight.w600,
          fontSize: 14.5,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
    );
  }

  DateTime? _parseDob(String? dob) {
    if (dob == null || dob.trim().isEmpty) return null;

    final value = dob.trim();

    try {
      if (value.contains('/')) {
        return DateFormat('dd/MM/yyyy').parseStrict(value);
      }
      if (value.contains('-')) {
        return DateTime.parse(value);
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  String _formatDob(String? dob) {
    final date = _parseDob(dob);
    if (date == null) return "Chưa cập nhật";
    return DateFormat('dd/MM/yyyy').format(date);
  }
}