import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../domain/entities/vaccination_record.dart';

class NotificationService {
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const LinuxInitializationSettings initializationSettingsLinux =
        LinuxInitializationSettings(defaultActionName: 'Open notification');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
      linux: initializationSettingsLinux,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap
      },
    );
  }

  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      
      final bool? granted = await androidImplementation?.requestNotificationsPermission();
      return granted ?? false;
    } else if (Platform.isIOS) {
      final bool? granted = await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      return granted ?? false;
    }
    return true;
  }

  Future<void> scheduleVaccinationReminder(VaccinationRecord record) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsEnabled = prefs.getBool(_notificationsEnabledKey) ?? true;
      if (!notificationsEnabled) return;

      final reminderDate = DateTime.tryParse(record.reminderDate);
      if (reminderDate == null) return;

      // Schedule for 8:00 AM on the reminder date
      final scheduledTime = tz.TZDateTime.from(
        DateTime(reminderDate.year, reminderDate.month, reminderDate.day, 8, 0),
        tz.local,
      );

      if (scheduledTime.isBefore(tz.TZDateTime.now(tz.local))) return;

      await _notificationsPlugin.zonedSchedule(
        record.id ?? record.hashCode,
        'Nhắc lịch tiêm chủng: ${record.vaccineName}',
        'Đến ngày tiêm mũi ${record.dose} theo lịch hẹn của bạn tại ${record.location}.',
        scheduledTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'vaccination_reminders',
            'Vaccination Reminders',
            channelDescription: 'Notifications for scheduled vaccinations',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: record.id?.toString(),
      );
    } catch (e) {
      debugPrint("Error scheduling notification: $e");
      // Don't rethrow, so we don't break the booking flow if only notifications fail
    }
  }

  Future<void> showInstantNotification(String title, String body) async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsEnabled = prefs.getBool(_notificationsEnabledKey) ?? true;
    if (!notificationsEnabled) return;

    const NotificationDetails notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'instant_notifications',
        'Instant Notifications',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _notificationsPlugin.show(
      0,
      title,
      body,
      notificationDetails,
    );
  }

  Future<void> cancelReminder(int id) async {
    await _notificationsPlugin.cancel(id);
  }
}
