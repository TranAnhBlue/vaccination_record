import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../domain/services/vaccine_suggestion_service.dart';
import '../../domain/entities/vaccination_record.dart';
import '../../domain/entities/member.dart';
import '../../domain/entities/appointment.dart';
import '../viewmodels/household_viewmodel.dart';
import '../viewmodels/vaccination_viewmodel.dart';
import '../viewmodels/appointment_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../../core/theme/app_theme.dart';

class SuggestionsScreen extends StatefulWidget {
  const SuggestionsScreen({super.key});
  @override
  State<SuggestionsScreen> createState() => _SuggestionsScreenState();
}

class _SuggestionsScreenState extends State<SuggestionsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final _service = VaccineSuggestionService();
  // memberId → index tab đang hiển thị
  int _selectedMemberIndex = 0;

  @override
  void initState() {
    super.initState();
    // Khởi tạo với length: 1 để tránh assertion error khi members chưa load
    _tabController = TabController(length: 1, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hVm = context.watch<HouseholdViewModel>();
    final vacVm = context.watch<VaccinationViewModel>();
    final members = hVm.members;

    if (members.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: _appBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Rebuild TabController nếu số members thay đổi
    if (_tabController.length != members.length) {
      _tabController.dispose();
      _tabController = TabController(length: members.length, vsync: this);
      _tabController.addListener(() {
        if (!_tabController.indexIsChanging) {
          setState(() => _selectedMemberIndex = _tabController.index);
          // Load vaccination records của member mới
          final m = members[_tabController.index];
          if (m.id != null) vacVm.load(memberId: m.id);
        }
      });
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _appBar(),
      body: Column(
        children: [
          // ── Tab thành viên ──────────────────────────────────────────
          _buildMemberTabs(members),
          // ── Content ────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: members.map((member) {
                return _MemberVaccineView(
                  member: member,
                  service: _service,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  AppBar _appBar() => AppBar(
    title: const Text('Lịch tiêm theo độ tuổi',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
    backgroundColor: Colors.white,
    elevation: 0,
    centerTitle: true,
  );

  Widget _buildMemberTabs(List<Member> members) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: AppTheme.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppTheme.primary,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.tab,
            tabAlignment: TabAlignment.start,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            unselectedLabelStyle: const TextStyle(fontSize: 13),
            tabs: members.map((m) {
              return Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: AppTheme.primary.withOpacity(0.12),
                      child: Text(
                        m.name.isNotEmpty ? m.name[0].toUpperCase() : '?',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.relationship == 'Chủ hộ' ? 'Tôi' : m.name),
                        Text(
                          m.dob.isEmpty ? 'Chưa cập nhật' : _service.getAgeLabelFromDob(m.dob),
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.normal, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }
}

// ─── Widget riêng cho từng thành viên ─────────────────────────────────────────
class _MemberVaccineView extends StatefulWidget {
  final Member member;
  final VaccineSuggestionService service;
  const _MemberVaccineView({required this.member, required this.service});

  @override
  State<_MemberVaccineView> createState() => _MemberVaccineViewState();
}

class _MemberVaccineViewState extends State<_MemberVaccineView> {
  String _filter = 'Tất cả';
  // Set vaccine IDs đang loading (khi user tick)
  final Set<String> _loadingIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.member.id != null) {
        context.read<VaccinationViewModel>().load(memberId: widget.member.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vacVm = context.watch<VaccinationViewModel>();
    final memberRecords = widget.member.id != null
        ? vacVm.recordsForMember(widget.member.id!)
        : <VaccinationRecord>[];
    final suggestion = widget.service.getSuggestionsForMember(
        widget.member, memberRecords);

    final filtered = _applyFilter(suggestion.vaccines);

    return Column(
      children: [
        // ── Progress header ───────────────────────────────────────────
        _buildProgressHeader(suggestion),
        // ── Filter chips ─────────────────────────────────────────────
        _buildFilterBar(suggestion),
        // ── List ────────────────────────────────────────────────────
        Expanded(
          child: filtered.isEmpty
              ? _buildEmpty()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => _buildVaccineCard(filtered[i], suggestion.member),
                ),
        ),
      ],
    );
  }

  List<SuggestedVaccineStatus> _applyFilter(List<SuggestedVaccineStatus> all) {
    switch (_filter) {
      case 'Chưa tiêm': return all.where((v) => v.status == VaccineStatus.pending).toList();
      case 'Đã tiêm': return all.where((v) => v.status == VaccineStatus.done).toList();
      case 'Lịch hẹn': return all.where((v) => v.status == VaccineStatus.scheduled).toList();
      case 'Bắt buộc': return all.where((v) => v.vaccine.isMandatory).toList();
      default: return all;
    }
  }

  // ── Progress header ────────────────────────────────────────────────
  Widget _buildProgressHeader(MemberVaccineSuggestion s) {
    final percent = (s.progress * 100).toInt();
    final Color progressColor = percent == 100
        ? AppTheme.success
        : percent >= 60
            ? Colors.orange
            : AppTheme.primary;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.member.dob.isEmpty
                          ? 'Chưa cập nhật ngày sinh'
                          : widget.service.getAgeLabelFromDob(widget.member.dob),
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(color: Colors.black87),
                        children: [
                          TextSpan(
                            text: '${s.doneCount}',
                            style: TextStyle(
                                fontSize: 28, fontWeight: FontWeight.w900, color: progressColor),
                          ),
                          TextSpan(
                            text: ' / ${s.vaccines.length} mũi đã tiêm',
                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Circular progress
              SizedBox(
                width: 64, height: 64,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: s.progress,
                      strokeWidth: 6,
                      color: progressColor,
                      backgroundColor: progressColor.withOpacity(0.1),
                    ),
                    Text('$percent%',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: progressColor)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Stats row
          Row(
            children: [
              _statChip(Icons.pending_outlined, '${s.pendingCount} chưa tiêm', Colors.red.shade400),
              const SizedBox(width: 8),
              _statChip(Icons.event_outlined, '${s.scheduledCount} lịch hẹn', Colors.orange),
              const SizedBox(width: 8),
              _statChip(Icons.check_circle_outline, '${s.doneCount} đã xong', AppTheme.success),
            ],
          ),
          // Warning nếu chưa có ngày sinh
          if (widget.member.dob.isEmpty) ...[
            const SizedBox(height: 12),
            _dobWarning(),
          ],
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _dobWarning() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Cập nhật ngày sinh trong "Thành viên" để nhận gợi ý chính xác theo độ tuổi.',
              style: TextStyle(color: Colors.orange, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ── Filter bar ─────────────────────────────────────────────────────
  Widget _buildFilterBar(MemberVaccineSuggestion s) {
    final filters = ['Tất cả', 'Chưa tiêm', 'Lịch hẹn', 'Đã tiêm', 'Bắt buộc'];
    return Container(
      height: 52,
      color: Colors.white,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        children: filters.map((f) {
          final isSelected = _filter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _filter = f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primary : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  f,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Vaccine card ───────────────────────────────────────────────────
  Widget _buildVaccineCard(SuggestedVaccineStatus vs, Member member) {
    final vaccine = vs.vaccine;
    final isDone = vs.status == VaccineStatus.done;
    final isScheduled = vs.status == VaccineStatus.scheduled;
    final isPending = vs.status == VaccineStatus.pending;
    final isLoading = _loadingIds.contains(vaccine.id);
    final catColor = Color(widget.service.categoryColorValue(vaccine.category));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isDone
            ? Border.all(color: AppTheme.success.withOpacity(0.3))
            : vaccine.isMandatory && isPending
                ? Border.all(color: Colors.orange.withOpacity(0.4))
                : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDone ? 0.01 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Checkbox ──────────────────────────────────────────
                GestureDetector(
                  onTap: isLoading ? null : () => _toggleDone(vs, member),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone ? AppTheme.success : Colors.transparent,
                      border: Border.all(
                        color: isDone ? AppTheme.success : Colors.grey.shade300,
                        width: 2,
                      ),
                    ),
                    child: isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(5),
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey),
                          )
                        : isDone
                            ? const Icon(Icons.check, color: Colors.white, size: 16)
                            : null,
                  ),
                ),
                const SizedBox(width: 12),

                // ── Info ──────────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              vaccine.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: isDone ? Colors.grey : Colors.black87,
                                decoration: isDone ? TextDecoration.lineThrough : null,
                                decorationColor: Colors.grey,
                              ),
                            ),
                          ),
                          // Badge bắt buộc
                          if (vaccine.isMandatory && !isDone)
                            Container(
                              margin: const EdgeInsets.only(left: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.orange.shade200),
                              ),
                              child: const Text('Bắt buộc',
                                  style: TextStyle(fontSize: 9, color: Colors.orange, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      // Age range tag + category
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: catColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              vaccine.ageRange,
                              style: TextStyle(fontSize: 10, color: catColor, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        vaccine.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDone ? Colors.grey.shade400 : Colors.grey.shade600,
                          height: 1.4,
                        ),
                      ),
                      // Scheduled record info
                      if (isScheduled && vs.record != null) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.event_outlined, size: 12, color: Colors.blue),
                              const SizedBox(width: 4),
                              Text(
                                'Lịch: ${_formatDate(vs.record!.date)} · ${vs.record!.location}',
                                style: const TextStyle(fontSize: 11, color: Colors.blue),
                              ),
                            ],
                          ),
                        ),
                      ],
                      // Done record info
                      if (isDone && vs.record != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '✓ Đã tiêm ngày ${_formatDate(vs.record!.date)}',
                          style: const TextStyle(fontSize: 11, color: AppTheme.success),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Action buttons (chỉ khi chưa tiêm) ────────────────────
          if (isPending || isScheduled) ...[
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade100)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  // Tick đã tiêm
                  Expanded(
                    child: _ActionButton(
                      label: '✓ Đã tiêm rồi',
                      color: AppTheme.success,
                      outlined: false,
                      isLoading: isLoading,
                      onTap: () => _toggleDone(vs, member),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Đặt lịch hẹn
                  Expanded(
                    child: _ActionButton(
                      label: '📅 Đặt lịch hẹn',
                      color: AppTheme.primary,
                      outlined: true,
                      onTap: () => _showBookingSheet(vs.vaccine.name, member),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Xử lý tick ─────────────────────────────────────────────────────
  Future<void> _toggleDone(SuggestedVaccineStatus vs, Member member) async {
    if (member.id == null) return;
    final vaccine = vs.vaccine;

    setState(() => _loadingIds.add(vaccine.id));

    try {
      final vacVm = context.read<VaccinationViewModel>();

      if (vs.record != null && vs.status != VaccineStatus.done) {
        // Đã có record → mark isCompleted = true
        await vacVm.update(vs.record!.copyWith(isCompleted: true));
      } else if (vs.record != null && vs.status == VaccineStatus.done) {
        // Bỏ tick
        await vacVm.update(vs.record!.copyWith(isCompleted: false));
      } else {
        // Chưa có record → tạo mới và mark done
        await vacVm.add(VaccinationRecord(
          vaccineName: vaccine.name,
          dose: 1,
          date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
          reminderDate: '',
          location: '',
          note: 'Xác nhận từ gợi ý tiêm chủng',
          memberId: member.id,
          isCompleted: true,
        ));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            vs.status == VaccineStatus.done
                ? 'Đã bỏ xác nhận ${vaccine.name}'
                : '✓ Đã ghi nhận ${vaccine.name} cho ${member.name}',
          ),
          backgroundColor: vs.status == VaccineStatus.done ? Colors.grey : AppTheme.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ));
      }
    } finally {
      if (mounted) setState(() => _loadingIds.remove(vaccine.id));
    }
  }

  // ── Bottom sheet đặt lịch nhanh ─────────────────────────────────
  void _showBookingSheet(String vaccineName, Member member) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _QuickBookingSheet(
        vaccineName: vaccineName,
        member: member,
        onBooked: () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Đã đặt lịch tiêm $vaccineName cho ${member.name}'),
              backgroundColor: AppTheme.primary,
              behavior: SnackBarBehavior.floating,
            ));
          }
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.verified_rounded, size: 64, color: Colors.green.shade400),
          ),
          const SizedBox(height: 20),
          const Text('Hoàn hảo! Không còn gợi ý nào',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            _filter == 'Tất cả'
                ? 'Tất cả mũi tiêm phù hợp độ tuổi đã được ghi nhận.'
                : 'Không có mũi tiêm nào ở mục "$_filter".',
            style: const TextStyle(color: Colors.grey, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    final d = DateTime.tryParse(dateStr);
    if (d == null) return dateStr;
    return DateFormat('dd/MM/yyyy').format(d);
  }
}

// ─── Quick Booking Bottom Sheet ────────────────────────────────────────────────
class _QuickBookingSheet extends StatefulWidget {
  final String vaccineName;
  final Member member;
  final VoidCallback onBooked;
  const _QuickBookingSheet({required this.vaccineName, required this.member, required this.onBooked});

  @override
  State<_QuickBookingSheet> createState() => _QuickBookingSheetState();
}

class _QuickBookingSheetState extends State<_QuickBookingSheet> {
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);
  late String _center;
  bool _loading = false;

  final List<String> _centers = [
    'Trung tâm Tiêm chủng VNVC',
    'Viện Pasteur',
    'Bệnh viện Nhi Đồng',
    'Trung tâm Y tế Dự phòng',
    'Trạm y tế phường/xã',
  ];

  @override
  void initState() {
    super.initState();
    _center = _centers.first;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1), shape: BoxShape.circle,
                ),
                child: const Icon(Icons.event_available, color: AppTheme.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Đặt lịch hẹn nhanh',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(
                      '${widget.vaccineName} · ${widget.member.name}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Center picker
          _label('Cơ sở tiêm chủng'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _centers.contains(_center) ? _center : _centers.first,
                isExpanded: true,
                items: _centers.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)))).toList(),
                onChanged: (v) => setState(() => _center = v!),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Date + Time
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Ngày hẹn'),
                    const SizedBox(height: 8),
                    _pickerTile(
                      icon: Icons.calendar_today,
                      text: DateFormat('dd/MM/yyyy').format(_date),
                      onTap: () async {
                        final p = await showDatePicker(
                          context: context,
                          initialDate: _date,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (p != null) setState(() => _date = p);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Giờ hẹn'),
                    const SizedBox(height: 8),
                    _pickerTile(
                      icon: Icons.access_time,
                      text: _time.format(context),
                      onTap: () async {
                        final p = await showTimePicker(context: context, initialTime: _time);
                        if (p != null) setState(() => _time = p);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Submit
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _loading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Xác nhận đặt lịch',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String t) => Text(t, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey));

  Widget _pickerTile({required IconData icon, required String text, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppTheme.primary),
            const SizedBox(width: 8),
            Text(text, style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (widget.member.id == null) return;
    setState(() => _loading = true);
    try {
      final apptVm = context.read<AppointmentViewModel>();
      final authVm = context.read<AuthViewModel>();
      await apptVm.addAppointment(
        memberId: widget.member.id!,
        vaccineName: widget.vaccineName,
        center: _center,
        date: _date,
        time: _time,
      );
      if (authVm.currentUser?.id != null) {
        apptVm.load(userId: authVm.currentUser!.id);
      }
      if (mounted) {
        Navigator.pop(context);
        widget.onBooked();
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool outlined;
  final VoidCallback onTap;
  final bool isLoading;
  const _ActionButton({
    required this.label, required this.color,
    required this.outlined, required this.onTap, this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: outlined ? Colors.transparent : color,
          borderRadius: BorderRadius.circular(10),
          border: outlined ? Border.all(color: color) : null,
        ),
        child: Center(
          child: isLoading
              ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: color))
              : Text(
                  label,
                  style: TextStyle(
                    color: outlined ? color : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
        ),
      ),
    );
  }
}
