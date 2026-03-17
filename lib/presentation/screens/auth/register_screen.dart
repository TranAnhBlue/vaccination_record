import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/routes/app_routes.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _agreeToTerms = false;

  DateTime? _selectedDob;
  String _selectedGender = '';

  final List<String> _genderOptions = ['Nam', 'Nữ', 'Khác'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthViewModel>().clearError();
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(1990, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Chọn ngày sinh',
    );
    if (picked != null) setState(() => _selectedDob = picked);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();

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
          'Đăng ký',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 10),
              // Logo
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.vaccines_outlined, size: 60, color: AppTheme.primary),
              ),
              const SizedBox(height: 20),
              const Text(
                'Tạo tài khoản mới',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A)),
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Nhập đầy đủ thông tin để theo dõi lịch tiêm chủng cho cả gia đình.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Color(0xFF828282)),
                ),
              ),
              const SizedBox(height: 28),

              // ── Họ và tên ────────────────────────────────────────────────
              _fieldLabel('Họ và tên *'),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(hintText: 'Nguyễn Văn A'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Vui lòng nhập họ tên' : null,
              ),
              const SizedBox(height: 20),

              // ── Số điện thoại ────────────────────────────────────────────
              _fieldLabel('Số điện thoại *'),
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(hintText: '09xx xxx xxx'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Vui lòng nhập số điện thoại';
                  if (v.trim().length < 10) return 'Số điện thoại không hợp lệ';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // ── Ngày sinh ────────────────────────────────────────────────
              _fieldLabel('Ngày sinh *'),
              InkWell(
                onTap: _pickDob,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade50,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.cake_outlined, color: AppTheme.primary, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        _selectedDob == null
                            ? 'Chọn ngày sinh'
                            : DateFormat('dd/MM/yyyy').format(_selectedDob!),
                        style: TextStyle(
                          fontSize: 14,
                          color: _selectedDob == null ? Colors.grey : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_selectedDob != null) ...[
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      _getAgeString(_selectedDob!),
                      style: const TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // ── Giới tính ────────────────────────────────────────────────
              _fieldLabel('Giới tính *'),
              Row(
                children: _genderOptions.map((g) {
                  final isSelected = _selectedGender == g;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () => setState(() => _selectedGender = g),
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.primary : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppTheme.primary : Colors.grey.shade300,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              g,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black87,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // ── Mật khẩu ────────────────────────────────────────────────
              _fieldLabel('Mật khẩu *'),
              TextFormField(
                controller: passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu';
                  if (v.length < 6) return 'Mật khẩu tối thiểu 6 ký tự';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // ── Xác nhận mật khẩu ────────────────────────────────────────
              _fieldLabel('Xác nhận mật khẩu *'),
              TextFormField(
                controller: confirmController,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                validator: (v) {
                  if (v != passwordController.text) return 'Mật khẩu xác nhận không khớp';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // ── Terms ────────────────────────────────────────────────────
              Row(
                children: [
                  SizedBox(
                    width: 24, height: 24,
                    child: Checkbox(
                      value: _agreeToTerms,
                      onChanged: (val) => setState(() => _agreeToTerms = val ?? false),
                      activeColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: 'Tôi đồng ý với ',
                        style: TextStyle(fontSize: 13, color: Color(0xFF4F4F4F)),
                        children: [
                          TextSpan(
                            text: 'Điều khoản & Chính sách bảo mật',
                            style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // ── Register Button ──────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: (!_agreeToTerms || vm.loading) ? null : _submit,
                  child: vm.loading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Đăng ký', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.lock_outline, size: 14, color: Color(0xFF828282)),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Thông tin được bảo mật tuyệt đối theo tiêu chuẩn y tế.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Color(0xFF828282)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Đã có tài khoản? ', style: TextStyle(color: Color(0xFF828282))),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text('Đăng nhập ngay', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ngày sinh'), backgroundColor: Colors.orange),
      );
      return;
    }

    if (_selectedGender.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn giới tính'), backgroundColor: Colors.orange),
      );
      return;
    }

    final vm = context.read<AuthViewModel>();
    final success = await vm.register(
      nameController.text.trim(),
      phoneController.text.trim(),
      passwordController.text,
      dob: DateFormat('yyyy-MM-dd').format(_selectedDob!),
      gender: _selectedGender,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: AppTheme.success, content: Text('Đăng ký thành công!')),
      );
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (r) => false);
    } else if (vm.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppTheme.danger, content: Text(vm.error!)),
      );
    }
  }

  String _getAgeString(DateTime dob) {
    final now = DateTime.now();
    final months = (now.year - dob.year) * 12 + now.month - dob.month;
    if (months < 12) return '$months tháng tuổi';
    final years = (months / 12).floor();
    return '$years tuổi';
  }

  Widget _fieldLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 4),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF333333))),
      ),
    );
  }
}
