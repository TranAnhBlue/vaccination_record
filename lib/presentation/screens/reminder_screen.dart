import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../viewmodels/appointment_viewmodel.dart';
import '../viewmodels/household_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'booking/booking_screen.dart';

class ReminderScreen extends StatefulWidget {
  final VoidCallback? onSeeAll;
  const ReminderScreen({super.key, this.onSeeAll});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  void _reload() {
    final authVm = context.read<AuthViewModel>();
    if (authVm.currentUser?.id != null) {
      context.read<AppointmentViewModel>().load(userId: authVm.currentUser!.id);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final apptVm = context.watch<AppointmentViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FC),
      body: Column(
        children: [
          _buildHeader(apptVm),
          Expanded(
            child: apptVm.loading
                ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
                : TabBarView(
              controller: _tabController,
              children: [
                _buildList(apptVm.upcoming, isPast: false),
                _buildList(apptVm.past, isPast: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AppointmentViewModel apptVm) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Lịch hẹn tiêm chủng',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BookingScreen()),
                ).then((_) => _reload()),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2F80ED), Color(0xFF56CCF2)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2F80ED).withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F6FA),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TabBar(
              controller: _tabController,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              labelColor: AppTheme.primary,
              unselectedLabelColor: Colors.grey,
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              tabs: [
                Tab(text: 'Sắp tới (${apptVm.upcoming.length})'),
                Tab(text: 'Đã qua (${apptVm.past.length})'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List appointments, {required bool isPast}) {
    if (appointments.isEmpty) {
      return _buildEmptyState(isPast: isPast);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: appointments.length,
      itemBuilder: (context, i) {
        return _buildAppointmentCard(appointments[i], isPast: isPast);
      },
    );
  }

  Widget _buildEmptyState({required bool isPast}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF4FA),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(
                isPast ? Icons.history_rounded : Icons.event_available_rounded,
                size: 46,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isPast
                  ? 'Chưa có lịch hẹn nào đã qua'
                  : 'Chưa có lịch hẹn sắp tới',
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isPast
                  ? 'Các lịch đã hoàn thành hoặc đã qua sẽ hiển thị tại đây.'
                  : 'Hãy tạo lịch tiêm để nhận nhắc nhở đúng thời gian.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13.5,
                height: 1.5,
              ),
            ),
            if (!isPast) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BookingScreen()),
                ).then((_) => _reload()),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Đặt lịch ngay',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(dynamic appt, {required bool isPast}) {
    final date = DateTime.tryParse(appt.appointmentDate);
    final now = DateTime.now();

    final isToday = date != null &&
        date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;

    final isOverdue =
        date != null && date.isBefore(now) && appt.status == 'pending';

    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (appt.status) {
      case 'completed':
        statusColor = AppTheme.success;
        statusLabel = 'Đã hoàn thành';
        statusIcon = Icons.check_circle;
        break;
      case 'cancelled':
        statusColor = Colors.grey;
        statusLabel = 'Đã huỷ';
        statusIcon = Icons.cancel;
        break;
      default:
        if (isOverdue) {
          statusColor = AppTheme.danger;
          statusLabel = 'Quá hạn';
          statusIcon = Icons.error;
        } else if (isToday) {
          statusColor = Colors.orange;
          statusLabel = 'Hôm nay';
          statusIcon = Icons.today;
        } else {
          statusColor = AppTheme.primary;
          statusLabel = 'Đã đặt';
          statusIcon = Icons.event;
        }
    }

    final hVm = context.read<HouseholdViewModel>();
    final member = hVm.members.where((m) => m.id == appt.memberId).firstOrNull;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: isToday
            ? Border.all(color: Colors.orange.withOpacity(0.35), width: 1.4)
            : isOverdue
            ? Border.all(
          color: AppTheme.danger.withOpacity(0.28),
          width: 1.4,
        )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 58,
                  height: 62,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        date != null ? date.day.toString() : '--',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                        ),
                      ),
                      Text(
                        date != null ? 'Th${date.month}' : '--',
                        style: TextStyle(
                          fontSize: 10,
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              appt.vaccineName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15.5,
                                color: Color(0xFF111827),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(statusIcon, size: 11, color: statusColor),
                                const SizedBox(width: 4),
                                Text(
                                  statusLabel,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: statusColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        Icons.access_time_rounded,
                        appt.appointmentTime,
                      ),
                      const SizedBox(height: 4),
                      _buildInfoRow(
                        Icons.location_on_outlined,
                        appt.center,
                      ),
                      if (member != null) ...[
                        const SizedBox(height: 4),
                        _buildInfoRow(
                          Icons.person_outline,
                          '${member.name} · ${member.relationship}',
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (appt.note.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.notes_rounded, size: 15, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      appt.note,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF374151),
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (appt.status == 'pending')
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade100),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => _confirmComplete(appt.id),
                      icon: const Icon(
                        Icons.check_circle_outline,
                        size: 17,
                        color: AppTheme.success,
                      ),
                      label: const Text(
                        'Đã tiêm',
                        style: TextStyle(
                          color: AppTheme.success,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 26,
                    color: Colors.grey.shade200,
                  ),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => _confirmCancel(appt.id, appt.vaccineName),
                      icon: const Icon(
                        Icons.cancel_outlined,
                        size: 17,
                        color: Colors.grey,
                      ),
                      label: const Text(
                        'Huỷ lịch',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 13, color: Colors.grey),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _confirmComplete(int id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text(
          'Xác nhận đã tiêm?',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'Bạn xác nhận đã thực hiện mũi tiêm này thành công?',
          style: TextStyle(height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Huỷ'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AppointmentViewModel>().completeAppointment(id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Xác nhận',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmCancel(int id, String vaccineName) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text(
          'Huỷ lịch hẹn?',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Bạn có chắc muốn huỷ lịch tiêm $vaccineName?',
          style: const TextStyle(height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Không'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AppointmentViewModel>().cancelAppointment(id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Huỷ lịch',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}