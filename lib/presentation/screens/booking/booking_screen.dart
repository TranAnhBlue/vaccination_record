import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/notification_service.dart';
import '../../../domain/entities/vaccine_info.dart';
import '../../../data/repositories/vaccine_info_repository.dart';
import '../../viewmodels/appointment_viewmodel.dart';
import '../../viewmodels/household_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';

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
  String _selectedCenter = 'Trung tâm Tiêm chủng VNVC';
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _vaccineSearchController = TextEditingController();

  final List<String> _centers = [
    'Trung tâm Tiêm chủng VNVC',
    'Viện Pasteur TP.HCM',
    'Bệnh viện Nhi Đồng',
    'Trung tâm Y tế Dự phòng',
    'Phòng tiêm chủng Safpo',
    'Trạm y tế phường/xã',
  ];

  late List<VaccineInfo> _allVaccines;
  List<VaccineInfo> _filteredVaccines = [];
  bool _showDropdown = false;

  @override
  void initState() {
    super.initState();
    _allVaccines = VaccineInfoRepository().getAllVaccines();

    if (widget.preSelectedVaccine != null) {
      _selectedVaccineName = widget.preSelectedVaccine!.name;
      _vaccineSearchController.text = _selectedVaccineName!;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final hVm = context.read<HouseholdViewModel>();
      if (hVm.selectedMember?.id != null) {
        final ids = hVm.members.map((m) => m.id).toList();
        if (ids.contains(hVm.selectedMember!.id)) {
          setState(() => _selectedMemberId = hVm.selectedMember!.id);
        }
      }
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    _vaccineSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final householdVm = context.watch<HouseholdViewModel>();
    final apptVm = context.watch<AppointmentViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Đặt lịch tiêm chủng',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Banner ───────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primary.withOpacity(0.08), AppTheme.primary.withOpacity(0.02)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.15)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.event_available, color: AppTheme.primary, size: 24),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Đặt lịch hẹn', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          SizedBox(height: 2),
                          Text(
                            'Lịch hẹn sẽ được lưu và nhắc nhở trước ngày tiêm.',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Thành viên ───────────────────────────────────────────────
              _sectionTitle('Thành viên tiêm chủng'),
              const SizedBox(height: 10),
              _buildMemberSelector(householdVm),
              const SizedBox(height: 24),

              // ── Vắc-xin ─────────────────────────────────────────────────
              _sectionTitle('Loại vắc-xin'),
              const SizedBox(height: 10),
              _buildVaccineSelector(),
              const SizedBox(height: 24),

              // ── Trung tâm ────────────────────────────────────────────────
              _sectionTitle('Cơ sở tiêm chủng'),
              const SizedBox(height: 10),
              _buildCenterDropdown(),
              const SizedBox(height: 24),

              // ── Ngày & Giờ ──────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('Ngày tiêm'),
                        const SizedBox(height: 10),
                        _buildDatePicker(),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('Giờ tiêm'),
                        const SizedBox(height: 10),
                        _buildTimePicker(),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Ghi chú ──────────────────────────────────────────────────
              _sectionTitle('Ghi chú sức khỏe (tuỳ chọn)'),
              const SizedBox(height: 10),
              TextFormField(
                controller: _noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Dị ứng thuốc, tiền sử bệnh, lưu ý đặc biệt...',
                  fillColor: Colors.grey.shade50,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // ── Submit ───────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: apptVm.loading ? null : _submitBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: apptVm.loading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Xác nhận đặt lịch',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(t,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey));

  Widget _buildMemberSelector(HouseholdViewModel hVm) {
    // Guard: đảm bảo value luôn nằm trong danh sách items
    final memberIds = hVm.members.map((m) => m.id).toList();
    final safeValue = memberIds.contains(_selectedMemberId) ? _selectedMemberId : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: safeValue,
          isExpanded: true,
          hint: const Text('Chọn thành viên'),
          items: hVm.members.map<DropdownMenuItem<int>>((m) {
            return DropdownMenuItem<int>(
              value: m.id,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppTheme.primary.withOpacity(0.1),
                    child: Text(m.name.isNotEmpty ? m.name[0].toUpperCase() : '?',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(m.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      Text(m.relationship, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
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
              _showDropdown = val.isNotEmpty;
              _filteredVaccines = _allVaccines
                  .where((v) => v.name.toLowerCase().contains(val.toLowerCase()))
                  .toList();
            });
          },
          decoration: InputDecoration(
            hintText: 'Tìm kiếm vắc-xin...',
            prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
            suffixIcon: _vaccineSearchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _vaccineSearchController.clear();
                      setState(() { _selectedVaccineName = null; _showDropdown = false; });
                    })
                : null,
            fillColor: Colors.grey.shade50,
            filled: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
          ),
        ),
        if (_showDropdown && _filteredVaccines.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _filteredVaccines.length,
              itemBuilder: (context, i) {
                final v = _filteredVaccines[i];
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.vaccines, color: AppTheme.primary, size: 18),
                  title: Text(v.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: Text(v.schedule, style: const TextStyle(fontSize: 11)),
                  onTap: () => setState(() {
                    _selectedVaccineName = v.name;
                    _vaccineSearchController.text = v.name;
                    _showDropdown = false;
                  }),
                );
              },
            ),
          ),
        if (_selectedVaccineName != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: AppTheme.success, size: 16),
                const SizedBox(width: 6),
                Text('Đã chọn: $_selectedVaccineName',
                    style: const TextStyle(color: AppTheme.success, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _centers.contains(_selectedCenter) ? _selectedCenter : _centers.first,
          isExpanded: true,
          items: _centers.map<DropdownMenuItem<String>>((c) =>
              DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 14)))).toList(),
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
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 18, color: AppTheme.primary),
            const SizedBox(width: 10),
            Text(DateFormat('dd/MM/yyyy').format(_selectedDate), style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker() {
    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(context: context, initialTime: _selectedTime);
        if (picked != null) setState(() => _selectedTime = picked);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time, size: 18, color: AppTheme.primary),
            const SizedBox(width: 10),
            Text(_selectedTime.format(context), style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Future<void> _submitBooking() async {
    if (_selectedMemberId == null) {
      _showError('Vui lòng chọn thành viên');
      return;
    }
    if (_selectedVaccineName == null || _selectedVaccineName!.isEmpty) {
      _showError('Vui lòng chọn vắc-xin');
      return;
    }

    final apptVm = context.read<AppointmentViewModel>();
    final authVm = context.read<AuthViewModel>();

    final success = await apptVm.addAppointment(
      memberId: _selectedMemberId!,
      vaccineName: _selectedVaccineName!,
      center: _selectedCenter,
      date: _selectedDate,
      time: _selectedTime,
      note: _noteController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      // Reload appointments for the user
      if (authVm.currentUser != null) {
        apptVm.load(userId: authVm.currentUser!.id);
      }

      // Send local notification
      NotificationService().showInstantNotification(
        'Đặt lịch thành công 🎉',
        'Lịch tiêm $_selectedVaccineName vào ${DateFormat('dd/MM/yyyy').format(_selectedDate)} lúc ${_selectedTime.format(context)} tại $_selectedCenter',
      );

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã đặt lịch tiêm $_selectedVaccineName thành công!'),
          backgroundColor: AppTheme.success,
        ),
      );
    } else {
      _showError(apptVm.error ?? 'Không thể đặt lịch. Vui lòng thử lại.');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.danger),
    );
  }
}
