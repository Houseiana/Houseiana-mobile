import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/theme/app_radius.dart';
import 'package:houseiana_mobile_app/core/theme/app_spacing.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

class PaymobPhoneBottomSheet extends StatefulWidget {
  const PaymobPhoneBottomSheet({super.key});

  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PaymobPhoneBottomSheet(),
    );
  }

  @override
  State<PaymobPhoneBottomSheet> createState() => _PaymobPhoneBottomSheetState();
}

class _PaymobPhoneBottomSheetState extends State<PaymobPhoneBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _validate(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return context.tr('booking.paymobPhoneRequired');
    }
    if (trimmed.length < 10 || trimmed.length > 15) {
      return context.tr('booking.paymobPhoneInvalid');
    }
    return null;
  }

  void _onConfirm() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.pop(context, _controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.bottomSheetTopRadius,
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.neutral300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              AppSpacing.verticalSpaceLg,
              Text(
                context.tr('booking.paymobPhoneTitle'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.charcoal,
                ),
              ),
              AppSpacing.verticalSpaceSm,
              Text(
                context.tr('booking.paymobPhoneSubtitle'),
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.neutral600,
                ),
              ),
              AppSpacing.verticalSpaceLg,
              TextFormField(
                controller: _controller,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(15),
                ],
                autofocus: true,
                validator: _validate,
                decoration: InputDecoration(
                  hintText: context.tr('booking.paymobPhoneHint'),
                  prefixIcon: const Icon(
                    Icons.phone_outlined,
                    color: AppColors.neutral500,
                  ),
                  filled: true,
                  fillColor: AppColors.neutral100,
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.inputRadiusAll,
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppRadius.inputRadiusAll,
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppRadius.inputRadiusAll,
                    borderSide: const BorderSide(
                      color: AppColors.primaryColor,
                      width: 1.5,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: AppRadius.inputRadiusAll,
                    borderSide: const BorderSide(
                      color: AppColors.error,
                      width: 1,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: AppRadius.inputRadiusAll,
                    borderSide: const BorderSide(
                      color: AppColors.error,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              AppSpacing.verticalSpaceLg,
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, null),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                        side: const BorderSide(color: AppColors.neutral300),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.buttonRadiusAll,
                        ),
                      ),
                      child: Text(
                        context.tr('common.cancel'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.charcoal,
                        ),
                      ),
                    ),
                  ),
                  AppSpacing.horizontalSpaceMd,
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _onConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: AppColors.charcoal,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.buttonRadiusAll,
                        ),
                      ),
                      child: Text(
                        context.tr('common.confirm'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
