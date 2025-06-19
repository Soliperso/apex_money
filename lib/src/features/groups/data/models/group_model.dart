class GroupModel {
  final String? id;
  final String name;
  final String? description;
  final String? imageUrl;
  final String adminId; // User ID of the group admin
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  // MVP Settings - essentials for bill sharing preparation
  final String defaultCurrency; // For future bill sharing
  final bool allowMemberInvites; // Can members invite others?

  const GroupModel({
    this.id,
    required this.name,
    this.description,
    this.imageUrl,
    required this.adminId,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.defaultCurrency = 'USD', // Default currency
    this.allowMemberInvites = true, // Default allow member invites
  });

  /// Factory constructor from JSON (API response)
  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['id']?.toString(),
      name: json['name'] as String,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      adminId: json['admin_id']?.toString() ?? '',
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] ?? DateTime.now().toIso8601String(),
      ),
      isActive: json['is_active'] as bool? ?? true,
      defaultCurrency: json['default_currency'] as String? ?? 'USD',
      allowMemberInvites: json['allow_member_invites'] as bool? ?? true,
    );
  }

  /// Convert to JSON (for API requests)
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'description': description,
      'image_url': imageUrl,
      'admin_id': adminId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_active': isActive,
      'default_currency': defaultCurrency,
      'allow_member_invites': allowMemberInvites,
    };
  }

  /// Copy with method for state updates
  GroupModel copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    String? adminId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    String? defaultCurrency,
    bool? allowMemberInvites,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      adminId: adminId ?? this.adminId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
      allowMemberInvites: allowMemberInvites ?? this.allowMemberInvites,
    );
  }

  /// Helper method to check if user is admin
  bool isUserAdmin(String userId) {
    return adminId == userId;
  }

  @override
  String toString() {
    return 'GroupModel(id: $id, name: $name, adminId: $adminId, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GroupModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
