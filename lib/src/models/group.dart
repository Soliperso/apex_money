class Group {
  final String id;
  final String name;
  final String description;
  final List<String> members;
  final String createdBy;
  final DateTime createdAt;
  final double totalAmount;
  final String currency;

  const Group({
    required this.id,
    required this.name,
    required this.description,
    required this.members,
    required this.createdBy,
    required this.createdAt,
    required this.totalAmount,
    this.currency = 'USD',
  });

  Group copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? members,
    String? createdBy,
    DateTime? createdAt,
    double? totalAmount,
    String? currency,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      members: members ?? this.members,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      totalAmount: totalAmount ?? this.totalAmount,
      currency: currency ?? this.currency,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'members': members,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'totalAmount': totalAmount,
      'currency': currency,
    };
  }

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      members: List<String>.from(json['members']),
      createdBy: json['createdBy'],
      createdAt: DateTime.parse(json['createdAt']),
      totalAmount: json['totalAmount'].toDouble(),
      currency: json['currency'] ?? 'USD',
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Group && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Group(id: $id, name: $name, members: ${members.length}, totalAmount: $totalAmount)';
  }
}
