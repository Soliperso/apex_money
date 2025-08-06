import 'package:flutter/material.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_theme.dart';

class InsightFeedbackWidget extends StatefulWidget {
  final Function(bool isHelpful) onFeedback;
  final bool compact;

  const InsightFeedbackWidget({
    Key? key,
    required this.onFeedback,
    this.compact = false,
  }) : super(key: key);

  @override
  State<InsightFeedbackWidget> createState() => _InsightFeedbackWidgetState();
}

class _InsightFeedbackWidgetState extends State<InsightFeedbackWidget>
    with SingleTickerProviderStateMixin {
  bool? _feedback;
  bool _submitted = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleFeedback(bool isHelpful) {
    setState(() {
      _feedback = isHelpful;
      _submitted = true;
    });

    // Trigger animation
    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    // Call the callback
    widget.onFeedback(isHelpful);

    // Auto-hide after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _submitted = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_submitted) {
      return AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding:
                  widget.compact
                      ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
                      : const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.successColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: widget.compact ? 14 : 16,
                    color: AppTheme.successColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Thanks!',
                    style: TextStyle(
                      fontSize: widget.compact ? 11 : 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.successColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    return Container(
      padding:
          widget.compact
              ? const EdgeInsets.symmetric(horizontal: 4, vertical: 2)
              : const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!widget.compact) ...[
            Text(
              'Helpful?',
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 6),
          ],

          // Thumbs up button
          InkWell(
            onTap: () => _handleFeedback(true),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.thumb_up_outlined,
                size: widget.compact ? 14 : 16,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),

          const SizedBox(width: 2),

          // Thumbs down button
          InkWell(
            onTap: () => _handleFeedback(false),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.thumb_down_outlined,
                size: widget.compact ? 14 : 16,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
