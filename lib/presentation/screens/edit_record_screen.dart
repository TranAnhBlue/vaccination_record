import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/constants/vaccine_data.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../viewmodels/vaccination_viewmodel.dart';
import '../../domain/entities/vaccination_record.dart';
import '../../core/theme/app_theme.dart';

class EditRecordScreen extends StatefulWidget {
  final VaccinationRecord record;
  const EditRecordScreen({super.key, required this.record});

  @override
  State<EditRecordScreen> createState() => _EditRecordScreenState();
}

class _EditRecordScreenState extends State<EditRecordScreen> {
  bool _isSuccess = false;
  late TextEditingController nameController;
  late TextEditingController doseController;
  late TextEditingController locationController;
  late TextEditingController reactionController;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  
  DateTime? _injectionDate;
  DateTime? _reminderDate;
  File? _imageFile;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.record.vaccineName);
    doseController = TextEditingController(text: widget.record.dose.toString());
    locationController = TextEditingController(text: widget.record.location);
    reactionController = TextEditingController(text: widget.record.note);
    _injectionDate = DateTime.tryParse(widget.record.date);
    _reminderDate = widget.record.reminderDate.isNotEmpty ? DateTime.tryParse(widget.record.reminderDate) : null;
  }

  @override
  Widget build(BuildContext context) {
    if (_isSuccess) return _buildSuccessView();

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
          "Chỉnh sửa mũi tiêm",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: _buildEditForm(),
        ),
      ),
    );
  }

  Widget _buildEditForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Thông tin vaccine"),
        const SizedBox(height: 24),
        _buildLabel("Loại vaccine"),
        _buildVaccineSelector(),
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
        _buildTextFormField(reactionController, "Nhập phản ứng sau tiêm (nếu có)"),
        const SizedBox(height: 32),
        _buildLabel("Hình ảnh chứng nhận"),
        _buildImagePicker(),
        const SizedBox(height: 48),
        if (_isLoading)
          const Center(child: CircularProgressIndicator()),
        if (!_isLoading) ...[
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _handleUpdate,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Lưu mũi tiêm", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Hủy", style: TextStyle(color: Color(0xFF828282), fontWeight: FontWeight.bold)),
            ),
          ),
        ],
        const SizedBox(height: 20),
      ],
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

  Widget _buildVaccineSelector() {
    return InkWell(
      onTap: _showVaccinePicker,
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
            Expanded(
              child: Text(
                nameController.text.isEmpty ? "Chọn loại vaccine" : nameController.text,
                style: TextStyle(
                  color: nameController.text.isEmpty ? const Color(0xFFBDBDBD) : const Color(0xFF1F1F1F),
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: Color(0xFF828282)),
          ],
        ),
      ),
    );
  }

  void _showVaccinePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _VaccinePickerSheet(
        onSelected: (vaccine) {
          setState(() {
            nameController.text = vaccine.name;
          });
        },
      ),
    );
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

  void _handleUpdate() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final vm = context.read<VaccinationViewModel>();
        await vm.update(VaccinationRecord(
          id: widget.record.id,
          vaccineName: nameController.text.trim(),
          dose: int.tryParse(doseController.text.trim()) ?? 1,
          date: DateFormat('yyyy-MM-dd').format(_injectionDate!),
          reminderDate: _reminderDate != null ? DateFormat('yyyy-MM-dd').format(_reminderDate!) : "",
          location: locationController.text.trim(),
          note: reactionController.text.trim(),
          imagePath: _imageFile?.path ?? widget.record.imagePath,
        ));
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isSuccess = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Cập nhật mũi tiêm thành công"), backgroundColor: AppTheme.success),
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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập đầy đủ thông tin bắt buộc")),
      );
    }
  }

  Widget _buildSuccessView() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: AppTheme.success, size: 100),
              const SizedBox(height: 32),
              const Text("Cập nhật thành công", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1F1F1F))),
              const SizedBox(height: 12),
              const Text(
                "Thông tin vắc-xin đã được cập nhật thành công vào sổ tiêm chủng điện tử của bạn.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF828282), height: 1.5),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Go back to Home
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text("Về trang chủ", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VaccinePickerSheet extends StatefulWidget {
  final Function(Vaccine) onSelected;

  const _VaccinePickerSheet({required this.onSelected});

  @override
  State<_VaccinePickerSheet> createState() => _VaccinePickerSheetState();
}

class _VaccinePickerSheetState extends State<_VaccinePickerSheet> {
  String _searchQuery = "";
  final _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final filtered = commonVaccines.where((v) => 
      v.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      v.disease.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Chọn loại vaccine", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: "Tìm kiếm vaccine...",
                    prefixIcon: const Icon(Icons.search, size: 20),
                    filled: true,
                    fillColor: const Color(0xFFF3F4F6),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final v = filtered[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  title: Text(v.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  subtitle: Text(v.disease, style: const TextStyle(color: Color(0xFF828282), fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                  onTap: () {
                    widget.onSelected(v);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          if (filtered.isEmpty)
             Padding(
               padding: const EdgeInsets.all(40),
               child: Column(
                 children: [
                   const Text("Không thấy loại vaccine bạn cần?", style: TextStyle(color: Colors.grey)),
                   TextButton(
                     onPressed: () {
                       widget.onSelected(Vaccine(name: _searchQuery, description: "", disease: ""));
                       Navigator.pop(context);
                     }, 
                     child: Text("Sử dụng tên: '$_searchQuery'", style: const TextStyle(fontWeight: FontWeight.bold))
                   ),
                 ],
               ),
             ),
        ],
      ),
    );
  }
}
