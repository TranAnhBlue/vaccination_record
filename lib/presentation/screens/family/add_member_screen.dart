import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/household_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../domain/entities/member.dart';
import '../../../core/theme/app_theme.dart';

class AddMemberScreen extends StatefulWidget {
  const AddMemberScreen({super.key});

  @override
  State<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  DateTime? _dob;
  String _gender = "Nam";
  String _relationship = "Con";
  bool _isLoading = false;

  final List<String> _genders = ["Nam", "Nữ", "Khác"];
  final List<String> _relationships = ["Vợ/Chồng", "Con", "Bố/Mẹ", "Anh/Chị/Em", "Khác"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Thêm thành viên"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                      onSelected: (val) => setState(() => _gender = g),
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
                    value: _relationships.contains(_relationship) ? _relationship : _relationships.first,
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
                  child: const Text("Thêm thành viên"),
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
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (d != null) setState(() => _dob = d);
  }

  void _save() async {
    if (!_formKey.currentState!.validate() || _dob == null) {
      if (_dob == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng chọn ngày sinh")));
      }
      return;
    }

    setState(() => _isLoading = true);
    final authVm = context.read<AuthViewModel>();
    final householdVm = context.read<HouseholdViewModel>();

    try {
      await householdVm.addMember(Member(
        userId: authVm.currentUser!.id!,
        name: nameController.text.trim(),
        dob: DateFormat('yyyy-MM-dd').format(_dob!),
        gender: _gender,
        relationship: _relationship,
      ));
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Thêm thành viên thành công"), backgroundColor: AppTheme.success),
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
