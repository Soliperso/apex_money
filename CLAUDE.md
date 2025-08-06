# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Apex Money** (SavvySplit) is a cross-platform Flutter personal finance application with AI-powered insights, designed to provide comprehensive expense management, group-based bill sharing, and intelligent financial analysis.

### Primary Goal
To empower users with an intelligent, intuitive, and efficient tool for personal financial management and collaborative expense distribution.

### Key Objectives
- Implement a resilient system for granular individual expense tracking
- Facilitate seamless creation and administration of user groups
- Enable fluid bill sharing and sophisticated splitting methodologies within defined groups
- Integrate advanced AI capabilities for proactive spending pattern analysis and predictive financial forecasting
- Ensure highly performant, modular, and scalable application architecture
- Deliver a visually cohesive, professionally designed, and highly usable interface adhering to modern mobile design principles
- Optimize navigation for efficiency and clarity across the application's entire feature set

### Target Audience
Individuals, cohabitants, and social groups requiring:
- Comprehensive personal spending oversight
- Equitable sharing and reconciliation of shared expenses
- Actionable insights into financial habits and anticipating future expenditure

## Environment Setup

### Initial Configuration
1. **Copy environment template:**
   ```bash
   cp .env.example .env
   ```

2. **Configure your environment variables in `.env`:**
   ```bash
   # Backend API Configuration - Replace with your Laravel backend
   API_BASE_URL=https://your-backend-domain.com/api
   
   # OpenAI API Configuration - Get key from https://platform.openai.com/api-keys
   OPENAI_API_KEY=your_actual_openai_api_key_here
   OPENAI_BASE_URL=https://api.openai.com/v1
   OPENAI_MODEL=gpt-3.5-turbo
   
   # App Configuration
   APP_NAME=Apex Money
   APP_VERSION=1.0.0
   DEBUG_MODE=false
   ```

3. **Security Notes:**
   - Never commit your `.env` file to version control
   - Use different API keys for development and production
   - Rotate API keys regularly for security
   - The `.env` file is automatically excluded via `.gitignore`

## Development Commands

```bash
# Essential Flutter commands
flutter pub get              # Install dependencies
flutter run                  # Run app in debug mode  
flutter run --release        # Run in release mode
flutter run -d chrome        # Run in Chrome (for web debugging)
flutter clean                # Clean build artifacts
dart format lib/              # Format code
dart format lib/ --set-exit-if-changed  # Check if formatting needed (CI/CD)

# Testing commands
flutter test                 # Run all tests
flutter test --coverage     # Run tests with coverage report
flutter test test/widget_test.dart  # Run specific test file
flutter test --name="test name"     # Run specific test by name
flutter test --reporter=json        # JSON output for CI/CD

# Static analysis and code quality
flutter analyze              # Static code analysis (may have analyzer issues)
flutter analyze --fatal-infos       # Treat info messages as fatal
dart fix --dry-run           # Preview automatic fixes
dart fix --apply             # Apply automatic fixes

# Platform-specific builds
flutter build apk            # Android APK
flutter build apk --release  # Release APK
flutter build ios --no-codesign    # iOS build (development)
flutter build macos          # macOS desktop
flutter build windows        # Windows desktop
flutter build linux          # Linux desktop

# Debugging and troubleshooting
flutter doctor               # Check Flutter setup
flutter doctor -v            # Verbose Flutter setup check
flutter pub deps             # Show dependency tree
flutter pub outdated         # Check for package updates
flutter logs                 # View device logs
flutter attach               # Attach to running app for debugging
flutter devices              # List available devices/simulators

# Performance and profiling
flutter run --profile        # Run in profile mode for performance testing
flutter drive --target=test_driver/app.dart  # Integration tests
```

## Architecture Overview

This is a Flutter personal finance app built with **Clean Architecture + Feature-First organization**. Each feature module follows a consistent layered structure:

```
lib/src/features/[feature]/
├── data/
│   ├── models/      # JSON serializable data models
│   └── services/    # API clients and data sources
├── presentation/    # UI layer
│   ├── pages/       # Full screen widgets
│   ├── widgets/     # Reusable UI components
│   └── providers/   # Provider state management
```

## Key Architectural Patterns

- **State Management**: Provider pattern (primary), BLoC/Cubit for groups module
- **Navigation**: GoRouter for type-safe declarative routing (`src/routes/app_router.dart`)
- **Security**: JWT tokens in SharedPreferences, biometric auth with `local_auth`
- **Authentication**: JWT-based with Laravel backend integration
- **Provider Setup**: MultiProvider in `main.dart` with ThemeProvider, GroupsProvider, NotificationProvider
- **Orientation**: Locked to portrait mode only (`main.dart` - SystemChrome.setPreferredOrientations)
- **Networking**: Dio for HTTP client with custom interceptors for authentication
- **AI Integration**: OpenAI GPT-3.5-turbo via dedicated `AIService` with comprehensive prompt engineering
- **Real-time Updates**: Dashboard sync service for cross-feature data synchronization
- **Error Handling**: Comprehensive error boundaries and user-friendly error messaging

## API Integration

- **Base URL**: `https://srv797850.hstgr.cloud/api`
- **Authentication**: Bearer token (JWT) stored in SharedPreferences
- **User Model**: Laravel backend uses simple user model with `name` and `email` fields only

### Backend Integration Status

**Production Ready**: All core services are now integrated with Laravel backend:

```dart
// BACKEND INTEGRATED:
- TransactionService: ✅ FULLY integrated with Laravel backend
- AuthService: ✅ FULLY integrated with Laravel backend  
- GroupService: ✅ FULLY integrated with Laravel backend (CRUD complete)

// LOCAL STORAGE / HYBRID:
- BillService: ✅ Integrated with GroupService backend + local calculation logic
- GoalService: Uses local storage + transactions integration
```

**Current Status**: Groups CRUD operations are fully functional with real Laravel API endpoints. User authentication uses email-based identification system compatible with Laravel user model structure.

## User Data Architecture

### No Dedicated User Model
The app **does not have a dedicated User model class**. User data is handled as `Map<String, dynamic>` throughout the application:

```dart
// Login response structure:
{
  "user": {
    "name": "John Doe",
    "email": "john.doe@example.com"
  },
  "access_token": "jwt_token_here"
}

// Profile data structure:
{
  "name": "John Doe", 
  "email": "john.doe@example.com",
  "profile_picture": "optional_url"
}
```

### Email-Based User Identification
- **User ID = Email Address**: The user's email serves as the unique identifier
- **Storage**: Email stored as `user_id` in SharedPreferences during login
- **Laravel Compatibility**: Matches Laravel user model with only `name` and `email` fields
- **Group Operations**: Email address used as `created_by_user_id` in group API calls

### Data Storage Strategy
- **Access Token**: Stored in SharedPreferences as `access_token`
- **User Email**: Stored in SharedPreferences as `user_id` 
- **Profile Data**: Managed via `UserProfileNotifier` as Map<String, dynamic>
- **No FlutterSecureStorage**: Despite mentions in docs, actual implementation uses SharedPreferences

## Code Conventions & Critical Patterns

### Navigation Architecture
- **Centralized Navigation**: Use `MainNavigationWrapper` from `shared/widgets/main_navigation_wrapper.dart` for all main pages
- **Bottom Navigation**: Automatically handled by MainNavigationWrapper with proper currentIndex (0-4)
- **Profile Access**: Dashboard avatar is clickable and navigates to `/profile`
- **Settings Menu**: `AppSettingsMenu` provides theme toggle and logout functionality
- **Deep Navigation**: Group detail and bill creation pages have breadcrumb navigation

### Constant Expression Rules
**CRITICAL**: When using theme variables in widgets, avoid `const` keyword:
```dart
// ❌ WRONG - Will cause compilation errors
const Text('Hello', style: TextStyle(color: isDark ? Colors.white : Colors.black))

// ✅ CORRECT - Remove const when using runtime variables
Text('Hello', style: TextStyle(color: isDark ? Colors.white : Colors.black))
```

### Data Models & Services
- **Models**: Use `fromJson`/`toJson` for all data models
- **Error Handling**: Always show user-friendly error messages with loading states
- **Shared Widgets**: Use `AppGradientBackground` and `AppCard` from `shared/widgets/`

### Glass-Morphism UI System

The app uses a consistent glass-morphism design pattern:

```dart
// Standard glass-morphism pattern:
decoration: BoxDecoration(
  color: Theme.of(context).brightness == Brightness.dark
      ? colorScheme.surfaceContainer.withValues(alpha: 0.6)
      : colorScheme.surface.withValues(alpha: 0.5),
  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
  border: Border.all(
    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
    width: 1,
  ),
)

// Card-level styling:
color: theme.brightness == Brightness.dark
    ? colorScheme.surfaceContainerHigh.withValues(alpha: 0.7)
    : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)
```

### Color System

- **Income**: Use `AppTheme.successColor` (green) - never blue
- **Expenses**: Use `AppTheme.errorColor` (red)  
- **Primary Actions**: Use `AppTheme.primaryColor` (blue)

## Functional Requirements & Implementation Status

### Authentication & Profile Module (AUTH)
**Status: Production Ready**

**Requirements Implemented:**
- FR-AUTH-001: ✅ User registration via email and password
- FR-AUTH-002: ✅ Google Sign-In integration for streamlined registration/authentication
- FR-AUTH-003: ✅ Apple Sign-In integration for iOS ecosystem
- FR-AUTH-004: ✅ Authenticated user login with established credentials
- FR-AUTH-005: ✅ Secure user logout mechanism
- FR-AUTH-006: ✅ "Forgot Password" workflow implementation
- FR-AUTH-007: ✅ Profile management (name, email, optional profile picture)

**Additional Features:**
- ✅ Biometric authentication support (Face ID/Touch ID/Fingerprint)
- ✅ JWT-based session management with Laravel backend
- ✅ Account lockout after failed attempts

### Personal Expense Management Module (EXPENSES)
**Status: MVP Ready**

**Requirements Implemented:**
- FR-EXP-001: ✅ Create expense records (Amount, Category, Date, Description, Payment Method)
- FR-EXP-002: ✅ Configurable predefined expense categories
- FR-EXP-003: ✅ Comprehensive list of recorded personal expenses
- FR-EXP-004: ✅ Expense filtering by category
- FR-EXP-005: ✅ Expense filtering by date range
- FR-EXP-006: ✅ Edit existing expense entries
- FR-EXP-007: ✅ Delete existing expense entries
- FR-EXP-008: ✅ Summarized spending view on dashboard (monthly total, category breakdown)
- FR-EXP-009: ✅ Basic graphical visualizations (pie charts, bar charts) for spending patterns

**Technical Notes:**
- Basic payment method support (uses default payment method ID)
- Income transactions display in green (AppTheme.successColor)
- Expense transactions display in red (AppTheme.errorColor)

### Group Management Module (GROUPS)
**Status: Production Ready**

**Requirements Implemented:**
- FR-GRP-001: ✅ Create new groups by providing group name
- FR-GRP-002: ✅ Invite registered users via email or username lookup
- FR-GRP-003: ✅ Display list of all groups user is member of
- FR-GRP-004: ✅ Detailed group views (member rosters, associated shared bills)
- FR-GRP-005: ✅ Group administrators can add new members
- FR-GRP-006: ✅ Group administrators can remove members
- FR-GRP-007: ✅ Group administrators can modify group name
- FR-GRP-008: ✅ Group administrators can delete groups

### Bill Sharing & Splitting Module (BILLS)
**Status: MVP Ready (Core Features Complete)**

**Requirements Implemented:**
- FR-BILL-001: ✅ Group members can submit new shared bills
- FR-BILL-002: ✅ Capture bill's total amount, description, transaction date
- FR-BILL-003: ✅ Select payer(s) from group members
- FR-BILL-004: ✅ Equitable bill distribution among selected group members
- FR-BILL-005: ✅ Custom percentage-based bill distribution
- FR-BILL-006: ✅ Custom fixed-amount bill distribution
- FR-BILL-007: ✅ Accurate computation of individual shares and debt/credit calculations
- FR-BILL-008: ✅ Clear summary of outstanding inter-group debts and credits

**Post-MVP Requirements:**
- FR-BILL-009: 🔄 Mark individual debts as "settled" or "paid"
- FR-BILL-010: 🔄 History of settled bills within groups

### Goal Management Module (GOALS)
**Status: Production Ready**

**Requirements Implemented:**
- FR-GOAL-001: ✅ Create financial goals (Goal Name, Target Amount, optional Deadline)
- FR-GOAL-002: ✅ Visual progress tracker for each active financial goal
- FR-GOAL-003: ✅ Manual updates for saved amount towards goals
- FR-GOAL-004: ✅ Edit or delete existing goals

### AI Capabilities Module (AI_INSIGHTS)
**Status: Production Ready (Requires API Key Configuration)**

**Requirements Implemented:**
- FR-AI-001: ✅ Comprehensive historical spending analysis with 6-month context
- FR-AI-002: ✅ AI-generated spending pattern summaries via OpenAI GPT-3.5-turbo
- FR-AI-003: ✅ Future spending predictions with confidence levels
- FR-AI-004: ✅ Visual insights with interactive charts and time filtering

**Advanced Features:**
- ✅ Sophisticated `AIService` with OpenAI integration
- ✅ Enhanced prompt engineering for financial analysis
- ✅ Anomaly detection and seasonal pattern analysis
- ✅ Category trend analysis and spending velocity calculations
- ✅ Interactive time filtering (7D/30D/90D/1Y)
- ✅ Dashboard integration with real-time AI insights
- ✅ Comprehensive AI insight models and response parsing

**Configuration Required:**
- OpenAI API key setup in `.env` file (OPENAI_API_KEY=your_key_here)
- API key validation logic complete, needs proper configuration

### Notifications Module (IN-APP REMINDERS)
**Status: Production Ready**

**Requirements Implemented:**
- FR-NOTIF-001: ✅ In-app notification framework with state management
- FR-NOTIF-002: ✅ Debt reminder system with configurable intervals
- FR-NOTIF-003: ✅ Settlement confirmation notifications

**Advanced Features:**
- ✅ `NotificationService` with periodic reminder processing
- ✅ `NotificationProvider` with comprehensive state management
- ✅ Configurable reminder intervals and cleanup routines
- ✅ Notification models and UI components (`NotificationBadge`, `NotificationList`)
- ✅ Background processing with timer-based reminders
- ✅ Integration with bill and debt systems

## Non-Functional Requirements

### Performance Requirements
- **NFR-PERF-001**: App screens render within 2 seconds under stable network conditions
- **NFR-PERF-002**: Data synchronization operations complete within 3 seconds for standard data volumes
- **NFR-PERF-003**: AI-driven spending analysis and prediction results display within 5 seconds of initiation

### Usability (UX) Requirements
- **NFR-USAB-001**: User interface exhibits high degree of intuitiveness for novice users
- **NFR-USAB-002**: All interactive UI elements provide clear and immediate visual feedback
- **NFR-USAB-003**: Error messages are explicit, concise, and provide actionable guidance
- **NFR-USAB-004**: Application optimally supports portrait orientation (locked in main.dart)
- **NFR-USAB-005**: Consistent terminology and labeling throughout all interfaces

### Reliability Requirements
- **NFR-RELI-001**: Graceful management and recovery from network connectivity fluctuations
- **NFR-RELI-002**: All user-submitted data persisted reliably and consistently
- **NFR-RELI-003**: Minimize occurrences of crashes and Application Not Responding (ANR) errors

### Security Requirements
- **NFR-SECU-001**: User authentication conforms to industry-standard secure protocols (OAuth 2.0, Firebase Authentication)
- **NFR-SECU-002**: All sensitive user data encrypted both in transit and at rest
- **NFR-SECU-003**: Access control to group-specific data restricted to authorized group members only
- **NFR-SECU-004**: Application hardened against common mobile security vulnerabilities (OWASP Mobile Top 10)

### Maintainability Requirements
- **NFR-MAINT-001**: Codebase adheres to established Flutter best practices and Dart language guidelines
- **NFR-MAINT-002**: Modular architecture facilitates independent development, testing, and future feature expansion
- **NFR-MAINT-003**: Comprehensive documentation with inline comments and consistent naming conventions

### Scalability Requirements
- **NFR-SCAL-001**: Backend system (Laravel) designed to accommodate substantial and growing user base
- **NFR-SCAL-002**: Data models and repository layers structured to support future functional extensions

### Compatibility Requirements
- **NFR-COMP-001**: Android compatibility (API 21+)
- **NFR-COMP-002**: iOS compatibility (iOS 14+)
- **NFR-COMP-003**: Responsive rendering across broad spectrum of screen sizes (smartphones to tablets)

### Testing Strategy
```bash
flutter test                 # Run all tests (basic test setup exists)
flutter test --coverage     # Run tests with coverage report
flutter analyze              # Static analysis for code quality
dart format lib/ --set-exit-if-changed  # Check code formatting
```

**Coverage Requirements:**
- Unit Tests: >90% coverage for business logic
- Widget Tests: All custom widgets and screens
- Integration Tests: Critical user flows
- Golden Tests: UI consistency across devices

**Current Test Coverage**: Minimal - only `test/widget_test.dart` exists

## MVP Implementation Summary

### Launch Readiness: 95% Complete ✅

**Fully Implemented Modules (6/7):**
1. ✅ **Authentication & Profile** (100%) - Production ready with biometric auth
2. ✅ **Personal Expenses** (100%) - Full CRUD with backend integration  
3. ✅ **Group Management** (100%) - Complete CRUD with Laravel backend
4. ✅ **Bill Sharing & Splitting** (95%) - Core features complete, settlement tracking partially implemented
5. ✅ **Goal Management** (100%) - Full integration with transaction sync
6. ✅ **Notifications** (100%) - Complete in-app notification system

**Configuration Required (1/7):**
7. 🔧 **AI Insights** (95%) - Complete implementation, requires OpenAI API key setup

### Key Implementation Highlights

**Advanced Features Beyond MVP:**
- Sophisticated AI service with GPT-3.5-turbo integration
- Real-time dashboard with AI-powered insights
- Comprehensive bill calculation engine with debt tracking
- Automatic goal-transaction synchronization
- Biometric authentication and account security
- Glass-morphism UI design with dark/light theme support
- Role-based group permissions and admin controls
- Interactive charts and data visualizations
- Background notification processing

**Production-Grade Architecture:**
- Clean Architecture with feature-first organization
- Comprehensive error handling and user feedback
- JWT-based authentication with Laravel backend
- Provider-based state management with reactive updates
- Centralized navigation with breadcrumb support
- Performance optimization with caching and sync services

## Current Development Priority

### MVP Launch Ready (95% Complete)
**All core features implemented and production-ready**

### Final Configuration Tasks
1. **AI Features Activation** (CONFIGURATION ONLY)
   - Add OpenAI API key to `.env` file
   - Verify API key validation in `ApiConfig.validateConfig()`
   - All AI infrastructure and UI complete

2. **Optional Enhancements** (POST-MVP)
   - Bill settlement history improvements
   - Additional payment method features
   - Advanced analytics and reporting

### Post-MVP Features (Future Considerations)
1. **Advanced Payment Methods Management**
   - Payment method CRUD operations beyond basic default support
   - Payment method selection UI in transaction forms
   - Payment method-specific analytics and filtering

2. **Bill Settlement Enhancements**
   - "Mark as paid" functionality (FR-BILL-009)
   - Settled bills history with timestamps (FR-BILL-010)
   - Debt settlement tracking and notifications

3. **Advanced Financial Features**
   - Advanced budgeting features with customizable alerts
   - Direct integration with external financial services via secure APIs
   - Multi-currency transaction handling
   - Investment portfolio tracking

4. **Enhanced User Experience**
   - OCR-based receipt scanning for automated expense entry
   - Enhanced AI capabilities: anomaly detection, personalized financial planning, saving recommendations
   - Advanced data visualizations with interactive charts and drill-down capabilities
   - Export financial reports functionality

5. **Platform Expansion**
   - Cross-platform web or desktop support
   - Robust push notification services for proactive user engagement
   - Integration with wearable devices (Apple Watch, Android Wear)

6. **Advanced AI Features**
   - Automated transaction categorization using NLP
   - Personalized financial planning recommendations
   - Anomaly detection for unusual spending patterns
   - Integration with external financial data sources

## UI/UX Requirements

### Design Principles
- **Clean & Minimalist**: Prioritize essential information, avoid clutter
- **Intuitive Navigation**: Logical grouping with clear visual hierarchy
- **Responsive Layout**: Adaptive design for various screen sizes
- **Accessibility**: Sufficient color contrast, legible fonts
- **Consistent Branding**: Unified color palette and typography

### Key UI Components
- **Bottom Navigation**: Primary module navigation (Home, Expenses, Groups, AI Insights, Settings)
- **Floating Action Buttons**: Primary actions (Add Expense, Create Group)
- **Cards/List Tiles**: Data display with glass-morphism styling
- **Charts & Graphs**: Financial data visualizations using fl_chart
- **Forms**: Streamlined input with proper validation

### Navigation Structure
```
Bottom Navigation (MainNavigationWrapper):
├── Dashboard (Home) - Expense summaries, quick actions, clickable avatar → profile
├── Transactions - Personal expense management  
├── Goals - Goal tracking and management
├── Groups - Group management and bill sharing
└── AI Insights - Spending analysis and predictions

Settings Access: AppSettingsMenu in app bars across all pages
├── Profile → Navigate to /profile
├── Theme Toggle → Dark/Light mode switch  
└── Logout → Secure logout with confirmation

Deep Navigation:
├── Groups > Group Detail (breadcrumb navigation)
└── Groups > Group Detail > Create Bill (full breadcrumb)
```

## Security Implementation

### Data Protection
- **Authentication Data**: JWT tokens stored in SharedPreferences with secure session management
- **Sensitive Operations**: Biometric authentication for app access via `local_auth` package
- **Network Security**: HTTPS-only API communication with Laravel backend
- **Data Privacy**: No sensitive data in logs or error reports
- **Local Storage**: User preferences and cached data in SharedPreferences
- **Environment Variables**: All sensitive configuration stored in `.env` file (excluded from version control)

### Authentication Security
- **JWT Storage**: Access tokens stored in SharedPreferences (not FlutterSecureStorage as mentioned elsewhere)
- **Biometric Authentication**: Face ID/Touch ID/Fingerprint support via `local_auth` package
- **Account Lockout**: Automatic lockout after failed login attempts via `LoginAttemptService`
- **Session Management**: Token-based authentication with Laravel backend
- **User Identification**: Email-based user ID system compatible with Laravel user model
- **Password Security**: Server-side hashing with Laravel's built-in security standards

### Environment Configuration Security
- **Centralized Configuration**: All sensitive data managed through `ApiConfig` class using environment variables
- **Git Exclusion**: `.env` files are properly excluded from version control via `.gitignore`
- **Template System**: `.env.example` provides secure template for environment setup
- **API Key Management**: OpenAI and backend API configurations secured in environment variables
- **No Hardcoded Secrets**: All URLs, API keys, and sensitive configuration externalized

## Important Development Notes

### Critical Architecture Decisions
- **Portrait-Only**: App orientation locked in `main.dart`
- **Centralized Routing**: All routes defined in `src/routes/app_router.dart`
- **Provider Pattern**: All providers must be added to `MultiProvider` in `main.dart`
- **Navigation Wrapper**: All main pages use `MainNavigationWrapper` (eliminates duplicate bottom nav code)
- **Theme System**: Fully implemented with `ThemeProvider` accessible via settings menu

### Backend Integration Status
- **Transactions & Auth**: ✅ Fully integrated with Laravel backend
- **Groups**: ✅ Fully integrated with Laravel backend (CRUD operations complete)
- **Bills**: ✅ Integrated with GroupService backend + local calculation logic
- **Goals**: ✅ Fully integrated with Laravel backend with transaction sync
- **AI Services**: ✅ OpenAI integration complete (requires API key configuration)
- **Notifications**: ✅ Full in-app notification system implemented

### User Data Handling
- **No User Model Class**: User data handled as `Map<String, dynamic>` throughout app
- **Email as User ID**: User's email address serves as unique identifier in `user_id` field
- **Storage Method**: All auth data stored in SharedPreferences (not FlutterSecureStorage)
- **Laravel Compatibility**: Backend user model contains only `name` and `email` fields

### Common Development Pitfalls
1. **Const Expressions**: Avoid `const` with runtime theme variables (isDark, colorScheme)
2. **Navigation**: Use `context.pop()` for back navigation, `context.go()` for direct navigation  
3. **FAB Types**: MainNavigationWrapper accepts `Widget?` for flexible FloatingActionButton support
4. **Settings Access**: Settings menu automatically added to all main page app bars
5. **User ID References**: Remember that `user_id` contains email address, not numeric ID
6. **Authentication Storage**: Use SharedPreferences, not FlutterSecureStorage for tokens
7. **AI Service Initialization**: Always check `_aiService != null` before calling AI methods
8. **Provider Dependencies**: NotificationProvider requires initialization in NotificationService
9. **Bill Calculations**: Use `BillCalculationService` for accurate debt/credit calculations
10. **Goal Sync**: Goals automatically sync with transactions via `GoalTransactionSyncService`

## Success Metrics

### Adoption Metrics
- New user signups and active user retention
- Feature adoption rates (expense logging, group creation, goal setting)
- Onboarding completion rates

### Engagement Metrics
- Daily/weekly active users
- AI insights interaction rates
- In-app notification response rates

### Financial Metrics
- Average transactions per user
- Groups created and bills processed
- Goal completion rates