/// Integration test for Groups feature
/// This file tests the integration of all components
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/services/group_service.dart';
import 'presentation/providers/groups_provider.dart';
import 'presentation/pages/groups_page.dart';

/// Test widget to verify groups feature integration
class GroupsTestApp extends StatelessWidget {
  const GroupsTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Groups Feature Test',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: ChangeNotifierProvider(
        create: (context) => GroupsProvider(),
        child: const GroupsPage(),
      ),
    );
  }
}

/// Test function to verify all components can be instantiated
Future<void> testGroupsIntegration() async {
  // Test service initialization
  final groupService = GroupService.instance;
  await groupService.initialize();

  // Test provider instantiation
  final provider = GroupsProvider();

  // Test data models (implicitly tested through service)
  await provider.loadGroups();
  await provider.loadInvitations();

  print('✅ Groups feature integration test passed!');
  print('📊 Loaded ${provider.groups.length} groups');
  print('📨 Loaded ${provider.invitations.length} invitations');
  print('👤 Current user ID: ${provider.getCurrentUserId()}');
}
