/// Group member roles - MVP simple binary system
enum GroupMemberRole { admin, member }

/// Group member status for invitation workflow
enum GroupMemberStatus {
  active, // Active member
  invited, // Pending invitation
  left, // Left the group voluntarily
  removed, // Removed by admin
}

class GroupMemberModel {
  final String? id;
  final String groupId;
  final String userId;
  final GroupMemberRole role;
  final GroupMemberStatus status;
  final DateTime joinedAt;
  final DateTime? invitedAt;
  final String? invitedBy; // User ID who sent the invitation

  // User details (populated from API joins for UI display)
  final String? userName;
  final String? userEmail;
  final String? userAvatar;

  const GroupMemberModel({
    this.id,
    required this.groupId,
    required this.userId,
    required this.role,
    required this.status,
    required this.joinedAt,
    this.invitedAt,
    this.invitedBy,
    this.userName,
    this.userEmail,
    this.userAvatar,
  });

  /// Factory constructor from JSON (API response)
  factory GroupMemberModel.fromJson(Map<String, dynamic> json) {
    return GroupMemberModel(
      id: json['id']?.toString(),
      groupId:
          json['group_id']?.toString() ?? json['groupId']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? json['userId']?.toString() ?? '',
      role: GroupMemberRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => GroupMemberRole.member,
      ),
      status: GroupMemberStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => GroupMemberStatus.active,
      ),
      joinedAt:
          DateTime.tryParse(
            json['joined_at']?.toString() ?? json['joinedAt']?.toString() ?? '',
          ) ??
          DateTime.now(),
      invitedAt:
          json['invited_at'] != null || json['invitedAt'] != null
              ? DateTime.tryParse(
                json['invited_at']?.toString() ??
                    json['invitedAt']?.toString() ??
                    '',
              )
              : null,
      invitedBy:
          json['invited_by']?.toString() ?? json['invitedBy']?.toString(),
      // User details from JOIN query results - handle both field name variations
      userName: json['user_name']?.toString() ?? json['userName']?.toString(),
      userEmail:
          json['user_email']?.toString() ?? json['userEmail']?.toString(),
      userAvatar:
          json['user_avatar']?.toString() ?? json['userAvatar']?.toString(),
    );
  }

  /// Convert to JSON (for API requests)
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'group_id': groupId,
      'user_id': userId,
      'role': role.name,
      'status': status.name,
      'joined_at': joinedAt.toIso8601String(),
      if (invitedAt != null) 'invited_at': invitedAt!.toIso8601String(),
      if (invitedBy != null) 'invited_by': invitedBy,
    };
  }

  /// Helper methods for easy status checking
  bool get isAdmin => role == GroupMemberRole.admin;
  bool get isActive => status == GroupMemberStatus.active;
  bool get isPending => status == GroupMemberStatus.invited;
  bool get canManageGroup => isAdmin && isActive;

  /// Display name for UI
  String get displayName => userName ?? userEmail ?? 'User $userId';

  /// Copy with method for state updates
  GroupMemberModel copyWith({
    String? id,
    String? groupId,
    String? userId,
    GroupMemberRole? role,
    GroupMemberStatus? status,
    DateTime? joinedAt,
    DateTime? invitedAt,
    String? invitedBy,
    String? userName,
    String? userEmail,
    String? userAvatar,
  }) {
    return GroupMemberModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      status: status ?? this.status,
      joinedAt: joinedAt ?? this.joinedAt,
      invitedAt: invitedAt ?? this.invitedAt,
      invitedBy: invitedBy ?? this.invitedBy,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userAvatar: userAvatar ?? this.userAvatar,
    );
  }

  @override
  String toString() {
    return 'GroupMemberModel(id: $id, groupId: $groupId, userId: $userId, role: ${role.name}, status: ${status.name})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GroupMemberModel &&
        other.groupId == groupId &&
        other.userId == userId;
  }

  @override
  int get hashCode => Object.hash(groupId, userId);
}
