import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/theme/app_radius.dart';
import 'package:houseiana_mobile_app/core/theme/app_shadows.dart';
import 'package:houseiana_mobile_app/core/theme/app_spacing.dart';

/// Primary button with modern design
class PrimaryButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool fullWidth;
  final double height;
  final Color? backgroundColor;
  final Color? textColor;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.fullWidth = true,
    this.height = 50,
    this.backgroundColor,
    this.textColor,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null && !widget.isLoading;
    final bgColor = widget.backgroundColor ?? AppColors.primaryColor;
    final txtColor = widget.textColor ?? AppColors.charcoal;

    return GestureDetector(
      onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: isEnabled ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: isEnabled ? () => setState(() => _isPressed = false) : null,
      onTap: isEnabled
          ? () {
              HapticFeedback.mediumImpact();
              widget.onPressed?.call();
            }
          : null,
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: widget.fullWidth ? double.infinity : null,
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.isLoading
                ? bgColor.withValues(alpha: 0.7)
                : bgColor,
            borderRadius: AppRadius.buttonRadiusAll,
            boxShadow: isEnabled && !_isPressed
                ? [
                    BoxShadow(
                      color: bgColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: widget.isLoading
                ? SpinKitThreeBounce(
                    color: txtColor,
                    size: 20,
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(
                          widget.icon,
                          size: 20,
                          color: txtColor,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      Text(
                        widget.text,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: txtColor,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Secondary outline button
class SecondaryButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool fullWidth;
  final double height;
  final Color? borderColor;
  final Color? textColor;

  const SecondaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.fullWidth = true,
    this.height = 50,
    this.borderColor,
    this.textColor,
  });

  @override
  State<SecondaryButton> createState() => _SecondaryButtonState();
}

class _SecondaryButtonState extends State<SecondaryButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null && !widget.isLoading;
    final borderClr = widget.borderColor ?? AppColors.neutral200;
    final txtColor = widget.textColor ?? AppColors.charcoal;

    return GestureDetector(
      onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: isEnabled ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: isEnabled ? () => setState(() => _isPressed = false) : null,
      onTap: isEnabled
          ? () {
              HapticFeedback.lightImpact();
              widget.onPressed?.call();
            }
          : null,
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: widget.fullWidth ? double.infinity : null,
          height: widget.height,
          decoration: BoxDecoration(
            color: _isPressed ? AppColors.neutral100 : Colors.white,
            borderRadius: AppRadius.buttonRadiusAll,
            border: Border.all(color: borderClr, width: 1.5),
          ),
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(txtColor),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, size: 20, color: txtColor),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      Text(
                        widget.text,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: txtColor,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Icon button with modern design
class AppIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;
  final bool showShadow;

  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.backgroundColor,
    this.iconColor,
    this.size = 44,
    this.showShadow = true,
  });

  @override
  State<AppIconButton> createState() => _AppIconButtonState();
}

class _AppIconButtonState extends State<AppIconButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null;
    final bgColor = widget.backgroundColor ?? AppColors.cardBackground;
    final icColor = widget.iconColor ?? AppColors.charcoal;

    Widget button = GestureDetector(
      onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: isEnabled ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: isEnabled ? () => setState(() => _isPressed = false) : null,
      onTap: isEnabled
          ? () {
              HapticFeedback.lightImpact();
              widget.onPressed?.call();
            }
          : null,
      child: AnimatedScale(
        scale: _isPressed ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: widget.showShadow && !_isPressed
                ? AppShadows.iconButtonShadow
                : null,
          ),
          child: Icon(
            widget.icon,
            size: widget.size * 0.45,
            color: icColor,
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(
        message: widget.tooltip!,
        child: button,
      );
    }

    return button;
  }
}

/// Circle button for actions
class CircleButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;
  final String? tooltip;

  const CircleButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.size = 40,
    this.tooltip,
  });

  @override
  State<CircleButton> createState() => _CircleButtonState();
}

class _CircleButtonState extends State<CircleButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null;
    final bgColor = widget.backgroundColor ?? Colors.white.withValues(alpha: 0.9);
    final icColor = widget.iconColor ?? AppColors.charcoal;

    Widget button = GestureDetector(
      onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: isEnabled ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: isEnabled ? () => setState(() => _isPressed = false) : null,
      onTap: isEnabled
          ? () {
              HapticFeedback.lightImpact();
              widget.onPressed?.call();
            }
          : null,
      child: AnimatedScale(
        scale: _isPressed ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
          ),
          child: Icon(
            widget.icon,
            size: widget.size * 0.5,
            color: icColor,
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(
        message: widget.tooltip!,
        child: button,
      );
    }

    return button;
  }
}

/// Category filter chip
class FilterChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final IconData? icon;

  const FilterChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.icon,
  });

  @override
  State<FilterChip> createState() => _FilterChipState();
}

class _FilterChipState extends State<FilterChip> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap?.call();
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppColors.charcoal
                : AppColors.cardBackground,
            borderRadius: AppRadius.chipRadiusAll,
            border: Border.all(
              color: widget.isSelected
                  ? AppColors.charcoal
                  : AppColors.neutral200,
              width: 1.5,
            ),
            boxShadow: widget.isSelected ? AppShadows.chipShadow : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: 16,
                  color: widget.isSelected
                      ? AppColors.textLight
                      : AppColors.neutral600,
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: widget.isSelected
                      ? AppColors.textLight
                      : AppColors.neutral600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
