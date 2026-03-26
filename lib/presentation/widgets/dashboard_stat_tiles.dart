import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Hai ô “Sắp tới (7 ngày)” / “Trễ hẹn” trên trang chủ.
class DashboardStatRow extends StatelessWidget {
  final int upcomingWeekCount;
  final DateTime? nearestDate;
  final int overdueCount;

  const DashboardStatRow({
    super.key,
    required this.upcomingWeekCount,
    required this.nearestDate,
    required this.overdueCount,
  });

  @override
  Widget build(BuildContext context) {
    final upcomingValue =
        upcomingWeekCount > 0 ? '$upcomingWeekCount mũi' : '0 mũi';
    final upcomingSub = (nearestDate != null && upcomingWeekCount > 0)
        ? 'Gần nhất ${DateFormat('dd/MM/yyyy').format(nearestDate!)}'
        : null;

    return Row(
      children: [
        Expanded(
          child: _StatTile(
            'Sắp tới (7 ngày)',
            upcomingValue,
            Icons.calendar_today_rounded,
            Colors.orange,
            subtitle: upcomingSub,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _StatTile(
            'Trễ hẹn',
            '$overdueCount mũi',
            Icons.error_outline_rounded,
            Colors.red,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;

  const _StatTile(
    this.label,
    this.value,
    this.icon,
    this.color, {
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.grey, fontSize: 12.5),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
