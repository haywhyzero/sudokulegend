import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();

  static const String _notificationEnabledKey = 'notification_enabled';
  static const String _lastPlayedDateKey = 'last_played_date';

  /// Initialize the notification service
  Future<void> initialize() async {
    tz.initializeTimeZones();
    
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings( 
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  // TODO: check where notifications are called and scheduled. Also fix the tap trigger

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // Navigate to Daily Challenge page
    // You can use a navigation key or callback here
    print('Notification tapped: ${response.payload}');
  }

  /// Request notification permissions (iOS)
  Future<bool> requestPermissions() async {
    final result = await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
    
    return result ?? true; // Android doesn't need runtime permission
  }

  /// Schedule daily challenge reminder
  Future<void> scheduleDailyChallengeReminder({
    int hour = 9,
    int minute = 0,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool(_notificationEnabledKey) ?? false;
    
    if (!isEnabled) return;

    await _notifications.zonedSchedule(
      0, // Notification ID
      '🏆 Daily Challenge Available!',
      'Complete today\'s Sudoku challenge and earn your trophy!',
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_challenge_channel',
          'Daily Challenge',
          channelDescription: 'Reminders for daily Sudoku challenges',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'daily_challenge',
    );
  }

  /// Schedule reminder if user hasn't played today (afternoon reminder)
  Future<void> scheduleAfternoonReminder() async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool(_notificationEnabledKey) ?? false;
    
    if (!isEnabled) return;

    final hasPlayedToday = await _hasPlayedToday();
    if (hasPlayedToday) return;

    await _notifications.zonedSchedule(
      1, // Different notification ID
      '⏰ Don\'t Forget Your Daily Challenge!',
      'You haven\'t played today\'s challenge yet. Keep your streak going!',
      _nextInstanceOfTime(15, 0), // 3 PM
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'reminder_channel',
          'Challenge Reminders',
          channelDescription: 'Reminders to complete daily challenges',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'afternoon_reminder',
    );
  }

  /// Schedule evening reminder if still haven't played
  Future<void> scheduleEveningReminder() async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool(_notificationEnabledKey) ?? false;
    
    if (!isEnabled) return;

    final hasPlayedToday = await _hasPlayedToday();
    if (hasPlayedToday) return;

    await _notifications.zonedSchedule(
      2, // Different notification ID
      '🌙 Last Chance for Today\'s Challenge!',
      'The day is almost over! Complete your daily challenge now.',
      _nextInstanceOfTime(20, 0), // 8 PM
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'reminder_channel',
          'Challenge Reminders',
          channelDescription: 'Reminders to complete daily challenges',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'evening_reminder',
    );
  }

  /// Schedule all daily reminders
  Future<void> scheduleAllReminders() async {
    await scheduleDailyChallengeReminder(hour: 9, minute: 0);
    await scheduleAfternoonReminder();
    await scheduleEveningReminder();
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Cancel specific notification
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  Future<bool> hasPlayedTodayCheck() async {
    return _hasPlayedToday();
  }

  /// Enable notifications
  Future<void> enableNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationEnabledKey, true);
    await scheduleAllReminders();
  }


  /// Disable notifications
  Future<void> disableNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationEnabledKey, false);
    await cancelAllNotifications();
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationEnabledKey) ?? false;
  }

  /// Mark today as played
  Future<void> markTodayAsPlayed() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    await prefs.setString(_lastPlayedDateKey, today);
    
    // Cancel afternoon and evening reminders since user played
    await cancelNotification(1);
    await cancelNotification(2);
  }

  /// Check if user played today
  Future<bool> _hasPlayedToday() async {
    final prefs = await SharedPreferences.getInstance();
    final lastPlayed = prefs.getString(_lastPlayedDateKey);
    if (lastPlayed == null) return false;
    
    final today = DateTime.now().toIso8601String().split('T')[0];
    return lastPlayed == today;
  }

  /// Get next instance of specified time
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    

    // If the scheduled time has passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  /// Show immediate notification (for testing)
  Future<void> showImmediateNotification({
    String title = 'Daily Challenge',
    String body = 'Time to play!',
  }) async {
    await _notifications.show(
      999,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'test_channel',
          'Test Notifications',
          channelDescription: 'Test notification channel',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'test',
    );
  }

  /// Get pending notifications (for debugging)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// Schedule streak reminder (when user has active streak)
  Future<void> scheduleStreakReminder(int streakDays) async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool(_notificationEnabledKey) ?? false;
    
    if (!isEnabled) return;

    await _notifications.zonedSchedule(
      3,
      '🔥 Keep Your $streakDays-Day Streak Alive!',
      'Don\'t break your streak! Complete today\'s challenge.',
      _nextInstanceOfTime(10, 0),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'streak_channel',
          'Streak Reminders',
          channelDescription: 'Reminders about active streaks',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'streak_reminder',
    );
  }
}