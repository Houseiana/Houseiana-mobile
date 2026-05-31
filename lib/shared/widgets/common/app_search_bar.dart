import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/theme/app_icons.dart';
import 'package:houseiana_mobile_app/core/theme/app_radius.dart';
import 'package:houseiana_mobile_app/core/theme/app_shadows.dart';
import 'package:houseiana_mobile_app/core/theme/app_spacing.dart';

/// Enhanced search bar with modern design and animations
class AppSearchBar extends StatefulWidget {
  final String? hintText;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final VoidCallback? onFilterTap;
  final bool showFilterButton;
  final bool autofocus;
  final TextEditingController? controller;

  const AppSearchBar({
    super.key,
    this.hintText,
    this.initialValue,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.onFilterTap,
    this.showFilterButton = true,
    this.autofocus = false,
    this.controller,
  });

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isFocused = false;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: (_) {
          _animationController.forward();
          if (widget.onTap != null) {
            widget.onTap!();
          }
        },
        onTapUp: (_) => _animationController.reverse(),
        onTapCancel: () => _animationController.reverse(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppRadius.radiusXl,
            border: Border.all(
              color: _isFocused ? AppColors.primaryColor : AppColors.neutral200,
              width: _isFocused ? 2 : 1,
            ),
            boxShadow: _isFocused ? AppShadows.searchBarShadow : AppShadows.cardShadow,
          ),
          child: Row(
            children: [
              // Search icon
              Container(
                width: 48,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.neutral100,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(20),
                  ),
                ),
                child: const Icon(
                  AppIcons.search,
                  color: AppColors.charcoal,
                  size: 20,
                ),
              ),

              // Search input
              Expanded(
                child: Focus(
                  onFocusChange: (focused) {
                    setState(() => _isFocused = focused);
                  },
                  child: TextField(
                    controller: _controller,
                    autofocus: widget.autofocus,
                    onChanged: widget.onChanged,
                    onSubmitted: widget.onSubmitted,
                    onTap: widget.onTap,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.charcoal,
                    ),
                    decoration: InputDecoration(
                      hintText: widget.hintText ?? 'Search...',
                      hintStyle: const TextStyle(
                        color: AppColors.neutral400,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.lg,
                      ),
                    ),
                  ),
                ),
              ),

              // Filter button
              if (widget.showFilterButton) ...[
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    widget.onFilterTap?.call();
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      AppIcons.filter,
                      color: AppColors.charcoal,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Advanced search bar with date and guest selection
class AdvancedSearchBar extends StatelessWidget {
  final String? locationHint;
  final String? checkInHint;
  final String? checkOutHint;
  final String? guestHint;
  final VoidCallback? onLocationTap;
  final VoidCallback? onDateTap;
  final VoidCallback? onGuestTap;
  final VoidCallback? onSearchTap;

  const AdvancedSearchBar({
    super.key,
    this.locationHint,
    this.checkInHint,
    this.checkOutHint,
    this.guestHint,
    this.onLocationTap,
    this.onDateTap,
    this.onGuestTap,
    this.onSearchTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.searchBarRadius),
        boxShadow: AppShadows.searchBarShadow,
      ),
      child: Row(
        children: [
          // Location
          Expanded(
            flex: 3,
            child: _buildField(
              label: 'Where',
              value: locationHint ?? 'Search destinations',
              onTap: onLocationTap,
              showDivider: true,
            ),
          ),

          // Dates
          Expanded(
            flex: 4,
            child: _buildField(
              label: 'When',
              value: checkInHint ?? 'Add dates',
              onTap: onDateTap,
              showDivider: true,
            ),
          ),

          // Guests
          Expanded(
            flex: 3,
            child: _buildField(
              label: 'Who',
              value: guestHint ?? 'Add guests',
              onTap: onGuestTap,
              showDivider: false,
            ),
          ),

          // Search button
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              onSearchTap?.call();
            },
            child: Container(
              width: 48,
              height: 48,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                AppIcons.search,
                color: AppColors.charcoal,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required String value,
    VoidCallback? onTap,
    bool showDivider = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          border: showDivider
              ? const Border(
                  right: BorderSide(color: AppColors.neutral200, width: 1),
                )
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.charcoal,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: value.contains('Add')
                    ? AppColors.neutral400
                    : AppColors.charcoal,
                height: 1.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
