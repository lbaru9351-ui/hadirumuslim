import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';

enum BadgeType {
  success,
  warning,
  error,
  info,
}

class StatusBadge extends StatelessWidget {
  final String label;
  final BadgeType type;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    this.type = BadgeType.info,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    Color textColor;
    Color bgColor;

    switch (type) {
      case BadgeType.success:
        textColor = AppColors.success;
        bgColor = AppColors.successBg;
        break;
      case BadgeType.warning:
        textColor = AppColors.warning;
        bgColor = AppColors.warningBg;
        break;
      case BadgeType.error:
        textColor = AppColors.error;
        bgColor = AppColors.errorBg;
        break;
      case BadgeType.info:
        textColor = AppColors.info;
        bgColor = AppColors.infoBg;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: AppDimensions.spaceXS),
          ],
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

