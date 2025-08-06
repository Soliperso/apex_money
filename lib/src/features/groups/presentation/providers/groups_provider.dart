import 'package:flutter/foundation.dart';
import '../../data/models/models.dart';
import '../../data/services/group_service.dart';

/// State management for Groups using Provider
class GroupsProvider extends ChangeNotifier {
  final GroupService _groupService;

  // State variables
  List<GroupWithMembersModel> _groups = [];
  List<GroupInvitationModel> _invitations = [];
  bool _isLoading = false;
  bool _isCreating = false;
  bool _isUpdating = false;
  bool _isDeleting = false;
  bool _isSendingInvitation = false;
  String? _error;

  GroupsProvider({GroupService? groupService})
    : _groupService = groupService ?? GroupService.instance;

  // Getters
  List<GroupWithMembersModel> get groups => List.unmodifiable(_groups);
  List<GroupInvitationModel> get invitations => List.unmodifiable(_invitations);
  bool get isLoading => _isLoading;
  bool get isCreating => _isCreating;
  bool get isUpdating => _isUpdating;
  bool get isDeleting => _isDeleting;
  bool get isSendingInvitation => _isSendingInvitation;
  String? get error => _error;
  bool get hasError => _error != null;

  /// Get current user ID
  String getCurrentUserId() => _groupService.currentUserId;

  /// Clear error state
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Load all groups for the current user
  Future<void> loadGroups() async {
    _setLoading(true);
    _clearError();

    try {
      final groups = await _groupService.fetchUserGroups();
      _groups = groups;
    } catch (e) {
      print('Groups loading error: $e'); // Debug log

      // Handle different types of errors gracefully
      if (e.toString().contains('404')) {
        print('Groups endpoint not implemented yet - using empty list');
        _groups = [];
      } else if (e.toString().contains('No internet connection')) {
        _setError(
          'No internet connection. Please check your connection and try again.',
        );
      } else if (e.toString().contains('timeout')) {
        _setError('Request timed out. Please try again.');
      } else if (e.toString().contains('type \'Null\' is not a subtype')) {
        print('Data parsing error - likely empty/malformed response');
        _groups = [];
        _setError(
          'Unable to load groups. The server may be experiencing issues.',
        );
      } else if (e.toString().contains('Authentication required')) {
        _setError('Please log in again to continue.');
      } else {
        // Generic error message for other cases
        _setError('Unable to load groups. Please try again later.');
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Create a new group
  Future<GroupWithMembersModel?> createGroup({
    required String name,
    String? description,
    String? imageUrl,
    String defaultCurrency = 'USD',
    bool allowMemberInvites = true,
  }) async {
    _setCreating(true);
    _clearError();

    try {
      final newGroup = await _groupService
          .createGroup(
            name: name,
            description: description,
            imageUrl: imageUrl,
            defaultCurrency: defaultCurrency,
            allowMemberInvites: allowMemberInvites,
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw Exception('Request timed out - please try again');
            },
          );

      // Add to local list
      _groups.add(newGroup);
      notifyListeners();

      return newGroup;
    } catch (e) {
      // Log the actual API error for debugging
      print('Create group API error: $e');
      _setError(e.toString());
      return null;
    } finally {
      _setCreating(false);
    }
  }

  /// Update group information
  Future<GroupWithMembersModel?> updateGroup({
    required String groupId,
    String? name,
    String? description,
    String? imageUrl,
    String? defaultCurrency,
    bool? allowMemberInvites,
  }) async {
    _setUpdating(true);
    _clearError();

    try {
      final updatedGroup = await _groupService.updateGroup(
        groupId: groupId,
        name: name,
        description: description,
        imageUrl: imageUrl,
        defaultCurrency: defaultCurrency,
        allowMemberInvites: allowMemberInvites,
      );

      // Update local list
      final index = _groups.indexWhere((g) => g.group.id == groupId);
      if (index != -1) {
        _groups[index] = updatedGroup;
        notifyListeners();
      }

      return updatedGroup;
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setUpdating(false);
    }
  }

  /// Delete a group
  Future<bool> deleteGroup(String groupId) async {
    _setDeleting(true);
    _clearError();

    try {
      await _groupService.deleteGroup(groupId);

      // Remove from local list
      _groups.removeWhere((g) => g.group.id == groupId);
      notifyListeners();

      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setDeleting(false);
    }
  }

  /// Send invitation to join group
  Future<GroupInvitationModel?> sendInvitation({
    required String groupId,
    required String inviteeEmail,
    String? message,
  }) async {
    _setSendingInvitation(true);
    _clearError();

    try {
      final invitation = await _groupService.sendInvitation(
        groupId: groupId,
        inviteeEmail: inviteeEmail,
        message: message,
      );

      // Add to local invitations list
      _invitations.add(invitation);
      notifyListeners();

      return invitation;
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setSendingInvitation(false);
    }
  }

  /// Add member to group
  Future<bool> addMember({
    required String groupId,
    required String userId,
    required String userName,
    required String userEmail,
    GroupMemberRole role = GroupMemberRole.member,
  }) async {
    _clearError();

    try {
      await _groupService.addMemberToGroup(
        groupId: groupId,
        userId: userId,
        userName: userName,
        userEmail: userEmail,
        role: role,
      );

      // Reload groups to reflect changes
      await loadGroups();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  /// Remove member from group
  Future<bool> removeMember({
    required String groupId,
    required String userId,
  }) async {
    _clearError();

    try {
      await _groupService.removeMemberFromGroup(
        groupId: groupId,
        userId: userId,
      );

      // Reload groups to reflect changes
      await loadGroups();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  /// Transfer admin role
  Future<bool> transferAdminRole({
    required String groupId,
    required String newAdminUserId,
  }) async {
    _clearError();

    try {
      await _groupService.transferAdminRole(
        groupId: groupId,
        newAdminUserId: newAdminUserId,
      );

      // Reload groups to reflect changes
      await loadGroups();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  /// Leave group
  Future<bool> leaveGroup(String groupId) async {
    _clearError();

    try {
      await _groupService.leaveGroup(groupId);

      // Remove from local list
      _groups.removeWhere((g) => g.group.id == groupId);
      notifyListeners();

      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  /// Load invitations for current user
  Future<void> loadInvitations() async {
    _clearError();

    try {
      final invitations = await _groupService.getUserInvitations();
      _invitations = invitations;
      notifyListeners();
    } catch (e) {
      // Handle 404 errors gracefully - invitations endpoint might not be implemented yet
      if (e.toString().contains('404')) {
        print('Invitations endpoint not implemented yet - using empty list');
        _invitations = [];
        notifyListeners();
      } else {
        _setError(e.toString());
      }
    }
  }

  /// Accept an invitation
  Future<bool> acceptInvitation(String invitationId) async {
    _clearError();

    try {
      await _groupService.acceptInvitation(invitationId);

      // Remove from invitations and reload groups
      _invitations.removeWhere((inv) => inv.id == invitationId);
      await loadGroups();

      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  /// Decline an invitation
  Future<bool> declineInvitation(String invitationId) async {
    _clearError();

    try {
      await _groupService.declineInvitation(invitationId);

      // Remove from invitations
      _invitations.removeWhere((inv) => inv.id == invitationId);
      notifyListeners();

      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  /// Get specific group by ID
  GroupWithMembersModel? getGroupById(String groupId) {
    try {
      return _groups.firstWhere((group) => group.group.id == groupId);
    } catch (e) {
      return null;
    }
  }

  /// Get pending invitations for a specific group
  List<GroupInvitationModel> getGroupInvitations(String groupId) {
    return _invitations
        .where((inv) => inv.groupId == groupId && inv.isPending)
        .toList();
  }

  // ============================================================================
  // ENHANCED MEMBER CRUD OPERATIONS
  // ============================================================================

  /// Get all members of a specific group
  Future<List<GroupMemberModel>> getGroupMembers(String groupId) async {
    _clearError();

    try {
      return await _groupService.getGroupMembers(groupId);
    } catch (e) {
      _setError(e.toString());
      return [];
    }
  }

  /// Get specific member details by user ID within a group
  Future<GroupMemberModel?> getGroupMemberById({
    required String groupId,
    required String userId,
  }) async {
    _clearError();

    try {
      return await _groupService.getGroupMemberById(
        groupId: groupId,
        userId: userId,
      );
    } catch (e) {
      _setError(e.toString());
      return null;
    }
  }

  /// Update member role within a group
  Future<bool> updateMemberRole({
    required String groupId,
    required String userId,
    required GroupMemberRole newRole,
  }) async {
    _clearError();

    try {
      await _groupService.updateMemberRole(
        groupId: groupId,
        userId: userId,
        newRole: newRole,
      );

      // Reload groups to reflect changes
      await loadGroups();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  /// Update member status within a group
  Future<bool> updateMemberStatus({
    required String groupId,
    required String userId,
    required GroupMemberStatus newStatus,
  }) async {
    _clearError();

    try {
      await _groupService.updateMemberStatus(
        groupId: groupId,
        userId: userId,
        newStatus: newStatus,
      );

      // Reload groups to reflect changes
      await loadGroups();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  /// Get current user's membership details for a specific group
  Future<GroupMemberModel?> getCurrentUserMembership(String groupId) async {
    _clearError();

    try {
      return await _groupService.getCurrentUserMembership(groupId);
    } catch (e) {
      _setError(e.toString());
      return null;
    }
  }

  /// Check if current user can manage a specific group (is admin)
  Future<bool> canManageGroup(String groupId) async {
    try {
      return await _groupService.canManageGroup(groupId);
    } catch (e) {
      print('Error checking group management permissions: $e');
      return false;
    }
  }

  /// Bulk invite multiple users to a group by email
  Future<bool> bulkInviteMembers({
    required String groupId,
    required List<String> emails,
    String? message,
  }) async {
    _clearError();

    try {
      final invitations = await _groupService.bulkInviteMembers(
        groupId: groupId,
        emails: emails,
        message: message,
      );

      // Add new invitations to local list
      _invitations.addAll(invitations);
      notifyListeners();

      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  /// Helper methods for state management
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setCreating(bool creating) {
    _isCreating = creating;
    notifyListeners();
  }

  void _setUpdating(bool updating) {
    _isUpdating = updating;
    notifyListeners();
  }

  void _setDeleting(bool deleting) {
    _isDeleting = deleting;
    notifyListeners();
  }

  void _setSendingInvitation(bool sending) {
    _isSendingInvitation = sending;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}
