import 'package:flutter/material.dart';
import '../utils/theme_data.dart';

/// Circular Icon Button Widget
/// Follows the design system: CircleAvatar + Icon style
class CircularIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double radius;
  final Color? backgroundColor;
  final Color? iconColor;
  final String? tooltip;

  const CircularIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.radius = 30,
    this.backgroundColor,
    this.iconColor,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final button = CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? AppTheme.secondaryMint,
      child: IconButton(
        icon: Icon(
          icon,
          color: iconColor ?? AppTheme.primaryGreen,
          size: radius * 0.7,
        ),
        onPressed: onPressed,
      ),
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip!,
        child: button,
      );
    }

    return button;
  }
}

