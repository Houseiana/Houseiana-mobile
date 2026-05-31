import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';

/// Modern button with various styles and animations
class ModernButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final ModernButtonStyle style;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double height;

  const ModernButton({
    super.key,
    required this.text,
    this.onPressed,
    this.style = ModernButtonStyle.primary,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 50,
  });

  @override
  State<ModernButton> createState() => _ModernButtonState();
}

enum ModernButtonStyle {
  primary,
  secondary,
  outline,
  text,
  danger,
}

class _ModernButtonState extends State<ModernButton> {
  bool _isPressed = false;

  Color get _backgroundColor {
    if (widget.isLoading) {
      return widget.style == ModernButtonStyle.primary
          ? AppColors.primaryColor.withValues(alpha: 0.7)
          : AppColors.neutral100;
    }
    switch (widget.style) {
      case ModernButtonStyle.primary:
        return AppColors.primaryColor;
      case ModernButtonStyle.secondary:
        return AppColors.neutral100;
      case ModernButtonStyle.outline:
        return Colors.transparent;
      case ModernButtonStyle.text:
        return Colors.transparent;
      case ModernButtonStyle.danger:
        return AppColors.error;
    }
  }

  Color get _textColor {
    switch (widget.style) {
      case ModernButtonStyle.primary:
        return AppColors.charcoal;
      case ModernButtonStyle.secondary:
        return AppColors.charcoal;
      case ModernButtonStyle.outline:
        return AppColors.charcoal;
      case ModernButtonStyle.text:
        return AppColors.primaryColor;
      case ModernButtonStyle.danger:
        return AppColors.textLight;
    }
  }

  BorderSide? get _borderSide {
    if (widget.style == ModernButtonStyle.outline) {
      return const BorderSide(color: AppColors.neutral200, width: 1.5);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onPressed != null
          ? (_) => setState(() => _isPressed = true)
          : null,
      onTapUp: widget.onPressed != null
          ? (_) => setState(() => _isPressed = false)
          : null,
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.isLoading
          ? null
          : () {
              HapticFeedback.lightImpact();
              widget.onPressed?.call();
            },
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: widget.width ?? double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: _borderSide != null ? Border.fromBorderSide(_borderSide!) : null,
            boxShadow: widget.style == ModernButtonStyle.primary &&
                    !_isPressed &&
                    widget.onPressed != null
                ? [
                    BoxShadow(
                      color: AppColors.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(_textColor),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(
                          widget.icon,
                          size: 20,
                          color: _textColor,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        widget.text,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _textColor,
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

/// Icon button with tooltip
class ModernIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;

  const ModernIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.backgroundColor,
    this.iconColor,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: backgroundColor ?? AppColors.cardBackground,
      borderRadius: BorderRadius.circular(12),
      elevation: 0,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onPressed?.call();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: size * 0.45,
            color: iconColor ?? AppColors.charcoal,
          ),
        ),
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

/// Chip/tag widget for categories
class ModernChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final IconData? icon;

  const ModernChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.charcoal : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.charcoal : AppColors.neutral200,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.charcoal.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected ? AppColors.textLight : AppColors.neutral600,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.textLight : AppColors.neutral600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
