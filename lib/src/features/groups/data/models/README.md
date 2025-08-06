# Group Data Models

This directory contains all data models for the Groups module, implementing the requirements outlined in the PRD (FR-GRP-001 through FR-GRP-008).

## Models Overview

### 1. `GroupModel` - Core Group Entity
- **Purpose**: Represents the fundamental group entity
- **Key Features**:
  - Simple admin system (one admin per group for MVP)
  - Basic group metadata (name, description, image)
  - Group-level settings (currency, member permissions)
  - Timestamps for audit trail

### 2. `GroupMemberModel` - Member Management
- **Purpose**: Represents group membership with roles and status
- **Key Features**:
  - Binary role system: admin/member (MVP scope)
  - Member status tracking (active, invited, left, removed)
  - Invitation workflow support
  - User details integration for UI display

### 3. `GroupInvitationModel` - Invitation System
- **Purpose**: Manages the complete invitation lifecycle
- **Key Features**:
  - Email-based invitations (works for unregistered users)
  - Secure token-based invitation links
  - Expiration handling (7-day default)
  - Status tracking (pending, accepted, declined, expired, cancelled)
  - Optional personal messages

### 4. `GroupSettingsModel` - Group Configuration
- **Purpose**: Manages group-specific settings and preferences
- **Key Features**:
  - Currency settings (preparation for bill sharing)
  - Member permission controls
  - Bill splitting defaults (for future bill module)
  - Notification preferences
  - Simple boolean flags for MVP

### 5. `GroupWithMembersModel` - UI Convenience Model
- **Purpose**: Combined model for UI components needing complete group data
- **Key Features**:
  - Aggregates group, members, and settings
  - Helper methods for common UI operations
  - Permission checking utilities
  - Member filtering and counting

## PRD Compliance

| Requirement | Implementation | Status |
|-------------|---------------|--------|
| FR-GRP-001 | Group creation with name | ✅ GroupModel |
| FR-GRP-002 | Member invitation via email | ✅ GroupInvitationModel |
| FR-GRP-003 | Group listing support | ✅ All models |
| FR-GRP-004 | Group detail views | ✅ GroupWithMembersModel |
| FR-GRP-005 | Add members | ✅ GroupMemberModel |
| FR-GRP-006 | Remove members | ✅ GroupMemberModel status |
| FR-GRP-007 | Modify group name | ✅ GroupModel.copyWith() |
| FR-GRP-008 | Delete group | ✅ GroupModel.isActive flag |

## MVP Design Decisions

### ✅ **Included in MVP**
- Simple admin/member role system
- Email-based invitation workflow
- Basic group settings for future bill sharing
- Status tracking for members and invitations
- Consistent JSON serialization for API integration

### ❌ **Excluded from MVP** (Future Enhancement)
- Complex permission systems
- Multiple admin roles
- Rich group settings
- File attachments
- Group categories/tags
- Multiple currencies (per PRD scope)

## Usage Examples

```dart
// Import all models
import 'package:apex_money/src/features/groups/data/models/models.dart';

// Create a new group
final group = GroupModel(
  name: 'House Expenses',
  description: 'Shared household bills',
  adminId: 'user123',
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

// Invite a member
final invitation = GroupInvitationModel(
  groupId: group.id!,
  inviteeEmail: 'friend@example.com',
  invitedBy: 'user123',
  status: InvitationStatus.pending,
  createdAt: DateTime.now(),
  expiresAt: DateTime.now().add(Duration(days: 7)),
);

// Check permissions
final canInvite = group.allowMemberInvites;
final isAdmin = group.isUserAdmin('user123');
```

## Next Steps

With these models in place, the next implementation steps are:

1. **Group Services** - API integration for CRUD operations
2. **Group Repository** - Data layer abstraction
3. **Group BLoC/Cubit** - State management
4. **Group UI Components** - User interface implementation

## Database Schema Implications

These models suggest the following database tables:

- `groups` - Core group information
- `group_members` - Member relationships and roles
- `group_invitations` - Invitation tracking
- `group_settings` - Group configuration (optional, could be embedded in groups table)

The models are designed to work with both SQL (Firebase Firestore) and NoSQL databases through the JSON serialization methods.
