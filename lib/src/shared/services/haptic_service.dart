import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class HapticService {
  static final HapticService _instance = HapticService._internal();

  factory HapticService() => _instance;

  HapticService._internal();

  bool _isEnabled = true;

  /// Enable or disable haptic feedback
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  /// Check if haptic feedback is enabled
  bool get isEnabled => _isEnabled;

  /// Light haptic feedback - for subtle interactions
  /// Use for: UI element selection, button press, toggle switches
  void light() {
    if (_isEnabled && !kIsWeb) {
      HapticFeedback.lightImpact();
    }
  }

  /// Medium haptic feedback - for standard interactions
  /// Use for: form submissions, navigation, confirmations
  void medium() {
    if (_isEnabled && !kIsWeb) {
      HapticFeedback.mediumImpact();
    }
  }

  /// Heavy haptic feedback - for important interactions
  /// Use for: critical actions, errors, major state changes
  void heavy() {
    if (_isEnabled && !kIsWeb) {
      HapticFeedback.heavyImpact();
    }
  }

  /// Success haptic feedback - for successful actions
  /// Use for: successful transactions, goal completions, saves
  void success() {
    if (_isEnabled && !kIsWeb) {
      HapticFeedback.lightImpact();
      Future.delayed(const Duration(milliseconds: 100), () {
        HapticFeedback.lightImpact();
      });
    }
  }

  /// Error haptic feedback - for errors and failures
  /// Use for: validation errors, failed operations, warnings
  void error() {
    if (_isEnabled && !kIsWeb) {
      HapticFeedback.heavyImpact();
      Future.delayed(const Duration(milliseconds: 100), () {
        HapticFeedback.lightImpact();
      });
    }
  }

  /// Selection haptic feedback - for UI selection
  /// Use for: selecting items, changing tabs, menu navigation
  void selection() {
    if (_isEnabled && !kIsWeb) {
      HapticFeedback.selectionClick();
    }
  }

  /// Vibration haptic feedback - for notifications
  /// Use for: notifications, alerts, reminders
  void vibrate() {
    if (_isEnabled && !kIsWeb) {
      HapticFeedback.vibrate();
    }
  }

  /// Custom haptic sequence for specific actions
  void customSequence(List<HapticType> sequence) {
    if (!_isEnabled || kIsWeb) return;

    for (int i = 0; i < sequence.length; i++) {
      Future.delayed(Duration(milliseconds: i * 100), () {
        switch (sequence[i]) {
          case HapticType.light:
            HapticFeedback.lightImpact();
            break;
          case HapticType.medium:
            HapticFeedback.mediumImpact();
            break;
          case HapticType.heavy:
            HapticFeedback.heavyImpact();
            break;
          case HapticType.selection:
            HapticFeedback.selectionClick();
            break;
        }
      });
    }
  }

  // Specific use case methods for common app actions

  /// Haptic feedback for button press
  void buttonPress() => light();

  /// Haptic feedback for form submission
  void formSubmit() => medium();

  /// Haptic feedback for transaction creation
  void transactionCreate() => success();

  /// Haptic feedback for transaction deletion
  void transactionDelete() => heavy();

  /// Haptic feedback for goal completion
  void goalComplete() =>
      customSequence([HapticType.light, HapticType.medium, HapticType.light]);

  /// Haptic feedback for navigation
  void navigate() => selection();

  /// Haptic feedback for tab change
  void tabChange() => selection();

  /// Haptic feedback for toggle switch
  void toggle() => light();

  /// Haptic feedback for pull to refresh
  void pullToRefresh() => medium();

  /// Haptic feedback for swipe actions
  void swipeAction() => light();

  /// Haptic feedback for long press
  void longPress() => medium();

  /// Haptic feedback for drag start
  void dragStart() => light();

  /// Haptic feedback for drag end
  void dragEnd() => medium();

  /// Haptic feedback for validation error
  void validationError() => error();

  /// Haptic feedback for network error
  void networkError() => error();

  /// Haptic feedback for successful save
  void saveSuccess() => success();

  /// Haptic feedback for successful login
  void loginSuccess() => success();

  /// Haptic feedback for logout
  void logout() => light();

  /// Haptic feedback for biometric authentication
  void biometricAuth() => light();

  /// Haptic feedback for notification received
  void notificationReceived() => vibrate();

  /// Haptic feedback for bill payment
  void billPayment() => success();

  /// Haptic feedback for group creation
  void groupCreate() => medium();

  /// Haptic feedback for invitation sent
  void invitationSent() => light();

  /// Haptic feedback for invitation accepted
  void invitationAccepted() => success();
}

enum HapticType { light, medium, heavy, selection }

// Extension to make it easier to use
extension HapticFeedbackExtension on Widget {
  Widget withHaptic(VoidCallback? onTap, {HapticType type = HapticType.light}) {
    return GestureDetector(
      onTap:
          onTap == null
              ? null
              : () {
                switch (type) {
                  case HapticType.light:
                    HapticService().light();
                    break;
                  case HapticType.medium:
                    HapticService().medium();
                    break;
                  case HapticType.heavy:
                    HapticService().heavy();
                    break;
                  case HapticType.selection:
                    HapticService().selection();
                    break;
                }
                onTap();
              },
      child: this,
    );
  }
}
