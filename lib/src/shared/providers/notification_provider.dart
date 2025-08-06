import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/notification_model.dart';

/// Provider for managing notifications state throughout the app
class NotificationProvider extends ChangeNotifier {
  static const String _notificationsKey = 'notifications';
  static const String _lastReadKey = 'last_notification_read';

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;
  DateTime? _lastReadTime;

  /// Getters
  List<NotificationModel> get notifications =>
      List.unmodifiable(_notifications);
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get lastReadTime => _lastReadTime;

  /// Get unread notifications
  List<NotificationModel> get unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();

  /// Get unread notifications count
  int get unreadCount => unreadNotifications.length;

  /// Get notifications by type
  List<NotificationModel> getNotificationsByType(NotificationType type) =>
      _notifications.where((n) => n.type == type).toList();

  /// Get recent notifications (last 7 days)
  List<NotificationModel> get recentNotifications {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return _notifications.where((n) => n.timestamp.isAfter(weekAgo)).toList();
  }

  /// Initialize the provider and load notifications from storage
  Future<void> initialize() async {
    _setLoading(true);
    try {
      await _loadNotifications();
      await _loadLastReadTime();
      _setError(null);
    } catch (e) {
      _setError('Failed to load notifications: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Add a new notification
  Future<void> addNotification(NotificationModel notification) async {
    try {
      _notifications.insert(0, notification); // Add to beginning of list
      await _saveNotifications();
      notifyListeners();
    } catch (e) {
      _setError('Failed to add notification: ${e.toString()}');
    }
  }

  /// Add multiple notifications
  Future<void> addNotifications(List<NotificationModel> notifications) async {
    try {
      _notifications.insertAll(0, notifications);
      await _saveNotifications();
      notifyListeners();
    } catch (e) {
      _setError('Failed to add notifications: ${e.toString()}');
    }
  }

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        await _saveNotifications();
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to mark notification as read: ${e.toString()}');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      _notifications =
          _notifications.map((n) => n.copyWith(isRead: true)).toList();
      _lastReadTime = DateTime.now();
      await _saveNotifications();
      await _saveLastReadTime();
      notifyListeners();
    } catch (e) {
      _setError('Failed to mark all notifications as read: ${e.toString()}');
    }
  }

  /// Remove a notification
  Future<void> removeNotification(String notificationId) async {
    try {
      _notifications.removeWhere((n) => n.id == notificationId);
      await _saveNotifications();
      notifyListeners();
    } catch (e) {
      _setError('Failed to remove notification: ${e.toString()}');
    }
  }

  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    try {
      _notifications.clear();
      await _saveNotifications();
      notifyListeners();
    } catch (e) {
      _setError('Failed to clear notifications: ${e.toString()}');
    }
  }

  /// Remove old notifications (older than 30 days)
  Future<void> cleanupOldNotifications() async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      _notifications.removeWhere((n) => n.timestamp.isBefore(thirtyDaysAgo));
      await _saveNotifications();
      notifyListeners();
    } catch (e) {
      _setError('Failed to cleanup old notifications: ${e.toString()}');
    }
  }

  /// Create and add a bill creation notification
  Future<void> notifyBillCreated({
    required String billId,
    required String groupName,
    required String creatorName,
    required double amount,
    required String currency,
  }) async {
    final notification = NotificationModel.billCreated(
      billId: billId,
      groupName: groupName,
      creatorName: creatorName,
      amount: amount,
      currency: currency,
    );
    await addNotification(notification);
  }

  /// Create and add a debt reminder notification
  Future<void> notifyDebtReminder({
    required String debtId,
    required String creditorName,
    required double amount,
    required String currency,
    required String groupName,
  }) async {
    final notification = NotificationModel.debtReminder(
      debtId: debtId,
      creditorName: creditorName,
      amount: amount,
      currency: currency,
      groupName: groupName,
    );
    await addNotification(notification);
  }

  /// Create and add a settlement confirmation notification
  Future<void> notifySettlementConfirmation({
    required String paymentId,
    required String payerName,
    required double amount,
    required String currency,
    required String groupName,
  }) async {
    final notification = NotificationModel.settlementConfirmation(
      paymentId: paymentId,
      payerName: payerName,
      amount: amount,
      currency: currency,
      groupName: groupName,
    );
    await addNotification(notification);
  }

  /// Create and add a group invitation notification
  Future<void> notifyGroupInvitation({
    required String groupId,
    required String groupName,
    required String inviterName,
  }) async {
    final notification = NotificationModel.groupInvitation(
      groupId: groupId,
      groupName: groupName,
      inviterName: inviterName,
    );
    await addNotification(notification);
  }

  /// Private helper methods

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  /// Load notifications from SharedPreferences
  Future<void> _loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getStringList(_notificationsKey);

      if (notificationsJson != null) {
        _notifications =
            notificationsJson
                .map((json) => NotificationModel.fromJson(jsonDecode(json)))
                .toList();
      }
    } catch (e) {
      print('Error loading notifications: $e');
      _notifications = [];
    }
  }

  /// Save notifications to SharedPreferences
  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson =
          _notifications
              .map((notification) => jsonEncode(notification.toJson()))
              .toList();
      await prefs.setStringList(_notificationsKey, notificationsJson);
    } catch (e) {
      print('Error saving notifications: $e');
    }
  }

  /// Load last read time from SharedPreferences
  Future<void> _loadLastReadTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastReadMillis = prefs.getInt(_lastReadKey);
      if (lastReadMillis != null) {
        _lastReadTime = DateTime.fromMillisecondsSinceEpoch(lastReadMillis);
      }
    } catch (e) {
      print('Error loading last read time: $e');
    }
  }

  /// Save last read time to SharedPreferences
  Future<void> _saveLastReadTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_lastReadTime != null) {
        await prefs.setInt(_lastReadKey, _lastReadTime!.millisecondsSinceEpoch);
      }
    } catch (e) {
      print('Error saving last read time: $e');
    }
  }
}
