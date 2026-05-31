import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/theme/app_icons.dart';
import 'package:houseiana_mobile_app/core/theme/app_spacing.dart';

/// Enhanced bottom navigation with frosted glass effect
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<AppBottomNavItem>? items;
  final bool showBadge;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.items,
    this.showBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    final navItems = items ?? _defaultItems;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 80,
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              border: const Border(
                top: BorderSide(color: AppColors.neutral200, width: 0.5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(navItems.length, (index) {
                final item = navItems[index];
                final isSelected = currentIndex == index;
                return _BottomNavItemWidget(
                  icon: isSelected ? item.activeIcon : item.icon,
                  label: item.label,
                  isSelected: isSelected,
                  badge: showBadge ? item.badge : null,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onTap(index);
                  },
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  static List<AppBottomNavItem> get _defaultItems => [
        AppBottomNavItem(
          icon: AppIcons.home,
          activeIcon: AppIcons.homeFilled,
          label: 'Explore',
        ),
        AppBottomNavItem(
          icon: AppIcons.search,
          activeIcon: AppIcons.search,
          label: 'Search',
        ),
        AppBottomNavItem(
          icon: AppIcons.favorites,
          activeIcon: AppIcons.favoritesFilled,
          label: 'Favorites',
        ),
        AppBottomNavItem(
          icon: AppIcons.trips,
          activeIcon: AppIcons.tripsFilled,
          label: 'Trips',
        ),
        AppBottomNavItem(
          icon: AppIcons.messages,
          activeIcon: AppIcons.messagesFilled,
          label: 'Messages',
          badge: 0,
        ),
        AppBottomNavItem(
          icon: AppIcons.profile,
          activeIcon: AppIcons.profileFilled,
          label: 'Profile',
        ),
      ];
}

/// Bottom navigation item data class
class AppBottomNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int? badge;

  const AppBottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badge,
  });
}

/// Bottom navigation item widget with animation
class _BottomNavItemWidget extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final int? badge;
  final VoidCallback onTap;

  const _BottomNavItemWidget({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon with badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    icon,
                    size: 24,
                    color: isSelected
                        ? AppColors.charcoal
                        : AppColors.neutral400,
                  ),
                ),
                // Badge
                if (badge != null && badge! > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        badge! > 99 ? '99+' : badge.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            // Label
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? AppColors.charcoal
                    : AppColors.neutral400,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
