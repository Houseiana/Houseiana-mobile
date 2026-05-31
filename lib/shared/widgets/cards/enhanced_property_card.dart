import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/theme/app_icons.dart';
import 'package:houseiana_mobile_app/core/theme/app_radius.dart';
import 'package:houseiana_mobile_app/core/theme/app_shadows.dart';
import 'package:houseiana_mobile_app/core/theme/app_spacing.dart';

/// Enhanced property card with modern design
class EnhancedPropertyCard extends StatefulWidget {
  final String id;
  final String imageUrl;
  final String title;
  final String location;
  final double price;
  final double? originalPrice;
  final double rating;
  final int reviewCount;
  final bool isFavorite;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;
  final bool isSuperhost;
  final String? ribbonText;
  final int? bedrooms;
  final int? bathrooms;
  final int? guests;
  final bool showDiscount;
  final double? discountPercentage;

  const EnhancedPropertyCard({
    super.key,
    required this.id,
    required this.imageUrl,
    required this.title,
    required this.location,
    required this.price,
    this.originalPrice,
    required this.rating,
    this.reviewCount = 0,
    this.isFavorite = false,
    this.onTap,
    this.onFavoriteToggle,
    this.isSuperhost = false,
    this.ribbonText,
    this.bedrooms,
    this.bathrooms,
    this.guests,
    this.showDiscount = true,
    this.discountPercentage,
  });

  @override
  State<EnhancedPropertyCard> createState() => _EnhancedPropertyCardState();
}

class _EnhancedPropertyCardState extends State<EnhancedPropertyCard>
    with SingleTickerProviderStateMixin {
  bool _isFavorite = false;
  bool _isPressed = false;
  late AnimationController _heartController;
  late Animation<double> _heartAnimation;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.isFavorite;
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _heartAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 33),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 0.8), weight: 33),
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.0), weight: 34),
    ]).animate(CurvedAnimation(
      parent: _heartController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  void _toggleFavorite() {
    HapticFeedback.lightImpact();
    setState(() => _isFavorite = !_isFavorite);
    if (_isFavorite) {
      _heartController.forward(from: 0);
    }
    widget.onFavoriteToggle?.call();
  }

  double get _effectiveDiscount {
    if (widget.discountPercentage != null) return widget.discountPercentage!;
    if (widget.originalPrice != null && widget.originalPrice! > widget.price) {
      return ((1 - widget.price / widget.originalPrice!) * 100);
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final showDiscount = _effectiveDiscount > 0 && widget.showDiscount;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap?.call();
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: AppRadius.cardRadiusAll,
            boxShadow: _isPressed ? AppShadows.cardShadowHover : AppShadows.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image section
              _buildImageSection(showDiscount),
              // Content section
              _buildContentSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection(bool showDiscount) {
    return Stack(
      children: [
        // Image with rounded top corners
        ClipRRect(
          borderRadius: AppRadius.cardTopRadius,
          child: CachedNetworkImage(
            imageUrl: widget.imageUrl,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.neutral200,
                borderRadius: AppRadius.cardTopRadius,
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryColor,
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE8E8E8), Color(0xFFD4D4D4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: AppRadius.cardTopRadius,
              ),
              child: const Icon(
                Icons.home_outlined,
                size: 48,
                color: AppColors.neutral400,
              ),
            ),
          ),
        ),

        // Gradient overlay for better text readability
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: AppRadius.cardTopRadius,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.05),
                ],
                stops: const [0.6, 1.0],
              ),
            ),
          ),
        ),

        // Ribbon text (e.g., "Superhost", "Promo")
        if (widget.ribbonText != null)
          Positioned(
            top: AppSpacing.md,
            left: AppSpacing.md,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.charcoal,
                borderRadius: AppRadius.badgeRadiusAll,
              ),
              child: Text(
                widget.ribbonText!,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textLight,
                ),
              ),
            ),
          ),

        // Discount badge
        if (showDiscount)
          Positioned(
            top: AppSpacing.md,
            left: widget.ribbonText != null ? 90 : AppSpacing.md,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: AppRadius.badgeRadiusAll,
              ),
              child: Text(
                '-${_effectiveDiscount.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textLight,
                ),
              ),
            ),
          ),

        // Favorite button with animation
        Positioned(
          top: AppSpacing.md,
          right: AppSpacing.md,
          child: ScaleTransition(
            scale: _heartAnimation,
            child: GestureDetector(
              onTap: _toggleFavorite,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  size: 20,
                  color: _isFavorite ? AppColors.error : AppColors.neutral600,
                ),
              ),
            ),
          ),
        ),

        // Rating badge
        Positioned(
          bottom: AppSpacing.md,
          left: AppSpacing.md,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: AppRadius.badgeRadiusAll,
              boxShadow: AppShadows.iconButtonShadow,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  AppIcons.star,
                  size: 14,
                  color: AppColors.bioYellow,
                ),
                const SizedBox(width: 4),
                Text(
                  widget.rating.toStringAsFixed(2),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.charcoal,
                  ),
                ),
                if (widget.reviewCount > 0) ...[
                  Text(
                    ' (${widget.reviewCount})',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.neutral600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Superhost badge
        if (widget.isSuperhost)
          Positioned(
            bottom: AppSpacing.md,
            right: AppSpacing.md,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: AppRadius.badgeRadiusAll,
                boxShadow: AppShadows.iconButtonShadow,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    AppIcons.superhost,
                    size: 14,
                    color: AppColors.secondaryColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Superhost',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.charcoal.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildContentSection() {
    return Padding(
      padding: AppSpacing.paddingCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            widget.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.charcoal,
              height: 1.3,
            ),
          ),

          AppSpacing.verticalSpaceXs,

          // Location
          Row(
            children: [
              const Icon(
                AppIcons.location,
                size: 14,
                color: AppColors.neutral600,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  widget.location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.neutral600,
                  ),
                ),
              ),
            ],
          ),

          AppSpacing.verticalSpaceMd,

          // Price and amenities
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Price
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '\$${widget.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.charcoal,
                        ),
                      ),
                      const Text(
                        ' / night',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.neutral600,
                        ),
                      ),
                    ],
                  ),
                  if (widget.originalPrice != null &&
                      widget.originalPrice! > widget.price) ...[
                    const SizedBox(height: 2),
                    Text(
                      '\$${widget.originalPrice!.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.neutral400,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                ],
              ),

              const Spacer(),

              // Quick amenities
              if (widget.bedrooms != null || widget.bathrooms != null)
                Row(
                  children: [
                    if (widget.bedrooms != null) ...[
                      _buildAmenityChip(
                        Icons.king_bed_outlined,
                        '${widget.bedrooms}',
                      ),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    if (widget.bathrooms != null)
                      _buildAmenityChip(
                        Icons.bathtub_outlined,
                        '${widget.bathrooms}',
                      ),
                    if (widget.guests != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      _buildAmenityChip(
                        Icons.people_outlined,
                        '${widget.guests}',
                      ),
                    ],
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmenityChip(IconData icon, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        borderRadius: AppRadius.radiusSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.neutral600),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.neutral600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact property card for horizontal lists
class CompactPropertyCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String location;
  final double price;
  final double rating;
  final VoidCallback? onTap;

  const CompactPropertyCard({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.location,
    required this.price,
    required this.rating,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: AppRadius.radiusLg,
          boxShadow: AppShadows.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.lg),
              ),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                height: 120,
                width: 200,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 120,
                  color: AppColors.neutral200,
                ),
                errorWidget: (context, url, error) => Container(
                  height: 120,
                  color: AppColors.neutral200,
                  child: const Icon(Icons.home_outlined),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.charcoal,
                    ),
                  ),

                  AppSpacing.verticalSpaceXs,

                  // Location
                  Text(
                    location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.neutral600,
                    ),
                  ),

                  AppSpacing.verticalSpaceSm,

                  // Price and rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${price.toStringAsFixed(0)}/night',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.charcoal,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            AppIcons.star,
                            size: 12,
                            color: AppColors.bioYellow,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.charcoal,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
