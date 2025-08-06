import 'package:flutter/material.dart';
import '../../../../shared/theme/app_theme.dart';

class SeverityIndicator extends StatelessWidget {
  final String severity;
  final String type;
  final bool compact;

  const SeverityIndicator({
    Key? key,
    required this.severity,
    required this.type,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = _getSeverityColor();
    final icon = _getSeverityIcon();
    final label = _getSeverityLabel();

    if (compact) {
      return Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor() {
    switch (severity.toLowerCase()) {
      case 'high':
        return AppTheme.errorColor;
      case 'medium':
        return AppTheme.warningColor;
      case 'low':
      default:
        return AppTheme.infoColor;
    }
  }

  IconData _getSeverityIcon() {
    switch (severity.toLowerCase()) {
      case 'high':
        return Icons.warning;
      case 'medium':
        return Icons.info;
      case 'low':
      default:
        return Icons.lightbulb;
    }
  }

  String _getSeverityLabel() {
    switch (severity.toLowerCase()) {
      case 'high':
        return 'HIGH';
      case 'medium':
        return 'MED';
      case 'low':
      default:
        return 'LOW';
    }
  }
}
