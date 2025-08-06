import 'package:flutter_test/flutter_test.dart';
import 'package:apex_money/src/features/groups/data/models/models.dart';

void main() {
  group('Group JSON Parsing Tests', () {
    test('GroupWithMembersModel can parse your JSON structure', () {
      // Your exact JSON structure
      final jsonData = {
        "group": {
          "id": "group_123",
          "name": "Roommates Expenses",
          "description": "Shared expenses for apartment 4B",
          "createdByUserId": "user_456",
          "createdAt": "2024-01-15T10:30:00Z",
          "updatedAt": "2024-01-20T14:15:00Z",
          "isActive": true,
          "allowMemberInvites": true,
          "defaultCurrency": "USD"
        },
        "members": [
          {
            "id": "member_789",
            "userId": "user_456",
            "userName": "John Doe",
            "userEmail": "john@example.com",
            "role": "admin",
            "status": "active",
            "joinedAt": "2024-01-15T10:30:00Z"
          }
        ],
        "settings": {
          "defaultCurrency": "USD",
          "requireApprovalForExpenses": false,
          "defaultSplitMethod": "equal"
        },
        "statistics": {
          "memberCount": 3,
          "activeBills": 2,
          "totalBillAmount": 256.47,
          "pendingInvitationsCount": 1
        }
      };

      // This should not throw an exception
      expect(() {
        final groupWithMembers = GroupWithMembersModel.fromJson(jsonData);
        
        // Verify the parsing worked correctly
        expect(groupWithMembers.group.id, 'group_123');
        expect(groupWithMembers.group.name, 'Roommates Expenses');
        expect(groupWithMembers.group.adminId, 'user_456');
        expect(groupWithMembers.members.length, 1);
        expect(groupWithMembers.members[0].userName, 'John Doe');
        expect(groupWithMembers.pendingInvitationsCount, 1);
      }, returnsNormally);
    });

    test('GroupWithMembersModel handles flat JSON structure (no group key)', () {
      // Test the fallback when there's no 'group' key
      final flatJsonData = {
        "id": "group_123",
        "name": "Roommates Expenses",
        "description": "Shared expenses for apartment 4B",
        "createdByUserId": "user_456",
        "createdAt": "2024-01-15T10:30:00Z",
        "updatedAt": "2024-01-20T14:15:00Z",
        "isActive": true,
        "allowMemberInvites": true,
        "defaultCurrency": "USD",
        "members": [
          {
            "id": "member_789",
            "userId": "user_456",
            "userName": "John Doe",
            "userEmail": "john@example.com",
            "role": "admin",
            "status": "active",
            "joinedAt": "2024-01-15T10:30:00Z"
          }
        ]
      };

      expect(() {
        final groupWithMembers = GroupWithMembersModel.fromJson(flatJsonData);
        expect(groupWithMembers.group.id, 'group_123');
        expect(groupWithMembers.group.name, 'Roommates Expenses');
        expect(groupWithMembers.members.length, 1);
      }, returnsNormally);
    });

    test('GroupWithMembersModel handles null/empty data gracefully', () {
      final minimalJsonData = {
        "group": {
          "name": "Test Group",
          "createdByUserId": "user_123"
        },
        "members": []
      };

      expect(() {
        final groupWithMembers = GroupWithMembersModel.fromJson(minimalJsonData);
        expect(groupWithMembers.group.name, 'Test Group');
        expect(groupWithMembers.members.isEmpty, true);
        expect(groupWithMembers.pendingInvitationsCount, null);
      }, returnsNormally);
    });

    test('GroupModel handles both field name variations', () {
      // Test camelCase fields (your JSON format)
      final camelCaseJson = {
        "id": "group_123",
        "name": "Test Group",
        "createdByUserId": "user_456",
        "createdAt": "2024-01-15T10:30:00Z",
        "updatedAt": "2024-01-20T14:15:00Z",
        "isActive": true,
        "allowMemberInvites": true,
        "defaultCurrency": "USD"
      };

      expect(() {
        final group = GroupModel.fromJson(camelCaseJson);
        expect(group.name, 'Test Group');
        expect(group.adminId, 'user_456');
        expect(group.isActive, true);
      }, returnsNormally);

      // Test snake_case fields (Laravel API format)
      final snakeCaseJson = {
        "id": "group_123",
        "name": "Test Group",
        "admin_id": "user_456",
        "created_at": "2024-01-15T10:30:00Z",
        "updated_at": "2024-01-20T14:15:00Z",
        "is_active": true,
        "allow_member_invites": true,
        "default_currency": "USD"
      };

      expect(() {
        final group = GroupModel.fromJson(snakeCaseJson);
        expect(group.name, 'Test Group');
        expect(group.adminId, 'user_456');
        expect(group.isActive, true);
      }, returnsNormally);
    });
  });
}
