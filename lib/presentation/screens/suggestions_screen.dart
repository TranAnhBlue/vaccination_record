import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../domain/services/vaccine_suggestion_service.dart';
import '../../domain/entities/appointment.dart';
import '../../domain/entities/vaccination_record.dart';
import '../../domain/entities/member.dart';
import '../viewmodels/household_viewmodel.dart';
import '../viewmodels/vaccination_viewmodel.dart';
import '../viewmodels/appointment_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../sync/user_medical_data_sync.dart';
import '../../core/theme/app_theme.dart';

const _sPageBg = Color(0xFFF8FAFC);
const _sBorder = Color(0xFFE2E8F0);
const _sTextMuted = Color(0xFF64748B);

class SuggestionsScreen extends StatefulWidget {
  const SuggestionsScreen({super.key});

  @override
  State<SuggestionsScreen> createState() => _SuggestionsScreenState();
}

class _SuggestionsScreenState extends State<SuggestionsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final _service = VaccineSuggestionService();

  @override
  void initState() {
    super.initState();
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
        backgroundColor: _sPageBg,
        appBar: _appBar(),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }

    if (_tabController.length != members.length) {
      _tabController.dispose();
      _tabController = TabController(length: members.length, vsync: this);
      _tabController.addListener(() {
        if (!_tabController.indexIsChanging) {
          final m = members[_tabController.index];
          if (m.id != null) vacVm.load(memberId: m.id);
        }
      });
    }

    return Scaffold(
      backgroundColor: _sPageBg,
      appBar: _appBar(),
      body: Column(
        children: [
          _buildMemberTabs(members),
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
    title: const Text(
      'Lịch tiêm theo độ tuổi',
      style: TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 17,
        color: Color(0xFF0F172A),
      ),
    ),
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.white,
    elevation: 0,
    centerTitle: true,
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(1),
      child: Container(height: 1, color: _sBorder.withValues(alpha: 0.6)),
    ),
  );

  Widget _buildMemberTabs(List<Member> members) {
    return Material(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          clipBehavior: Clip.none,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _sBorder.withValues(alpha: 0.85)),
          ),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            dividerColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 2),
            // Không thụt ngang: indicator trùng vùng tab, avatar không tràn ra ngoài viền chọn.
            indicatorPadding: const EdgeInsets.symmetric(vertical: 4),
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.35)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1E40AF).withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            labelColor: AppTheme.primary,
            unselectedLabelColor: _sTextMuted,
            tabAlignment: TabAlignment.start,
            labelPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            tabs: members.map((m) {
              return Tab(
                height: 58,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: const Color(0xFFDBEAFE),
                        child: Text(
                          m.name.isNotEmpty ? m.name[0].toUpperCase() : '?',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1D4ED8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 112),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.relationship == 'Chủ hộ' ? 'Tôi' : m.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                height: 1.2,
                                color: Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              m.dob.isEmpty
                                  ? 'Chưa cập nhật'
                                  : _service.getAgeLabelFromDob(m.dob),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                height: 1.15,
                                color: _sTextMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _MemberVaccineView extends StatefulWidget {
  final Member member;
  final VaccineSuggestionService service;

  const _MemberVaccineView({
    required this.member,
    required this.service,
  });

  @override
  State<_MemberVaccineView> createState() => _MemberVaccineViewState();
}

class _MemberVaccineViewState extends State<_MemberVaccineView> {
  String _filter = 'Tất cả';
  final Set<String> _loadingIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final uid = context.read<AuthViewModel>().currentUser?.id;
      if (uid != null) {
        await context.read<AppointmentViewModel>().load(userId: uid);
      }
      if (!mounted) return;
      if (widget.member.id != null) {
        context.read<VaccinationViewModel>().load(memberId: widget.member.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vacVm = context.watch<VaccinationViewModel>();
    final apptVm = context.watch<AppointmentViewModel>();
    final memberRecords = widget.member.id != null
        ? vacVm.recordsForMember(widget.member.id!)
        : <VaccinationRecord>[];

    final memberAppts = widget.member.id != null
        ? apptVm.appointments
            .where(
              (a) =>
                  a.memberId == widget.member.id && a.status == 'pending',
            )
            .toList()
        : <Appointment>[];

    final suggestion = widget.service.getSuggestionsForMember(
      widget.member,
      memberRecords,
      appointments: memberAppts,
    );

    final filtered = _applyFilter(suggestion.vaccines);

    return Column(
      children: [
        _buildProgressHeader(suggestion),
        _buildFilterBar(),
        Expanded(
          child: filtered.isEmpty
              ? _buildEmpty()
              : ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 90),
            itemCount: filtered.length,
            itemBuilder: (_, i) =>
                _buildVaccineCard(filtered[i], suggestion.member),
          ),
        ),
      ],
    );
  }

  List<SuggestedVaccineStatus> _applyFilter(List<SuggestedVaccineStatus> all) {
    switch (_filter) {
      case 'Chưa tiêm':
        return all.where((v) => v.status == VaccineStatus.pending).toList();
      case 'Đã tiêm':
        return all.where((v) => v.status == VaccineStatus.done).toList();
      case 'Lịch hẹn':
        return all.where((v) => v.status == VaccineStatus.scheduled).toList();
      case 'Bắt buộc':
        return all.where((v) => v.vaccine.isMandatory).toList();
      default:
        return all;
    }
  }

  Widget _buildProgressHeader(MemberVaccineSuggestion s) {
    final percent = (s.progress * 100).toInt();
    final ringColor = percent >= 100
        ? const Color(0xFF86EFAC)
        : percent >= 60
            ? const Color(0xFFFDE68A)
            : Colors.white;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF1D4ED8), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.member.dob.isEmpty
                          ? 'Chưa cập nhật ngày sinh'
                          : widget.service.getAgeLabelFromDob(widget.member.dob),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(color: Colors.white),
                        children: [
                          TextSpan(
                            text: '${s.doneCount}',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              height: 1,
                              letterSpacing: -0.5,
                            ),
                          ),
                          TextSpan(
                            text: ' / ${s.vaccines.length}',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.white.withValues(alpha: 0.75),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextSpan(
                            text: ' mũi đã tiêm',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.75),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 72,
                height: 72,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 72,
                      height: 72,
                      child: CircularProgressIndicator(
                        value: s.progress,
                        strokeWidth: 5,
                        color: ringColor,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Text(
                      '$percent%',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _miniStatTile(
                  Icons.hourglass_empty_rounded,
                  '${s.pendingCount}',
                  'Chưa tiêm',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _miniStatTile(
                  Icons.event_available_rounded,
                  '${s.scheduledCount}',
                  'Lịch hẹn',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _miniStatTile(
                  Icons.verified_rounded,
                  '${s.doneCount}',
                  'Đã xong',
                ),
              ),
            ],
          ),
          if (widget.member.dob.isEmpty) ...[
            const SizedBox(height: 14),
            _dobWarning(),
          ],
        ],
      ),
    );
  }

  Widget _miniStatTile(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: Colors.white.withValues(alpha: 0.95)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              height: 1.15,
              color: Colors.white.withValues(alpha: 0.88),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dobWarning() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.white, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Cập nhật ngày sinh để nhận gợi ý chính xác theo độ tuổi.',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final filters = ['Tất cả', 'Chưa tiêm', 'Lịch hẹn', 'Đã tiêm', 'Bắt buộc'];

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        children: filters.map((f) {
          final isSelected = _filter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() => _filter = f),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primary
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primary
                          : _sBorder.withValues(alpha: 0.9),
                    ),
                  ),
                  child: Text(
                    f,
                    style: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF334155),
                      fontSize: 12.5,
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildVaccineCard(SuggestedVaccineStatus vs, Member member) {
    final vaccine = vs.vaccine;
    final isDone = vs.status == VaccineStatus.done;
    final isScheduled = vs.status == VaccineStatus.scheduled;
    final isPending = vs.status == VaccineStatus.pending;
    final isLoading = _loadingIds.contains(vaccine.id);
    final catColor = Color(widget.service.categoryColorValue(vaccine.category));
    final Color? accentBar = isDone
        ? AppTheme.success
        : (vaccine.isMandatory && isPending ? AppTheme.primary : null);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _sBorder),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (accentBar != null)
              Container(width: 4, color: accentBar),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Tooltip(
                          message: isDone
                              ? 'Nhấn để bỏ xác nhận đã tiêm'
                              : 'Đánh dấu đã tiêm',
                          child: GestureDetector(
                            onTap: isLoading ? null : () => _toggleDone(vs, member),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDone
                                    ? AppTheme.success
                                    : const Color(0xFFF8FAFC),
                                border: Border.all(
                                  color: isDone
                                      ? AppTheme.success
                                      : _sBorder,
                                  width: 2,
                                ),
                              ),
                              child: isLoading
                                  ? const Padding(
                                      padding: EdgeInsets.all(7),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppTheme.primary,
                                      ),
                                    )
                                  : isDone
                                      ? const Icon(
                                          Icons.check_rounded,
                                          color: Colors.white,
                                          size: 18,
                                        )
                                      : Icon(
                                          Icons.circle_outlined,
                                          size: 18,
                                          color: Colors.grey.shade400,
                                        ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      vaccine.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15.5,
                                        height: 1.25,
                                        color: isDone
                                            ? const Color(0xFF94A3B8)
                                            : const Color(0xFF0F172A),
                                        decoration: isDone
                                            ? TextDecoration.lineThrough
                                            : null,
                                        decorationColor: const Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ),
                                  if (vaccine.isMandatory && !isDone)
                                    Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF6FF),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: const Color(0xFFBFDBFE),
                                        ),
                                      ),
                                      child: const Text(
                                        'Bắt buộc',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF1D4ED8),
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: catColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      vaccine.ageRange,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: catColor,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      vaccine.category,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: _sTextMuted,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                vaccine.description,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDone
                                      ? const Color(0xFFCBD5E1)
                                      : const Color(0xFF475569),
                                  height: 1.5,
                                ),
                              ),
                              if (isScheduled &&
                                  (vs.record != null ||
                                      vs.appointment != null)) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFBFDBFE),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.event_available_rounded,
                                        size: 18,
                                        color: Color(0xFF1D4ED8),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _scheduledDetailLine(vs),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF1E40AF),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              if (isDone && vs.record != null) ...[
                                const SizedBox(height: 10),
                                Text(
                                  'Đã tiêm ${_formatDate(vs.record!.date)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.success,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isPending || isScheduled)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                      child: Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppTheme.success,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                              onPressed: isLoading
                                  ? null
                                  : () => _toggleDone(vs, member),
                              icon: isLoading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.check_rounded, size: 18),
                              label: const Text(
                                'Đã tiêm rồi',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.primary,
                                side: const BorderSide(
                                  color: AppTheme.primary,
                                  width: 1.5,
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: () =>
                                  _showBookingSheet(vs.vaccine.name, member),
                              icon: const Icon(
                                Icons.calendar_month_rounded,
                                size: 18,
                              ),
                              label: const Text(
                                'Đặt lịch',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleDone(SuggestedVaccineStatus vs, Member member) async {
    if (member.id == null) return;
    final vaccine = vs.vaccine;

    setState(() => _loadingIds.add(vaccine.id));

    try {
      final vacVm = context.read<VaccinationViewModel>();

      if (vs.record != null && vs.status != VaccineStatus.done) {
        await vacVm.update(vs.record!.copyWith(isCompleted: true));
      } else if (vs.record != null && vs.status == VaccineStatus.done) {
        await vacVm.update(vs.record!.copyWith(isCompleted: false));
      } else {
        await vacVm.add(
          VaccinationRecord(
            vaccineName: vaccine.name,
            date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
            reminderDate: '',
            location: '',
            note: 'Xác nhận từ gợi ý tiêm chủng',
            memberId: member.id,
            isCompleted: true,
          ),
        );
      }

      if (mounted) {
        await syncUserMedicalData(context);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              vs.status == VaccineStatus.done
                  ? 'Đã bỏ xác nhận ${vaccine.name}'
                  : '✓ Đã ghi nhận ${vaccine.name} cho ${member.name}',
            ),
            backgroundColor:
            vs.status == VaccineStatus.done ? Colors.grey : AppTheme.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingIds.remove(vaccine.id));
    }
  }

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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Đã đặt lịch tiêm $vaccineName cho ${member.name}'),
                backgroundColor: AppTheme.primary,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: const Icon(
                Icons.verified_rounded,
                size: 56,
                color: AppTheme.success,
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Không còn gợi ý trong mục này',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              _filter == 'Tất cả'
                  ? 'Các mũi tiêm phù hợp độ tuổi đã được ghi nhận đủ.'
                  : 'Không có mũi tiêm nào khớp bộ lọc "$_filter".',
              style: const TextStyle(
                color: _sTextMuted,
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _scheduledDetailLine(SuggestedVaccineStatus vs) {
    final r = vs.record;
    if (r != null) {
      return 'Lịch: ${_formatDate(r.date)} · ${r.location}';
    }
    final a = vs.appointment;
    if (a != null) {
      return 'Lịch: ${_formatDate(a.appointmentDate)} · ${a.appointmentTime} · ${a.center}';
    }
    return '';
  }

  String _formatDate(String dateStr) {
    final d = DateTime.tryParse(dateStr);
    if (d == null) return dateStr;
    return DateFormat('dd/MM/yyyy').format(d);
  }
}

class _QuickBookingSheet extends StatefulWidget {
  final String vaccineName;
  final Member member;
  final VoidCallback onBooked;

  const _QuickBookingSheet({
    required this.vaccineName,
    required this.member,
    required this.onBooked,
  });

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
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.event_available_rounded,
                  color: AppTheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Đặt lịch hẹn nhanh',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.vaccineName} · ${widget.member.name}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _label('Cơ sở tiêm chủng'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _centers.contains(_center) ? _center : _centers.first,
                isExpanded: true,
                borderRadius: BorderRadius.circular(16),
                items: _centers
                    .map(
                      (c) => DropdownMenuItem(
                    value: c,
                    child: Text(
                      c,
                      style: const TextStyle(fontSize: 13.5),
                    ),
                  ),
                )
                    .toList(),
                onChanged: (v) => setState(() => _center = v!),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Ngày hẹn'),
                    const SizedBox(height: 8),
                    _pickerTile(
                      icon: Icons.calendar_today_rounded,
                      text: DateFormat('dd/MM/yyyy').format(_date),
                      onTap: () async {
                        final p = await showDatePicker(
                          context: context,
                          initialDate: _date,
                          firstDate: DateTime.now(),
                          lastDate:
                          DateTime.now().add(const Duration(days: 365)),
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
                      icon: Icons.access_time_rounded,
                      text: _time.format(context),
                      onTap: () async {
                        final p = await showTimePicker(
                          context: context,
                          initialTime: _time,
                        );
                        if (p != null) setState(() => _time = p);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _loading
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : const Text(
                'Xác nhận đặt lịch',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String t) => const Text(
    '',
  ).copyWithText(t);

  Widget _pickerTile({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppTheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
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
        if (!mounted) return;
        await syncUserMedicalData(context);
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

extension on Text {
  Widget copyWithText(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Colors.grey,
      ),
    );
  }
}