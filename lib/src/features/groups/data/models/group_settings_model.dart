/// Group-specific settings and preferences for MVP
/// Focuses on essential settings needed for group management and future bill sharing
class GroupSettingsModel {
  final String groupId;

  // Currency and localization (preparation for bill sharing)
  final String defaultCurrency;
  final String? locale; // For number formatting

  // Member permissions (MVP: simple boolean flags)
  final bool allowMemberInvites; // Can members invite others? (FR-GRP-002)
  final bool allowMemberCreateBills; // Future: Can members create bills?
  final bool requireAdminApproval; // Future: Admin approval for new members

  // Bill splitting defaults (preparation for future bill sharing module)
  final String defaultSplitMethod; // 'equal', 'percentage', 'custom'
  final bool autoCalculateSettlements; // Auto-suggest settlements?

  // Notification preferences (group-level defaults)
  final bool notifyNewMembers; // Notify when new members join
  final bool notifyMemberLeaves; // Notify when members leave
  final bool notifyNewBills; // Future: Notify about new bills
  final bool notifyBillUpdates; // Future: Notify about bill updates

  const GroupSettingsModel({
    required this.groupId,
    this.defaultCurrency = 'USD',
    this.locale,
    this.allowMemberInvites = true, // Default: members can invite
    this.allowMemberCreateBills = true, // Default: members can create bills
    this.requireAdminApproval = false, // Default: no approval required
    this.defaultSplitMethod = 'equal', // Default: equal splitting
    this.autoCalculateSettlements = true, // Default: auto-calculate
    this.notifyNewMembers = true, // Default: notify new members
    this.notifyMemberLeaves = false, // Default: don't notify leaves
    this.notifyNewBills = true, // Default: notify new bills
    this.notifyBillUpdates = true, // Default: notify bill updates
  });

  /// Factory constructor from JSON (API response)
  factory GroupSettingsModel.fromJson(Map<String, dynamic> json) {
    return GroupSettingsModel(
      groupId: json['group_id']?.toString() ?? '',
      defaultCurrency: json['default_currency'] as String? ?? 'USD',
      locale: json['locale'] as String?,
      allowMemberInvites: json['allow_member_invites'] as bool? ?? true,
      allowMemberCreateBills:
          json['allow_member_create_bills'] as bool? ?? true,
      requireAdminApproval: json['require_admin_approval'] as bool? ?? false,
      defaultSplitMethod: json['default_split_method'] as String? ?? 'equal',
      autoCalculateSettlements:
          json['auto_calculate_settlements'] as bool? ?? true,
      notifyNewMembers: json['notify_new_members'] as bool? ?? true,
      notifyMemberLeaves: json['notify_member_leaves'] as bool? ?? false,
      notifyNewBills: json['notify_new_bills'] as bool? ?? true,
      notifyBillUpdates: json['notify_bill_updates'] as bool? ?? true,
    );
  }

  /// Convert to JSON (for API requests)
  Map<String, dynamic> toJson() {
    return {
      'group_id': groupId,
      'default_currency': defaultCurrency,
      if (locale != null) 'locale': locale,
      'allow_member_invites': allowMemberInvites,
      'allow_member_create_bills': allowMemberCreateBills,
      'require_admin_approval': requireAdminApproval,
      'default_split_method': defaultSplitMethod,
      'auto_calculate_settlements': autoCalculateSettlements,
      'notify_new_members': notifyNewMembers,
      'notify_member_leaves': notifyMemberLeaves,
      'notify_new_bills': notifyNewBills,
      'notify_bill_updates': notifyBillUpdates,
    };
  }

  /// Helper methods for common permission checks
  bool canMemberInvite(String userId, String adminId) {
    return allowMemberInvites || userId == adminId;
  }

  bool canMemberCreateBill(String userId, String adminId) {
    return allowMemberCreateBills || userId == adminId;
  }

  /// Copy with method for state updates
  GroupSettingsModel copyWith({
    String? groupId,
    String? defaultCurrency,
    String? locale,
    bool? allowMemberInvites,
    bool? allowMemberCreateBills,
    bool? requireAdminApproval,
    String? defaultSplitMethod,
    bool? autoCalculateSettlements,
    bool? notifyNewMembers,
    bool? notifyMemberLeaves,
    bool? notifyNewBills,
    bool? notifyBillUpdates,
  }) {
    return GroupSettingsModel(
      groupId: groupId ?? this.groupId,
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
      locale: locale ?? this.locale,
      allowMemberInvites: allowMemberInvites ?? this.allowMemberInvites,
      allowMemberCreateBills:
          allowMemberCreateBills ?? this.allowMemberCreateBills,
      requireAdminApproval: requireAdminApproval ?? this.requireAdminApproval,
      defaultSplitMethod: defaultSplitMethod ?? this.defaultSplitMethod,
      autoCalculateSettlements:
          autoCalculateSettlements ?? this.autoCalculateSettlements,
      notifyNewMembers: notifyNewMembers ?? this.notifyNewMembers,
      notifyMemberLeaves: notifyMemberLeaves ?? this.notifyMemberLeaves,
      notifyNewBills: notifyNewBills ?? this.notifyNewBills,
      notifyBillUpdates: notifyBillUpdates ?? this.notifyBillUpdates,
    );
  }

  @override
  String toString() {
    return 'GroupSettingsModel(groupId: $groupId, currency: $defaultCurrency, splitMethod: $defaultSplitMethod)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GroupSettingsModel && other.groupId == groupId;
  }

  @override
  int get hashCode => groupId.hashCode;
}
