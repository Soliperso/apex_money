class DebtModel {
  final String? id;
  final String groupId;
  final String debtorUserId; // Person who owes money
  final String? debtorName; // Added to match DB model
  final String creditorUserId; // Person who is owed money
  final String? creditorName; // Added to match DB model
  final double originalAmount; // Renamed to match DB model
  final double paidAmount; // Added to match DB model
  final double remainingAmount; // Added to match DB model
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
    this.debtorName,
    required this.creditorUserId,
    this.creditorName,
    required this.originalAmount,
    required this.paidAmount,
    required this.remainingAmount,
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
      debtorName: json['debtor_name']?.toString(),
      creditorUserId: json['creditor_user_id']?.toString() ?? '',
      creditorName: json['creditor_name']?.toString(),
      originalAmount:
          (json['original_amount'] is int)
              ? (json['original_amount'] as int).toDouble()
              : (json['original_amount'] as double? ?? 0.0),
      paidAmount:
          (json['paid_amount'] is int)
              ? (json['paid_amount'] as int).toDouble()
              : (json['paid_amount'] as double? ?? 0.0),
      remainingAmount:
          (json['remaining_amount'] is int)
              ? (json['remaining_amount'] as int).toDouble()
              : (json['remaining_amount'] as double? ?? 0.0),
      currency: json['currency'] ?? 'USD',
      status: json['status'] ?? 'active',
      billIds:
          (json['bill_ids'] as List<dynamic>? ?? [])
              .map((id) => id.toString())
              .toList(),
      createdDate:
          json['created_date'] != null
              ? DateTime.parse(json['created_date'])
              : DateTime.now(),
      settledDate:
          json['settled_date'] != null
              ? DateTime.parse(json['settled_date'])
              : null,
      payments:
          (json['payments'] as List<dynamic>? ?? [])
              .map((payment) => PaymentModel.fromJson(payment))
              .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'debtor_user_id': debtorUserId,
      'debtor_name': debtorName,
      'creditor_user_id': creditorUserId,
      'creditor_name': creditorName,
      'original_amount': originalAmount,
      'paid_amount': paidAmount,
      'remaining_amount': remainingAmount,
      'currency': currency,
      'status': status,
      'bill_ids': billIds,
      'created_date': createdDate.toIso8601String(),
      'settled_date': settledDate?.toIso8601String(),
      'payments': payments.map((payment) => payment.toJson()).toList(),
    };
  }

  bool get isFullySettled =>
      remainingAmount <= 0.01; // Account for floating point precision

  DebtModel copyWith({
    String? id,
    String? groupId,
    String? debtorUserId,
    String? debtorName,
    String? creditorUserId,
    String? creditorName,
    double? originalAmount,
    double? paidAmount,
    double? remainingAmount,
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
      debtorName: debtorName ?? this.debtorName,
      creditorUserId: creditorUserId ?? this.creditorUserId,
      creditorName: creditorName ?? this.creditorName,
      originalAmount: originalAmount ?? this.originalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
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
      amount:
          (json['amount'] is int)
              ? (json['amount'] as int).toDouble()
              : (json['amount'] as double? ?? 0.0),
      currency: json['currency'] ?? 'USD',
      paymentDate:
          json['payment_date'] != null
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
