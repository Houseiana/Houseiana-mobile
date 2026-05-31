import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';

class TripSkeletonCard extends StatelessWidget {
  const TripSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      containersColor: AppColors.skeletonBaseColor,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 180,
              decoration: const BoxDecoration(
                color: AppColors.neutral200,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 20,
                    width: 70,
                    decoration: BoxDecoration(
                      color: AppColors.neutral200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 12),
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
                    width: 200,
                    decoration: BoxDecoration(
                      color: AppColors.neutral200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 14,
                    width: 120,
                    decoration: BoxDecoration(
                      color: AppColors.neutral200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.neutral200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.neutral200,
                            borderRadius: BorderRadius.circular(8),
                          ),
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

class TripSkeletonList extends StatelessWidget {
  final int itemCount;

  const TripSkeletonList({super.key, this.itemCount = 3});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (_, __) => const TripSkeletonCard(),
    );
  }
}
