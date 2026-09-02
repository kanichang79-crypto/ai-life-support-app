import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/alarm.dart';

/// flutter_local_notifications を使い、アラームの通知を端末に登録・解除するサービス。
class NotificationService {
  NotificationService._internal();

  static final NotificationService instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static const _channelId = 'alarm_channel';
  static const _channelName = 'アラーム';
  static const _channelDescription = '目覚まし(アラーム)の通知';

  Future<void> init() async {
    if (_initialized) return;

    tzdata.initializeTimeZones();
    try {
      final timeZoneName = (await FlutterTimezone.getLocalTimezone()).identifier;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (_) {
      // 端末のタイムゾーンが取得できない場合は既定のタイムゾーンのまま続行する。
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    // iOS/macOS の権限リクエストは初期化直後に明示的に行うため、
    // initialize() 時点では自動リクエストしない。
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(settings: initSettings);

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    await _plugin
        .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    _initialized = true;
  }

  NotificationDetails get _details => const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.max,
          priority: Priority.high,
          category: AndroidNotificationCategory.alarm,
          fullScreenIntent: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

  /// [alarm] の通知をスケジュールし直す。既存の予約があれば一度すべて解除してから
  /// 有効な場合のみ再登録する。
  Future<void> scheduleAlarm(Alarm alarm) async {
    await cancelAlarm(alarm);
    if (!alarm.isEnabled) return;

    if (alarm.repeatDays.isEmpty) {
      final scheduledDate = _nextInstanceOfTime(alarm.hour, alarm.minute);
      await _plugin.zonedSchedule(
        id: alarm.notificationBaseId,
        title: alarm.label.isEmpty ? 'アラーム' : alarm.label,
        body: '設定した時刻になりました',
        scheduledDate: scheduledDate,
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        payload: alarm.id,
      );
      return;
    }

    for (final weekday in alarm.repeatDays) {
      final scheduledDate =
          _nextInstanceOfWeekdayTime(weekday, alarm.hour, alarm.minute);
      await _plugin.zonedSchedule(
        id: _weekdayNotificationId(alarm, weekday),
        title: alarm.label.isEmpty ? 'アラーム' : alarm.label,
        body: '設定した時刻になりました',
        scheduledDate: scheduledDate,
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: alarm.id,
      );
    }
  }

  /// [alarm] に紐づくすべての予約通知(単発・曜日ごとの繰り返し)を解除する。
  Future<void> cancelAlarm(Alarm alarm) async {
    await _plugin.cancel(id: alarm.notificationBaseId);
    for (var weekday = DateTime.monday; weekday <= DateTime.sunday; weekday++) {
      await _plugin.cancel(id: _weekdayNotificationId(alarm, weekday));
    }
  }

  int _weekdayNotificationId(Alarm alarm, int weekday) =>
      alarm.notificationBaseId * 10 + weekday;

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!scheduledDate.isAfter(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  tz.TZDateTime _nextInstanceOfWeekdayTime(int weekday, int hour, int minute) {
    var scheduledDate = _nextInstanceOfTime(hour, minute);
    while (scheduledDate.weekday != weekday) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
