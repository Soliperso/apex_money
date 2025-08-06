import 'group_model.dart';
import 'group_member_model.dart';
import 'group_settings_model.dart';

/// Combined model for group with its members and settings
/// This is a convenience model for UI components that need complete group information
class GroupWithMembersModel {
  final GroupModel group;
  final List<GroupMemberModel> members;
  final GroupSettingsModel? settings;
  final int? pendingInvitationsCount;

  const GroupWithMembersModel({
    required this.group,
    required this.members,
    this.settings,
    this.pendingInvitationsCount,
  });

  /// Factory constructor from JSON with nested members data
  factory GroupWithMembersModel.fromJson(Map<String, dynamic> json) {
    // Handle cases where the JSON structure might be different
    // If 'group' key doesn't exist, treat the entire json as the group data
    final groupData = json['group'] as Map<String, dynamic>? ?? json;

    return GroupWithMembersModel(
      group: GroupModel.fromJson(groupData),
      members:
          (json['members'] as List<dynamic>?)
              ?.map((memberJson) => GroupMemberModel.fromJson(memberJson))
              .toList() ??
          [],
      settings:
          json['settings'] != null
              ? GroupSettingsModel.fromJson(json['settings'])
              : null,
      // Handle both field name variations for pending invitations count
      pendingInvitationsCount:
          json['pending_invitations_count'] as int? ??
          json['pendingInvitationsCount'] as int? ??
          (json['statistics']
                  as Map<String, dynamic>?)?['pendingInvitationsCount']
              as int?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'group': group.toJson(),
      'members': members.map((member) => member.toJson()).toList(),
      if (settings != null) 'settings': settings!.toJson(),
      if (pendingInvitationsCount != null)
        'pending_invitations_count': pendingInvitationsCount,
    };
  }

  /// Helper methods for common UI operations

  /// Get active members only
  List<GroupMemberModel> get activeMembers {
    return members.where((member) => member.isActive).toList();
  }

  /// Get pending invitations (members with invited status)
  List<GroupMemberModel> get pendingMembers {
    return members.where((member) => member.isPending).toList();
  }

  /// Get admin member
  GroupMemberModel? get adminMember {
    return members
        .where((member) => member.isAdmin && member.isActive)
        .firstOrNull;
  }

  /// Check if current user is admin
  bool isUserAdmin(String userId) {
    return group.isUserAdmin(userId);
  }

  /// Check if current user can invite members
  bool canUserInvite(String userId) {
    if (settings == null) return group.allowMemberInvites;
    return settings!.canMemberInvite(userId, group.adminId);
  }

  /// Get member count (active members only)
  int get memberCount => activeMembers.length;

  /// Get total member count including pending
  int get totalMemberCount => members.length;

  /// Find member by user ID
  GroupMemberModel? findMemberByUserId(String userId) {
    return members.where((member) => member.userId == userId).firstOrNull;
  }

  /// Check if user is a member of this group
  bool isMember(String userId) {
    return findMemberByUserId(userId) != null;
  }

  /// Check if user is an active member
  bool isActiveMember(String userId) {
    final member = findMemberByUserId(userId);
    return member?.isActive ?? false;
  }

  /// Copy with method for state updates
  GroupWithMembersModel copyWith({
    GroupModel? group,
    List<GroupMemberModel>? members,
    GroupSettingsModel? settings,
    int? pendingInvitationsCount,
  }) {
    return GroupWithMembersModel(
      group: group ?? this.group,
      members: members ?? this.members,
      settings: settings ?? this.settings,
      pendingInvitationsCount:
          pendingInvitationsCount ?? this.pendingInvitationsCount,
    );
  }

  @override
  String toString() {
    return 'GroupWithMembersModel(group: ${group.name}, memberCount: $memberCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GroupWithMembersModel && other.group.id == group.id;
  }

  @override
  int get hashCode => group.id.hashCode;
}

/// Extension to add firstOrNull to Iterable for older Dart versions
extension FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
