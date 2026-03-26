import 'package:flutter/material.dart';

enum AppointmentDateBadgeSize {
  /// 48×52 — ô “Lịch hẹn sắp tới” trên trang chủ.
  compact,

  /// 58×62 — thẻ lịch trong màn nhắc.
  standard,
}

/// Ô ngày/tháng (ThM) dùng chung cho danh sách lịch hẹn.
class AppointmentDateBadge extends StatelessWidget {
  final DateTime? date;
  final Color accentColor;
  final AppointmentDateBadgeSize size;

  const AppointmentDateBadge({
    super.key,
    required this.date,
    required this.accentColor,
    this.size = AppointmentDateBadgeSize.compact,
  });

  @override
  Widget build(BuildContext context) {
    final w = size == AppointmentDateBadgeSize.compact ? 48.0 : 58.0;
    final h = size == AppointmentDateBadgeSize.compact ? 52.0 : 62.0;
    final dayFont = size == AppointmentDateBadgeSize.compact ? 16.0 : 22.0;
    final monthFont = size == AppointmentDateBadgeSize.compact ? 9.0 : 10.0;
    final radius = size == AppointmentDateBadgeSize.compact ? 14.0 : 16.0;
    final weight = size == AppointmentDateBadgeSize.standard
        ? FontWeight.w800
        : FontWeight.bold;

    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            date != null ? date!.day.toString() : '--',
            style: TextStyle(
              fontWeight: weight,
              fontSize: dayFont,
              color: accentColor,
            ),
          ),
          Text(
            date != null ? 'Th${date!.month}' : '--',
            style: TextStyle(
              fontSize: monthFont,
              color: accentColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
