import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';

/// Generic list-of-tiles skeleton (notifications, addresses, payment
/// methods, reviews, payouts, bookings…). Each tile: leading shape +
/// two text lines + optional trailing bar, inside a card container.
class TileListSkeleton extends StatelessWidget {
  final int itemCount;
  final double leadingSize;
  final bool leadingCircle;
  final bool showLeading;
  final bool showTrailing;
  final double tileHeight;
  final EdgeInsetsGeometry padding;

  TileListSkeleton({
    super.key,
    this.itemCount = 6,
    this.leadingSize = 44,
    this.leadingCircle = false,
    this.showLeading = true,
    this.showTrailing = false,
    this.tileHeight = 76,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: padding,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => TileSkeletonItem(
        leadingSize: leadingSize,
        leadingCircle: leadingCircle,
        showLeading: showLeading,
        showTrailing: showTrailing,
        height: tileHeight,
      ),
    );
  }
}

/// A single tile skeleton row — use inside custom scroll views when
/// [TileListSkeleton] doesn't fit the layout.
class TileSkeletonItem extends StatelessWidget {
  final double leadingSize;
  final bool leadingCircle;
  final bool showLeading;
  final bool showTrailing;
  final double height;

  TileSkeletonItem({
    super.key,
    this.leadingSize = 44,
    this.leadingCircle = false,
    this.showLeading = true,
    this.showTrailing = false,
    this.height = 76,
  });

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      containersColor: AppColors.skeletonBaseColor,
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            if (showLeading) ...[
              Container(
                width: leadingSize,
                height: leadingSize,
                decoration: BoxDecoration(
                  color: AppColors.neutral200,
                  shape: leadingCircle ? BoxShape.circle : BoxShape.rectangle,
                  borderRadius:
                      leadingCircle ? null : BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 15,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.neutral200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FractionallySizedBox(
                    widthFactor: 0.6,
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.neutral200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (showTrailing) ...[
              const SizedBox(width: 12),
              Container(
                height: 24,
                width: 56,
                decoration: BoxDecoration(
                  color: AppColors.neutral200,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Skeleton for form screens (personal info, settings, verification…):
/// optional avatar, then label + input-box pairs, optional bottom button.
class FormSkeleton extends StatelessWidget {
  final int fieldCount;
  final bool showAvatar;
  final bool showButton;
  final EdgeInsetsGeometry padding;

  FormSkeleton({
    super.key,
    this.fieldCount = 5,
    this.showAvatar = false,
    this.showButton = true,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      containersColor: AppColors.skeletonBaseColor,
      child: SingleChildScrollView(
        padding: padding,
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showAvatar) ...[
              Center(
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.neutral200,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            ...List.generate(fieldCount, (_) => _FormFieldSkeleton()),
            if (showButton) ...[
              const SizedBox(height: 12),
              Container(
                height: 52,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.neutral200,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FormFieldSkeleton extends StatelessWidget {
  _FormFieldSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 13,
            width: 90,
            decoration: BoxDecoration(
              color: AppColors.neutral200,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 50,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.neutral200,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton for detail pages (booking/trip details, owner profile…):
/// hero block + title lines + section cards.
class DetailsPageSkeleton extends StatelessWidget {
  final double heroHeight;
  final bool circularHero;
  final int sectionCount;

  DetailsPageSkeleton({
    super.key,
    this.heroHeight = 240,
    this.circularHero = false,
    this.sectionCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      containersColor: AppColors.skeletonBaseColor,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (circularHero)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Container(
                    width: heroHeight,
                    height: heroHeight,
                    decoration: BoxDecoration(
                      color: AppColors.neutral200,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              )
            else
              Container(
                height: heroHeight,
                width: double.infinity,
                color: AppColors.neutral200,
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 22,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.neutral200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FractionallySizedBox(
                    widthFactor: 0.5,
                    child: Container(
                      height: 15,
                      decoration: BoxDecoration(
                        color: AppColors.neutral200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ...List.generate(
                    sectionCount,
                    (_) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Container(
                        height: 110,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.neutral200,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
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

/// Month-calendar skeleton (host calendar, availability, nightly prices):
/// month title + weekday row + 6×7 day-cell grid.
class CalendarSkeleton extends StatelessWidget {
  final bool showHeader;
  final EdgeInsetsGeometry padding;

  CalendarSkeleton({
    super.key,
    this.showHeader = true,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      containersColor: AppColors.skeletonBaseColor,
      child: SingleChildScrollView(
        padding: padding,
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showHeader) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    height: 20,
                    width: 130,
                    decoration: BoxDecoration(
                      color: AppColors.neutral200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Row(
                    children: List.generate(
                      2,
                      (_) => Container(
                        width: 36,
                        height: 36,
                        margin: const EdgeInsetsDirectional.only(start: 8),
                        decoration: BoxDecoration(
                          color: AppColors.neutral200,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
            Row(
              children: List.generate(
                7,
                (_) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.neutral200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(
              6,
              (_) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: List.generate(
                    7,
                    (_) => Expanded(
                      child: AspectRatio(
                        aspectRatio: 0.9,
                        child: Container(
                          margin: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: AppColors.neutral200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Grid-of-cards skeleton (wishlists, photo grids, category grids…).
class GridSkeleton extends StatelessWidget {
  final int itemCount;
  final int crossAxisCount;
  final double childAspectRatio;
  final EdgeInsetsGeometry padding;

  GridSkeleton({
    super.key,
    this.itemCount = 6,
    this.crossAxisCount = 2,
    this.childAspectRatio = 0.8,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      containersColor: AppColors.skeletonBaseColor,
      child: GridView.builder(
        padding: padding,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: itemCount,
        itemBuilder: (_, __) => Container(
          decoration: BoxDecoration(
            color: AppColors.neutral200,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

/// Dashboard-style skeleton: a row of stat cards then content blocks.
class StatsPageSkeleton extends StatelessWidget {
  final int statCount;
  final int blockCount;

  StatsPageSkeleton({
    super.key,
    this.statCount = 4,
    this.blockCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      containersColor: AppColors.skeletonBaseColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.9,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: statCount,
              itemBuilder: (_, __) => Container(
                decoration: BoxDecoration(
                  color: AppColors.neutral200,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ...List.generate(
              blockCount,
              (_) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.neutral200,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
