import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

import 'session_repository.dart';

class SessionReminderResult {
  const SessionReminderResult({
    required this.notificationsAllowed,
    required this.reminderScheduled,
    required this.sentImmediately,
    required this.preciseAlarmGranted,
  });

  final bool notificationsAllowed;
  final bool reminderScheduled;
  final bool sentImmediately;
  final bool preciseAlarmGranted;
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const String reminderChannelKey = 'practice_reminders';
  static const Duration reminderLeadTime = Duration(minutes: 30);

  Future<void> initialize() async {
    await AwesomeNotifications().initialize(null, [
      NotificationChannel(
        channelKey: reminderChannelKey,
        channelName: 'Practice Reminders',
        channelDescription: 'Reminder for upcoming choir practice sessions.',
        importance: NotificationImportance.High,
        defaultColor: const Color(0xFF10316B),
        ledColor: const Color(0xFFFDBE34),
        playSound: true,
        enableVibration: true,
        channelShowBadge: true,
      ),
    ], debug: false);
  }

  Future<SessionReminderResult> scheduleSessionReminder({
    required String teamId,
    required String teamName,
    required TeamSession session,
    bool requestPermissions = true,
  }) async {
    final notificationAllowed = await _ensureNotificationPermission(
      requestIfNeeded: requestPermissions,
    );

    if (!notificationAllowed) {
      await cancelSessionReminder(teamId: teamId, sessionId: session.id);
      return const SessionReminderResult(
        notificationsAllowed: false,
        reminderScheduled: false,
        sentImmediately: false,
        preciseAlarmGranted: false,
      );
    }

    final preciseAlarmGranted = await _ensurePreciseAlarmPermission(
      requestIfNeeded: requestPermissions,
    );

    final startTime = _parseSessionDateTime(session.dayDate, session.startTime);
    final now = DateTime.now();
    final reminderTime = startTime.subtract(reminderLeadTime);

    if (!startTime.isAfter(now)) {
      await cancelSessionReminder(teamId: teamId, sessionId: session.id);
      return SessionReminderResult(
        notificationsAllowed: true,
        reminderScheduled: false,
        sentImmediately: false,
        preciseAlarmGranted: preciseAlarmGranted,
      );
    }

    final notificationId = _notificationId(
      teamId: teamId,
      sessionId: session.id,
    );
    final title = 'Latihan $teamName sebentar lagi';
    final body =
        'Team $teamName ada latihan di ${session.location} pada jam ${session.startTime}.';
    final payload = <String, String>{
      'teamId': teamId,
      'teamName': teamName,
      'sessionId': session.id,
      'sessionDate': session.dayDate,
      'sessionLocation': session.location,
      'sessionStartTime': session.startTime,
    };

    await AwesomeNotifications().cancelSchedule(notificationId);
    await AwesomeNotifications().cancel(notificationId);

    if (!reminderTime.isAfter(now)) {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: notificationId,
          channelKey: reminderChannelKey,
          title: title,
          body: body,
          category: NotificationCategory.Reminder,
          wakeUpScreen: true,
          notificationLayout: NotificationLayout.Default,
          payload: payload,
        ),
      );

      return SessionReminderResult(
        notificationsAllowed: true,
        reminderScheduled: true,
        sentImmediately: true,
        preciseAlarmGranted: preciseAlarmGranted,
      );
    }

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: notificationId,
        channelKey: reminderChannelKey,
        title: title,
        body: body,
        category: NotificationCategory.Reminder,
        wakeUpScreen: true,
        notificationLayout: NotificationLayout.Default,
        payload: payload,
      ),
      schedule: NotificationCalendar.fromDate(
        date: reminderTime,
        allowWhileIdle: true,
        preciseAlarm: preciseAlarmGranted,
      ),
    );

    return SessionReminderResult(
      notificationsAllowed: true,
      reminderScheduled: true,
      sentImmediately: false,
      preciseAlarmGranted: preciseAlarmGranted,
    );
  }

  Future<int> syncTeamSessionReminders({
    required String teamId,
    required String teamName,
    bool requestPermissions = false,
  }) async {
    final notificationAllowed = await _ensureNotificationPermission(
      requestIfNeeded: requestPermissions,
    );
    if (!notificationAllowed) return 0;

    final sessions = await SessionRepository().fetchTeamSessions(teamId);
    var scheduledCount = 0;
    for (final session in sessions) {
      final result = await scheduleSessionReminder(
        teamId: teamId,
        teamName: teamName,
        session: session,
        requestPermissions: false,
      );
      if (result.reminderScheduled) {
        scheduledCount++;
      }
    }
    return scheduledCount;
  }

  Future<int> replaceTeamSessionReminders({
    required String teamId,
    required String teamName,
    bool requestPermissions = false,
  }) async {
    await clearAllSessionReminders();
    return syncTeamSessionReminders(
      teamId: teamId,
      teamName: teamName,
      requestPermissions: requestPermissions,
    );
  }

  Future<void> cancelSessionReminder({
    required String teamId,
    required String sessionId,
  }) async {
    final notificationId = _notificationId(
      teamId: teamId,
      sessionId: sessionId,
    );
    await AwesomeNotifications().cancelSchedule(notificationId);
    await AwesomeNotifications().cancel(notificationId);
  }

  Future<void> clearAllSessionReminders() async {
    await AwesomeNotifications().cancelAllSchedules();
    await AwesomeNotifications().cancelAll();
  }

  Future<bool> _ensureNotificationPermission({
    required bool requestIfNeeded,
  }) async {
    final allowed = await AwesomeNotifications().isNotificationAllowed();
    if (allowed || !requestIfNeeded) {
      return allowed;
    }

    return AwesomeNotifications().requestPermissionToSendNotifications(
      permissions: const [
        NotificationPermission.Alert,
        NotificationPermission.Sound,
        NotificationPermission.Badge,
        NotificationPermission.Vibration,
      ],
    );
  }

  Future<bool> _ensurePreciseAlarmPermission({
    required bool requestIfNeeded,
  }) async {
    final grantedPermissions = await AwesomeNotifications().checkPermissionList(
      permissions: const [NotificationPermission.PreciseAlarms],
    );
    if (grantedPermissions.contains(NotificationPermission.PreciseAlarms)) {
      return true;
    }

    if (!requestIfNeeded) return false;

    return AwesomeNotifications().requestPermissionToSendNotifications(
      permissions: const [NotificationPermission.PreciseAlarms],
    );
  }

  int _notificationId({required String teamId, required String sessionId}) {
    final raw = 'practice:$teamId:$sessionId';
    var hash = 0;
    for (final codeUnit in raw.codeUnits) {
      hash = (hash * 31 + codeUnit) & 0x7fffffff;
    }
    return hash == 0 ? 1 : hash;
  }

  DateTime _parseSessionDateTime(String dayDate, String time) {
    const months = {
      'Jan': 1,
      'Feb': 2,
      'Mar': 3,
      'Apr': 4,
      'May': 5,
      'Jun': 6,
      'Jul': 7,
      'Aug': 8,
      'Sep': 9,
      'Oct': 10,
      'Nov': 11,
      'Dec': 12,
    };

    final dateParts = dayDate.split(', ');
    final monthDay = dateParts.length == 2
        ? dateParts[1].trim().split(' ')
        : const <String>[];
    final timeParts = time.split(':');

    final month = monthDay.length == 2 ? months[monthDay[0]] : null;
    final day = monthDay.length == 2 ? int.tryParse(monthDay[1]) : null;
    final hour = timeParts.length == 2 ? int.tryParse(timeParts[0]) : null;
    final minute = timeParts.length == 2 ? int.tryParse(timeParts[1]) : null;
    final now = DateTime.now();

    return DateTime(
      now.year,
      month ?? now.month,
      day ?? now.day,
      hour ?? 0,
      minute ?? 0,
    );
  }
}
