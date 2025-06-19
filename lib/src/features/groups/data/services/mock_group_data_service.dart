import '../models/models.dart';

/// Mock data service for groups - provides realistic test data
/// This will be replaced with real API calls when backend is ready
class MockGroupDataService {
  // Simulate current user ID (would come from auth service)
  static const String currentUserId = 'user_123';

  /// Mock users for testing invitations and memberships
  static const List<Map<String, dynamic>> mockUsers = [
    {
      'id': 'user_123',
      'name': 'John Doe',
      'email': 'john.doe@example.com',
      'avatar': null,
    },
    {
      'id': 'user_456',
      'name': 'Jane Smith',
      'email': 'jane.smith@example.com',
      'avatar': null,
    },
    {
      'id': 'user_789',
      'name': 'Mike Johnson',
      'email': 'mike.johnson@example.com',
      'avatar': null,
    },
    {
      'id': 'user_101',
      'name': 'Sarah Wilson',
      'email': 'sarah.wilson@example.com',
      'avatar': null,
    },
    {
      'id': 'user_102',
      'name': 'David Brown',
      'email': 'david.brown@example.com',
      'avatar': null,
    },
  ];

  /// Generate mock groups with realistic data
  static List<GroupWithMembersModel> generateMockGroups() {
    final now = DateTime.now();

    return [
      // Group 1: House Expenses (User is admin)
      GroupWithMembersModel(
        group: GroupModel(
          id: 'group_1',
          name: 'House Expenses',
          description: 'Shared household bills and groceries',
          adminId: currentUserId,
          createdAt: now.subtract(const Duration(days: 30)),
          updatedAt: now.subtract(const Duration(days: 2)),
          defaultCurrency: 'USD',
          allowMemberInvites: true,
        ),
        members: [
          GroupMemberModel(
            id: 'member_1',
            groupId: 'group_1',
            userId: currentUserId,
            role: GroupMemberRole.admin,
            status: GroupMemberStatus.active,
            joinedAt: now.subtract(const Duration(days: 30)),
            userName: 'John Doe',
            userEmail: 'john.doe@example.com',
          ),
          GroupMemberModel(
            id: 'member_2',
            groupId: 'group_1',
            userId: 'user_456',
            role: GroupMemberRole.member,
            status: GroupMemberStatus.active,
            joinedAt: now.subtract(const Duration(days: 25)),
            userName: 'Jane Smith',
            userEmail: 'jane.smith@example.com',
          ),
          GroupMemberModel(
            id: 'member_3',
            groupId: 'group_1',
            userId: 'user_789',
            role: GroupMemberRole.member,
            status: GroupMemberStatus.active,
            joinedAt: now.subtract(const Duration(days: 20)),
            userName: 'Mike Johnson',
            userEmail: 'mike.johnson@example.com',
          ),
        ],
        settings: GroupSettingsModel(
          groupId: 'group_1',
          defaultCurrency: 'USD',
          allowMemberInvites: true,
          allowMemberCreateBills: true,
          defaultSplitMethod: 'equal',
          autoCalculateSettlements: true,
          notifyNewMembers: true,
          notifyNewBills: true,
        ),
        pendingInvitationsCount: 1,
      ),

      // Group 2: Weekend Trip (User is member)
      GroupWithMembersModel(
        group: GroupModel(
          id: 'group_2',
          name: 'Weekend Trip',
          description: 'Expenses for our Tahoe trip',
          adminId: 'user_456',
          createdAt: now.subtract(const Duration(days: 15)),
          updatedAt: now.subtract(const Duration(days: 1)),
          defaultCurrency: 'USD',
          allowMemberInvites: false, // Only admin can invite
        ),
        members: [
          GroupMemberModel(
            id: 'member_4',
            groupId: 'group_2',
            userId: 'user_456',
            role: GroupMemberRole.admin,
            status: GroupMemberStatus.active,
            joinedAt: now.subtract(const Duration(days: 15)),
            userName: 'Jane Smith',
            userEmail: 'jane.smith@example.com',
          ),
          GroupMemberModel(
            id: 'member_5',
            groupId: 'group_2',
            userId: currentUserId,
            role: GroupMemberRole.member,
            status: GroupMemberStatus.active,
            joinedAt: now.subtract(const Duration(days: 14)),
            userName: 'John Doe',
            userEmail: 'john.doe@example.com',
          ),
          GroupMemberModel(
            id: 'member_6',
            groupId: 'group_2',
            userId: 'user_101',
            role: GroupMemberRole.member,
            status: GroupMemberStatus.active,
            joinedAt: now.subtract(const Duration(days: 13)),
            userName: 'Sarah Wilson',
            userEmail: 'sarah.wilson@example.com',
          ),
        ],
        settings: GroupSettingsModel(
          groupId: 'group_2',
          defaultCurrency: 'USD',
          allowMemberInvites: false,
          allowMemberCreateBills: true,
          defaultSplitMethod: 'equal',
          autoCalculateSettlements: true,
          notifyNewMembers: false,
          notifyNewBills: true,
        ),
        pendingInvitationsCount: 0,
      ),

      // Group 3: Office Lunch Club (User is member)
      GroupWithMembersModel(
        group: GroupModel(
          id: 'group_3',
          name: 'Office Lunch Club',
          description: 'Weekly office lunch orders',
          adminId: 'user_102',
          createdAt: now.subtract(const Duration(days: 45)),
          updatedAt: now.subtract(const Duration(hours: 6)),
          defaultCurrency: 'USD',
          allowMemberInvites: true,
        ),
        members: [
          GroupMemberModel(
            id: 'member_7',
            groupId: 'group_3',
            userId: 'user_102',
            role: GroupMemberRole.admin,
            status: GroupMemberStatus.active,
            joinedAt: now.subtract(const Duration(days: 45)),
            userName: 'David Brown',
            userEmail: 'david.brown@example.com',
          ),
          GroupMemberModel(
            id: 'member_8',
            groupId: 'group_3',
            userId: currentUserId,
            role: GroupMemberRole.member,
            status: GroupMemberStatus.active,
            joinedAt: now.subtract(const Duration(days: 40)),
            userName: 'John Doe',
            userEmail: 'john.doe@example.com',
          ),
          GroupMemberModel(
            id: 'member_9',
            groupId: 'group_3',
            userId: 'user_789',
            role: GroupMemberRole.member,
            status: GroupMemberStatus.active,
            joinedAt: now.subtract(const Duration(days: 35)),
            userName: 'Mike Johnson',
            userEmail: 'mike.johnson@example.com',
          ),
          // Pending member
          GroupMemberModel(
            id: 'member_10',
            groupId: 'group_3',
            userId: 'user_101',
            role: GroupMemberRole.member,
            status: GroupMemberStatus.invited,
            joinedAt: now.subtract(const Duration(days: 2)),
            invitedAt: now.subtract(const Duration(days: 2)),
            invitedBy: 'user_102',
            userName: 'Sarah Wilson',
            userEmail: 'sarah.wilson@example.com',
          ),
        ],
        settings: GroupSettingsModel(
          groupId: 'group_3',
          defaultCurrency: 'USD',
          allowMemberInvites: true,
          allowMemberCreateBills: false, // Only admin can create bills
          defaultSplitMethod: 'equal',
          autoCalculateSettlements: false,
          notifyNewMembers: true,
          notifyNewBills: true,
        ),
        pendingInvitationsCount: 1,
      ),
    ];
  }

  /// Generate mock invitations
  static List<GroupInvitationModel> generateMockInvitations() {
    final now = DateTime.now();

    return [
      // Pending invitation to House Expenses
      GroupInvitationModel(
        id: 'invite_1',
        groupId: 'group_1',
        inviteeEmail: 'alice.cooper@example.com',
        invitedBy: currentUserId,
        status: InvitationStatus.pending,
        createdAt: now.subtract(const Duration(days: 3)),
        expiresAt: now.add(const Duration(days: 4)),
        token: 'invite_token_123',
        message: 'Join our house expenses group!',
        groupName: 'House Expenses',
        inviterName: 'John Doe',
        inviterEmail: 'john.doe@example.com',
      ),

      // Pending invitation to Office Lunch Club
      GroupInvitationModel(
        id: 'invite_2',
        groupId: 'group_3',
        inviteeEmail: 'sarah.wilson@example.com',
        invitedBy: 'user_102',
        status: InvitationStatus.pending,
        createdAt: now.subtract(const Duration(days: 2)),
        expiresAt: now.add(const Duration(days: 5)),
        token: 'invite_token_456',
        message: 'Come join our lunch group!',
        groupName: 'Office Lunch Club',
        inviterName: 'David Brown',
        inviterEmail: 'david.brown@example.com',
      ),

      // Recently accepted invitation
      GroupInvitationModel(
        id: 'invite_3',
        groupId: 'group_2',
        inviteeEmail: 'john.doe@example.com',
        invitedBy: 'user_456',
        status: InvitationStatus.accepted,
        createdAt: now.subtract(const Duration(days: 14)),
        respondedAt: now.subtract(const Duration(days: 14)),
        expiresAt: now.subtract(const Duration(days: 7)),
        token: 'invite_token_789',
        groupName: 'Weekend Trip',
        inviterName: 'Jane Smith',
        inviterEmail: 'jane.smith@example.com',
      ),
    ];
  }

  /// Find user by email (for invitation lookup)
  static Map<String, dynamic>? findUserByEmail(String email) {
    try {
      return mockUsers.firstWhere((user) => user['email'] == email);
    } catch (e) {
      return null;
    }
  }

  /// Generate unique ID for new entities
  static String generateId() {
    return 'mock_${DateTime.now().millisecondsSinceEpoch}';
  }
}
