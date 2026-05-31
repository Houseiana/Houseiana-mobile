import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';

/// Skeleton loader for list screens (Home, Search, etc.)
class ListSkeletonLoader extends StatelessWidget {
  final int itemCount;
  final bool showSearchBar;
  final bool showCategories;

  const ListSkeletonLoader({
    super.key,
    this.itemCount = 5,
    this.showSearchBar = true,
    this.showCategories = true,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header skeleton
          if (showSearchBar) ...[
            _buildHeaderSkeleton(),
            const SizedBox(height: 20),
          ],

          // Categories skeleton
          if (showCategories) ...[
            _buildCategoriesSkeleton(),
            const SizedBox(height: 24),
          ],

          // List items skeleton
          ...List.generate(itemCount, (index) => _buildListItemSkeleton()),
        ],
      ),
    );
  }

  Widget _buildHeaderSkeleton() {
    return Skeletonizer(
      containersColor: AppColors.skeletonBaseColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 24,
                width: 120,
                decoration: BoxDecoration(
                  color: AppColors.neutral200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                height: 14,
                width: 80,
                decoration: BoxDecoration(
                  color: AppColors.neutral200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.neutral200,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSkeleton() {
    return Skeletonizer(
      containersColor: AppColors.skeletonBaseColor,
      
      child: SizedBox(
        height: 36,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 6,
          itemBuilder: (context, index) {
            return Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.neutral200,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Container(
                width: 60,
                decoration: BoxDecoration(
                  color: AppColors.neutral200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildListItemSkeleton() {
    return Skeletonizer(
      containersColor: AppColors.skeletonBaseColor,
      
      child: Container(
        height: 280,
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
            // Image area
            Container(
              height: 160,
              decoration: const BoxDecoration(
                color: AppColors.neutral200,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 18,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.neutral200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 14,
                    width: 150,
                    decoration: BoxDecoration(
                      color: AppColors.neutral200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 12),
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

/// Profile skeleton loader
class ProfileSkeletonLoader extends StatelessWidget {
  const ProfileSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      containersColor: AppColors.skeletonBaseColor,
      
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              height: 22,
              width: 100,
              decoration: BoxDecoration(
                color: AppColors.neutral200,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 20),

            // User card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.neutral200,
                      borderRadius: BorderRadius.circular(32),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 18,
                          width: 120,
                          decoration: BoxDecoration(
                            color: AppColors.neutral200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 14,
                          width: 160,
                          decoration: BoxDecoration(
                            color: AppColors.neutral200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 12,
                          width: 80,
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
            const SizedBox(height: 24),

            // Menu sections
            ...List.generate(3, (index) => _buildMenuSection()),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 14,
          width: 80,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.neutral200,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: List.generate(
              3,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.neutral200,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 14,
                        decoration: BoxDecoration(
                          color: AppColors.neutral200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
