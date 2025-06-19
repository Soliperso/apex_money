// Goal types that determine how transactions contribute to progress
enum GoalType {
  savings, // Accumulate positive amounts (income, transfers in)
  expenseLimit, // Track spending in categories (don't exceed target)
  incomeTarget, // Track income in specific categories
  netWorth, // Track overall balance increase
  debtPaydown, // Track debt payments (specific to debt categories)
}

class Goal {
  final String? id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final DateTime? deadline;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? description;
  final bool isCompleted;
  // New fields for transaction integration
  final GoalType type;
  final List<String> linkedCategories;
  final bool autoUpdate;

  Goal({
    this.id,
    required this.name,
    required this.targetAmount,
    this.currentAmount = 0.0,
    this.deadline,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.isCompleted = false,
    this.type = GoalType.savings,
    this.linkedCategories = const [],
    this.autoUpdate = true,
  });

  // Calculate progress percentage (0.0 to 1.0)
  double get progressPercentage {
    if (targetAmount <= 0) return 0.0;
    final progress = currentAmount / targetAmount;
    return progress > 1.0 ? 1.0 : progress;
  }

  // Calculate remaining amount to reach goal
  double get remainingAmount {
    final remaining = targetAmount - currentAmount;
    return remaining > 0 ? remaining : 0.0;
  }

  // Check if goal is overachieved
  bool get isOverachieved => currentAmount > targetAmount;

  // Check if deadline has passed
  bool get isOverdue {
    if (deadline == null) return false;
    return DateTime.now().isAfter(deadline!) && !isCompleted;
  }

  // Calculate days remaining until deadline
  int? get daysRemaining {
    if (deadline == null) return null;
    final now = DateTime.now();
    final difference = deadline!.difference(now).inDays;
    return difference > 0 ? difference : 0;
  }

  // Create a copy with updated fields
  Goal copyWith({
    String? id,
    String? name,
    double? targetAmount,
    double? currentAmount,
    DateTime? deadline,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? description,
    bool? isCompleted,
    GoalType? type,
    List<String>? linkedCategories,
    bool? autoUpdate,
  }) {
    return Goal(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      deadline: deadline ?? this.deadline,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      type: type ?? this.type,
      linkedCategories: linkedCategories ?? this.linkedCategories,
      autoUpdate: autoUpdate ?? this.autoUpdate,
    );
  }

  // Convert from JSON
  factory Goal.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse double values
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        return double.tryParse(value) ?? 0.0;
      }
      return 0.0;
    }

    // Helper function to safely parse GoalType
    GoalType parseGoalType(dynamic value) {
      if (value == null) return GoalType.savings;
      if (value is int) {
        return value >= 0 && value < GoalType.values.length
            ? GoalType.values[value]
            : GoalType.savings;
      }
      if (value is String) {
        // Try to parse by name first
        for (var type in GoalType.values) {
          if (type.name.toLowerCase() == value.toLowerCase()) {
            return type;
          }
        }
        // Try to parse as index
        final index = int.tryParse(value);
        if (index != null && index >= 0 && index < GoalType.values.length) {
          return GoalType.values[index];
        }
      }
      return GoalType.savings;
    }

    // Helper function to safely parse DateTime
    DateTime parseDateTime(dynamic value, {DateTime? defaultValue}) {
      if (value == null) return defaultValue ?? DateTime.now();
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return defaultValue ?? DateTime.now();
        }
      }
      return defaultValue ?? DateTime.now();
    }

    return Goal(
      id: json['id']?.toString(),
      name: json['name']?.toString() ?? '',
      targetAmount: parseDouble(json['target_amount']),
      currentAmount: parseDouble(json['current_amount']),
      deadline:
          json['deadline'] != null ? parseDateTime(json['deadline']) : null,
      createdAt: parseDateTime(json['created_at']),
      updatedAt: parseDateTime(json['updated_at']),
      description: json['description']?.toString(),
      isCompleted:
          json['is_completed'] == true || json['is_completed'] == 'true',
      type: parseGoalType(json['type']),
      linkedCategories:
          json['linked_categories'] is List
              ? List<String>.from(
                json['linked_categories'].map((e) => e.toString()),
              )
              : <String>[],
      autoUpdate: json['auto_update'] == true || json['auto_update'] == 'true',
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'deadline': deadline?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'description': description,
      'is_completed': isCompleted,
      'type': type.name, // Send as string name instead of index
      'linked_categories': linkedCategories,
      'auto_update': autoUpdate,
    };
  }

  @override
  String toString() {
    return 'Goal(id: $id, name: $name, target: $targetAmount, current: $currentAmount, progress: ${(progressPercentage * 100).toStringAsFixed(1)}%)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Goal &&
        other.id == id &&
        other.name == name &&
        other.targetAmount == targetAmount &&
        other.currentAmount == currentAmount;
  }

  @override
  int get hashCode {
    return Object.hash(id, name, targetAmount, currentAmount);
  }
}
