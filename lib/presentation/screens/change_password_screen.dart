import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../../core/theme/app_theme.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _showOld = false;
  bool _showNew = false;
  bool _showConfirm = false;

  bool _hasMinLength = false;
  bool _hasLetterAndNumber = false;
  bool _hasSpecialChar = false;

  @override
  void initState() {
    super.initState();
    _newPasswordController.addListener(_validatePassword);
  }

  void _validatePassword() {
    final pass = _newPasswordController.text;
    setState(() {
      _hasMinLength = pass.length >= 8;
      _hasLetterAndNumber = pass.contains(RegExp(r'[A-Za-z]')) && pass.contains(RegExp(r'[0-9]'));
      _hasSpecialChar = pass.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    });
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_hasMinLength || !_hasLetterAndNumber) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng tuân thủ các yêu cầu bảo mật")),
      );
      return;
    }

    final vm = context.read<AuthViewModel>();
    final success = await vm.changePassword(
      _oldPasswordController.text,
      _newPasswordController.text,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đổi mật khẩu thành công"), backgroundColor: AppTheme.success),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(vm.error ?? "Mật khẩu cũ không chính xác hoặc đã xảy ra lỗi"),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthViewModel>().loading;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Đổi mật khẩu"),
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Tạo mật khẩu mới", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text(
                "Vui lòng tạo mật khẩu mới để bảo mật thông tin tiêm chủng và hồ sơ sức khỏe của bạn.",
                style: TextStyle(color: Color(0xFF828282), fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 32),
              _buildLabel("Mật khẩu ban đầu"),
              _buildPasswordField(_oldPasswordController, "Nhập mật khẩu ban đầu", _showOld, () => setState(() => _showOld = !_showOld)),
              const SizedBox(height: 20),
              _buildLabel("Mật khẩu mới"),
              _buildPasswordField(_newPasswordController, "Nhập mật khẩu mới", _showNew, () => setState(() => _showNew = !_showNew)),
              const SizedBox(height: 20),
              _buildLabel("Xác nhận mật khẩu mới"),
              _buildPasswordField(_confirmPasswordController, "Nhập lại mật khẩu mới", _showConfirm, () => setState(() => _showConfirm = !_showConfirm), 
                validator: (v) {
                  if (v != _newPasswordController.text) return "Mật khẩu xác nhận không khớp";
                  return null;
                }
              ),
              const SizedBox(height: 32),
              const Text("Yêu cầu bảo mật:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF333333))),
              const SizedBox(height: 16),
              _buildRequirementRow("Ít nhất 8 ký tự", _hasMinLength),
              _buildRequirementRow("Bao gồm chữ cái và chữ số", _hasLetterAndNumber),
              _buildRequirementRow("Bao gồm ký tự đặc biệt (!@#...)", _hasSpecialChar),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: loading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("Cập nhật mật khẩu", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF333333))),
    );
  }

  Widget _buildPasswordField(TextEditingController controller, String hint, bool show, VoidCallback toggle, {String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      obscureText: !show,
      validator: validator ?? (v) => v!.isEmpty ? "Vui lòng nhập mật khẩu" : null,
      decoration: InputDecoration(
        hintText: hint,
        suffixIcon: IconButton(
          icon: Icon(show ? Icons.visibility : Icons.visibility_off, color: Colors.grey, size: 20),
          onPressed: toggle,
        ),
      ),
    );
  }

  Widget _buildRequirementRow(String text, bool met) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(met ? Icons.check_circle : Icons.circle_outlined, color: met ? Colors.blue : Colors.grey.shade300, size: 20),
          const SizedBox(width: 12),
          Text(text, style: TextStyle(color: met ? const Color(0xFF333333) : Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }
}
