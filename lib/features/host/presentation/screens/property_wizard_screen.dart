import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/features/host/cubit/listing_wizard_cubit.dart';
import 'package:houseiana_mobile_app/features/host/cubit/listing_wizard_state.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';
import 'package:houseiana_mobile_app/features/host/presentation/screens/wizard/step_01_property_type_screen.dart';
import 'package:houseiana_mobile_app/features/host/presentation/screens/wizard/step_03_location_screen.dart';
import 'package:houseiana_mobile_app/features/host/presentation/screens/wizard/step_04_basics_screen.dart';
import 'package:houseiana_mobile_app/features/host/presentation/screens/wizard/step_05_amenities_screen.dart';
import 'package:houseiana_mobile_app/features/host/presentation/screens/wizard/step_06_photos_screen.dart';
import 'package:houseiana_mobile_app/features/host/presentation/screens/wizard/step_07_title_screen.dart';
import 'package:houseiana_mobile_app/features/host/presentation/screens/wizard/step_09_discounts_screen.dart';
import 'package:houseiana_mobile_app/features/host/presentation/screens/wizard/step_10_policy_screen.dart';
import 'package:houseiana_mobile_app/features/host/presentation/screens/wizard/step_11_settings_screen.dart';
import 'package:houseiana_mobile_app/features/host/presentation/screens/wizard/step_12_documents_screen.dart';
import 'package:houseiana_mobile_app/features/host/presentation/screens/wizard/step_13_review_publish_screen.dart';
import 'package:houseiana_mobile_app/features/host/presentation/screens/wizard/step_10_house_rules_screen.dart';
import 'package:houseiana_mobile_app/features/host/presentation/screens/wizard/step_11_pricing_screen.dart';

class PropertyWizardScreen extends StatelessWidget {
  /// When provided, the wizard opens in EDIT mode: it prefills from the
  /// existing property and saves through the same draft endpoint with this id.
  final String? editPropertyId;

  const PropertyWizardScreen({super.key, this.editPropertyId});

  @override
  Widget build(BuildContext context) {
    final isEditing = editPropertyId != null && editPropertyId!.isNotEmpty;
    return BlocProvider(
      create: (_) {
        final cubit = ListingWizardCubit();
        if (isEditing) cubit.loadForEdit(editPropertyId!);
        return cubit;
      },
      child: _PropertyWizardView(isEditing: isEditing),
    );
  }
}

class _PropertyWizardView extends StatefulWidget {
  final bool isEditing;

  const _PropertyWizardView({this.isEditing = false});

  @override
  State<_PropertyWizardView> createState() => _PropertyWizardViewState();
}

class _PropertyWizardViewState extends State<_PropertyWizardView> {
  late PageController _pageController;
  // In edit mode, jump the PageView to the hydrated step exactly once.
  bool _editStepApplied = false;

  String _stepTitle(BuildContext context, int index) {
    return context.tr('wizard.stepTitle${index + 1}');
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ListingWizardCubit, ListingWizardState>(
      listener: (context, state) {
        // Single error handler for the whole wizard (draft saves + publish).
        // Success (publishedListingId) is owned by the review step's dialog to
        // avoid a double-navigation / double-snackbar race.
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error!),
              backgroundColor: AppColors.error,
            ),
          );
        }
        // Edit mode: once prefill finishes, move the PageView to the saved step.
        if (widget.isEditing && !state.isHydrating && !_editStepApplied) {
          _editStepApplied = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || !_pageController.hasClients) return;
            if (_pageController.page?.round() != state.currentStep) {
              _pageController.jumpToPage(state.currentStep);
            }
          });
        }
      },
      builder: (context, state) {
        final cubit = context.read<ListingWizardCubit>();

        if (state.isHydrating) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primaryColor),
            ),
          );
        }

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: AppColors.charcoal),
              // Block exiting mid-save/publish to avoid losing an in-flight write.
              onPressed: (state.isSavingDraft || state.isPublishing)
                  ? null
                  : () => _showExitDialog(context),
            ),
            title: Text(
              _stepTitle(context, state.currentStep),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.charcoal,
              ),
            ),
            centerTitle: true,
            actions: [
              TextButton(
                onPressed: () async {
                  await cubit.saveDraft();
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
                child: state.isSavingDraft
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primaryColor,
                        ),
                      )
                    : Text(
                        context.tr('wizard.saveAndExit'),
                        style: const TextStyle(
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ],
          ),
          body: Column(
            children: [
              _buildProgressBar(state),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) => cubit.goToStep(index),
                  children: const [
                    Step01PropertyTypeScreen(),
                    Step03LocationScreen(),
                    Step04BasicsScreen(),
                    Step05AmenitiesScreen(),
                    Step10HouseRulesScreen(),
                    Step06PhotosScreen(),
                    Step07TitleScreen(),
                    Step11PricingScreen(),
                    Step09DiscountsScreen(),
                    Step10PolicyScreen(),
                    Step11SettingsScreen(),
                    Step12DocumentsScreen(),
                    Step13ReviewPublishScreen(),
                  ],
                ),
              ),
              _buildNavigationButtons(context, state),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressBar(ListingWizardState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              const Spacer(),
              Text(
                context.tr('wizard.stepProgress', args: {
                  'n': state.currentStep + 1,
                  'total': state.totalSteps,
                }),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.neutral700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(state.totalSteps, (index) {
              final isCompleted = index <= state.currentStep;
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: index == state.totalSteps - 1 ? 0 : 8),
                  decoration: BoxDecoration(
                    color: isCompleted ? AppColors.primaryColor : AppColors.neutral200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(
      BuildContext context, ListingWizardState state) {
    final cubit = context.read<ListingWizardCubit>();
    final isLast = state.isLastStep;
    final busy = state.isSavingDraft || state.isPublishing;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (state.canGoBack)
            Expanded(
              child: OutlinedButton(
                onPressed: busy
                    ? null
                    : () {
                        cubit.previousStep();
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.charcoal,
                  side: const BorderSide(color: AppColors.neutral300),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(context.tr('wizard.wizardBack')),
              ),
            ),
          if (state.canGoBack) const SizedBox(width: 12),
          Expanded(
            flex: state.canGoBack ? 1 : 2,
            child: ElevatedButton(
              onPressed: busy
                  ? null
                  : () async {
                      // Last step: finalize/publish (web parity: the footer's
                      // primary button becomes the submit action on review).
                      if (isLast) {
                        await cubit.publishListing();
                        return;
                      }
                      final validationError =
                          cubit.validateStepForContinue(state.currentStep);
                      if (validationError != null) {
                        if (state.currentStep == 7) {
                          // Pricing step: show field-level inline error
                          // near the price input instead of a snackbar.
                          cubit.setBasePriceError(validationError);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(validationError),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                        return;
                      }
                      // Await so draftId is saved in state before the next
                      // draft call (backend requires propertyId when StepDraft > 1).
                      final success = await cubit.saveDraft();
                      if (!context.mounted) return;
                      if (!success) {
                        // Don't advance — error is already shown via BlocListener
                        return;
                      }
                      cubit.nextStep();
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      isLast
                          ? context.tr(widget.isEditing
                              ? 'wizard.editList'
                              : 'wizard.createList')
                          : context.tr('wizard.wizardContinue'),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _showExitDialog(BuildContext context) {
    // Mode-aware copy: in edit mode the listing already exists (it is NOT a
    // draft), and this X path does not save — so warn about discarding unsaved
    // changes rather than falsely claiming a draft was saved.
    final titleKey =
        widget.isEditing ? 'wizard.exitEditTitle' : 'wizard.exitWizardTitle';
    final descKey =
        widget.isEditing ? 'wizard.exitEditDesc' : 'wizard.exitWizardDesc';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr(titleKey)),
        content: Text(context.tr(descKey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.tr('wizard.wizardCancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: Text(context.tr('wizard.wizardExit')),
          ),
        ],
      ),
    );
  }
}
