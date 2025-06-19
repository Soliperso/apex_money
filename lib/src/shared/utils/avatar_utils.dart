import 'package:flutter/material.dart';

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
  /// Generate gradient colors based on the user's name
  static List<Color> getGradientColors(String name) {
    final gradients = [
      [const Color(0xFF64B5F6), const Color(0xFF42A5F5)], // Light Blue to Medium Blue
      [const Color(0xFF81D4FA), const Color(0xFF29B6F6)], // Very Light Blue to Sky Blue
      [const Color(0xFF80DEEA), const Color(0xFF26C6DA)], // Light Cyan to Cyan
      [const Color(0xFFB39DDB), const Color(0xFF9575CD)], // Light Purple to Purple
      [const Color(0xFFA5D6A7), const Color(0xFF81C784)], // Light Green to Medium Green
      [const Color(0xFF90CAF9), const Color(0xFF64B5F6)], // Very Light Blue to Light Blue
      [const Color(0xFFB0BEC5), const Color(0xFF90A4AE)], // Light Blue Grey to Blue Grey
      [const Color(0xFF84FFFF), const Color(0xFF18FFFF)], // Light Cyan to Bright Cyan
      [const Color(0xFFCE93D8), const Color(0xFFBA68C8)], // Light Pink to Pink
      [const Color(0xFFC8E6C9), const Color(0xFFA5D6A7)], // Very Light Green to Light Green
    ];

    if (name.isEmpty) return gradients[0];
    int gradientIndex = name.trim().codeUnitAt(0) % gradients.length;
    return gradients[gradientIndex];
  }

  /// Generate a consistent theme-based color based on the user's name
  static Color getAvatarColor(String name, [Color? themeColor]) {
    // Use theme color as base if provided, otherwise use default theme colors
    final colors = [
      themeColor?.withValues(alpha: 0.8) ?? const Color(0xFF1976D2), // Primary Blue
      themeColor?.withValues(alpha: 0.7) ?? const Color(0xFF388E3C), // Success Green
      themeColor?.withValues(alpha: 0.9) ?? const Color(0xFFF57C00), // Warning Orange
      themeColor?.withValues(alpha: 0.75) ?? const Color(0xFF7B1FA2), // Purple
      themeColor?.withValues(alpha: 0.85) ?? const Color(0xFF303F9F), // Indigo
      themeColor?.withValues(alpha: 0.8) ?? const Color(0xFF0097A7), // Cyan
      themeColor?.withValues(alpha: 0.9) ?? const Color(0xFF5D4037), // Brown
      themeColor?.withValues(alpha: 0.7) ?? const Color(0xFF616161), // Grey
      themeColor?.withValues(alpha: 0.8) ?? const Color(0xFFE64A19), // Deep Orange
      themeColor?.withValues(alpha: 0.85) ?? const Color(0xFF1976D2), // Blue
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
            child: _buildStatusIndicator(status, radius),
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
          color: borderColor ?? Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
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
    required String userName,
    String? profilePicture,
    required double radius,
    required double fontSize,
    required AvatarStyle style,
  }) {
    switch (style) {
      case AvatarStyle.gradient:
        return _buildGradientAvatar(userName, profilePicture, radius, fontSize);
      case AvatarStyle.premium:
        return _buildPremiumAvatar(userName, profilePicture, radius, fontSize);
      case AvatarStyle.minimal:
        return _buildMinimalAvatar(userName, profilePicture, radius, fontSize);
      case AvatarStyle.standard:
        return _buildStandardAvatar(userName, profilePicture, radius, fontSize);
    }
  }

  /// Standard avatar with shadow
  static Widget _buildStandardAvatar(String userName, String? profilePicture, double radius, double fontSize) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: getAvatarColor(userName).withValues(alpha: 0.3),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundImage: profilePicture != null ? NetworkImage(profilePicture) : null,
        backgroundColor: profilePicture == null ? getAvatarColor(userName) : Colors.transparent,
        child: profilePicture == null
            ? Text(
                getInitials(userName),
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              )
            : null,
      ),
    );
  }

  /// Gradient avatar with modern styling
  static Widget _buildGradientAvatar(String userName, String? profilePicture, double radius, double fontSize) {
    final gradientColors = getGradientColors(userName);
    
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
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              )
            : null,
      ),
    );
  }

  /// Premium avatar with premium effects
  static Widget _buildPremiumAvatar(String userName, String? profilePicture, double radius, double fontSize) {
    final gradientColors = getGradientColors(userName);
    
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
            color: Colors.white.withValues(alpha: 0.1),
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
              Colors.white.withValues(alpha: 0.2),
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
                    color: Colors.white,
                    letterSpacing: 1.0,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.3),
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
  static Widget _buildMinimalAvatar(String userName, String? profilePicture, double radius, double fontSize) {
    return CircleAvatar(
      radius: radius,
      backgroundImage: profilePicture != null ? NetworkImage(profilePicture) : null,
      backgroundColor: profilePicture == null ? getAvatarColor(userName).withValues(alpha: 0.1) : Colors.transparent,
      child: profilePicture == null
          ? Text(
              getInitials(userName),
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: getAvatarColor(userName),
                letterSpacing: 0.5,
              ),
            )
          : null,
    );
  }

  /// Build status indicator
  static Widget _buildStatusIndicator(StatusIndicator status, double avatarRadius) {
    Color indicatorColor;
    IconData? icon;
    double size = avatarRadius * 0.3;

    switch (status) {
      case StatusIndicator.online:
        indicatorColor = const Color(0xFF10B981);
        break;
      case StatusIndicator.offline:
        indicatorColor = const Color(0xFF6B7280);
        break;
      case StatusIndicator.verified:
        indicatorColor = const Color(0xFF3B82F6);
        icon = Icons.verified;
        size = avatarRadius * 0.4;
        break;
      case StatusIndicator.premium:
        indicatorColor = const Color(0xFFF59E0B);
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
          color: Colors.white,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: icon != null
          ? Icon(
              icon,
              size: size * 0.6,
              color: Colors.white,
            )
          : null,
    );
  }

  /// Legacy method for backward compatibility
  static Widget buildLegacyAvatar({
    required String userName,
    String? profilePicture,
    double radius = 20.0,
    double fontSize = 14.0,
  }) {
    return buildAvatar(
      userName: userName,
      profilePicture: profilePicture,
      radius: radius,
      fontSize: fontSize,
      style: AvatarStyle.standard,
    );
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
