import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/notification_provider.dart';

/// Service for managing notifications including periodic reminders,
/// background processing, and integration with external systems
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  NotificationProvider? _notificationProvider;
  Timer? _reminderTimer;
  Timer? _cleanupTimer;
  bool _isInitialized = false;

  static const String _enableRemindersKey = 'enable_debt_reminders';
  static const String _reminderIntervalKey = 'reminder_interval_hours';
  static const int _defaultReminderIntervalHours = 24;

  /// Initialize the notification service
  Future<void> initialize(NotificationProvider notificationProvider) async {
    if (_isInitialized) return;

    _notificationProvider = notificationProvider;

    // Start periodic tasks
    _startPeriodicReminders();
    _startPeriodicCleanup();

    _isInitialized = true;
  }

  /// Check if debt reminders are enabled
  Future<bool> get areRemindersEnabled async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enableRemindersKey) ?? true;
  }

  /// Set debt reminders enabled/disabled
  Future<void> setRemindersEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enableRemindersKey, enabled);

    if (enabled) {
      _startPeriodicReminders();
    } else {
      _stopPeriodicReminders();
    }
  }

  /// Get reminder interval in hours
  Future<int> get reminderIntervalHours async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_reminderIntervalKey) ?? _defaultReminderIntervalHours;
  }

  /// Set reminder interval in hours
  Future<void> setReminderInterval(int hours) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_reminderIntervalKey, hours);

    // Restart timer with new interval
    _stopPeriodicReminders();
    _startPeriodicReminders();
  }

  /// Send a bill creation notification
  Future<void> notifyBillCreated({
    required String billId,
    required String groupName,
    required String creatorName,
    required double amount,
    required String currency,
  }) async {
    if (_notificationProvider == null) return;

    try {
      await _notificationProvider!.notifyBillCreated(
        billId: billId,
        groupName: groupName,
        creatorName: creatorName,
        amount: amount,
        currency: currency,
      );

      // In a real app, you might also:
      // - Send push notification
      // - Send email notification
      // - Log to analytics
    } catch (e) {
      debugPrint('Failed to send bill creation notification: $e');
    }
  }

  /// Send debt reminder notifications
  Future<void> notifyDebtReminder({
    required String debtId,
    required String creditorName,
    required double amount,
    required String currency,
    required String groupName,
  }) async {
    if (_notificationProvider == null) return;

    try {
      await _notificationProvider!.notifyDebtReminder(
        debtId: debtId,
        creditorName: creditorName,
        amount: amount,
        currency: currency,
        groupName: groupName,
      );
    } catch (e) {
      debugPrint('Failed to send debt reminder notification: $e');
    }
  }

  /// Send settlement confirmation notification
  Future<void> notifySettlementConfirmation({
    required String paymentId,
    required String payerName,
    required double amount,
    required String currency,
    required String groupName,
  }) async {
    if (_notificationProvider == null) return;

    try {
      await _notificationProvider!.notifySettlementConfirmation(
        paymentId: paymentId,
        payerName: payerName,
        amount: amount,
        currency: currency,
        groupName: groupName,
      );
    } catch (e) {
      debugPrint('Failed to send settlement confirmation notification: $e');
    }
  }

  /// Send group invitation notification
  Future<void> notifyGroupInvitation({
    required String groupId,
    required String groupName,
    required String inviterName,
  }) async {
    if (_notificationProvider == null) return;

    try {
      await _notificationProvider!.notifyGroupInvitation(
        groupId: groupId,
        groupName: groupName,
        inviterName: inviterName,
      );
    } catch (e) {
      debugPrint('Failed to send group invitation notification: $e');
    }
  }

  /// Process debt reminders - this would integrate with your debt/bill data
  Future<void> processDebtReminders() async {
    if (_notificationProvider == null || !await areRemindersEnabled) return;

    try {
      // In a real implementation, you would:
      // 1. Fetch outstanding debts from your data source
      // 2. Check which debts need reminders (based on time since last reminder)
      // 3. Send appropriate notifications

      // For now, this is a placeholder that demonstrates the structure
      debugPrint('Processing debt reminders...');

      // Example: Mock debt data (replace with actual data fetching)
      // final outstandingDebts = await _fetchOutstandingDebts();
      // for (final debt in outstandingDebts) {
      //   if (_shouldSendReminder(debt)) {
      //     await notifyDebtReminder(
      //       debtId: debt.id,
      //       creditorName: debt.creditorName,
      //       amount: debt.amount,
      //       currency: debt.currency,
      //       groupName: debt.groupName,
      //     );
      //   }
      // }
    } catch (e) {
      debugPrint('Failed to process debt reminders: $e');
    }
  }

  /// Start periodic debt reminder checking
  void _startPeriodicReminders() {
    _stopPeriodicReminders();

    areRemindersEnabled.then((enabled) {
      if (!enabled) return;

      reminderIntervalHours.then((intervalHours) {
        final duration = Duration(hours: intervalHours);
        _reminderTimer = Timer.periodic(duration, (timer) {
          processDebtReminders();
        });
      });
    });
  }

  /// Stop periodic debt reminder checking
  void _stopPeriodicReminders() {
    _reminderTimer?.cancel();
    _reminderTimer = null;
  }

  /// Start periodic cleanup of old notifications
  void _startPeriodicCleanup() {
    _stopPeriodicCleanup();

    // Clean up old notifications daily
    _cleanupTimer = Timer.periodic(const Duration(days: 1), (timer) {
      _notificationProvider?.cleanupOldNotifications();
    });
  }

  /// Stop periodic cleanup
  void _stopPeriodicCleanup() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
  }

  /// Get notification summary for display
  Future<Map<String, dynamic>> getNotificationSummary() async {
    if (_notificationProvider == null) {
      return {'total': 0, 'unread': 0, 'types': <String, int>{}, 'recent': 0};
    }

    final notifications = _notificationProvider!.notifications;
    final unreadCount = _notificationProvider!.unreadCount;
    final recentCount = _notificationProvider!.recentNotifications.length;

    // Count notifications by type
    final typeCount = <String, int>{};
    for (final notification in notifications) {
      final typeName = notification.type.name;
      typeCount[typeName] = (typeCount[typeName] ?? 0) + 1;
    }

    return {
      'total': notifications.length,
      'unread': unreadCount,
      'types': typeCount,
      'recent': recentCount,
    };
  }

  /// Dispose of the service
  void dispose() {
    _stopPeriodicReminders();
    _stopPeriodicCleanup();
    _notificationProvider = null;
    _isInitialized = false;
  }
}

/// Extension methods for easier notification handling
extension NotificationServiceExtension on NotificationService {
  /// Quick method to send a bill notification with minimal parameters
  Future<void> quickNotifyBill({
    required String billId,
    required String groupName,
    required String creatorName,
    required double amount,
  }) async {
    await notifyBillCreated(
      billId: billId,
      groupName: groupName,
      creatorName: creatorName,
      amount: amount,
      currency: 'USD', // Default currency
    );
  }

  /// Quick method to send a debt reminder with minimal parameters
  Future<void> quickNotifyDebt({
    required String debtId,
    required String creditorName,
    required double amount,
    required String groupName,
  }) async {
    await notifyDebtReminder(
      debtId: debtId,
      creditorName: creditorName,
      amount: amount,
      currency: 'USD', // Default currency
      groupName: groupName,
    );
  }
}
