import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';

class ModernFlatNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const ModernFlatNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class ModernFlatNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<ModernFlatNavItem> items;

  const ModernFlatNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (index) {
            final isSelected = index == currentIndex;
            final item = items[index];

            return _NavBarItemWidget(
              item: item,
              isSelected: isSelected,
              onTap: () => onTap(index),
            );
          }),
        ),
      ),
    );
  }
}

class _NavBarItemWidget extends StatelessWidget {
  final ModernFlatNavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItemWidget({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? item.activeIcon : item.icon,
              size: 22,
              color: isSelected ? AppColors.primary : AppColors.textMuted,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                item.label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

