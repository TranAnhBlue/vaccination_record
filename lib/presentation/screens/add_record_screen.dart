import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../viewmodels/vaccination_viewmodel.dart';
import '../../domain/entities/vaccination_record.dart';
import '../../core/theme/app_theme.dart';

class AddRecordScreen extends StatefulWidget {
  const AddRecordScreen({super.key});

  @override
  State<AddRecordScreen> createState() => _AddRecordScreenState();
}

class _AddRecordScreenState extends State<AddRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final doseController = TextEditingController();
  final locationController = TextEditingController();
  final reactionController = TextEditingController();
  final noteController = TextEditingController();

  DateTime _injectionDate = DateTime.now();
  DateTime? _reminderDate;
  File? _imageFile;
  final _picker = ImagePicker();
  bool _isSuccess = false;

  @override
  Widget build(BuildContext context) {
    if (_isSuccess) return _buildSuccessScreen();

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
          "Thêm mũi tiêm mới",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle("Thông tin vaccine"),
              const SizedBox(height: 24),
              _buildLabel("Loại vaccine"),
              _buildTextFormField(nameController, "Chọn loại vaccine", validator: (v) => v!.isEmpty ? "Vui lòng chọn loại vaccine" : null),
              const SizedBox(height: 20),
              _buildLabel("Mũi số"),
              _buildTextFormField(doseController, "Nhập số mũi", keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? "Vui lòng nhập mũi số" : null),
              const SizedBox(height: 32),
              _buildSectionTitle("Thời gian"),
              const SizedBox(height: 24),
              _buildLabel("Ngày tiêm"),
              _buildDatePickerTile(_injectionDate, (d) => setState(() => _injectionDate = d)),
              const SizedBox(height: 20),
              _buildLabel("Ngày nhắc mũi tiếp theo (Dự kiến)"),
              _buildDatePickerTile(_reminderDate, (d) => setState(() => _reminderDate = d), isOptional: true),
              const SizedBox(height: 32),
              _buildLabel("Địa điểm"),
              _buildTextFormField(locationController, "Nhập địa điểm tiêm"),
              const SizedBox(height: 20),
              _buildLabel("Phản ứng sau tiêm"),
              _buildTextFormField(reactionController, "Sốt nhẹ, đau chỗ tiêm..."),
              const SizedBox(height: 32),
              _buildSectionTitle("Hình ảnh chứng nhận"),
              const SizedBox(height: 16),
              _buildImagePicker(),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Thêm mũi tiêm", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Hủy", style: TextStyle(color: Color(0xFF828282), fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField(TextEditingController controller, String hint, {TextInputType keyboardType = TextInputType.text, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primary, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 1)),
      ),
    );
  }

  void _handleSave() async {
    if (_formKey.currentState!.validate()) {
      final vm = context.read<VaccinationViewModel>();
      await vm.add(VaccinationRecord(
        vaccineName: nameController.text,
        dose: int.tryParse(doseController.text) ?? 1,
        date: DateFormat('yyyy-MM-dd').format(_injectionDate),
        reminderDate: _reminderDate != null ? DateFormat('yyyy-MM-dd').format(_reminderDate!) : "",
        location: locationController.text,
        note: reactionController.text,
        imagePath: _imageFile?.path,
      ));
      setState(() => _isSuccess = true);
    }
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1F1F1F)));
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF333333))),
    );
  }

  Widget _buildDatePickerTile(DateTime? date, Function(DateTime) onPicked, {bool isOptional = false}) {
    return InkWell(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (d != null) onPicked(d);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              date == null ? "Chọn ngày" : DateFormat('dd/MM/yyyy').format(date),
              style: TextStyle(color: date == null ? const Color(0xFFBDBDBD) : const Color(0xFF1F1F1F), fontSize: 14),
            ),
            const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFF828282)),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: _imageFile != null
          ? Stack(
              children: [
                ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.file(_imageFile!, fit: BoxFit.cover, width: double.infinity)),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: TextButton(
                    onPressed: () => _pickImage(),
                    style: TextButton.styleFrom(backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    child: const Text("Thay đổi", style: TextStyle(color: AppTheme.primary, fontSize: 12)),
                  ),
                ),
              ],
            )
          : InkWell(
              onTap: _pickImage,
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_upload_outlined, color: AppTheme.primary, size: 40),
                  SizedBox(height: 12),
                  Text("Chạm để tải ảnh phiếu tiêm", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1F1F1F))),
                  Text("Hỗ trợ JPG, PNG, PDF", style: TextStyle(color: Color(0xFF828282), fontSize: 12)),
                ],
              ),
            ),
    );
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) setState(() => _imageFile = File(pickedFile.path));
  }

  Widget _buildSuccessScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ),
              const Text("Hoàn tất", style: TextStyle(color: Color(0xFF828282), fontWeight: FontWeight.bold)),
              const Spacer(),
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(color: Color(0xFFE7F6EC), shape: BoxShape.circle),
                child: const Icon(Icons.check_circle, color: Color(0xFF198754), size: 56),
              ),
              const SizedBox(height: 32),
              const Text("Thêm mũi tiêm thành công", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1B1B1B))),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "Thông tin vắc-xin đã được lưu lại an toàn vào sổ tiêm chủng điện tử cá nhân của bạn.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF828282), height: 1.5, fontSize: 13),
                ),
              ),
              const SizedBox(height: 48),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB).withOpacity(0.5))),
                      child: const Icon(Icons.vaccines, color: Color(0xFF4285F4), size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Loại vắc-xin", style: TextStyle(color: Color(0xFF828282), fontSize: 11)),
                          Text("${nameController.text} (Mũi ${doseController.text})", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 14, color: Color(0xFF828282)),
                  const SizedBox(width: 8),
                  Text("Đã tiêm: ${DateFormat('dd/MM/yyyy').format(_injectionDate)}", style: const TextStyle(color: Color(0xFF828282), fontSize: 13)),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text("Xem danh sách mũi tiêm", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: TextButton(
                  onPressed: () => setState(() {
                    _isSuccess = false;
                    nameController.clear();
                    doseController.clear();
                    locationController.clear();
                    reactionController.clear();
                    _imageFile = null;
                    _injectionDate = DateTime.now();
                    _reminderDate = null;
                  }),
                  style: TextButton.styleFrom(backgroundColor: const Color(0xFFF1F5F9), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text("Thêm mũi tiêm khác", style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}