class Transaction {
  final String description;
  final double amount;
  final DateTime date;
  final String category;
  final String type;
  final String status;
  final String paymentMethodId;
  final String accountId;
  final String? toAccountId;
  final String? notes;
  final bool isRecurring;
  final String? recurringFrequency;
  final String? locationName;
  final double? latitude;
  final double? longitude;

  Transaction({
    required this.description,
    required this.amount,
    required this.date,
    required this.category,
    required this.type,
    required this.status,
    required this.paymentMethodId,
    required this.accountId,
    this.toAccountId,
    this.notes,
    required this.isRecurring,
    this.recurringFrequency,
    this.locationName,
    this.latitude,
    this.longitude,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      description: json['description'],
      amount: json['amount'],
      date: DateTime.parse(json['date']),
      category: json['category'],
      type: json['type'],
      status: json['status'],
      paymentMethodId: json['payment_method_id'],
      accountId: json['account_id'],
      toAccountId: json['to_account_id'],
      notes: json['notes'],
      isRecurring: json['is_recurring'],
      recurringFrequency: json['recurring_frequency'],
      locationName: json['location_name'],
      latitude: json['latitude'],
      longitude: json['longitude'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'amount': amount,
      'date': date.toIso8601String(),
      'category': category,
      'type': type,
      'status': status,
      'payment_method_id': paymentMethodId,
      'account_id': accountId,
      'to_account_id': toAccountId,
      'notes': notes,
      'is_recurring': isRecurring,
      'recurring_frequency': recurringFrequency,
      'location_name': locationName,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
