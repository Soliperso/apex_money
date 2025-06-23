import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A comprehensive avatar utility class that provides theme-aware avatar components
/// for the Apex Money application.
/// 
/// This utility supports multiple avatar styles, status indicators, and ensures
/// proper theming for both light and dark modes. All colors are derived from
/// the app's ColorScheme to maintain consistency across the application.
/// 
/// Features:
/// - Theme-aware color schemes for light and dark modes
/// - Multiple avatar styles (standard, gradient, premium, minimal)
/// - Status indicators (online, offline, verified, premium)
/// - Automatic gradient generation based on user names
/// - Full Material Design 3 compliance
/// - Animation support
/// 
/// Usage:
/// ```dart
/// AvatarUtils.buildAvatar(
///   context: context,
///   userName: 'John Doe',
///   style: AvatarStyle.premium,
///   status: StatusIndicator.verified,
/// )
/// ```

enum AvatarStyle {
  standard,
  gradient,
  premium,
  minimal,
}

enum StatusIndicator {
  none,
  online,
  offline,
  verified,
  premium,
}

class AvatarUtils {
  /// Generate gradient colors based on the user's name and theme
  static List<Color> getGradientColors(String name, BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    // Create theme-aware gradients that work well in both light and dark modes
    final gradients = [
      [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.7)], // Primary gradient
      [colorScheme.secondary, colorScheme.secondary.withValues(alpha: 0.8)], // Secondary gradient
      [colorScheme.tertiary, colorScheme.tertiary.withValues(alpha: 0.7)], // Tertiary gradient
      [colorScheme.success, colorScheme.success.withValues(alpha: 0.8)], // Success gradient
      [colorScheme.warning, colorScheme.warning.withValues(alpha: 0.8)], // Warning gradient
      [colorScheme.info, colorScheme.info.withValues(alpha: 0.8)], // Info gradient
      [colorScheme.primaryContainer, colorScheme.primary], // Primary container gradient
      [colorScheme.secondaryContainer, colorScheme.secondary], // Secondary container gradient
      [isDark ? const Color(0xFF64B5F6) : const Color(0xFF1976D2), isDark ? const Color(0xFF42A5F5) : const Color(0xFF1565C0)], // Blue gradient
      [isDark ? const Color(0xFF81C784) : const Color(0xFF388E3C), isDark ? const Color(0xFF66BB6A) : const Color(0xFF2E7D32)], // Green gradient
    ];

    if (name.isEmpty) return gradients[0];
    int gradientIndex = name.trim().codeUnitAt(0) % gradients.length;
    return gradients[gradientIndex];
  }

  /// Generate a consistent theme-based color based on the user's name
  static Color getAvatarColor(String name, BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Use theme colors for consistency
    final colors = [
      colorScheme.primary,
      colorScheme.secondary,
      colorScheme.tertiary,
      colorScheme.success,
      colorScheme.warning,
      colorScheme.info,
      colorScheme.primaryContainer,
      colorScheme.secondaryContainer,
      colorScheme.onSurfaceVariant,
      colorScheme.outline,
    ];

    if (name.isEmpty) return colors[0];
    int colorIndex = name.trim().codeUnitAt(0) % colors.length;
    return colors[colorIndex];
  }

  /// Get initials from user's name (supports first name + last name)
  static String getInitials(String name) {
    if (name.isEmpty) return 'U';

    List<String> nameParts = name.trim().split(' ');
    if (nameParts.length == 1) {
      return nameParts[0].substring(0, 1).toUpperCase();
    } else {
      String firstInitial = nameParts[0].isNotEmpty 
          ? nameParts[0].substring(0, 1).toUpperCase() 
          : '';
      String lastInitial = nameParts.last.isNotEmpty 
          ? nameParts.last.substring(0, 1).toUpperCase() 
          : '';
      return '$firstInitial$lastInitial';
    }
  }

  /// Get the initial letter from user's name for the avatar (legacy method)
  static String getInitial(String name) {
    if (name.isEmpty) return 'U';
    String firstName = name.trim().split(' ').first;
    if (firstName.isEmpty) return 'U';
    return firstName.substring(0, 1).toUpperCase();
  }

  /// Build an enhanced avatar with multiple style options
  static Widget buildAvatar({
    required BuildContext context,
    required String userName,
    String? profilePicture,
    double radius = 20.0,
    double fontSize = 14.0,
    AvatarStyle style = AvatarStyle.standard,
    StatusIndicator status = StatusIndicator.none,
    bool showBorder = false,
    Color? borderColor,
    double borderWidth = 2.0,
    bool enableAnimation = false,
    VoidCallback? onTap,
  }) {
    Widget avatar = _buildAvatarContent(
      context: context,
      userName: userName,
      profilePicture: profilePicture,
      radius: radius,
      fontSize: fontSize,
      style: style,
    );

    // Add status indicator if needed
    if (status != StatusIndicator.none) {
      avatar = Stack(
        children: [
          avatar,
          Positioned(
            bottom: 0,
            right: 0,
            child: _buildStatusIndicator(status, radius, context),
          ),
        ],
      );
    }

    // Add border if requested
    if (showBorder) {
      avatar = Container(
        padding: EdgeInsets.all(borderWidth),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: borderColor ?? Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
              blurRadius: 8,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: avatar,
      );
    }

    // Add animation wrapper if enabled
    if (enableAnimation) {
      avatar = _AnimatedAvatarWrapper(child: avatar);
    }

    // Add tap functionality if provided
    if (onTap != null) {
      avatar = GestureDetector(
        onTap: onTap,
        child: avatar,
      );
    }

    return avatar;
  }

  /// Build the core avatar content based on style
  static Widget _buildAvatarContent({
    required BuildContext context,
    required String userName,
    String? profilePicture,
    required double radius,
    required double fontSize,
    required AvatarStyle style,
  }) {
    switch (style) {
      case AvatarStyle.gradient:
        return _buildGradientAvatar(context, userName, profilePicture, radius, fontSize);
      case AvatarStyle.premium:
        return _buildPremiumAvatar(context, userName, profilePicture, radius, fontSize);
      case AvatarStyle.minimal:
        return _buildMinimalAvatar(context, userName, profilePicture, radius, fontSize);
      case AvatarStyle.standard:
        return _buildStandardAvatar(context, userName, profilePicture, radius, fontSize);
    }
  }

  /// Standard avatar with shadow
  static Widget _buildStandardAvatar(BuildContext context, String userName, String? profilePicture, double radius, double fontSize) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: getAvatarColor(userName, context).withValues(alpha: 0.3),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundImage: profilePicture != null ? NetworkImage(profilePicture) : null,
        backgroundColor: profilePicture == null ? getAvatarColor(userName, context) : Colors.transparent,
        child: profilePicture == null
            ? Text(
                getInitials(userName),
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimary,
                  letterSpacing: 0.5,
                ),
              )
            : null,
      ),
    );
  }

  /// Gradient avatar with modern styling
  static Widget _buildGradientAvatar(BuildContext context, String userName, String? profilePicture, double radius, double fontSize) {
    final gradientColors = getGradientColors(userName, context);
    
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withValues(alpha: 0.4),
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: gradientColors[1].withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: -2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundImage: profilePicture != null ? NetworkImage(profilePicture) : null,
        backgroundColor: Colors.transparent,
        child: profilePicture == null
            ? Text(
                getInitials(userName),
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimary,
                  letterSpacing: 0.5,
                ),
              )
            : null,
      ),
    );
  }

  /// Premium avatar with premium effects
  static Widget _buildPremiumAvatar(BuildContext context, String userName, String? profilePicture, double radius, double fontSize) {
    final gradientColors = getGradientColors(userName, context);
    
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withValues(alpha: 0.5),
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: gradientColors[1].withValues(alpha: 0.3),
            blurRadius: 32,
            spreadRadius: -4,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.1),
            blurRadius: 1,
            spreadRadius: 1,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.surface.withValues(alpha: 0.2),
              Colors.transparent,
            ],
          ),
        ),
        child: CircleAvatar(
          radius: radius - 2,
          backgroundImage: profilePicture != null ? NetworkImage(profilePicture) : null,
          backgroundColor: Colors.transparent,
          child: profilePicture == null
              ? Text(
                  getInitials(userName),
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onPrimary,
                    letterSpacing: 1.0,
                    shadows: [
                      Shadow(
                        color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.3),
                        offset: const Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                )
              : null,
        ),
      ),
    );
  }

  /// Minimal avatar with clean styling
  static Widget _buildMinimalAvatar(BuildContext context, String userName, String? profilePicture, double radius, double fontSize) {
    return CircleAvatar(
      radius: radius,
      backgroundImage: profilePicture != null ? NetworkImage(profilePicture) : null,
      backgroundColor: profilePicture == null ? getAvatarColor(userName, context).withValues(alpha: 0.1) : Colors.transparent,
      child: profilePicture == null
          ? Text(
              getInitials(userName),
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: getAvatarColor(userName, context),
                letterSpacing: 0.5,
              ),
            )
          : null,
    );
  }

  /// Build status indicator
  static Widget _buildStatusIndicator(StatusIndicator status, double avatarRadius, BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    Color indicatorColor;
    IconData? icon;
    double size = avatarRadius * 0.3;

    switch (status) {
      case StatusIndicator.online:
        indicatorColor = colorScheme.success;
        break;
      case StatusIndicator.offline:
        indicatorColor = colorScheme.onSurfaceVariant;
        break;
      case StatusIndicator.verified:
        indicatorColor = colorScheme.primary;
        icon = Icons.verified;
        size = avatarRadius * 0.4;
        break;
      case StatusIndicator.premium:
        indicatorColor = colorScheme.warning;
        icon = Icons.star;
        size = avatarRadius * 0.4;
        break;
      case StatusIndicator.none:
        indicatorColor = Colors.transparent;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: indicatorColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: colorScheme.surface,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: icon != null
          ? Icon(
              icon,
              size: size * 0.6,
              color: colorScheme.onPrimary,
            )
          : null,
    );
  }

  /// Legacy method for backward compatibility
  static Widget buildLegacyAvatar({
    required BuildContext context,
    required String userName,
    String? profilePicture,
    double radius = 20.0,
    double fontSize = 14.0,
  }) {
    return buildAvatar(
      context: context,
      userName: userName,
      profilePicture: profilePicture,
      radius: radius,
      fontSize: fontSize,
      style: AvatarStyle.standard,
    );
  }

  /// Quick method to build a small avatar for app bars
  static Widget buildAppBarAvatar({
    required BuildContext context,
    required String userName,
    String? profilePicture,
    VoidCallback? onTap,
  }) {
    return buildAvatar(
      context: context,
      userName: userName,
      profilePicture: profilePicture,
      radius: 16,
      fontSize: 12,
      style: AvatarStyle.standard,
      onTap: onTap,
    );
  }

  /// Quick method to build a large profile avatar
  static Widget buildProfileAvatar({
    required BuildContext context,
    required String userName,
    String? profilePicture,
    bool isPremium = false,
    bool isVerified = false,
    VoidCallback? onTap,
  }) {
    return buildAvatar(
      context: context,
      userName: userName,
      profilePicture: profilePicture,
      radius: 60,
      fontSize: 36,
      style: isPremium ? AvatarStyle.premium : AvatarStyle.gradient,
      status: isVerified ? StatusIndicator.verified : StatusIndicator.none,
      showBorder: true,
      enableAnimation: true,
      onTap: onTap,
    );
  }

  /// Quick method to build a list item avatar
  static Widget buildListAvatar({
    required BuildContext context,
    required String userName,
    String? profilePicture,
    bool isOnline = false,
  }) {
    return buildAvatar(
      context: context,
      userName: userName,
      profilePicture: profilePicture,
      radius: 24,
      fontSize: 16,
      style: AvatarStyle.standard,
      status: isOnline ? StatusIndicator.online : StatusIndicator.none,
    );
  }

  /// Get a preview of how an avatar will look with different styles
  static List<Widget> buildStylePreview({
    required BuildContext context,
    required String userName,
    String? profilePicture,
    double radius = 32,
  }) {
    return AvatarStyle.values.map((style) => 
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            buildAvatar(
              context: context,
              userName: userName,
              profilePicture: profilePicture,
              radius: radius,
              style: style,
            ),
            const SizedBox(height: 4),
            Text(
              style.name,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    ).toList();
  }
}

/// Animated wrapper for avatar with hover and tap effects
class _AnimatedAvatarWrapper extends StatefulWidget {
  final Widget child;

  const _AnimatedAvatarWrapper({required this.child});

  @override
  State<_AnimatedAvatarWrapper> createState() => _AnimatedAvatarWrapperState();
}

class _AnimatedAvatarWrapperState extends State<_AnimatedAvatarWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}
