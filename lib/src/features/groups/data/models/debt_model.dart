class DebtModel {
  final String? id;
  final String groupId;
  final String debtorUserId; // Person who owes money
  final String creditorUserId; // Person who is owed money
  final double amount;
  final String currency;
  final String status; // 'active', 'settled', 'partial'
  final List<String> billIds; // Bills that contribute to this debt
  final DateTime createdDate;
  final DateTime? settledDate;
  final List<PaymentModel> payments;

  DebtModel({
    this.id,
    required this.groupId,
    required this.debtorUserId,
    required this.creditorUserId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.billIds,
    required this.createdDate,
    this.settledDate,
    required this.payments,
  });

  factory DebtModel.fromJson(Map<String, dynamic> json) {
    return DebtModel(
      id: json['id']?.toString(),
      groupId: json['group_id']?.toString() ?? '',
      debtorUserId: json['debtor_user_id']?.toString() ?? '',
      creditorUserId: json['creditor_user_id']?.toString() ?? '',
      amount: (json['amount'] is int)
          ? (json['amount'] as int).toDouble()
          : (json['amount'] as double? ?? 0.0),
      currency: json['currency'] ?? 'USD',
      status: json['status'] ?? 'active',
      billIds: (json['bill_ids'] as List<dynamic>? ?? [])
          .map((id) => id.toString())
          .toList(),
      createdDate: json['created_date'] != null
          ? DateTime.parse(json['created_date'])
          : DateTime.now(),
      settledDate: json['settled_date'] != null
          ? DateTime.parse(json['settled_date'])
          : null,
      payments: (json['payments'] as List<dynamic>? ?? [])
          .map((payment) => PaymentModel.fromJson(payment))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'debtor_user_id': debtorUserId,
      'creditor_user_id': creditorUserId,
      'amount': amount,
      'currency': currency,
      'status': status,
      'bill_ids': billIds,
      'created_date': createdDate.toIso8601String(),
      'settled_date': settledDate?.toIso8601String(),
      'payments': payments.map((payment) => payment.toJson()).toList(),
    };
  }

  double get remainingAmount {
    final totalPaid = payments.fold<double>(
      0.0,
      (sum, payment) => sum + payment.amount,
    );
    return amount - totalPaid;
  }

  bool get isFullySettled => remainingAmount <= 0.01; // Account for floating point precision

  DebtModel copyWith({
    String? id,
    String? groupId,
    String? debtorUserId,
    String? creditorUserId,
    double? amount,
    String? currency,
    String? status,
    List<String>? billIds,
    DateTime? createdDate,
    DateTime? settledDate,
    List<PaymentModel>? payments,
  }) {
    return DebtModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      debtorUserId: debtorUserId ?? this.debtorUserId,
      creditorUserId: creditorUserId ?? this.creditorUserId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      billIds: billIds ?? this.billIds,
      createdDate: createdDate ?? this.createdDate,
      settledDate: settledDate ?? this.settledDate,
      payments: payments ?? this.payments,
    );
  }
}

class PaymentModel {
  final String? id;
  final String debtId;
  final String payerUserId;
  final String receiverUserId;
  final double amount;
  final String currency;
  final DateTime paymentDate;
  final String paymentMethod; // 'cash', 'bank_transfer', 'app_payment', etc.
  final String? notes;
  final bool isConfirmed;

  PaymentModel({
    this.id,
    required this.debtId,
    required this.payerUserId,
    required this.receiverUserId,
    required this.amount,
    required this.currency,
    required this.paymentDate,
    required this.paymentMethod,
    this.notes,
    this.isConfirmed = false,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id']?.toString(),
      debtId: json['debt_id']?.toString() ?? '',
      payerUserId: json['payer_user_id']?.toString() ?? '',
      receiverUserId: json['receiver_user_id']?.toString() ?? '',
      amount: (json['amount'] is int)
          ? (json['amount'] as int).toDouble()
          : (json['amount'] as double? ?? 0.0),
      currency: json['currency'] ?? 'USD',
      paymentDate: json['payment_date'] != null
          ? DateTime.parse(json['payment_date'])
          : DateTime.now(),
      paymentMethod: json['payment_method'] ?? 'cash',
      notes: json['notes'],
      isConfirmed: json['is_confirmed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'debt_id': debtId,
      'payer_user_id': payerUserId,
      'receiver_user_id': receiverUserId,
      'amount': amount,
      'currency': currency,
      'payment_date': paymentDate.toIso8601String(),
      'payment_method': paymentMethod,
      'notes': notes,
      'is_confirmed': isConfirmed,
    };
  }

  PaymentModel copyWith({
    String? id,
    String? debtId,
    String? payerUserId,
    String? receiverUserId,
    double? amount,
    String? currency,
    DateTime? paymentDate,
    String? paymentMethod,
    String? notes,
    bool? isConfirmed,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      debtId: debtId ?? this.debtId,
      payerUserId: payerUserId ?? this.payerUserId,
      receiverUserId: receiverUserId ?? this.receiverUserId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      paymentDate: paymentDate ?? this.paymentDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      isConfirmed: isConfirmed ?? this.isConfirmed,
    );
  }
}