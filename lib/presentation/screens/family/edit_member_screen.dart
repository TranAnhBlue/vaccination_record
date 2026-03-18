import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/household_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../domain/entities/member.dart';
import '../../../core/theme/app_theme.dart';

class EditMemberScreen extends StatefulWidget {
  final Member member;
  const EditMemberScreen({super.key, required this.member});

  @override
  State<EditMemberScreen> createState() => _EditMemberScreenState();
}

class _EditMemberScreenState extends State<EditMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nameController;
  DateTime? _dob;
  late String _gender;
  late String _relationship;
  bool _isLoading = false;

  final List<String> _genders = ["Nam", "Nữ", "Khác"];
  final List<String> _relationships = [
    "Chủ hộ",
    "Vợ/Chồng",
    "Con",
    "Bố/Mẹ",
    "Anh/Chị/Em",
    "Khác",
  ];

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.member.name);
    _gender = _genders.contains(widget.member.gender)
        ? widget.member.gender
        : "Nam";
    _relationship = _relationships.contains(widget.member.relationship)
        ? widget.member.relationship
        : "Khác";
    _dob = _parseFlexibleDate(widget.member.dob);
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FC),
      appBar: AppBar(
        title: const Text(
          "Chỉnh sửa thành viên",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
          ),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: "Xóa thành viên",
            onPressed: _confirmDelete,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.red,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroBanner(),
              const SizedBox(height: 18),
              _buildFormCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle("Thông tin cá nhân"),
                    const SizedBox(height: 16),
                    _buildLabel("Họ và tên"),
                    _buildTextField(
                      controller: nameController,
                      hint: "Nhập họ và tên",
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return "Vui lòng nhập tên";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildLabel("Ngày sinh"),
                    _buildDatePicker(),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildFormCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle("Thông tin khác"),
                    const SizedBox(height: 16),
                    _buildLabel("Giới tính"),
                    _buildGenderChips(),
                    const SizedBox(height: 18),
                    _buildLabel("Quan hệ với chủ hộ"),
                    _buildRelationshipDropdown(),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2F80ED), Color(0xFF56CCF2)],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2F80ED).withOpacity(0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text(
                        "Lưu thay đổi",
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroBanner() {
    final initial =
    widget.member.name.isNotEmpty ? widget.member.name[0].toUpperCase() : "?";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2F80ED), Color(0xFF56CCF2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2F80ED).withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Text(
              initial,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.member.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.member.relationship,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
      child: child,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 16,
        color: Color(0xFF111827),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          color: Color(0xFF6B7280),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              size: 18,
              color: AppTheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _dob == null
                    ? "Chọn ngày sinh"
                    : DateFormat('dd/MM/yyyy').format(_dob!),
                style: TextStyle(
                  color:
                  _dob == null ? const Color(0xFF9CA3AF) : const Color(0xFF111827),
                  fontSize: 14,
                  fontWeight: _dob == null ? FontWeight.normal : FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _genders.map((g) {
        final selected = _gender == g;
        return ChoiceChip(
          label: Text(g),
          selected: selected,
          onSelected: (_) => setState(() => _gender = g),
          showCheckmark: false,
          selectedColor: AppTheme.primary,
          backgroundColor: const Color(0xFFF8FAFC),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
            side: BorderSide(
              color: selected ? AppTheme.primary : const Color(0xFFE5E7EB),
            ),
          ),
          labelStyle: TextStyle(
            color: selected ? Colors.white : const Color(0xFF374151),
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRelationshipDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _relationships.contains(_relationship)
              ? _relationship
              : _relationships.first,
          isExpanded: true,
          borderRadius: BorderRadius.circular(16),
          onChanged: (v) => setState(() => _relationship = v!),
          items: _relationships
              .map((r) => DropdownMenuItem(value: r, child: Text(r)))
              .toList(),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate:
      _dob ?? DateTime.now().subtract(const Duration(days: 365 * 5)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppTheme.primary),
          ),
          child: child!,
        );
      },
    );
    if (d != null) setState(() => _dob = d);
  }

  void _save() async {
    if (!_formKey.currentState!.validate() || _dob == null) {
      if (_dob == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Vui lòng chọn ngày sinh"),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
      return;
    }

    if (_relationship == "Chủ hộ") {
      final now = DateTime.now();
      int age = now.year - _dob!.year;
      if (now.month < _dob!.month ||
          (now.month == _dob!.month && now.day < _dob!.day)) {
        age--;
      }
      if (age < 18) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Chủ hộ phải từ 18 tuổi trở lên"),
            backgroundColor: AppTheme.danger,
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);
    final householdVm = context.read<HouseholdViewModel>();

    try {
      await householdVm.updateMember(
        Member(
          id: widget.member.id,
          userId: widget.member.userId,
          name: nameController.text.trim(),
          dob: DateFormat('yyyy-MM-dd').format(_dob!),
          gender: _gender,
          relationship: _relationship,
        ),
      );

      if (_relationship == "Chủ hộ") {
        final authVm = context.read<AuthViewModel>();
        await authVm.updateProfile(
          nameController.text.trim(),
          DateFormat('yyyy-MM-dd').format(_dob!),
          _gender,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Cập nhật thành viên thành công"),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Lỗi: ${e.toString()}"),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          "Xóa thành viên",
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text(
          "Bạn có chắc muốn xóa \"${widget.member.name}\"?\nTất cả lịch sử tiêm chủng của thành viên này cũng sẽ bị xóa.",
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await _deleteMember();
            },
            child: const Text(
              "Xóa",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMember() async {
    setState(() => _isLoading = true);
    final householdVm = context.read<HouseholdViewModel>();

    try {
      await householdVm.deleteMember(widget.member.id!);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Đã xóa thành viên"),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Lỗi: ${e.toString()}"),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  DateTime? _parseFlexibleDate(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final text = value.trim();

    try {
      if (text.contains('/')) {
        return DateFormat('dd/MM/yyyy').parseStrict(text);
      }
      if (text.contains('-')) {
        return DateTime.parse(text);
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}