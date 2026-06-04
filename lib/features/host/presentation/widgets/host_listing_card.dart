import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/models/property_model.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

class HostListingCard extends StatelessWidget {
  final PropertyModel property;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const HostListingCard({
    super.key,
    required this.property,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildImageSection(context),
            _buildInfoSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: property.firstImageUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: property.firstImageUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 200,
                    width: double.infinity,
                    color: AppColors.neutral200,
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 200,
                    width: double.infinity,
                    color: AppColors.neutral200,
                    child: const Icon(Icons.image_not_supported_outlined,
                        color: AppColors.neutral400, size: 48),
                  ),
                )
              : Container(
                  height: 200,
                  width: double.infinity,
                  color: AppColors.neutral200,
                  child: const Icon(Icons.image_not_supported_outlined,
                      color: AppColors.neutral400, size: 48),
                ),
        ),
        // Status Badge (Top Left)
        Positioned(
          top: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getStatusIcon(property.status),
                  size: 14,
                  color: AppColors.neutral600,
                ),
                const SizedBox(width: 6),
                Text(
                  _formatStatus(context, property.status),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.charcoal,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Price Badge (Top Right)
        Positioned(
          top: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${property.currency ?? 'EGP'} ${property.displayPrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.charcoal,
                  ),
                ),
                Text(
                  ' ${context.tr('home.perNight')}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.neutral500,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Views Badge (Bottom Left)
        Positioned(
          bottom: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.visibility_outlined, color: Colors.white, size: 14),
                const SizedBox(width: 6),
                Text(
                  context.tr('host.cardViewsCount',
                      args: {'n': property.viewCount ?? 0}),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  property.displayTitle.isNotEmpty
                      ? property.displayTitle
                      : context.tr('host.untitledProperty'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.charcoal,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.neutral200),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: AppColors.error,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: AppColors.neutral400),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  property.displayLocation.isNotEmpty
                      ? property.displayLocation
                      : context.tr('propertyDetails.locationNotAvailable'),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.neutral500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (property.bedrooms != null)
                _buildFeaturePill(Icons.door_sliding_outlined,
                    context.tr('propertyDetails.bedrooms', args: {'n': property.bedrooms})),
              if (property.beds != null)
                _buildFeaturePill(Icons.bed_outlined,
                    context.tr('host.cardBeds', args: {'n': property.beds})),
              if (property.bathrooms != null)
                _buildFeaturePill(Icons.bathtub_outlined,
                    context.tr('propertyDetails.bathrooms', args: {'n': property.bathrooms})),
              if (property.maxGuests != null)
                _buildFeaturePill(Icons.people_outline,
                    context.tr('propertyDetails.guests', args: {'n': property.maxGuests})),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatBlock(
                  value: '${(property.occupancyRate ?? 0).toStringAsFixed(0)}%',
                  label: context.tr('host.cardOccupancy'),
                  valueColor: const Color(0xFFC79100), // Darker yellow for text
                  backgroundColor: AppColors.primaryColor.withValues(alpha: 0.1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatBlock(
                  value: (property.revenueThisMonth ?? 0).toStringAsFixed(0),
                  label: context.tr('host.cardThisMonth'),
                  valueColor: AppColors.charcoal,
                  backgroundColor: const Color(0xFFF5F6F8),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatBlock(
                  value: (property.viewCount ?? 0).toString(),
                  label: context.tr('host.cardTotalViews'),
                  valueColor: AppColors.charcoal,
                  backgroundColor: const Color(0xFFF5F6F8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturePill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9FA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.neutral100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.neutral600),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.charcoal,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBlock({
    required String value,
    required String label,
    required Color valueColor,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.neutral500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(String? status) {
    switch (status?.toUpperCase()) {
      case 'DRAFT':
        return Icons.insert_drive_file_outlined;
      case 'ACTIVE':
        return Icons.check_circle_outline;
      case 'PENDING':
        return Icons.schedule;
      default:
        return Icons.info_outline;
    }
  }

  String _formatStatus(BuildContext context, String? status) {
    if (status == null || status.isEmpty) return context.tr('host.statusUnknown');
    switch (status.toUpperCase()) {
      case 'DRAFT':
        return context.tr('host.statusDraft');
      case 'ACTIVE':
        return context.tr('host.statusActive');
      case 'PENDING':
        return context.tr('host.statusPending');
      default:
        return status[0].toUpperCase() + status.substring(1).toLowerCase();
    }
  }
}
