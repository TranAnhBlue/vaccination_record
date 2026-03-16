import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/vaccination_record.dart';
import '../../../domain/entities/vaccine_info.dart';
import '../../../data/repositories/vaccine_info_repository.dart';
import '../../viewmodels/vaccination_viewmodel.dart';
import '../../viewmodels/household_viewmodel.dart';

class BookingScreen extends StatefulWidget {
  final VaccineInfo? preSelectedVaccine;
  const BookingScreen({super.key, this.preSelectedVaccine});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _formKey = GlobalKey<FormState>();
  
  int? _selectedMemberId;
  String? _selectedVaccineName;
  String _selectedCenter = "Trung tâm Tiêm chủng VNVC";
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  final TextEditingController _noteController = TextEditingController();

  final List<String> _centers = [
    "Trung tâm Tiêm chủng VNVC",
    "Viện Pasteur TP.HCM",
    "Bệnh viện Nhi Đồng",
    "Trung tâm Y tế Dự phòng",
    "Phòng tiêm chủng Safpo"
  ];

  late List<VaccineInfo> _allVaccines;
  List<VaccineInfo> _filteredVaccines = [];
  final TextEditingController _vaccineSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _allVaccines = VaccineInfoRepository().getAllVaccines();
    _filteredVaccines = _allVaccines;
    
    if (widget.preSelectedVaccine != null) {
      _selectedVaccineName = widget.preSelectedVaccine!.name;
      _vaccineSearchController.text = _selectedVaccineName!;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final householdVm = context.read<HouseholdViewModel>();
      if (householdVm.selectedMember != null) {
        setState(() {
          _selectedMemberId = householdVm.selectedMember!.id;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final householdVm = context.watch<HouseholdViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Đặt lịch tiêm chủng",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle("Thành viên tiêm chủng"),
              const SizedBox(height: 12),
              _buildMemberDropdown(householdVm),
              const SizedBox(height: 24),

              _buildSectionTitle("Chọn loại Vắc-xin"),
              const SizedBox(height: 12),
              _buildVaccineSelector(),
              const SizedBox(height: 24),

              _buildSectionTitle("Trung tâm tiêm chủng"),
              const SizedBox(height: 12),
              _buildCenterDropdown(),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle("Ngày tiêm"),
                        const SizedBox(height: 12),
                        _buildDatePicker(),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle("Giờ tiêm"),
                        const SizedBox(height: 12),
                        _buildTimePicker(),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _buildSectionTitle("Ghi chú (nếu có)"),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteController,
                maxLines: 3,
                decoration: AppTheme.inputDecoration("Mô tả tình trạng sức khỏe...").copyWith(
                  fillColor: Colors.grey.shade50,
                  filled: true,
                ),
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _submitBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Xác nhận đặt lịch",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
    );
  }

  Widget _buildMemberDropdown(HouseholdViewModel householdVm) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedMemberId,
          isExpanded: true,
          hint: const Text("Chọn thành viên"),
          items: householdVm.members.map<DropdownMenuItem<int>>((m) {
            return DropdownMenuItem<int>(
              value: m.id,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: AppTheme.primary.withOpacity(0.1),
                    child: Text(
                      m.name.isNotEmpty ? m.name[0].toUpperCase() : "?", 
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(m.name, style: const TextStyle(fontSize: 14)),
                ],
              ),
            );
          }).toList(),
          onChanged: (val) => setState(() => _selectedMemberId = val),
        ),
      ),
    );
  }

  Widget _buildVaccineSelector() {
    return Column(
      children: [
        TextFormField(
          controller: _vaccineSearchController,
          onChanged: (val) {
            setState(() {
              _filteredVaccines = _allVaccines
                  .where((v) => v.name.toLowerCase().contains(val.toLowerCase()))
                  .toList();
            });
          },
          decoration: AppTheme.inputDecoration("Tìm kiếm vắc-xin...").copyWith(
            prefixIcon: const Icon(Icons.search, size: 20),
            fillColor: Colors.grey.shade50,
            filled: true,
          ),
        ),
        if (_filteredVaccines.isNotEmpty && _vaccineSearchController.text.isNotEmpty && _selectedVaccineName != _vaccineSearchController.text)
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _filteredVaccines.length,
              itemBuilder: (context, index) {
                final v = _filteredVaccines[index];
                return ListTile(
                  title: Text(v.name, style: const TextStyle(fontSize: 14)),
                  subtitle: Text(v.schedule, style: const TextStyle(fontSize: 11)),
                  onTap: () {
                    setState(() {
                      _selectedVaccineName = v.name;
                      _vaccineSearchController.text = v.name;
                      _filteredVaccines = [];
                    });
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildCenterDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCenter,
          isExpanded: true,
          items: _centers.map<DropdownMenuItem<String>>((c) {
            return DropdownMenuItem<String>(value: c, child: Text(c, style: const TextStyle(fontSize: 14)));
          }).toList(),
          onChanged: (val) => setState(() => _selectedCenter = val!),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) setState(() => _selectedDate = picked);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 18, color: AppTheme.primary),
            const SizedBox(width: 12),
            Text(DateFormat('dd/MM/yyyy').format(_selectedDate), style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker() {
    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: _selectedTime,
        );
        if (picked != null) setState(() => _selectedTime = picked);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time, size: 18, color: AppTheme.primary),
            const SizedBox(width: 12),
            Text(_selectedTime.format(context), style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  void _submitBooking() {
    if (_selectedMemberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng chọn thành viên")));
      return;
    }
    if (_selectedVaccineName == null || _selectedVaccineName!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng chọn vắc-xin")));
      return;
    }

    final vm = context.read<VaccinationViewModel>();
    
    // Combine date and time
    final bookingDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final record = VaccinationRecord(
      id: null,
      vaccineName: _selectedVaccineName!,
      dose: 1, // Default to 1 for new plan
      date: bookingDateTime.toIso8601String(),
      reminderDate: bookingDateTime.toIso8601String(),
      location: _selectedCenter,
      note: _noteController.text,
      memberId: _selectedMemberId!,
      isCompleted: false,
    );

    vm.add(record).then((_) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Đã đặt lịch tiêm ${_selectedVaccineName} thành công!"),
          backgroundColor: AppTheme.success,
        ),
      );
    });
  }
}
