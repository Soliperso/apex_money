import 'package:flutter/foundation.dart';

/// Enum representing different types of notifications in the app
enum NotificationType {
  billCreated,
  debtReminder,
  settlementConfirmation,
  groupInvitation,
  paymentReceived,
  systemAlert,
}

/// Model representing a notification in the app
class NotificationModel {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String? relatedEntityId; // Group ID, Bill ID, etc.
  final String? relatedEntityType; // 'group', 'bill', 'payment', etc.
  final Map<String, dynamic>?
  metadata; // Additional data for navigation/actions

  const NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.relatedEntityId,
    this.relatedEntityType,
    this.metadata,
  });

  /// Creates a NotificationModel from JSON
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NotificationType.systemAlert,
      ),
      title: json['title'] as String,
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['is_read'] as bool? ?? false,
      relatedEntityId: json['related_entity_id'] as String?,
      relatedEntityType: json['related_entity_type'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Converts NotificationModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'is_read': isRead,
      'related_entity_id': relatedEntityId,
      'related_entity_type': relatedEntityType,
      'metadata': metadata,
    };
  }

  /// Creates a copy of this notification with updated values
  NotificationModel copyWith({
    String? id,
    NotificationType? type,
    String? title,
    String? message,
    DateTime? timestamp,
    bool? isRead,
    String? relatedEntityId,
    String? relatedEntityType,
    Map<String, dynamic>? metadata,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      relatedEntityId: relatedEntityId ?? this.relatedEntityId,
      relatedEntityType: relatedEntityType ?? this.relatedEntityType,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Factory methods for creating specific notification types

  /// Creates a bill creation notification
  static NotificationModel billCreated({
    required String billId,
    required String groupName,
    required String creatorName,
    required double amount,
    required String currency,
  }) {
    return NotificationModel(
      id: 'bill_${billId}_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.billCreated,
      title: 'New Bill Created',
      message:
          '$creatorName created a new bill for $currency$amount in $groupName',
      timestamp: DateTime.now(),
      relatedEntityId: billId,
      relatedEntityType: 'bill',
      metadata: {
        'group_name': groupName,
        'creator_name': creatorName,
        'amount': amount,
        'currency': currency,
      },
    );
  }

  /// Creates a debt reminder notification
  static NotificationModel debtReminder({
    required String debtId,
    required String creditorName,
    required double amount,
    required String currency,
    required String groupName,
  }) {
    return NotificationModel(
      id: 'debt_${debtId}_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.debtReminder,
      title: 'Outstanding Debt',
      message: 'You owe $creditorName $currency$amount in $groupName',
      timestamp: DateTime.now(),
      relatedEntityId: debtId,
      relatedEntityType: 'debt',
      metadata: {
        'creditor_name': creditorName,
        'amount': amount,
        'currency': currency,
        'group_name': groupName,
      },
    );
  }

  /// Creates a settlement confirmation notification
  static NotificationModel settlementConfirmation({
    required String paymentId,
    required String payerName,
    required double amount,
    required String currency,
    required String groupName,
  }) {
    return NotificationModel(
      id: 'settlement_${paymentId}_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.settlementConfirmation,
      title: 'Payment Received',
      message: '$payerName paid you $currency$amount in $groupName',
      timestamp: DateTime.now(),
      relatedEntityId: paymentId,
      relatedEntityType: 'payment',
      metadata: {
        'payer_name': payerName,
        'amount': amount,
        'currency': currency,
        'group_name': groupName,
      },
    );
  }

  /// Creates a group invitation notification
  static NotificationModel groupInvitation({
    required String groupId,
    required String groupName,
    required String inviterName,
  }) {
    return NotificationModel(
      id: 'invite_${groupId}_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.groupInvitation,
      title: 'Group Invitation',
      message: '$inviterName invited you to join $groupName',
      timestamp: DateTime.now(),
      relatedEntityId: groupId,
      relatedEntityType: 'group',
      metadata: {'group_name': groupName, 'inviter_name': inviterName},
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationModel &&
        other.id == id &&
        other.type == type &&
        other.title == title &&
        other.message == message &&
        other.timestamp == timestamp &&
        other.isRead == isRead &&
        other.relatedEntityId == relatedEntityId &&
        other.relatedEntityType == relatedEntityType &&
        mapEquals(other.metadata, metadata);
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      type,
      title,
      message,
      timestamp,
      isRead,
      relatedEntityId,
      relatedEntityType,
      metadata,
    );
  }

  @override
  String toString() {
    return 'NotificationModel(id: $id, type: $type, title: $title, message: $message, timestamp: $timestamp, isRead: $isRead, relatedEntityId: $relatedEntityId, relatedEntityType: $relatedEntityType, metadata: $metadata)';
  }
}
