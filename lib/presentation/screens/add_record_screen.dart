import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/constants/vaccine_data.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../viewmodels/vaccination_viewmodel.dart';
import '../../domain/entities/vaccination_record.dart';
import '../../core/theme/app_theme.dart';
import '../viewmodels/household_viewmodel.dart';
import '../sync/user_medical_data_sync.dart';
import '../../domain/entities/member.dart';

class AddRecordScreen extends StatefulWidget {
  final String? initialVaccineName;

  const AddRecordScreen({
    super.key,
    this.initialVaccineName,
  });

  @override
  State<AddRecordScreen> createState() => _AddRecordScreenState();
}

class _AddRecordScreenState extends State<AddRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final locationController = TextEditingController();
  final reactionController = TextEditingController();
  final noteController = TextEditingController();

  DateTime _injectionDate = DateTime.now();
  DateTime? _reminderDate;
  File? _imageFile;
  final _picker = ImagePicker();
  bool _isSuccess = false;
  bool _isLoading = false;
  Member? _selectedMember;

  @override
  void initState() {
    super.initState();
    _selectedMember = context.read<HouseholdViewModel>().selectedMember;

    if (widget.initialVaccineName != null) {
      nameController.text = widget.initialVaccineName!;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    locationController.dispose();
    reactionController.dispose();
    noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isSuccess) return _buildSuccessScreen();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.black87,
              size: 18,
            ),
          ),
        ),
        title: const Text(
          "Thêm mũi tiêm mới",
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
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
                    _buildSectionTitle("Thông tin thành viên"),
                    const SizedBox(height: 16),
                    _buildMemberSelector(),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildFormCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle("Thông tin vaccine"),
                    const SizedBox(height: 16),
                    _buildLabel("Loại vaccine"),
                    _buildVaccineSelector(),
                    const SizedBox(height: 16),
                    _buildLabel("Tên vaccine (kèm - Mũi x)"),
                    _buildTextFormField(
                      nameController,
                      'Ví dụ: BCG — Phòng lao - Mũi 2',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildFormCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle("Thời gian"),
                    const SizedBox(height: 16),
                    _buildLabel("Ngày tiêm"),
                    _buildDatePickerTile(
                      _injectionDate,
                          (d) => setState(() => _injectionDate = d),
                    ),
                    const SizedBox(height: 16),
                    _buildLabel("Ngày nhắc mũi tiếp theo (Dự kiến)"),
                    _buildDatePickerTile(
                      _reminderDate,
                          (d) => setState(() => _reminderDate = d),
                      isOptional: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildFormCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle("Thông tin bổ sung"),
                    const SizedBox(height: 16),
                    _buildLabel("Địa điểm"),
                    _buildTextFormField(
                      locationController,
                      "Nhập địa điểm tiêm",
                    ),
                    const SizedBox(height: 16),
                    _buildLabel("Phản ứng sau tiêm"),
                    _buildTextFormField(
                      reactionController,
                      "Sốt nhẹ, đau chỗ tiêm...",
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildFormCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle("Hình ảnh chứng nhận"),
                    const SizedBox(height: 14),
                    _buildImagePicker(),
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
                ),
              if (!_isLoading) ...[
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
                      onPressed: _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text(
                        "Thêm mũi tiêm",
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Hủy",
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.add_chart_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Thêm thông tin mũi tiêm",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Lưu lại vaccine, ngày tiêm, địa điểm và ảnh chứng nhận.",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12.5,
                    height: 1.4,
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

  Widget _buildMemberSelector() {
    final householdVm = context.watch<HouseholdViewModel>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Member>(
          value: householdVm.members.contains(_selectedMember)
              ? _selectedMember
              : null,
          isExpanded: true,
          borderRadius: BorderRadius.circular(16),
          hint: const Text("Chọn thành viên"),
          onChanged: (m) => setState(() => _selectedMember = m),
          items: householdVm.members.map((m) {
            return DropdownMenuItem<Member>(
              value: m,
              child: Text(
                m.relationship == "Chủ hộ"
                    ? "Hồ sơ của tôi (${m.name})"
                    : m.name,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTextFormField(
      TextEditingController controller,
      String hint, {
        TextInputType keyboardType = TextInputType.text,
        String? Function(String?)? validator,
        int maxLines = 1,
      }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildVaccineSelector() {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: _showVaccinePicker,
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
              Icons.vaccines_outlined,
              color: AppTheme.primary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                nameController.text.isEmpty
                    ? "Chọn loại vaccine"
                    : nameController.text,
                style: TextStyle(
                  color: nameController.text.isEmpty
                      ? const Color(0xFF9CA3AF)
                      : const Color(0xFF111827),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF6B7280),
            ),
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

  void _handleSave() async {
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vui lòng chọn loại vaccine"),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    if (_selectedMember == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vui lòng chọn thành viên"),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      if (_selectedMember != null && _selectedMember!.dob.isNotEmpty) {
        final dob = DateTime.tryParse(_selectedMember!.dob);
        if (dob != null && _injectionDate.isBefore(dob)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
              Text("Ngày tiêm không thể trước ngày sinh của thành viên"),
              backgroundColor: AppTheme.danger,
            ),
          );
          return;
        }
      }

      setState(() => _isLoading = true);

      try {
        final vm = context.read<VaccinationViewModel>();
        await vm.add(
          VaccinationRecord(
            vaccineName: nameController.text.trim(),
            date: DateFormat('yyyy-MM-dd').format(_injectionDate),
            reminderDate: _reminderDate != null
                ? DateFormat('yyyy-MM-dd').format(_reminderDate!)
                : "",
            location: locationController.text.trim(),
            note: reactionController.text.trim(),
            imagePath: _imageFile?.path,
            memberId: _selectedMember?.id,
          ),
        );

        if (mounted) {
          await syncUserMedicalData(context);
        }
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isSuccess = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Đã lưu mũi tiêm thành công"),
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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vui lòng nhập đầy đủ thông tin bắt buộc"),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
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

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          color: Color(0xFF6B7280),
        ),
      ),
    );
  }

  Widget _buildDatePickerTile(
      DateTime? date,
      Function(DateTime) onPicked, {
        bool isOptional = false,
      }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        final firstDate = isOptional
            ? DateTime(2000)
            : (_selectedMember != null && _selectedMember!.dob.isNotEmpty
            ? DateTime.tryParse(_selectedMember!.dob) ?? DateTime(1900)
            : DateTime(1900));

        final lastDate = isOptional ? DateTime(2100) : DateTime.now();

        final initialDate = date != null
            ? date
            : (isOptional ? DateTime.now() : DateTime.now());

        final d = await showDatePicker(
          context: context,
          initialDate: initialDate.isBefore(firstDate)
              ? firstDate
              : initialDate.isAfter(lastDate)
              ? lastDate
              : initialDate,
          firstDate: firstDate,
          lastDate: lastDate,
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: AppTheme.primary,
                ),
              ),
              child: child!,
            );
          },
        );

        if (d != null) onPicked(d);
      },
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
              Icons.calendar_today_outlined,
              size: 18,
              color: AppTheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                date == null
                    ? (isOptional ? "Không chọn ngày" : "Chọn ngày")
                    : DateFormat('dd/MM/yyyy').format(date),
                style: TextStyle(
                  color: date == null
                      ? const Color(0xFF9CA3AF)
                      : const Color(0xFF111827),
                  fontSize: 14,
                  fontWeight: date == null ? FontWeight.normal : FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: _imageFile != null
          ? Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Image.file(
              _imageFile!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          Positioned(
            right: 12,
            bottom: 12,
            child: _imageActionButton("Thay đổi"),
          ),
        ],
      )
          : InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: _pickImage,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_upload_outlined,
                color: AppTheme.primary,
                size: 40,
              ),
              SizedBox(height: 12),
              Text(
                "Chạm để tải ảnh phiếu tiêm",
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
              SizedBox(height: 4),
              Text(
                "Hỗ trợ JPG, PNG",
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imageActionButton(String text) {
    return TextButton(
      onPressed: _pickImage,
      style: TextButton.styleFrom(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppTheme.primary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Widget _buildSuccessScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const Spacer(),
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppTheme.success,
                  size: 72,
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                "Thêm mũi tiêm thành công",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  "Thông tin vắc-xin đã được lưu lại an toàn vào sổ tiêm chủng điện tử cá nhân của bạn.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    height: 1.5,
                    fontSize: 13.5,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.035),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.vaccines,
                        color: AppTheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Loại vắc-xin",
                            style: TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            nameController.text,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 14,
                    color: Color(0xFF6B7280),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Đã tiêm: ${DateFormat('dd/MM/yyyy').format(_injectionDate)}",
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    "Xem danh sách mũi tiêm",
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
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
                    locationController.clear();
                    reactionController.clear();
                    noteController.clear();
                    _imageFile = null;
                    _injectionDate = DateTime.now();
                    _reminderDate = null;
                  }),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFF1F5F9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    "Thêm mũi tiêm khác",
                    style: TextStyle(
                      color: Color(0xFF475569),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = commonVaccines.where((v) {
      return v.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          v.disease.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Chọn loại vaccine",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: "Tìm kiếm vaccine...",
                    hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = "");
                      },
                      icon: const Icon(Icons.clear, size: 18),
                    )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF3F4F6),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.search_off_rounded,
                    size: 52,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Không tìm thấy vaccine phù hợp",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_searchQuery.trim().isNotEmpty)
                    TextButton(
                      onPressed: () {
                        widget.onSelected(
                          Vaccine(
                            name: _searchQuery.trim(),
                            description: "",
                            disease: "",
                          ),
                        );
                        Navigator.pop(context);
                      },
                      child: Text(
                        "Sử dụng tên: '$_searchQuery'",
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final v = filtered[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    leading: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.vaccines_outlined,
                        color: AppTheme.primary,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      v.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                      ),
                    ),
                    subtitle: Text(
                      v.disease,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 12,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: Colors.grey,
                    ),
                    onTap: () {
                      widget.onSelected(v);
                      Navigator.pop(context);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}