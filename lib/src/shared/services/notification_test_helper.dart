import 'package:flutter/foundation.dart';
import 'notification_service.dart';
import '../providers/notification_provider.dart';

/// Helper class for testing notifications in development
class NotificationTestHelper {
  static final NotificationService _notificationService = NotificationService();

  /// Generate sample notifications for testing
  static Future<void> generateSampleNotifications(
    NotificationProvider provider,
  ) async {
    if (!kDebugMode) {
      print('Sample notifications can only be generated in debug mode');
      return;
    }

    try {
      // Sample bill creation notification
      await _notificationService.notifyBillCreated(
        billId: 'test_bill_1',
        groupName: 'Roommates',
        creatorName: 'Alice',
        amount: 45.50,
        currency: 'USD',
      );

      // Sample debt reminder notification
      await _notificationService.notifyDebtReminder(
        debtId: 'test_debt_1',
        creditorName: 'Bob',
        amount: 25.00,
        currency: 'USD',
        groupName: 'Lunch Group',
      );

      // Sample settlement confirmation
      await _notificationService.notifySettlementConfirmation(
        paymentId: 'test_payment_1',
        payerName: 'Charlie',
        amount: 15.75,
        currency: 'USD',
        groupName: 'Coffee Fund',
      );

      // Sample group invitation
      await _notificationService.notifyGroupInvitation(
        groupId: 'test_group_1',
        groupName: 'Weekend Trip',
        inviterName: 'Diana',
      );
    } catch (e) {
      print('Error generating sample notifications: $e');
    }
  }

  /// Clear all test notifications
  static Future<void> clearTestNotifications(
    NotificationProvider provider,
  ) async {
    try {
      await provider.clearAllNotifications();
    } catch (e) {
      print('Error clearing test notifications: $e');
    }
  }

  /// Get notification statistics for debugging
  static Future<Map<String, dynamic>> getNotificationStats() async {
    try {
      return await _notificationService.getNotificationSummary();
    } catch (e) {
      print('Error getting notification stats: $e');
      return {};
    }
  }
}
