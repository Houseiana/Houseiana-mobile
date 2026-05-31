import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';

/// Modern property card with enhanced design
class PropertyCardV2 extends StatefulWidget {
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

  const PropertyCardV2({
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
  });

  @override
  State<PropertyCardV2> createState() => _PropertyCardV2State();
}

class _PropertyCardV2State extends State<PropertyCardV2>
    with SingleTickerProviderStateMixin {
  bool _isFavorite = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.isFavorite;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image section with overlay
              _buildImageSection(),
              // Content section
              _buildContentSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Stack(
      children: [
        // Image with rounded top corners
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: CachedNetworkImage(
            imageUrl: widget.imageUrl,
            height: 180,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              height: 180,
              color: AppColors.neutral200,
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryColor,
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              height: 180,
              color: AppColors.neutral200,
              child: const Icon(
                Icons.image_not_supported_outlined,
                color: AppColors.neutral400,
                size: 48,
              ),
            ),
          ),
        ),

        // Gradient overlay for better text readability
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.02),
                ],
                stops: const [0.7, 1.0],
              ),
            ),
          ),
        ),

        // Ribbon text (e.g., "Superhost", "Promo")
        if (widget.ribbonText != null)
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.charcoal,
                borderRadius: BorderRadius.circular(6),
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

        // Favorite button
        Positioned(
          top: 12,
          right: 12,
          child: _buildFavoriteButton(),

        ),

        // Rating badge
        Positioned(
          bottom: 12,
          left: 12,
          child: _buildRatingBadge(),
        ),

        // Superhost badge
        if (widget.isSuperhost)
          Positioned(
            bottom: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.verified,
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

  Widget _buildFavoriteButton() {
    return Material(
      color: AppColors.cardBackground.withValues(alpha: 0.9),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: () {
          setState(() => _isFavorite = !_isFavorite);
          widget.onFavoriteToggle?.call();
        },
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              key: ValueKey(_isFavorite),
              size: 22,
              color: _isFavorite ? Colors.red : AppColors.charcoal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRatingBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star,
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
    );
  }

  Widget _buildContentSection() {
    return Padding(
      padding: const EdgeInsets.all(14),
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

          const SizedBox(height: 4),

          // Location
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 14,
                color: AppColors.neutral600,
              ),
              const SizedBox(width: 2),
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

          const SizedBox(height: 10),

          // Price section
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Current price
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

              // Original price (if on sale)
              if (widget.originalPrice != null &&
                  widget.originalPrice! > widget.price) ...[
                const SizedBox(width: 8),
                Text(
                  '\$${widget.originalPrice!.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.neutral400,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${((1 - widget.price / widget.originalPrice!) * 100).toStringAsFixed(0)}% OFF',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.red.shade700,
                    ),
                  ),
                ),
              ],

              const Spacer(),

              // Amenities quick icons
              Row(
                children: [
                  _buildAmenityIcon(Icons.king_bed_outlined, 'King'),
                  const SizedBox(width: 8),
                  _buildAmenityIcon(Icons.wifi_outlined, 'WiFi'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmenityIcon(IconData icon, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: Icon(
        icon,
        size: 16,
        color: AppColors.neutral400,
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
  final String currency;
  final VoidCallback? onTap;

  const CompactPropertyCard({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.location,
    required this.price,
    required this.rating,
    this.currency = 'EGP',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
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
                  child: const Icon(Icons.image_not_supported_outlined),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(10),
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

                  const SizedBox(height: 2),

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

                  const SizedBox(height: 6),

                  // Price and rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          '${price.toStringAsFixed(0)} $currency/night',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.charcoal,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
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
