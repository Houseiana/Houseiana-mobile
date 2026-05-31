import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';

class PropertyDetailsSkeleton extends StatelessWidget {
  const PropertyDetailsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    height: 300,
                    width: double.infinity,
                    color: AppColors.neutral200,
                  ),
                  
                  // Thumbnails
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: List.generate(4, (i) => Container(
                        width: 52,
                        height: 52,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: AppColors.neutral200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      )),
                    ),
                  ),

                  // Info
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Bone.text(words: 1),
                        const SizedBox(height: 12),
                        const Bone.text(words: 3),
                        const SizedBox(height: 8),
                        const Bone.text(words: 2),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Bone.button(width: 40, height: 20),
                            const SizedBox(width: 12),
                            const Bone.text(words: 2),
                            const SizedBox(width: 12),
                            const Bone.text(words: 3),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const _SkeletonDivider(),

                  // Highlights
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: List.generate(3, (i) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          children: [
                            const Bone.circle(size: 32),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Bone.text(words: 2),
                                const SizedBox(height: 4),
                                const Bone.text(words: 4),
                              ],
                            ),
                          ],
                        ),
                      )),
                    ),
                  ),

                  const _SkeletonDivider(),

                  // Host
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Bone.circle(size: 56),
                        SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Bone.text(words: 2),
                            SizedBox(height: 6),
                            Bone.text(words: 1),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const _SkeletonDivider(),

                  // About
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Bone.text(words: 2),
                        SizedBox(height: 16),
                        Bone.multiText(lines: 3),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom Bar
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.neutral200)),
            ),
            child: const Row(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Bone.text(words: 1),
                    SizedBox(height: 4),
                    Bone.text(words: 1),
                  ],
                ),
                Spacer(),
                Bone.button(width: 140, height: 50, ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonDivider extends StatelessWidget {
  const _SkeletonDivider();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Divider(color: AppColors.neutral200, height: 1),
    );
  }
}
