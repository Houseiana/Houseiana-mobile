import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/features/host/cubit/listing_wizard_cubit.dart';
import 'package:houseiana_mobile_app/features/host/cubit/listing_wizard_state.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';

class Step06PhotosScreen extends StatefulWidget {
  const Step06PhotosScreen({super.key});

  @override
  State<Step06PhotosScreen> createState() => _Step06PhotosScreenState();
}

class _Step06PhotosScreenState extends State<Step06PhotosScreen> {
  final ImagePicker _picker = ImagePicker();

  // ── Cover Photo picker ────────────────────────────────────────────────────

  Future<void> _pickCoverPhoto() async {
    final cubit = context.read<ListingWizardCubit>();

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.neutral300,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                context.tr('wizard.wizardPhotosUploadCoverTitle'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.charcoal,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.tr('wizard.wizardPhotosUploadCoverDesc'),
                style: const TextStyle(fontSize: 14, color: AppColors.neutral600),
              ),
              const SizedBox(height: 20),
              _PhotoSourceTile(
                icon: Icons.photo_library_outlined,
                title: context.tr('wizard.wizardPhotosChooseFromGallery'),
                subtitle: context.tr('wizard.wizardPhotosChooseFromGallerySingle'),
                onTap: () async {
                  Navigator.pop(sheetCtx);
                  final file = await _picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 85,
                    maxWidth: 2400,
                  );
                  if (!mounted || file == null) return;
                  cubit.setCoverPhoto(file.path);
                },
              ),
              const SizedBox(height: 12),
              _PhotoSourceTile(
                icon: Icons.photo_camera_outlined,
                title: context.tr('wizard.wizardPhotosTakePhoto'),
                subtitle: context.tr('wizard.wizardPhotosUseCameraNow'),
                onTap: () async {
                  Navigator.pop(sheetCtx);
                  final file = await _picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 85,
                    maxWidth: 2400,
                  );
                  if (!mounted || file == null) return;
                  cubit.setCoverPhoto(file.path);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Regular photos pickers ────────────────────────────────────────────────

  Future<void> _showPhotoSourceSheet() async {
    final cubit = context.read<ListingWizardCubit>();
    if (cubit.state.isUploadingPhotos) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.neutral300,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                context.tr('wizard.wizardPhotosAddListingPhotos'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.charcoal,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.tr('wizard.wizardPhotosListingDesc'),
                style: const TextStyle(fontSize: 14, color: AppColors.neutral600),
              ),
              const SizedBox(height: 20),
              _PhotoSourceTile(
                icon: Icons.photo_library_outlined,
                title: context.tr('wizard.wizardPhotosChooseFromGallery'),
                subtitle: context.tr('wizard.wizardPhotosChooseFromGalleryMulti'),
                onTap: () async {
                  Navigator.pop(sheetCtx);
                  await _pickFromGallery();
                },
              ),
              const SizedBox(height: 12),
              _PhotoSourceTile(
                icon: Icons.photo_camera_outlined,
                title: context.tr('wizard.wizardPhotosTakePhoto'),
                subtitle: context.tr('wizard.wizardPhotosUseCameraUpload'),
                onTap: () async {
                  Navigator.pop(sheetCtx);
                  await _pickFromCamera();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickFromGallery() async {
    try {
      final files = await _picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 2400,
      );
      if (!mounted || files.isEmpty) return;
      for (final file in files) {
        await context.read<ListingWizardCubit>().uploadPhoto(file.path);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              'wizard.wizardPhotosUnableToPick',
              args: {'error': e.toString()},
            ),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _pickFromCamera() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 2400,
      );
      if (!mounted || file == null) return;
      await context.read<ListingWizardCubit>().uploadPhoto(file.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              'wizard.wizardPhotosUnableToCamera',
              args: {'error': e.toString()},
            ),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _confirmRemovePhoto(int index) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(context.tr('wizard.wizardPhotosRemoveTitle')),
        content: Text(
          context.tr('wizard.wizardPhotosRemoveMessage'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(context.tr('wizard.wizardPhotosCancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.read<ListingWizardCubit>().removePhotoAt(index);
            },
            child: Text(
              context.tr('wizard.wizardPhotosRemove'),
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _buildImageWidget(String path, {BoxFit fit = BoxFit.cover}) {
    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: fit,
        errorBuilder: (_, __, ___) => const _ImageErrorPlaceholder(),
      );
    }
    return Image.file(
      File(path),
      fit: fit,
      errorBuilder: (_, __, ___) => const _ImageErrorPlaceholder(),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ListingWizardCubit, ListingWizardState>(
      builder: (context, state) {
        final cubit = context.read<ListingWizardCubit>();
        final photos = state.data.photos;
        final coverPhoto = state.data.coverPhoto;
        final remainingCount = (5 - photos.length).clamp(0, 5);
        final hasMinimumPhotos = photos.length >= 5;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Page header ─────────────────────────────────────────────
              Text(
                context.tr('wizard.wizardPhotosStepTitle'),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.charcoal,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.tr('wizard.wizardPhotosStepSubtitle'),
                style: const TextStyle(fontSize: 15, color: AppColors.neutral600),
              ),
              const SizedBox(height: 28),

              // ── Cover Photo section ──────────────────────────────────────
              Text(
                context.tr('wizard.wizardPhotosCoverSectionTitle'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.charcoal,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                context.tr('wizard.wizardPhotosCoverSectionDesc'),
                style: const TextStyle(fontSize: 13, color: AppColors.neutral600),
              ),
              const SizedBox(height: 12),

              if (coverPhoto != null)
                // ── Cover photo is SET ──────────────────────────────────
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 220,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildImageWidget(coverPhoto),

                        // Subtle gradient scrim for readability
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: 80,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.35),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Yellow "Cover Photo" badge
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              context.tr('wizard.wizardPhotosCoverBadge'),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.charcoal,
                              ),
                            ),
                          ),
                        ),

                        // Change + Delete action buttons
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Row(
                            children: [
                              _IconActionButton(
                                icon: Icons.add_photo_alternate_outlined,
                                iconColor: AppColors.charcoal,
                                onTap: _pickCoverPhoto,
                                tooltip: context.tr('wizard.wizardPhotosChangeCoverTooltip'),
                              ),
                              const SizedBox(width: 8),
                              _IconActionButton(
                                icon: Icons.delete_outline_rounded,
                                iconColor: AppColors.error,
                                onTap: () => cubit.removeCoverPhoto(),
                                tooltip: context.tr('wizard.wizardPhotosRemoveCoverTooltip'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                // ── Cover photo EMPTY state ─────────────────────────────
                GestureDetector(
                  onTap: _pickCoverPhoto,
                  child: Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFE5E7EB),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF0F2F5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.photo_camera_outlined,
                            color: Color(0xFF9CA3AF),
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          context.tr('wizard.wizardPhotosUploadCoverTitle'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.neutral600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.tr('wizard.wizardPhotosFileTypes'),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // ── Divider ─────────────────────────────────────────────────
              const Divider(color: Color(0xFFE5E9EE), thickness: 1),
              const SizedBox(height: 24),

              // ── Progress banner ──────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: hasMinimumPhotos
                      ? const Color(0xFFF0FDF4)
                      : AppColors.ghostWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: hasMinimumPhotos
                        ? const Color(0xFF86EFAC)
                        : const Color(0xFFE5E7EB),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      hasMinimumPhotos
                          ? Icons.check_circle_outline
                          : Icons.photo_library_outlined,
                      color: hasMinimumPhotos
                          ? const Color(0xFF15803D)
                          : AppColors.primaryColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        hasMinimumPhotos
                            ? context.tr('wizard.wizardPhotosEnoughPhotos')
                            : context.tr(
                                remainingCount == 1
                                    ? 'wizard.wizardPhotosAddMoreSingular'
                                    : 'wizard.wizardPhotosAddMorePlural',
                                args: {'count': remainingCount},
                              ),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: hasMinimumPhotos
                              ? const Color(0xFF166534)
                              : AppColors.charcoal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Upload progress indicator ────────────────────────────────
              if (state.isUploadingPhotos)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          context.tr('wizard.wizardPhotosUploading'),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.charcoal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Photos grid ──────────────────────────────────────────────
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemCount: photos.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _AddPhotoTile(
                      isUploading: state.isUploadingPhotos,
                      onTap: _showPhotoSourceSheet,
                    );
                  }

                  final photo = photos[index - 1];
                  return _ListingPhotoTile(
                    imageUrl: photo,
                    indexLabel: context.tr(
                      'wizard.wizardPhotosPhotoLabel',
                      args: {'index': index},
                    ),
                    onRemove: () => _confirmRemovePhoto(index - 1),
                  );
                },
              ),

              if (photos.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    context.tr('wizard.wizardPhotosEmptyState'),
                    style: const TextStyle(
                      color: AppColors.neutral600,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ── Private widgets ───────────────────────────────────────────────────────────

class _IconActionButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  final String tooltip;

  const _IconActionButton({
    required this.icon,
    required this.iconColor,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E9EE)),
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
      ),
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  final bool isUploading;
  final VoidCallback onTap;

  const _AddPhotoTile({
    required this.isUploading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isUploading ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.ghostWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFD1D5DB),
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isUploading
                        ? Icons.hourglass_top_rounded
                        : Icons.add_a_photo_outlined,
                    color: AppColors.neutral600,
                    size: 32,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isUploading
                        ? context.tr('wizard.wizardPhotosUploadingShort')
                        : context.tr('wizard.wizardPhotosAddPhotos'),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.tr('wizard.wizardPhotosGalleryOrCamera'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.neutral600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ListingPhotoTile extends StatelessWidget {
  final String imageUrl;
  final String indexLabel;
  final VoidCallback onRemove;

  const _ListingPhotoTile({
    required this.imageUrl,
    required this.indexLabel,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          imageUrl.startsWith('http')
              ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const _ImageErrorPlaceholder(),
                )
              : Image.file(
                  File(imageUrl),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const _ImageErrorPlaceholder(),
                ),
          // Index label
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                indexLabel,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          // Delete button
          Positioned(
            top: 8,
            right: 8,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onRemove,
                borderRadius: BorderRadius.circular(999),
                child: Ink(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageErrorPlaceholder extends StatelessWidget {
  const _ImageErrorPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.ghostWhite,
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_outlined,
        color: AppColors.neutral600,
        size: 28,
      ),
    );
  }
}

class _PhotoSourceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PhotoSourceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.ghostWhite,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.charcoal),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.neutral600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.neutral600,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
