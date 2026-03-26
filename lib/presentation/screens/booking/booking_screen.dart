import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/notification_service.dart';
import '../../../domain/entities/vaccine_info.dart';
import '../../../data/repositories/vaccine_info_repository.dart';
import '../../../domain/services/vaccine_suggestion_service.dart';
import '../../viewmodels/appointment_viewmodel.dart';
import '../../viewmodels/household_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../sync/user_medical_data_sync.dart';

/// Gộp danh mục trong app + lịch BYT cho ô tìm vắc-xin.
class _BookingVaccineOption {
  final String name;
  final String subtitle;

  const _BookingVaccineOption({
    required this.name,
    required this.subtitle,
  });
}

String _foldVietnamese(String input) {
  const map = {
    'à': 'a', 'á': 'a', 'ạ': 'a', 'ả': 'a', 'ã': 'a',
    'â': 'a', 'ầ': 'a', 'ấ': 'a', 'ậ': 'a', 'ẩ': 'a', 'ẫ': 'a',
    'ă': 'a', 'ằ': 'a', 'ắ': 'a', 'ặ': 'a', 'ẳ': 'a', 'ẵ': 'a',
    'è': 'e', 'é': 'e', 'ẹ': 'e', 'ẻ': 'e', 'ẽ': 'e',
    'ê': 'e', 'ề': 'e', 'ế': 'e', 'ệ': 'e', 'ể': 'e', 'ễ': 'e',
    'ì': 'i', 'í': 'i', 'ị': 'i', 'ỉ': 'i', 'ĩ': 'i',
    'ò': 'o', 'ó': 'o', 'ọ': 'o', 'ỏ': 'o', 'õ': 'o',
    'ô': 'o', 'ồ': 'o', 'ố': 'o', 'ộ': 'o', 'ổ': 'o', 'ỗ': 'o',
    'ơ': 'o', 'ờ': 'o', 'ớ': 'o', 'ợ': 'o', 'ở': 'o', 'ỡ': 'o',
    'ù': 'u', 'ú': 'u', 'ụ': 'u', 'ủ': 'u', 'ũ': 'u',
    'ư': 'u', 'ừ': 'u', 'ứ': 'u', 'ự': 'u', 'ử': 'u', 'ữ': 'u',
    'ỳ': 'y', 'ý': 'y', 'ỵ': 'y', 'ỷ': 'y', 'ỹ': 'y',
    'đ': 'd',
  };
  final lower = StringBuffer();
  for (final c in input.toLowerCase().characters) {
    lower.write(map[c] ?? c);
  }
  return lower.toString();
}

int _suggestionRank(_BookingVaccineOption item, String queryRaw) {
  final q = _foldVietnamese(queryRaw.trim());
  if (q.isEmpty) return 99;
  final name = _foldVietnamese(item.name);
  final sub = _foldVietnamese(item.subtitle);
  if (name.startsWith(q)) return 0;
  if (sub.startsWith(q)) return 1;
  if (name.contains(q)) return 2;
  if (sub.contains(q)) return 3;
  return 99;
}

List<_BookingVaccineOption> _buildBookingVaccineCatalog() {
  final seen = <String>{};
  final out = <_BookingVaccineOption>[];

  void add(String name, String subtitle) {
    final key = name.toLowerCase().trim();
    if (key.isEmpty || seen.contains(key)) return;
    seen.add(key);
    out.add(_BookingVaccineOption(name: name, subtitle: subtitle));
  }

  for (final v in VaccineInfoRepository().getAllVaccines()) {
    add(v.name, v.schedule);
  }
  for (final s in VaccineSuggestionService.nationalScheduleForSearch) {
    add(s.name, s.ageRange);
  }
  out.sort((a, b) => a.name.compareTo(b.name));
  return out;
}

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
  final TextEditingController _vaccineSearchController =
  TextEditingController();

  final List<String> _centers = [
    'Trung tâm Tiêm chủng VNVC',
    'Viện Pasteur TP.HCM',
    'Bệnh viện Nhi Đồng',
    'Trung tâm Y tế Dự phòng',
    'Phòng tiêm chủng Safpo',
    'Trạm y tế phường/xã',
  ];

  late List<_BookingVaccineOption> _vaccineCatalog;
  List<_BookingVaccineOption> _filteredVaccines = [];
  bool _showDropdown = false;

  @override
  void initState() {
    super.initState();
    _vaccineCatalog = _buildBookingVaccineCatalog();

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
      backgroundColor: const Color(0xFFF6F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.close, color: Colors.black, size: 18),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Đặt lịch tiêm chủng',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroBanner(),
              const SizedBox(height: 18),
              _buildFormCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('Thành viên tiêm chủng'),
                    const SizedBox(height: 10),
                    _buildMemberSelector(householdVm),
                    const SizedBox(height: 20),
                    _sectionTitle('Loại vắc-xin'),
                    const SizedBox(height: 10),
                    _buildVaccineSelector(),
                    const SizedBox(height: 20),
                    _sectionTitle('Cơ sở tiêm chủng'),
                    const SizedBox(height: 10),
                    _buildCenterDropdown(),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildFormCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Thời gian tiêm',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 14),
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
                        const SizedBox(width: 14),
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
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildFormCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('Ghi chú sức khỏe (tuỳ chọn)'),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _noteController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText:
                        'Dị ứng thuốc, tiền sử bệnh, lưu ý đặc biệt...',
                        hintStyle: const TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 14,
                        ),
                        fillColor: const Color(0xFFF8FAFC),
                        filled: true,
                        contentPadding: const EdgeInsets.all(16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide:
                          const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide:
                          const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide:
                          const BorderSide(color: AppTheme.primary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2F80ED), Color(0xFF56CCF2)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2F80ED).withOpacity(0.22),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: apptVm.loading ? null : _submitBooking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      disabledBackgroundColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: apptVm.loading
                        ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.2,
                      ),
                    )
                        : const Text(
                      'Xác nhận đặt lịch',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
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
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.event_available_rounded,
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
                  'Đặt lịch hẹn tiêm chủng',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Lịch hẹn sẽ được lưu và nhắc nhở trước ngày tiêm.',
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

  Widget _sectionTitle(String t) {
    return Text(
      t,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Color(0xFF6B7280),
      ),
    );
  }

  Widget _buildMemberSelector(HouseholdViewModel hVm) {
    final memberIds = hVm.members.map((m) => m.id).toList();
    final safeValue = memberIds.contains(_selectedMemberId)
        ? _selectedMemberId
        : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: safeValue,
          isExpanded: true,
          hint: const Text('Chọn thành viên'),
          borderRadius: BorderRadius.circular(16),
          items: hVm.members.map<DropdownMenuItem<int>>((m) {
            return DropdownMenuItem<int>(
              value: m.id,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: AppTheme.primary.withOpacity(0.12),
                    child: Text(
                      m.name.isNotEmpty ? m.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          m.relationship,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _vaccineSearchController,
          onChanged: (val) {
            setState(() {
              final q = val.trim();
              if (_selectedVaccineName != null && val != _selectedVaccineName) {
                _selectedVaccineName = null;
              }
              if (q.isEmpty) {
                _showDropdown = false;
                _filteredVaccines = [];
                return;
              }
              _showDropdown = true;
              final hits = _vaccineCatalog
                  .where((e) => _suggestionRank(e, q) < 99)
                  .toList()
                ..sort((a, b) {
                  final ra = _suggestionRank(a, q);
                  final rb = _suggestionRank(b, q);
                  final c = ra.compareTo(rb);
                  if (c != 0) return c;
                  return a.name.compareTo(b.name);
                });
              _filteredVaccines =
                  hits.length > 50 ? hits.sublist(0, 50) : hits;
            });
          },
          decoration: InputDecoration(
            hintText: 'Tìm kiếm vắc-xin...',
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
            prefixIcon:
            const Icon(Icons.search, size: 20, color: Colors.grey),
            suffixIcon: _vaccineSearchController.text.isNotEmpty
                ? IconButton(
              icon: const Icon(Icons.clear, size: 18),
              onPressed: () {
                _vaccineSearchController.clear();
                setState(() {
                  _selectedVaccineName = null;
                  _showDropdown = false;
                  _filteredVaccines = [];
                });
              },
            )
                : null,
            fillColor: const Color(0xFFF8FAFC),
            filled: true,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              borderSide: const BorderSide(color: AppTheme.primary),
            ),
          ),
        ),
        if (_showDropdown &&
            _vaccineSearchController.text.trim().isNotEmpty)
          _filteredVaccines.isEmpty
              ? Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: const Text(
                    'Không có gợi ý trùng khớp. Bạn vẫn có thể dùng tên đã gõ khi đặt lịch.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF6B7280),
                      height: 1.35,
                    ),
                  ),
                )
              : Container(
                  constraints: const BoxConstraints(maxHeight: 220),
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      physics: const ClampingScrollPhysics(),
                      itemCount: _filteredVaccines.length,
                      itemBuilder: (context, i) {
                        final v = _filteredVaccines[i];
                        return ListTile(
                          dense: true,
                          leading: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.vaccines,
                              color: AppTheme.primary,
                              size: 18,
                            ),
                          ),
                          title: Text(
                            v.name,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            v.subtitle,
                            style: const TextStyle(fontSize: 11.5),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () {
                            FocusScope.of(context).unfocus();
                            setState(() {
                              _selectedVaccineName = v.name;
                              _vaccineSearchController.text = v.name;
                              _showDropdown = false;
                              _filteredVaccines = [];
                            });
                          },
                        );
                      },
                    ),
                  ),
                ),
        if (_vaccineSearchController.text.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.success.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: AppTheme.success,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedVaccineName ==
                              _vaccineSearchController.text.trim()
                          ? 'Đã chọn: ${_vaccineSearchController.text.trim()}'
                          : 'Sẽ dùng tên: ${_vaccineSearchController.text.trim()}',
                      style: const TextStyle(
                        color: AppTheme.success,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCenterDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _centers.contains(_selectedCenter)
              ? _selectedCenter
              : _centers.first,
          isExpanded: true,
          borderRadius: BorderRadius.circular(16),
          items: _centers
              .map(
                (c) => DropdownMenuItem(
              value: c,
              child: Text(
                c,
                style: const TextStyle(fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
              .toList(),
          onChanged: (val) => setState(() => _selectedCenter = val!),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
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
        if (picked != null) {
          setState(() => _selectedDate = picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
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
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                DateFormat('dd/MM/yyyy').format(_selectedDate),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker() {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: _selectedTime,
        );
        if (picked != null) {
          setState(() => _selectedTime = picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.access_time_rounded,
              size: 18,
              color: AppTheme.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _selectedTime.format(context),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
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
    final vaccineName = _vaccineSearchController.text.trim();
    if (vaccineName.isEmpty) {
      _showError('Vui lòng nhập hoặc chọn vắc-xin');
      return;
    }

    final apptVm = context.read<AppointmentViewModel>();
    final authVm = context.read<AuthViewModel>();

    final success = await apptVm.addAppointment(
      memberId: _selectedMemberId!,
      vaccineName: vaccineName,
      center: _selectedCenter,
      date: _selectedDate,
      time: _selectedTime,
      note: _noteController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      if (authVm.currentUser != null) {
        await syncUserMedicalData(context);
      }
      if (!mounted) return;

      NotificationService().showInstantNotification(
        'Đặt lịch thành công 🎉',
        'Lịch tiêm $vaccineName vào ${DateFormat('dd/MM/yyyy').format(_selectedDate)} lúc ${_selectedTime.format(context)} tại $_selectedCenter',
      );

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã đặt lịch tiêm $vaccineName thành công!'),
          backgroundColor: AppTheme.success,
        ),
      );
    } else {
      _showError(apptVm.error ?? 'Không thể đặt lịch. Vui lòng thử lại.');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppTheme.danger,
      ),
    );
  }
}