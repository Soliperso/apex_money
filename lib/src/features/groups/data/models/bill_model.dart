class BillModel {
  final String? id;
  final String groupId;
  final String title;
  final String description;
  final double totalAmount;
  final String currency;
  final String paidByUserId;
  final DateTime dateCreated;
  final DateTime? dueDate;
  final String status; // 'active', 'settled', 'cancelled'
  final String splitMethod; // 'equal', 'percentage', 'custom'
  final List<BillSplitModel> splits;
  final Map<String, dynamic>? metadata;

  BillModel({
    this.id,
    required this.groupId,
    required this.title,
    required this.description,
    required this.totalAmount,
    required this.currency,
    required this.paidByUserId,
    required this.dateCreated,
    this.dueDate,
    required this.status,
    required this.splitMethod,
    required this.splits,
    this.metadata,
  });

  factory BillModel.fromJson(Map<String, dynamic> json) {
    return BillModel(
      id: json['id']?.toString(),
      groupId: json['group_id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      totalAmount: (json['total_amount'] is int)
          ? (json['total_amount'] as int).toDouble()
          : (json['total_amount'] as double? ?? 0.0),
      currency: json['currency'] ?? 'USD',
      paidByUserId: json['paid_by_user_id']?.toString() ?? '',
      dateCreated: json['date_created'] != null
          ? DateTime.parse(json['date_created'])
          : DateTime.now(),
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'])
          : null,
      status: json['status'] ?? 'active',
      splitMethod: json['split_method'] ?? 'equal',
      splits: (json['splits'] as List<dynamic>? ?? [])
          .map((split) => BillSplitModel.fromJson(split))
          .toList(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'title': title,
      'description': description,
      'total_amount': totalAmount,
      'currency': currency,
      'paid_by_user_id': paidByUserId,
      'date_created': dateCreated.toIso8601String(),
      'due_date': dueDate?.toIso8601String(),
      'status': status,
      'split_method': splitMethod,
      'splits': splits.map((split) => split.toJson()).toList(),
      'metadata': metadata,
    };
  }

  BillModel copyWith({
    String? id,
    String? groupId,
    String? title,
    String? description,
    double? totalAmount,
    String? currency,
    String? paidByUserId,
    DateTime? dateCreated,
    DateTime? dueDate,
    String? status,
    String? splitMethod,
    List<BillSplitModel>? splits,
    Map<String, dynamic>? metadata,
  }) {
    return BillModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      title: title ?? this.title,
      description: description ?? this.description,
      totalAmount: totalAmount ?? this.totalAmount,
      currency: currency ?? this.currency,
      paidByUserId: paidByUserId ?? this.paidByUserId,
      dateCreated: dateCreated ?? this.dateCreated,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      splitMethod: splitMethod ?? this.splitMethod,
      splits: splits ?? this.splits,
      metadata: metadata ?? this.metadata,
    );
  }
}

class BillSplitModel {
  final String? id;
  final String billId;
  final String userId;
  final double amount;
  final double percentage;
  final bool isPaid;
  final DateTime? paidDate;
  final String? paymentMethod;

  BillSplitModel({
    this.id,
    required this.billId,
    required this.userId,
    required this.amount,
    required this.percentage,
    this.isPaid = false,
    this.paidDate,
    this.paymentMethod,
  });

  factory BillSplitModel.fromJson(Map<String, dynamic> json) {
    return BillSplitModel(
      id: json['id']?.toString(),
      billId: json['bill_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      amount: (json['amount'] is int)
          ? (json['amount'] as int).toDouble()
          : (json['amount'] as double? ?? 0.0),
      percentage: (json['percentage'] is int)
          ? (json['percentage'] as int).toDouble()
          : (json['percentage'] as double? ?? 0.0),
      isPaid: json['is_paid'] ?? false,
      paidDate: json['paid_date'] != null
          ? DateTime.parse(json['paid_date'])
          : null,
      paymentMethod: json['payment_method'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bill_id': billId,
      'user_id': userId,
      'amount': amount,
      'percentage': percentage,
      'is_paid': isPaid,
      'paid_date': paidDate?.toIso8601String(),
      'payment_method': paymentMethod,
    };
  }

  BillSplitModel copyWith({
    String? id,
    String? billId,
    String? userId,
    double? amount,
    double? percentage,
    bool? isPaid,
    DateTime? paidDate,
    String? paymentMethod,
  }) {
    return BillSplitModel(
      id: id ?? this.id,
      billId: billId ?? this.billId,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      percentage: percentage ?? this.percentage,
      isPaid: isPaid ?? this.isPaid,
      paidDate: paidDate ?? this.paidDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }
}