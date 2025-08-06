import 'package:flutter_test/flutter_test.dart';
import 'package:apex_money/src/features/groups/data/models/group_with_members_model.dart';

void main() {
  group('GroupWithMembersModel', () {
    test('fromJson handles null group field gracefully', () {
      // Test case that was causing the error
      final json = {
        'id': '1',
        'name': 'Test Group',
        'admin_id': 'user123',
        'members': [],
        // Note: 'group' field is missing, which was causing the null error
      };

      expect(() => GroupWithMembersModel.fromJson(json), returnsNormally);
    });

    test('fromJson handles nested group structure', () {
      final json = {
        'group': {
          'id': '1',
          'name': 'Test Group',
          'admin_id': 'user123',
        },
        'members': [],
      };

      expect(() => GroupWithMembersModel.fromJson(json), returnsNormally);
    });

    test('fromJson handles flat structure without group wrapper', () {
      final json = {
        'id': '1',
        'name': 'Test Group',
        'admin_id': 'user123',
        'members': [],
      };

      final result = GroupWithMembersModel.fromJson(json);
      expect(result.group.name, equals('Test Group'));
      expect(result.group.id, equals('1'));
    });

    test('fromJson handles null members gracefully', () {
      final json = {
        'id': '1',
        'name': 'Test Group',
        'admin_id': 'user123',
        'members': null,
      };

      final result = GroupWithMembersModel.fromJson(json);
      expect(result.members, isEmpty);
    });
  });
}
