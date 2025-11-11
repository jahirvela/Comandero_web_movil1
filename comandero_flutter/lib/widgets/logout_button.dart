import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

class LogoutButton extends StatelessWidget {
  final Future<void> Function()? onPressed;
  final bool isTablet;
  final String label;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const LogoutButton({
    super.key,
    required this.onPressed,
    required this.isTablet,
    this.label = 'Salir',
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed == null
          ? null
          : () async {
              await onPressed!.call();
            },
      icon: Icon(Icons.logout, size: isTablet ? 20.0 : 18.0),
      label: Text(
        label,
        style: TextStyle(
          fontSize: isTablet ? 14.0 : 12.0,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? AppColors.error,
        foregroundColor: foregroundColor ?? Colors.white,
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 16.0 : 12.0,
          vertical: isTablet ? 10.0 : 8.0,
        ),
        elevation: 0,
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
