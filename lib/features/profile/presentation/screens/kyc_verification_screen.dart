import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/features/profile/cubit/kyc_cubit.dart';
import 'package:houseiana_mobile_app/features/profile/cubit/kyc_state.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

class KycVerificationScreen extends StatelessWidget {
  const KycVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _KycView();
  }
}

class _KycView extends StatefulWidget {
  const _KycView();

  @override
  State<_KycView> createState() => _KycViewState();
}

class _KycViewState extends State<_KycView> {
  final _idController = TextEditingController();
  final _picker = ImagePicker();
  final _session = sl<UserSession>();

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_session.isLoggedIn) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.charcoal),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            context.tr('profile.identityVerification'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.charcoal,
            ),
          ),
          centerTitle: true,
        ),
        body: _buildLoginRequired(context),
      );
    }

    return BlocConsumer<KycCubit, KycState>(
      listener: (context, state) {
        if (state is KycSuccess) {
          showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                context.tr('profile.verificationSubmitted'),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              content: Text(
                context.tr('profile.verificationSubmittedDescription'),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  child: Text(context.tr('common.ok')),
                ),
              ],
            ),
          );
        } else if (state is KycError &&
            !state.message.toLowerCase().contains('not logged in')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        final progressState =
            state is KycInProgress ? state : KycInProgress(currentStep: 0);
        final step = progressState.currentStep;
        final docType = progressState.documentType;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.charcoal),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              context.tr('profile.identityVerification'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.charcoal,
              ),
            ),
            centerTitle: true,
          ),
          body: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: (step + 1) / 3,
                      backgroundColor: AppColors.neutral400.withValues(alpha: 0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.tr('profile.stepOfTotal', args: {'step': step + 1, 'total': 3}),
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.neutral600,
                          ),
                        ),
                        Text(
                          context.tr('profile.percentComplete', args: {'percent': ((step + 1) / 3 * 100).toInt()}),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.charcoal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildStepContent(context, step, docType, progressState),
                ),
              ),
              _buildNavigationBar(context, step, state),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoginRequired(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.verified_user_outlined,
              size: 52,
              color: AppColors.neutral500,
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('profile.signInForKyc'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.charcoal,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('profile.signInForKycDescription'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.neutral600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamed(
                  context,
                  Routes.login,
                  arguments: {'redirectRoute': Routes.kycVerification},
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: AppColors.charcoal,
                ),
                child: Text(context.tr('auth.signIn')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent(
    BuildContext context,
    int step,
    String docType,
    KycInProgress state,
  ) {
    switch (step) {
      case 0:
        return _buildSelectDocumentStep(context, docType);
      case 1:
        return _buildUploadDocumentStep(context, state);
      case 2:
        return _buildSelfieStep(context, state);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSelectDocumentStep(BuildContext context, String docType) {
    final documents = [
      {'type': 'ID Card', 'label': context.tr('profile.docTypeIdCard'), 'icon': Icons.credit_card},
      {'type': 'Passport', 'label': context.tr('profile.docTypePassport'), 'icon': Icons.book},
      {'type': 'Driver License', 'label': context.tr('profile.docTypeDriverLicense'), 'icon': Icons.directions_car},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('profile.selectDocumentType'),
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.charcoal,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          context.tr('profile.selectDocumentTypeDescription'),
          style: const TextStyle(fontSize: 15, color: AppColors.neutral600),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _idController,
          onChanged: (value) => context.read<KycCubit>().setIdNumber(
                value.trim(),
              ),
          keyboardType: TextInputType.text,
          decoration: InputDecoration(
            labelText: context.tr('profile.documentNumber'),
            hintText: context.tr('profile.enterDocumentNumber'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primaryColor,
                width: 2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        ...documents.map((doc) {
          final isSelected = docType == doc['type'];

          return GestureDetector(
            onTap: () => context.read<KycCubit>().setDocumentType(
                  doc['type'] as String,
                ),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryColor
                      : const Color(0xFFE5E7EB),
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
                color: isSelected
                    ? AppColors.primaryColor.withValues(alpha: 0.1)
                    : Colors.white,
              ),
              child: Row(
                children: [
                  Icon(
                    doc['icon'] as IconData,
                    size: 32,
                    color: isSelected
                        ? AppColors.charcoal
                        : AppColors.neutral600,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    doc['label'] as String,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: AppColors.charcoal,
                    ),
                  ),
                  const Spacer(),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.primaryColor,
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildUploadDocumentStep(BuildContext context, KycInProgress state) {
    final front = state.frontImagePath;
    final back = state.backImagePath;
    final docType = state.documentType;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('profile.uploadYourDocument'),
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.charcoal,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          context.tr('profile.uploadDocumentDescription', args: {'docType': docType}),
          style: const TextStyle(fontSize: 15, color: AppColors.neutral600),
        ),
        const SizedBox(height: 32),
        _buildUploadBox(
          context,
          context.tr('profile.frontSide'),
          front,
          () => _pickImage(context, isFront: true),
        ),
        const SizedBox(height: 16),
        _buildUploadBox(
          context,
          context.tr('profile.backSide'),
          back,
          () => _pickImage(context, isFront: false),
        ),
        const SizedBox(height: 24),
        _buildTipsCard(context, [
          context.tr('profile.tipGoodLighting'),
          context.tr('profile.tipReadable'),
          context.tr('profile.tipNoGlare'),
          context.tr('profile.tipAllCorners'),
        ]),
      ],
    );
  }

  Widget _buildSelfieStep(BuildContext context, KycInProgress state) {
    final selfie = state.selfiePath;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('profile.takeSelfie'),
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.charcoal,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          context.tr('profile.takeSelfieDescription'),
          style: const TextStyle(fontSize: 15, color: AppColors.neutral600),
        ),
        const SizedBox(height: 32),
        GestureDetector(
          onTap: () => _pickSelfie(context),
          child: Container(
            height: 300,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(16),
              image: selfie != null
                  ? DecorationImage(
                      image: FileImage(io.File(selfie)),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: selfie == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.face,
                          size: 80,
                          color: AppColors.neutral400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          context.tr('profile.tapToCapture'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.charcoal,
                          ),
                        ),
                      ],
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 24),
        _buildTipsCard(context, [
          context.tr('profile.tipLookStraight'),
          context.tr('profile.tipRemoveGlasses'),
          context.tr('profile.tipWellLit'),
          context.tr('profile.tipNeutralExpression'),
        ]),
      ],
    );
  }

  Widget _buildUploadBox(
    BuildContext context,
    String label,
    String? imagePath,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(12),
          image: imagePath != null
              ? DecorationImage(
                  image: FileImage(io.File(imagePath)),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: imagePath == null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.upload_file,
                      size: 40,
                      color: AppColors.neutral400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.tr('profile.tapToUpload'),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.neutral600,
                      ),
                    ),
                  ],
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildNavigationBar(BuildContext context, int step, KycState state) {
    final isSubmitting = state is KycSubmitting;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (step > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () => context.read<KycCubit>().goToStep(step - 1),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.charcoal,
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(context.tr('profile.back')),
              ),
            ),
          if (step > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () {
                      if (step < 2) {
                        context.read<KycCubit>().goToStep(step + 1);
                      } else {
                        context.read<KycCubit>().submitVerification();
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: AppColors.charcoal,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.charcoal,
                      ),
                    )
                  : Text(
                      step < 2
                          ? context.tr('common.continueAction')
                          : context.tr('profile.submit'),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsCard(BuildContext context, List<String> tips) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('profile.tipsForBestResults'),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 8),
          ...tips.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '- $tip',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.charcoal,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(
    BuildContext context, {
    required bool isFront,
  }) async {
    final source = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (source == null || !context.mounted) return;

    if (isFront) {
      context.read<KycCubit>().setFrontImage(source.path);
    } else {
      context.read<KycCubit>().setBackImage(source.path);
    }
  }

  Future<void> _pickSelfie(BuildContext context) async {
    final source = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (source == null || !context.mounted) return;
    context.read<KycCubit>().setSelfie(source.path);
  }
}
