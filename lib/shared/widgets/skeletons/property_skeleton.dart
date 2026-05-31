import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';

/// A shimmer-enabled skeleton card for property listings
class PropertySkeletonCard extends StatelessWidget {
  final double height;
  final double imageHeight;
  final bool isCompact;

  const PropertySkeletonCard({
    super.key,
    this.height = 280,
    this.imageHeight = 160,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      containersColor: AppColors.skeletonBaseColor,

      child: Container(
        height: height,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            Container(
              height: imageHeight,
              decoration: BoxDecoration(
                color: AppColors.skeletonBaseColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Stack(
                children: [
                  // Image area
                  Container(
                    height: imageHeight,
                    decoration: BoxDecoration(
                      color: AppColors.neutral200,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                  ),
                  // Favorite button placeholder
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.neutral200,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  // Rating badge placeholder
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      width: 50,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.neutral200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Content area
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title placeholder
                  Container(
                    height: 18,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.neutral200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Location placeholder
                  Container(
                    height: 14,
                    width: 150,
                    decoration: BoxDecoration(
                      color: AppColors.neutral200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Price row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        height: 20,
                        width: 80,
                        decoration: BoxDecoration(
                          color: AppColors.neutral200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Container(
                        height: 14,
                        width: 60,
                        decoration: BoxDecoration(
                          color: AppColors.neutral200,
                          borderRadius: BorderRadius.circular(4),
                        ),
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

/// Compact property skeleton for horizontal lists
class CompactPropertySkeleton extends StatelessWidget {
  final double width;

  const CompactPropertySkeleton({
    super.key,
    this.width = 200,
  });

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      containersColor: AppColors.skeletonBaseColor,
      child: Container(
        width: width,
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
            Container(
              height: 120,
              decoration: const BoxDecoration(
                color: AppColors.neutral200,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 14,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.neutral200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 12,
                    width: 80,
                    decoration: BoxDecoration(
                      color: AppColors.neutral200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 16,
                    width: 60,
                    decoration: BoxDecoration(
                      color: AppColors.neutral200,
                      borderRadius: BorderRadius.circular(4),
                    ),
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
