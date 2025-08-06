import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../../../../shared/config/api_config.dart';

/// Group Service - Handles all group-related operations with Laravel backend
class GroupService {
  String get baseUrl => ApiConfig.apiBaseUrl;
  // Singleton pattern
  static GroupService? _instance;
  GroupService._();
  static GroupService get instance {
    _instance ??= GroupService._();
    return _instance!;
  }

  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  /// Get current user ID (email) from shared preferences
  Future<String?> _getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id'); // This is actually the user's email
  }

  /// Get current user ID (email) and throw if not found
  Future<String> _getRequiredUserId() async {
    final userId = await _getCurrentUserId();
    if (userId == null) {
      throw Exception("User not authenticated - no user email found");
    }
    return userId;
  }

  /// Get current user ID synchronously (for provider compatibility)
  String get currentUserId {
    // This is a synchronous fallback - the async version should be preferred
    // UI components should handle the async version properly
    return 'placeholder_user_id';
  }

  // ============================================================================
  // GROUP MANAGEMENT METHODS (FR-GRP-001, FR-GRP-003, FR-GRP-007, FR-GRP-008)
  // ============================================================================

  /// Fetch all groups for the current user
  Future<List<GroupWithMembersModel>> fetchUserGroups() async {
    final token = await _getAuthToken();
    if (token == null) {
      throw Exception("Authentication required");
    }

    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/groups'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // Handle empty response
        if (response.body.trim().isEmpty) {
          return [];
        }

        final responseBody = jsonDecode(response.body);

        // Handle different possible response structures
        List<dynamic> groupsList;
        if (responseBody is List) {
          // Direct array response
          groupsList = responseBody;
        } else if (responseBody is Map<String, dynamic>) {
          // Wrapped in object
          groupsList = responseBody['groups'] ?? responseBody['data'] ?? [];
        } else if (responseBody == null) {
          return [];
        } else {
          throw Exception(
            'Invalid response format: expected List or Map, got ${responseBody.runtimeType}',
          );
        }

        try {
          return groupsList.cast<Map<String, dynamic>>().map((group) {
            try {
              return GroupWithMembersModel.fromJson(group);
            } catch (e) {
              rethrow;
            }
          }).toList();
        } catch (e) {
          throw Exception('Error parsing groups data: $e');
        }
      } else {
        throw Exception(
          'Failed to fetch groups: ${response.statusCode} - ${response.body}',
        );
      }
    } on SocketException {
      throw Exception('No internet connection');
    } on TimeoutException {
      throw Exception('Request timeout - please try again');
    } catch (e) {
      throw Exception('Error fetching groups: $e');
    }
  }

  /// Get a specific group by ID
  Future<GroupWithMembersModel?> getGroupById(String groupId) async {
    final token = await _getAuthToken();
    if (token == null) {
      throw Exception("Authentication required");
    }

    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/groups/$groupId'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 404) {
        return null;
      }

      return _handleResponse<GroupWithMembersModel>(
        response,
        (data) => GroupWithMembersModel.fromJson(data['group']),
      );
    } on SocketException {
      throw Exception('No internet connection');
    } on TimeoutException {
      throw Exception('Request timeout - please try again');
    } catch (e) {
      throw Exception('Error fetching group: $e');
    }
  }

  /// Create a new group (FR-GRP-001)
  Future<GroupWithMembersModel> createGroup({
    required String name,
    String? description,
    String? imageUrl,
    String defaultCurrency = 'USD',
    bool allowMemberInvites = true,
  }) async {
    final token = await _getAuthToken();
    if (token == null) {
      throw Exception("Authentication required");
    }

    try {
      final userId = await _getRequiredUserId();

      final requestBody = {
        'name': name,
        'description': description,
        'image_url': imageUrl,
        'default_currency': defaultCurrency,
        'allow_member_invites': allowMemberInvites,
        'created_by_user_id': userId,
      };

      final response = await http
          .post(
            Uri.parse('$baseUrl/groups'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);

        // Handle different possible response structures
        Map<String, dynamic> groupData;
        if (responseBody is Map<String, dynamic>) {
          // Check if group data is nested or direct
          groupData = responseBody['group'] ?? responseBody;
        } else {
          throw Exception(
            'Invalid response format: expected Map, got ${responseBody.runtimeType}',
          );
        }

        return GroupWithMembersModel.fromJson(groupData);
      } else {
        throw Exception(
          'Failed to create group: ${response.statusCode} - ${response.body}',
        );
      }
    } on SocketException {
      throw Exception('No internet connection');
    } on TimeoutException {
      throw Exception('Request timeout - please try again');
    } catch (e) {
      throw Exception('Error creating group: $e');
    }
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
    final token = await _getAuthToken();
    if (token == null) {
      throw Exception("Authentication required");
    }

    try {
      final Map<String, dynamic> updateData = {};
      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;
      if (imageUrl != null) updateData['image_url'] = imageUrl;
      if (defaultCurrency != null) {
        updateData['default_currency'] = defaultCurrency;
      }
      if (allowMemberInvites != null) {
        updateData['allow_member_invites'] = allowMemberInvites;
      }

      final response = await http
          .put(
            Uri.parse('$baseUrl/groups/$groupId'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(updateData),
          )
          .timeout(const Duration(seconds: 10));

      return _handleResponse<GroupWithMembersModel>(
        response,
        (data) => GroupWithMembersModel.fromJson(data['group']),
      );
    } on SocketException {
      throw Exception('No internet connection');
    } on TimeoutException {
      throw Exception('Request timeout - please try again');
    } catch (e) {
      throw Exception('Error updating group: $e');
    }
  }

  /// Delete a group (FR-GRP-008)
  Future<bool> deleteGroup(String groupId) async {
    final token = await _getAuthToken();
    if (token == null) {
      throw Exception("Authentication required");
    }

    try {
      final response = await http
          .delete(
            Uri.parse('$baseUrl/groups/$groupId'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 10));

      return _handleResponse<bool>(response, (data) => true);
    } on SocketException {
      throw Exception('No internet connection');
    } on TimeoutException {
      throw Exception('Request timeout - please try again');
    } catch (e) {
      throw Exception('Error deleting group: $e');
    }
  }

  // ============================================================================
  // MEMBER MANAGEMENT METHODS (FR-GRP-005, FR-GRP-006)
  // ============================================================================

  /// Add member to group (FR-GRP-005)
  Future<GroupMemberModel> addMemberToGroup({
    required String groupId,
    required String userId,
    required String userName,
    required String userEmail,
    GroupMemberRole role = GroupMemberRole.member,
  }) async {
    final token = await _getAuthToken();
    if (token == null) {
      throw Exception("Authentication required");
    }

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/groups/$groupId/members'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'user_id': userId,
              'user_name': userName,
              'user_email': userEmail,
              'role': role.name,
            }),
          )
          .timeout(const Duration(seconds: 10));

      return _handleResponse<GroupMemberModel>(
        response,
        (data) => GroupMemberModel.fromJson(data['member']),
      );
    } on SocketException {
      throw Exception('No internet connection');
    } on TimeoutException {
      throw Exception('Request timeout - please try again');
    } catch (e) {
      throw Exception('Error adding member: $e');
    }
  }

  /// Remove member from group (FR-GRP-006)
  Future<bool> removeMemberFromGroup({
    required String groupId,
    required String userId,
  }) async {
    final token = await _getAuthToken();
    if (token == null) {
      throw Exception("Authentication required");
    }

    try {
      final response = await http
          .delete(
            Uri.parse('$baseUrl/groups/$groupId/members/$userId'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 10));

      return _handleResponse<bool>(response, (data) => true);
    } on SocketException {
      throw Exception('No internet connection');
    } on TimeoutException {
      throw Exception('Request timeout - please try again');
    } catch (e) {
      throw Exception('Error removing member: $e');
    }
  }

  /// Transfer admin role to another member
  Future<GroupWithMembersModel> transferAdminRole({
    required String groupId,
    required String newAdminUserId,
  }) async {
    final token = await _getAuthToken();
    if (token == null) {
      throw Exception("Authentication required");
    }

    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl/groups/$groupId/admin'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'admin_user_id': newAdminUserId}),
          )
          .timeout(const Duration(seconds: 10));

      return _handleResponse<GroupWithMembersModel>(
        response,
        (data) => GroupWithMembersModel.fromJson(data['group']),
      );
    } on SocketException {
      throw Exception('No internet connection');
    } on TimeoutException {
      throw Exception('Request timeout - please try again');
    } catch (e) {
      throw Exception('Error transferring admin role: $e');
    }
  }

  /// Leave a group (for non-admin members)
  Future<bool> leaveGroup(String groupId) async {
    final token = await _getAuthToken();
    if (token == null) {
      throw Exception("Authentication required");
    }

    try {
      final response = await http
          .delete(
            Uri.parse('$baseUrl/groups/$groupId/members/self'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 10));

      return _handleResponse<bool>(response, (data) => true);
    } on SocketException {
      throw Exception('No internet connection');
    } on TimeoutException {
      throw Exception('Request timeout - please try again');
    } catch (e) {
      throw Exception('Error leaving group: $e');
    }
  }

  // ============================================================================
  // ENHANCED MEMBER CRUD OPERATIONS
  // ============================================================================

  /// Get all members of a specific group
  Future<List<GroupMemberModel>> getGroupMembers(String groupId) async {
    final token = await _getAuthToken();
    if (token == null) {
      throw Exception("Authentication required");
    }

    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/groups/$groupId/members'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);

        // Handle different possible response structures
        List<dynamic> membersList;
        if (responseBody is List) {
          // Direct array response
          membersList = responseBody;
        } else if (responseBody is Map<String, dynamic>) {
          // Wrapped in object
          membersList = responseBody['members'] ?? responseBody['data'] ?? [];
        } else {
          throw Exception('Invalid response format: expected List or Map');
        }

        return membersList
            .cast<Map<String, dynamic>>()
            .map((member) => GroupMemberModel.fromJson(member))
            .toList();
      } else {
        throw Exception(
          'Failed to fetch group members: ${response.statusCode} - ${response.body}',
        );
      }
    } on SocketException {
      throw Exception('No internet connection');
    } on TimeoutException {
      throw Exception('Request timeout - please try again');
    } catch (e) {
      throw Exception('Error fetching group members: $e');
    }
  }

  /// Get specific member details by user ID within a group
  Future<GroupMemberModel?> getGroupMemberById({
    required String groupId,
    required String userId,
  }) async {
    final token = await _getAuthToken();
    if (token == null) {
      throw Exception("Authentication required");
    }

    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/groups/$groupId/members/$userId'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 404) {
        return null; // Member not found
      }

      return _handleResponse<GroupMemberModel>(
        response,
        (data) => GroupMemberModel.fromJson(data['member'] ?? data),
      );
    } on SocketException {
      throw Exception('No internet connection');
    } on TimeoutException {
      throw Exception('Request timeout - please try again');
    } catch (e) {
      throw Exception('Error fetching group member: $e');
    }
  }

  /// Update member role within a group
  Future<GroupMemberModel> updateMemberRole({
    required String groupId,
    required String userId,
    required GroupMemberRole newRole,
  }) async {
    final token = await _getAuthToken();
    if (token == null) {
      throw Exception("Authentication required");
    }

    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl/groups/$groupId/members/$userId'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'role': newRole.name}),
          )
          .timeout(const Duration(seconds: 10));

      return _handleResponse<GroupMemberModel>(
        response,
        (data) => GroupMemberModel.fromJson(data['member'] ?? data),
      );
    } on SocketException {
      throw Exception('No internet connection');
    } on TimeoutException {
      throw Exception('Request timeout - please try again');
    } catch (e) {
      throw Exception('Error updating member role: $e');
    }
  }

  /// Update member status within a group
  Future<GroupMemberModel> updateMemberStatus({
    required String groupId,
    required String userId,
    required GroupMemberStatus newStatus,
  }) async {
    final token = await _getAuthToken();
    if (token == null) {
      throw Exception("Authentication required");
    }

    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl/groups/$groupId/members/$userId/status'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'status': newStatus.name}),
          )
          .timeout(const Duration(seconds: 10));

      return _handleResponse<GroupMemberModel>(
        response,
        (data) => GroupMemberModel.fromJson(data['member'] ?? data),
      );
    } on SocketException {
      throw Exception('No internet connection');
    } on TimeoutException {
      throw Exception('Request timeout - please try again');
    } catch (e) {
      throw Exception('Error updating member status: $e');
    }
  }

  /// Get current user's membership details for a specific group
  Future<GroupMemberModel?> getCurrentUserMembership(String groupId) async {
    final token = await _getAuthToken();
    if (token == null) {
      throw Exception("Authentication required");
    }

    try {
      final currentUserId = await _getCurrentUserId();
      if (currentUserId == null) {
        throw Exception("User not authenticated");
      }

      return await getGroupMemberById(groupId: groupId, userId: currentUserId);
    } catch (e) {
      throw Exception('Error fetching current user membership: $e');
    }
  }

  /// Check if current user can manage a specific group (is admin)
  Future<bool> canManageGroup(String groupId) async {
    try {
      final membership = await getCurrentUserMembership(groupId);
      return membership?.canManageGroup ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Bulk invite multiple users to a group by email
  Future<List<GroupInvitationModel>> bulkInviteMembers({
    required String groupId,
    required List<String> emails,
    String? message,
  }) async {
    final token = await _getAuthToken();
    if (token == null) {
      throw Exception("Authentication required");
    }

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/groups/$groupId/invitations/bulk'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'emails': emails, 'message': message}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseBody = jsonDecode(response.body);

        List<dynamic> invitationsList;
        if (responseBody is List) {
          invitationsList = responseBody;
        } else if (responseBody is Map<String, dynamic>) {
          invitationsList =
              responseBody['invitations'] ?? responseBody['data'] ?? [];
        } else {
          throw Exception('Invalid response format: expected List or Map');
        }

        return invitationsList
            .cast<Map<String, dynamic>>()
            .map((invitation) => GroupInvitationModel.fromJson(invitation))
            .toList();
      } else {
        throw Exception(
          'Failed to send bulk invitations: ${response.statusCode} - ${response.body}',
        );
      }
    } on SocketException {
      throw Exception('No internet connection');
    } on TimeoutException {
      throw Exception('Request timeout - please try again');
    } catch (e) {
      throw Exception('Error sending bulk invitations: $e');
    }
  }

  // ============================================================================
  // INVITATION MANAGEMENT METHODS (FR-GRP-002)
  // ============================================================================

  /// Send invitation to join a group (FR-GRP-002)
  Future<GroupInvitationModel> sendInvitation({
    required String groupId,
    required String inviteeEmail,
    String? message,
  }) async {
    final token = await _getAuthToken();
    if (token == null) {
      throw Exception("Authentication required");
    }

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/groups/$groupId/invitations'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'invitee_email': inviteeEmail,
              'message': message,
            }),
          )
          .timeout(const Duration(seconds: 10));

      return _handleResponse<GroupInvitationModel>(
        response,
        (data) => GroupInvitationModel.fromJson(data['invitation']),
      );
    } on SocketException {
      throw Exception('No internet connection');
    } on TimeoutException {
      throw Exception('Request timeout - please try again');
    } catch (e) {
      throw Exception('Error sending invitation: $e');
    }
  }

  /// Get pending invitations for a group
  Future<List<GroupInvitationModel>> getGroupInvitations(String groupId) async {
    final token = await _getAuthToken();
    if (token == null) {
      throw Exception("Authentication required");
    }

    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/groups/$groupId/invitations'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);

        // Handle different possible response structures
        List<dynamic> invitationsList;
        if (responseBody is List) {
          // Direct array response
          invitationsList = responseBody;
        } else if (responseBody is Map<String, dynamic>) {
          // Wrapped in object
          invitationsList =
              responseBody['invitations'] ?? responseBody['data'] ?? [];
        } else {
          throw Exception('Invalid response format: expected List or Map');
        }

        return invitationsList
            .cast<Map<String, dynamic>>()
            .map((invitation) => GroupInvitationModel.fromJson(invitation))
            .toList();
      } else {
        throw Exception(
          'Failed to fetch group invitations: ${response.statusCode} - ${response.body}',
        );
      }
    } on SocketException {
      throw Exception('No internet connection');
    } on TimeoutException {
      throw Exception('Request timeout - please try again');
    } catch (e) {
      throw Exception('Error fetching invitations: $e');
    }
  }

  /// Get invitations for current user
  Future<List<GroupInvitationModel>> getUserInvitations() async {
    final token = await _getAuthToken();
    if (token == null) {
      throw Exception("Authentication required");
    }

    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/invitations'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);

        // Handle different possible response structures
        List<dynamic> invitationsList;
        if (responseBody is List) {
          // Direct array response
          invitationsList = responseBody;
        } else if (responseBody is Map<String, dynamic>) {
          // Wrapped in object
          invitationsList =
              responseBody['invitations'] ?? responseBody['data'] ?? [];
        } else {
          throw Exception('Invalid response format: expected List or Map');
        }

        return invitationsList
            .cast<Map<String, dynamic>>()
            .map((invitation) => GroupInvitationModel.fromJson(invitation))
            .toList();
      } else {
        throw Exception(
          'Failed to fetch user invitations: ${response.statusCode} - ${response.body}',
        );
      }
    } on SocketException {
      throw Exception('No internet connection');
    } on TimeoutException {
      throw Exception('Request timeout - please try again');
    } catch (e) {
      throw Exception('Error fetching user invitations: $e');
    }
  }

  /// Accept an invitation
  Future<GroupWithMembersModel> acceptInvitation(String invitationId) async {
    final token = await _getAuthToken();
    if (token == null) {
      throw Exception("Authentication required");
    }

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/invitations/$invitationId/accept'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      return _handleResponse<GroupWithMembersModel>(
        response,
        (data) => GroupWithMembersModel.fromJson(data['group']),
      );
    } on SocketException {
      throw Exception('No internet connection');
    } on TimeoutException {
      throw Exception('Request timeout - please try again');
    } catch (e) {
      throw Exception('Error accepting invitation: $e');
    }
  }

  /// Decline an invitation
  Future<bool> declineInvitation(String invitationId) async {
    final token = await _getAuthToken();
    if (token == null) {
      throw Exception("Authentication required");
    }

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/invitations/$invitationId/decline'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      return _handleResponse<bool>(response, (data) => true);
    } on SocketException {
      throw Exception('No internet connection');
    } on TimeoutException {
      throw Exception('Request timeout - please try again');
    } catch (e) {
      throw Exception('Error declining invitation: $e');
    }
  }

  /// Cancel an invitation (by inviter)
  Future<bool> cancelInvitation(String invitationId) async {
    final token = await _getAuthToken();
    if (token == null) {
      throw Exception("Authentication required");
    }

    try {
      final response = await http
          .delete(
            Uri.parse('$baseUrl/invitations/$invitationId'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 10));

      return _handleResponse<bool>(response, (data) => true);
    } on SocketException {
      throw Exception('No internet connection');
    } on TimeoutException {
      throw Exception('Request timeout - please try again');
    } catch (e) {
      throw Exception('Error canceling invitation: $e');
    }
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Get group statistics
  Future<Map<String, dynamic>> getGroupStats(String groupId) async {
    final token = await _getAuthToken();
    if (token == null) {
      throw Exception("Authentication required");
    }

    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/groups/$groupId/stats'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 10));

      return _handleResponse<Map<String, dynamic>>(
        response,
        (data) => data['stats'] as Map<String, dynamic>,
      );
    } on SocketException {
      throw Exception('No internet connection');
    } on TimeoutException {
      throw Exception('Request timeout - please try again');
    } catch (e) {
      throw Exception('Error fetching group stats: $e');
    }
  }

  // ============================================================================
  // PRIVATE HELPER METHODS
  // ============================================================================

  /// Centralized response handler with comprehensive error handling
  Future<T> _handleResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic>) parser,
  ) async {
    try {
      switch (response.statusCode) {
        case 200:
        case 201:
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          return parser(data);
        case 204:
          // No content - return success for boolean operations
          if (T == bool) {
            return true as T;
          }
          throw Exception('Unexpected empty response');
        case 401:
          throw Exception('Authentication expired - please login again');
        case 403:
          throw Exception('Permission denied - insufficient access rights');
        case 404:
          throw Exception('Resource not found');
        case 422:
          final errorData = jsonDecode(response.body);
          final errors =
              errorData['errors'] ??
              errorData['message'] ??
              'Validation failed';
          throw Exception('Validation error: $errors');
        case 429:
          throw Exception(
            'Too many requests - please wait before trying again',
          );
        case 500:
        case 502:
        case 503:
        case 504:
          throw Exception('Server error - please try again later');
        default:
          throw Exception(
            'Unexpected error (${response.statusCode}): ${response.body}',
          );
      }
    } on FormatException {
      throw Exception('Invalid server response format');
    }
  }
}
