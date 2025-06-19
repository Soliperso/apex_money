import '../models/models.dart';
import 'mock_group_data_service.dart';

/// Group Service - Handles all group-related operations
/// Currently using mock data for development - will be replaced with real API calls
class GroupService {
  // Configuration
  static const bool useMockData = true; // Enable for development
  static const String baseUrl =
      'https://srv797850.hstgr.cloud/api/groups'; // Future API endpoint

  // Singleton pattern
  static GroupService? _instance;
  GroupService._();
  static GroupService get instance {
    _instance ??= GroupService._();
    return _instance!;
  }

  // In-memory storage for mock data persistence during session
  List<GroupWithMembersModel> _groups = [];
  List<GroupInvitationModel> _invitations = [];
  bool _isInitialized = false;

  /// Initialize the service with mock data
  Future<void> initialize() async {
    if (_isInitialized) return;

    if (useMockData) {
      await _initializeMockData();
    }

    _isInitialized = true;
  }

  /// Initialize with mock data for development
  Future<void> _initializeMockData() async {
    // Load mock data
    _groups = MockGroupDataService.generateMockGroups();
    _invitations = MockGroupDataService.generateMockInvitations();

    // Simulate loading delay
    await Future.delayed(const Duration(milliseconds: 300));
  }

  /// Get current user ID (placeholder for real implementation)
  String get currentUserId => MockGroupDataService.currentUserId;

  // ============================================================================
  // GROUP MANAGEMENT METHODS (FR-GRP-001, FR-GRP-003, FR-GRP-007, FR-GRP-008)
  // ============================================================================

  /// Fetch all groups for the current user
  Future<List<GroupWithMembersModel>> fetchUserGroups() async {
    await initialize();

    if (useMockData) {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));

      // Return groups where current user is a member
      return _groups.where((groupWithMembers) {
        return groupWithMembers.isMember(currentUserId);
      }).toList();
    }

    // TODO: Real API implementation
    throw UnimplementedError('Real API not implemented yet');
  }

  /// Get a specific group by ID
  Future<GroupWithMembersModel?> getGroupById(String groupId) async {
    await initialize();

    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 200));

      try {
        return _groups.firstWhere((group) => group.group.id == groupId);
      } catch (e) {
        return null;
      }
    }

    // TODO: Real API implementation
    throw UnimplementedError('Real API not implemented yet');
  }

  /// Create a new group (FR-GRP-001)
  Future<GroupWithMembersModel> createGroup({
    required String name,
    String? description,
    String? imageUrl,
    String defaultCurrency = 'USD',
    bool allowMemberInvites = true,
  }) async {
    await initialize();

    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 800));

      final now = DateTime.now();
      final groupId = MockGroupDataService.generateId();

      final group = GroupModel(
        id: groupId,
        name: name,
        description: description,
        imageUrl: imageUrl,
        adminId: currentUserId,
        createdAt: now,
        updatedAt: now,
        defaultCurrency: defaultCurrency,
        allowMemberInvites: allowMemberInvites,
      );

      final adminMember = GroupMemberModel(
        id: MockGroupDataService.generateId(),
        groupId: groupId,
        userId: currentUserId,
        role: GroupMemberRole.admin,
        status: GroupMemberStatus.active,
        joinedAt: now,
        userName: 'John Doe', // Would come from user service
        userEmail: 'john.doe@example.com',
      );

      final settings = GroupSettingsModel(
        groupId: groupId,
        defaultCurrency: defaultCurrency,
        allowMemberInvites: allowMemberInvites,
      );

      final groupWithMembers = GroupWithMembersModel(
        group: group,
        members: [adminMember],
        settings: settings,
        pendingInvitationsCount: 0,
      );

      _groups.add(groupWithMembers);
      return groupWithMembers;
    }

    // TODO: Real API implementation
    throw UnimplementedError('Real API not implemented yet');
  }

  /// Send invitation to join a group (FR-GRP-002)
  Future<GroupInvitationModel> sendInvitation({
    required String groupId,
    required String inviteeEmail,
    String? message,
  }) async {
    await initialize();

    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 600));

      final group = await getGroupById(groupId);
      if (group == null) {
        throw Exception('Group not found');
      }

      // Check permissions
      if (!group.canUserInvite(currentUserId)) {
        throw Exception(
          'You do not have permission to invite members to this group',
        );
      }

      final invitation = GroupInvitationModel(
        id: MockGroupDataService.generateId(),
        groupId: groupId,
        inviteeEmail: inviteeEmail,
        invitedBy: currentUserId,
        status: InvitationStatus.pending,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 7)),
        token: 'invite_${MockGroupDataService.generateId()}',
        message: message,
        groupName: group.group.name,
        inviterName: 'John Doe', // Would come from user service
        inviterEmail: 'john.doe@example.com',
      );

      _invitations.add(invitation);
      return invitation;
    }

    // TODO: Real API implementation
    throw UnimplementedError('Real API not implemented yet');
  }

  /// Get pending invitations for a group
  Future<List<GroupInvitationModel>> getGroupInvitations(String groupId) async {
    await initialize();

    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 200));

      return _invitations
          .where((invite) => invite.groupId == groupId && invite.isPending)
          .toList();
    }

    // TODO: Real API implementation
    throw UnimplementedError('Real API not implemented yet');
  }

  /// Update group information (FR-GRP-007)
  Future<GroupWithMembersModel> updateGroup({
    required String groupId,
    String? name,
    String? description,
    String? imageUrl,
    String? defaultCurrency,
    bool? allowMemberInvites,
  }) async {
    await initialize();

    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 600));

      final groupIndex = _groups.indexWhere((g) => g.group.id == groupId);
      if (groupIndex == -1) {
        throw Exception('Group not found');
      }

      final currentGroup = _groups[groupIndex];

      // Check if user is admin
      if (!currentGroup.isUserAdmin(currentUserId)) {
        throw Exception('Only group admins can update group information');
      }

      final updatedGroup = currentGroup.group.copyWith(
        name: name,
        description: description,
        imageUrl: imageUrl,
        defaultCurrency: defaultCurrency,
        allowMemberInvites: allowMemberInvites,
        updatedAt: DateTime.now(),
      );

      final updatedSettings = (currentGroup.settings ??
              GroupSettingsModel(
                groupId: groupId,
                defaultCurrency: defaultCurrency ?? 'USD',
                allowMemberInvites: allowMemberInvites ?? true,
              ))
          .copyWith(
            defaultCurrency: defaultCurrency,
            allowMemberInvites: allowMemberInvites,
          );

      final updatedGroupWithMembers = currentGroup.copyWith(
        group: updatedGroup,
        settings: updatedSettings,
      );

      _groups[groupIndex] = updatedGroupWithMembers;
      return updatedGroupWithMembers;
    }

    // TODO: Real API implementation
    throw UnimplementedError('Real API not implemented yet');
  }

  /// Delete a group (FR-GRP-008)
  Future<bool> deleteGroup(String groupId) async {
    await initialize();

    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 500));

      final groupIndex = _groups.indexWhere((g) => g.group.id == groupId);
      if (groupIndex == -1) {
        throw Exception('Group not found');
      }

      final group = _groups[groupIndex];

      // Check if user is admin
      if (!group.isUserAdmin(currentUserId)) {
        throw Exception('Only group admins can delete groups');
      }

      // Remove the group
      _groups.removeAt(groupIndex);

      // Remove related invitations
      _invitations.removeWhere((invite) => invite.groupId == groupId);

      return true;
    }

    // TODO: Real API implementation
    throw UnimplementedError('Real API not implemented yet');
  }

  /// Add member to group (FR-GRP-005)
  Future<GroupMemberModel> addMemberToGroup({
    required String groupId,
    required String userId,
    required String userName,
    required String userEmail,
    GroupMemberRole role = GroupMemberRole.member,
  }) async {
    await initialize();

    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 600));

      final groupIndex = _groups.indexWhere((g) => g.group.id == groupId);
      if (groupIndex == -1) {
        throw Exception('Group not found');
      }

      final currentGroup = _groups[groupIndex];

      // Check if user is admin or has permission to add members
      if (!currentGroup.canUserInvite(currentUserId)) {
        throw Exception(
          'You do not have permission to add members to this group',
        );
      }

      // Check if user is already a member
      if (currentGroup.isMember(userId)) {
        throw Exception('User is already a member of this group');
      }

      final newMember = GroupMemberModel(
        id: MockGroupDataService.generateId(),
        groupId: groupId,
        userId: userId,
        role: role,
        status: GroupMemberStatus.active,
        joinedAt: DateTime.now(),
        userName: userName,
        userEmail: userEmail,
      );

      final updatedMembers = List<GroupMemberModel>.from(currentGroup.members)
        ..add(newMember);
      final updatedGroup = currentGroup.copyWith(members: updatedMembers);

      _groups[groupIndex] = updatedGroup;
      return newMember;
    }

    // TODO: Real API implementation
    throw UnimplementedError('Real API not implemented yet');
  }

  /// Remove member from group (FR-GRP-006)
  Future<bool> removeMemberFromGroup({
    required String groupId,
    required String userId,
  }) async {
    await initialize();

    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 500));

      final groupIndex = _groups.indexWhere((g) => g.group.id == groupId);
      if (groupIndex == -1) {
        throw Exception('Group not found');
      }

      final currentGroup = _groups[groupIndex];

      // Check if user is admin
      if (!currentGroup.isUserAdmin(currentUserId)) {
        throw Exception('Only group admins can remove members');
      }

      // Cannot remove the admin
      if (userId == currentGroup.group.adminId) {
        throw Exception('Cannot remove the group admin');
      }

      // Check if user is a member
      if (!currentGroup.isMember(userId)) {
        throw Exception('User is not a member of this group');
      }

      final updatedMembers =
          currentGroup.members
              .where((member) => member.userId != userId)
              .toList();
      final updatedGroup = currentGroup.copyWith(members: updatedMembers);

      _groups[groupIndex] = updatedGroup;
      return true;
    }

    // TODO: Real API implementation
    throw UnimplementedError('Real API not implemented yet');
  }

  /// Transfer admin role to another member
  Future<GroupWithMembersModel> transferAdminRole({
    required String groupId,
    required String newAdminUserId,
  }) async {
    await initialize();

    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 600));

      final groupIndex = _groups.indexWhere((g) => g.group.id == groupId);
      if (groupIndex == -1) {
        throw Exception('Group not found');
      }

      final currentGroup = _groups[groupIndex];

      // Check if current user is admin
      if (!currentGroup.isUserAdmin(currentUserId)) {
        throw Exception('Only the current admin can transfer admin role');
      }

      // Check if new admin is a member
      if (!currentGroup.isMember(newAdminUserId)) {
        throw Exception('New admin must be a member of the group');
      }

      // Update group admin
      final updatedGroup = currentGroup.group.copyWith(
        adminId: newAdminUserId,
        updatedAt: DateTime.now(),
      );

      // Update member roles
      final updatedMembers =
          currentGroup.members.map((member) {
            if (member.userId == newAdminUserId) {
              return member.copyWith(role: GroupMemberRole.admin);
            } else if (member.userId == currentUserId) {
              return member.copyWith(role: GroupMemberRole.member);
            }
            return member;
          }).toList();

      final updatedGroupWithMembers = currentGroup.copyWith(
        group: updatedGroup,
        members: updatedMembers,
      );

      _groups[groupIndex] = updatedGroupWithMembers;
      return updatedGroupWithMembers;
    }

    // TODO: Real API implementation
    throw UnimplementedError('Real API not implemented yet');
  }

  // ============================================================================
  // INVITATION MANAGEMENT METHODS (FR-GRP-002)
  // ============================================================================

  /// Get invitations for current user
  Future<List<GroupInvitationModel>> getUserInvitations() async {
    await initialize();

    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 200));

      // In a real implementation, this would filter by user email
      // For now, return all pending invitations
      return _invitations.where((invite) => invite.isPending).toList();
    }

    // TODO: Real API implementation
    throw UnimplementedError('Real API not implemented yet');
  }

  /// Accept an invitation
  Future<GroupWithMembersModel> acceptInvitation(String invitationId) async {
    await initialize();

    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 800));

      final invitationIndex = _invitations.indexWhere(
        (invite) => invite.id == invitationId,
      );
      if (invitationIndex == -1) {
        throw Exception('Invitation not found');
      }

      final invitation = _invitations[invitationIndex];

      if (!invitation.isPending) {
        throw Exception('Invitation is no longer valid');
      }

      if (invitation.isExpired) {
        throw Exception('Invitation has expired');
      }

      // Update invitation status
      final updatedInvitation = invitation.copyWith(
        status: InvitationStatus.accepted,
        respondedAt: DateTime.now(),
      );
      _invitations[invitationIndex] = updatedInvitation;

      // Add user to group
      await addMemberToGroup(
        groupId: invitation.groupId,
        userId: currentUserId,
        userName: 'John Doe', // Would come from user service
        userEmail: invitation.inviteeEmail,
      );

      // Get updated group with members
      final groupWithMembers = await getGroupById(invitation.groupId);
      if (groupWithMembers == null) {
        throw Exception('Failed to get updated group information');
      }

      return groupWithMembers;
    }

    // TODO: Real API implementation
    throw UnimplementedError('Real API not implemented yet');
  }

  /// Decline an invitation
  Future<bool> declineInvitation(String invitationId) async {
    await initialize();

    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 400));

      final invitationIndex = _invitations.indexWhere(
        (invite) => invite.id == invitationId,
      );
      if (invitationIndex == -1) {
        throw Exception('Invitation not found');
      }

      final invitation = _invitations[invitationIndex];

      if (!invitation.isPending) {
        throw Exception('Invitation is no longer valid');
      }

      // Update invitation status
      final updatedInvitation = invitation.copyWith(
        status: InvitationStatus.declined,
        respondedAt: DateTime.now(),
      );
      _invitations[invitationIndex] = updatedInvitation;

      return true;
    }

    // TODO: Real API implementation
    throw UnimplementedError('Real API not implemented yet');
  }

  /// Cancel an invitation (by inviter)
  Future<bool> cancelInvitation(String invitationId) async {
    await initialize();

    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 400));

      final invitationIndex = _invitations.indexWhere(
        (invite) => invite.id == invitationId,
      );
      if (invitationIndex == -1) {
        throw Exception('Invitation not found');
      }

      final invitation = _invitations[invitationIndex];

      // Check if current user is the one who sent the invitation or group admin
      final group = await getGroupById(invitation.groupId);
      if (group == null) {
        throw Exception('Group not found');
      }

      if (invitation.invitedBy != currentUserId &&
          !group.isUserAdmin(currentUserId)) {
        throw Exception(
          'You can only cancel invitations you sent or if you are a group admin',
        );
      }

      if (!invitation.isPending) {
        throw Exception('Can only cancel pending invitations');
      }

      // Update invitation status
      final updatedInvitation = invitation.copyWith(
        status: InvitationStatus.cancelled,
        respondedAt: DateTime.now(),
      );
      _invitations[invitationIndex] = updatedInvitation;

      return true;
    }

    // TODO: Real API implementation
    throw UnimplementedError('Real API not implemented yet');
  }

  /// Get group statistics
  Future<Map<String, dynamic>> getGroupStats(String groupId) async {
    await initialize();

    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 300));

      final group = await getGroupById(groupId);
      if (group == null) {
        throw Exception('Group not found');
      }

      final pendingInvitations = await getGroupInvitations(groupId);

      return {
        'memberCount': group.members.length,
        'pendingInvitations': pendingInvitations.length,
        'adminId': group.group.adminId,
        'createdAt': group.group.createdAt,
        'settings': group.settings?.toJson() ?? {},
      };
    }

    // TODO: Real API implementation
    throw UnimplementedError('Real API not implemented yet');
  }

  /// Leave a group (for non-admin members)
  Future<bool> leaveGroup(String groupId) async {
    await initialize();

    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 500));

      final group = await getGroupById(groupId);
      if (group == null) {
        throw Exception('Group not found');
      }

      // Admin cannot leave, must transfer admin role first
      if (group.isUserAdmin(currentUserId)) {
        throw Exception(
          'Group admin cannot leave. Please transfer admin role first.',
        );
      }

      // Remove current user from group
      return await removeMemberFromGroup(
        groupId: groupId,
        userId: currentUserId,
      );
    }

    // TODO: Real API implementation
    throw UnimplementedError('Real API not implemented yet');
  }

  /// Clear all data (useful for testing)
  Future<void> clearAllData() async {
    _groups.clear();
    _invitations.clear();
    _isInitialized = false;
  }
}
