/// Invitation status for tracking invitation lifecycle
enum InvitationStatus {
  pending, // Invitation sent, awaiting response
  accepted, // Invitation accepted
  declined, // Invitation declined
  expired, // Invitation expired (time-based)
  cancelled, // Invitation cancelled by admin
}

class GroupInvitationModel {
  final String? id;
  final String groupId;
  final String inviteeEmail; // Email of person being invited
  final String invitedBy; // User ID who sent the invitation
  final InvitationStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;
  final DateTime expiresAt;
  final String? token; // Unique token for invitation link
  final String? message; // Optional personal message from inviter

  // Group and inviter details (populated from API joins for UI)
  final String? groupName;
  final String? inviterName;
  final String? inviterEmail;

  const GroupInvitationModel({
    this.id,
    required this.groupId,
    required this.inviteeEmail,
    required this.invitedBy,
    required this.status,
    required this.createdAt,
    this.respondedAt,
    required this.expiresAt,
    this.token,
    this.message,
    this.groupName,
    this.inviterName,
    this.inviterEmail,
  });

  /// Factory constructor from JSON (API response)
  factory GroupInvitationModel.fromJson(Map<String, dynamic> json) {
    return GroupInvitationModel(
      id: json['id']?.toString(),
      groupId: json['group_id']?.toString() ?? '',
      inviteeEmail: json['invitee_email'] as String,
      invitedBy: json['invited_by']?.toString() ?? '',
      status: InvitationStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => InvitationStatus.pending,
      ),
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      respondedAt:
          json['responded_at'] != null
              ? DateTime.parse(json['responded_at'] as String)
              : null,
      expiresAt: DateTime.parse(
        json['expires_at'] ??
            DateTime.now().add(const Duration(days: 7)).toIso8601String(),
      ),
      token: json['token'] as String?,
      message: json['message'] as String?,
      // Details from JOIN queries for UI display
      groupName: json['group_name'] as String?,
      inviterName: json['inviter_name'] as String?,
      inviterEmail: json['inviter_email'] as String?,
    );
  }

  /// Convert to JSON (for API requests)
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'group_id': groupId,
      'invitee_email': inviteeEmail,
      'invited_by': invitedBy,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      if (respondedAt != null) 'responded_at': respondedAt!.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      if (token != null) 'token': token,
      if (message != null) 'message': message,
    };
  }

  /// Helper methods for invitation state management
  bool get isPending => status == InvitationStatus.pending;
  bool get isExpired =>
      DateTime.now().isAfter(expiresAt) || status == InvitationStatus.expired;
  bool get canRespond => isPending && !isExpired;
  bool get isResolved =>
      status == InvitationStatus.accepted ||
      status == InvitationStatus.declined ||
      status == InvitationStatus.cancelled;

  /// Time left before expiration
  Duration get timeLeft {
    if (isExpired) return Duration.zero;
    return expiresAt.difference(DateTime.now());
  }

  /// Display name for inviter in UI
  String get displayInviter => inviterName ?? inviterEmail ?? 'User $invitedBy';

  /// Display group name for UI
  String get displayGroupName => groupName ?? 'Group $groupId';

  /// Create a copy with updated status and response time
  GroupInvitationModel respond(InvitationStatus newStatus) {
    return copyWith(status: newStatus, respondedAt: DateTime.now());
  }

  /// Copy with method for state updates
  GroupInvitationModel copyWith({
    String? id,
    String? groupId,
    String? inviteeEmail,
    String? invitedBy,
    InvitationStatus? status,
    DateTime? createdAt,
    DateTime? respondedAt,
    DateTime? expiresAt,
    String? token,
    String? message,
    String? groupName,
    String? inviterName,
    String? inviterEmail,
  }) {
    return GroupInvitationModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      inviteeEmail: inviteeEmail ?? this.inviteeEmail,
      invitedBy: invitedBy ?? this.invitedBy,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      token: token ?? this.token,
      message: message ?? this.message,
      groupName: groupName ?? this.groupName,
      inviterName: inviterName ?? this.inviterName,
      inviterEmail: inviterEmail ?? this.inviterEmail,
    );
  }

  @override
  String toString() {
    return 'GroupInvitationModel(id: $id, groupId: $groupId, inviteeEmail: $inviteeEmail, status: ${status.name})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GroupInvitationModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
