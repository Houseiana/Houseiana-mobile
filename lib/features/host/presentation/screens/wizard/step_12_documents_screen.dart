import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/features/host/cubit/listing_wizard_cubit.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

class Step12DocumentsScreen extends StatelessWidget {
  const Step12DocumentsScreen({super.key});

  Future<void> _pickDocument(BuildContext context, String fieldName) async {
    final picker = ImagePicker();
    final cubit = context.read<ListingWizardCubit>();
    
    // Design allows PDF, but image_picker only does images/videos.
    // For a production app, we would use file_picker. 
    // Here we use gallery as a proxy for document selection.
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image != null) {
      cubit.updateStepData({fieldName: image.path});
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<ListingWizardCubit>();
    final data = cubit.state.data;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('wizard.uploadDocs'),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1D242B),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          _buildUploadSection(
            context,
            title: context.tr('wizard.propertyDocument'),
            subtitle: context.tr('wizard.propertyDocDesc'),
            fieldName: 'propertyDocument',
            currentValue: data.propertyDocument,
          ),

          const SizedBox(height: 24),

          _buildUploadSection(
            context,
            title: context.tr('wizard.hostIdentityCard'),
            subtitle: context.tr('wizard.hostIdDesc'),
            fieldName: 'hostIdentityCard',
            currentValue: data.hostIdentityCard,
          ),

          const SizedBox(height: 24),

          _buildOwnershipToggle(context, cubit, data.isPropertyOwner ?? true),

          if (!(data.isPropertyOwner ?? true)) ...[
            const SizedBox(height: 24),
            _buildUploadSection(
              context,
              title: context.tr('wizard.powerOfAttorney'),
              subtitle: context.tr('wizard.poaDesc'),
              fieldName: 'powerOfAttorney',
              currentValue: data.powerOfAttorney,
            ),
          ],
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildUploadSection(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String fieldName,
    required String? currentValue,
  }) {
    final isUploaded = currentValue != null && currentValue.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1D242B),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              context.tr('wizard.docOptional'),
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7280),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () => _pickDocument(context, fieldName),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFF0F2F5),
                style: BorderStyle.solid, // In real app use dotted_border package
              ),
            ),
            child: Column(
              children: [
                if (isUploaded) ...[
                  const Icon(Icons.check_circle, color: Colors.green, size: 40),
                  const SizedBox(height: 12),
                  Text(
                    currentValue.split('/').last,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF1D242B),
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  TextButton(
                    onPressed: () => context.read<ListingWizardCubit>().updateStepData({fieldName: null}),
                    child: Text(context.tr('wizard.changeDoc'), style: const TextStyle(color: AppColors.primaryColor)),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.upload_outlined,
                      color: Color(0xFF6B7280),
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.tr('wizard.clickToUpload'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1D242B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.tr('wizard.fileTypes'),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOwnershipToggle(BuildContext context, ListingWizardCubit cubit, bool isOwner) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0F2F5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('wizard.areYouOwner'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1D242B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.tr('wizard.areYouOwnerDesc'),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Switch.adaptive(
            value: isOwner,
            onChanged: (v) => cubit.updateStepData({'isPropertyOwner': v}),
            activeThumbColor: AppColors.primaryColor,
          ),
        ],
      ),
    );
  }
}
