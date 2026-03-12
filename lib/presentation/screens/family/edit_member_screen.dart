import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/household_viewmodel.dart';
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
  final List<String> _relationships = ["Chủ hộ", "Vợ/Chồng", "Con", "Bố/Mẹ", "Anh/Chị/Em", "Khác"];

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.member.name);
    _gender = _genders.contains(widget.member.gender) ? widget.member.gender : "Nam";
    _relationship = _relationships.contains(widget.member.relationship) ? widget.member.relationship : "Khác";
    _dob = DateTime.tryParse(widget.member.dob);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Chỉnh sửa thành viên"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: "Xóa thành viên",
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: AppTheme.primary.withAlpha(26),
                  child: Text(
                    widget.member.name.isNotEmpty ? widget.member.name[0].toUpperCase() : "?",
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.primary),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              _buildLabel("Họ và tên"),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(hintText: "Nhập họ và tên"),
                validator: (v) => v!.isEmpty ? "Vui lòng nhập tên" : null,
              ),
              const SizedBox(height: 24),
              _buildLabel("Ngày sinh"),
              InkWell(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _dob == null ? "Chọn ngày sinh" : DateFormat('dd/MM/yyyy').format(_dob!),
                        style: TextStyle(color: _dob == null ? Colors.grey : Colors.black),
                      ),
                      const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildLabel("Giới tính"),
              Row(
                children: _genders.map((g) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(g),
                      selected: _gender == g,
                      onSelected: (_) => setState(() => _gender = g),
                    ),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 24),
              _buildLabel("Quan hệ với chủ hộ"),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _relationship,
                    isExpanded: true,
                    onChanged: (v) => setState(() => _relationship = v!),
                    items: _relationships.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 48),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: _save,
                  child: const Text("Lưu thay đổi"),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime.now().subtract(const Duration(days: 365 * 5)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (d != null) setState(() => _dob = d);
  }

  void _save() async {
    if (!_formKey.currentState!.validate() || _dob == null) {
      if (_dob == null) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng chọn ngày sinh")));
      return;
    }
    setState(() => _isLoading = true);
    final householdVm = context.read<HouseholdViewModel>();
    try {
      await householdVm.updateMember(Member(
        id: widget.member.id,
        userId: widget.member.userId,
        name: nameController.text.trim(),
        dob: DateFormat('yyyy-MM-dd').format(_dob!),
        gender: _gender,
        relationship: _relationship,
      ));
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cập nhật thành viên thành công"), backgroundColor: AppTheme.success),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi: ${e.toString()}"), backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xóa thành viên"),
        content: Text("Bạn có chắc muốn xóa \"${widget.member.name}\"?\nTất cả lịch sử tiêm chủng của thành viên này cũng sẽ bị xóa."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () async {
              Navigator.pop(ctx);
              await _deleteMember();
            },
            child: const Text("Xóa"),
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
          const SnackBar(content: Text("Đã xóa thành viên"), backgroundColor: AppTheme.danger),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi: ${e.toString()}"), backgroundColor: AppTheme.danger),
        );
      }
    }
  }
}
