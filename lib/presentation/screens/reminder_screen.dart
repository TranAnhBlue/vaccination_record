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

    return Column(
      children: [
        // ── Header ────────────────────────────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Lịch hẹn tiêm chủng',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const BookingScreen()),
                    ).then((_) => _reload()),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TabBar(
                controller: _tabController,
                labelColor: AppTheme.primary,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppTheme.primary,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                tabs: [
                  Tab(text: 'Sắp tới (${apptVm.upcoming.length})'),
                  Tab(text: 'Đã qua (${apptVm.past.length})'),
                ],
              ),
            ],
          ),
        ),

        // ── Content ───────────────────────────────────────────────────────
        Expanded(
          child: apptVm.loading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildList(apptVm.upcoming, isPast: false),
                    _buildList(apptVm.past, isPast: true),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildList(List appointments, {required bool isPast}) {
    if (appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPast ? Icons.history : Icons.event_available,
              size: 80,
              color: Colors.grey.shade200,
            ),
            const SizedBox(height: 16),
            Text(
              isPast ? 'Chưa có lịch hẹn nào đã qua' : 'Chưa có lịch hẹn sắp tới',
              style: const TextStyle(color: Colors.grey, fontSize: 15),
            ),
            if (!isPast) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BookingScreen()),
                ).then((_) => _reload()),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('Đặt lịch ngay'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: appointments.length,
      itemBuilder: (context, i) => _buildAppointmentCard(appointments[i], isPast: isPast),
    );
  }

  Widget _buildAppointmentCard(dynamic appt, {required bool isPast}) {
    final date = DateTime.tryParse(appt.appointmentDate);
    final now = DateTime.now();
    final isToday = date != null &&
        date.year == now.year && date.month == now.month && date.day == now.day;
    final isOverdue = date != null && date.isBefore(now) && appt.status == 'pending';

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
        borderRadius: BorderRadius.circular(20),
        border: isToday ? Border.all(color: Colors.orange.withOpacity(0.4), width: 1.5)
            : isOverdue ? Border.all(color: AppTheme.danger.withOpacity(0.3), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // ── Top Row ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                // Date box
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        date != null ? date.day.toString() : '--',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: statusColor),
                      ),
                      Text(
                        date != null ? 'Th${date.month}' : '--',
                        style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.w600),
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
                        children: [
                          Expanded(
                            child: Text(appt.vaccineName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(statusIcon, size: 11, color: statusColor),
                                const SizedBox(width: 3),
                                Text(statusLabel,
                                    style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 12, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(appt.appointmentTime,
                              style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          const SizedBox(width: 12),
                          const Icon(Icons.location_on_outlined, size: 12, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(appt.center,
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                      if (member != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.person_outline, size: 12, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text('${member.name} · ${member.relationship}',
                                style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Note ──────────────────────────────────────────────────────
          if (appt.note.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notes, size: 14, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(appt.note,
                        style: const TextStyle(fontSize: 12, color: Colors.black87)),
                  ),
                ],
              ),
            ),

          // ── Actions ───────────────────────────────────────────────────
          if (appt.status == 'pending')
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade100)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => _confirmComplete(appt.id),
                      icon: const Icon(Icons.check_circle_outline, size: 16, color: AppTheme.success),
                      label: const Text('Đã tiêm', style: TextStyle(color: AppTheme.success, fontSize: 13)),
                    ),
                  ),
                  Container(width: 1, height: 24, color: Colors.grey.shade200),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => _confirmCancel(appt.id, appt.vaccineName),
                      icon: const Icon(Icons.cancel_outlined, size: 16, color: Colors.grey),
                      label: const Text('Huỷ lịch', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _confirmComplete(int id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xác nhận đã tiêm?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Bạn xác nhận đã thực hiện mũi tiêm này thành công?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Huỷ')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AppointmentViewModel>().completeAppointment(id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
            child: const Text('Xác nhận', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmCancel(int id, String vaccineName) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Huỷ lịch hẹn?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Bạn có chắc muốn huỷ lịch tiêm $vaccineName?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Không')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AppointmentViewModel>().cancelAppointment(id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Huỷ lịch', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
