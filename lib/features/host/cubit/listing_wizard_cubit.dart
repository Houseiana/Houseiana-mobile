import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:houseiana_mobile_app/core/services/host_service.dart';
import 'package:houseiana_mobile_app/features/host/cubit/listing_wizard_state.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart'
    as houseiana_mobile_app;

final sl = GetIt.instance;

class ListingWizardCubit extends Cubit<ListingWizardState> {
  final _hostService = sl<HostService>();

  ListingWizardCubit() : super(ListingWizardState.initial());

  void goToStep(int step) {
    if (step >= 0 && step < state.totalSteps) {
      emit(state.copyWith(
        currentStep: step,
        clearError: true,
        clearBasePriceError: true,
      ));
    }
  }

  void nextStep() {
    if (!state.isLastStep) {
      emit(state.copyWith(
        currentStep: state.currentStep + 1,
        clearError: true,
        clearBasePriceError: true,
      ));
    }
  }

  void previousStep() {
    if (state.canGoBack) {
      emit(state.copyWith(
        currentStep: state.currentStep - 1,
        clearError: true,
        clearBasePriceError: true,
      ));
    }
  }

  void setBasePriceError(String message) {
    emit(state.copyWith(basePriceError: message));
  }

  void clearBasePriceError() {
    emit(state.copyWith(clearBasePriceError: true));
  }

  void updateData(WizardData data) {
    emit(state.copyWith(data: data));
  }

  void updateStepData(Map<String, dynamic> data) {
    final newBasePrice = (data['basePrice'] as num?)?.toDouble();
    final shouldClearBasePriceError = state.basePriceError != null &&
        newBasePrice != null &&
        newBasePrice >= 1000;
    emit(state.copyWith(
      clearBasePriceError: shouldClearBasePriceError,
      data: state.data.copyWith(
        propertyType:
            data['propertyType'] as String? ?? state.data.propertyType,
        propertyKind:
            data['propertyKind'] as String? ?? state.data.propertyKind,
        latitude: data['latitude'] as double? ?? state.data.latitude,
        longitude: data['longitude'] as double? ?? state.data.longitude,
        address: data['address'] as String? ?? state.data.address,
        city: data['city'] as String? ?? state.data.city,
        country: data['country'] as String? ?? state.data.country,
        stateProvince:
            data['stateProvince'] as String? ?? state.data.stateProvince,
        district: data['district'] as String? ?? state.data.district,
        village: data['village'] as String? ?? state.data.village,
        buildingNumber:
            data['buildingNumber'] as String? ?? state.data.buildingNumber,
        floorNumber: data['floorNumber'] as String? ?? state.data.floorNumber,
        unitNumber: data['unitNumber'] as String? ?? state.data.unitNumber,
        postalCode: data['postalCode'] as String? ?? state.data.postalCode,
        bedrooms: data['bedrooms'] as int? ?? state.data.bedrooms,
        bathrooms: data['bathrooms'] as int? ?? state.data.bathrooms,
        beds: data['beds'] as int? ?? state.data.beds,
        maxGuests: data['maxGuests'] as int? ?? state.data.maxGuests,
        totalArea: data['totalArea'] as double? ?? state.data.totalArea,
        amenities: data['amenities'] != null
            ? (data['amenities'] as List<String>)
            : state.data.amenities,
        photos: data['photos'] != null
            ? (data['photos'] as List<String>)
            : state.data.photos,
        title: data['title'] as String? ?? state.data.title,
        description: data['description'] as String? ?? state.data.description,
        highlights: data['highlights'] != null
            ? (data['highlights'] as List<int>)
            : state.data.highlights,
        houseRules: data['houseRules'] != null
            ? (data['houseRules'] as List<String>)
            : state.data.houseRules,
        allowPets: data['allowPets'] as bool? ?? state.data.allowPets,
        allowSmoking: data['allowSmoking'] as bool? ?? state.data.allowSmoking,
        allowEvents: data['allowEvents'] as bool? ?? state.data.allowEvents,
        allowGuests: data['allowGuests'] as bool? ?? state.data.allowGuests,
        marriedCouplesOnly:
            data['marriedCouplesOnly'] as bool? ?? state.data.marriedCouplesOnly,
        checkInTime: data['checkInTime'] as String? ?? state.data.checkInTime,
        checkOutTime: data['checkOutTime'] as String? ?? state.data.checkOutTime,
        basePrice: (data['basePrice'] as num?)?.toDouble() ?? state.data.basePrice,
        cleaningFee: (data['cleaningFee'] as num?)?.toDouble() ?? state.data.cleaningFee,
        serviceFeePercent: (data['serviceFeePercent'] as num?)?.toDouble() ??
            state.data.serviceFeePercent,
        weeklyDiscountPercent: (data['weeklyDiscountPercent'] as num?)?.toDouble() ??
            state.data.weeklyDiscountPercent,
        newListingDiscountPercent:
            (data['newListingDiscountPercent'] as num?)?.toDouble() ??
                state.data.newListingDiscountPercent,
        cancellationPolicyType: data['cancellationPolicyType'] as String? ??
            state.data.cancellationPolicyType,
        freeCancellationHours: data['freeCancellationHours'] as int? ??
            state.data.freeCancellationHours,
        freeCancellationDays: data['freeCancellationDays'] as int? ??
            state.data.freeCancellationDays,
        primaryPhone: data['primaryPhone'] as String? ?? state.data.primaryPhone,
        emergencyPhone:
            data['emergencyPhone'] as String? ?? state.data.emergencyPhone,
        instantBook: data['instantBook'] as bool? ?? state.data.instantBook,
        hasSecurityCameras: data['hasSecurityCameras'] as bool? ??
            state.data.hasSecurityCameras,
        hasNoiseMonitors:
            data['hasNoiseMonitors'] as bool? ?? state.data.hasNoiseMonitors,
        propertyDocument:
            data['propertyDocument'] as String? ?? state.data.propertyDocument,
        hostIdentityCard:
            data['hostIdentityCard'] as String? ?? state.data.hostIdentityCard,
        powerOfAttorney:
            data['powerOfAttorney'] as String? ?? state.data.powerOfAttorney,
        isPropertyOwner:
            data['isPropertyOwner'] as bool? ?? state.data.isPropertyOwner,
        stars: data['stars'] as int? ?? state.data.stars,
        electricalFee: (data['electricalFee'] as num?)?.toDouble() ??
            state.data.electricalFee,
        waterFee:
            (data['waterFee'] as num?)?.toDouble() ?? state.data.waterFee,
        availabilityType:
            data['availabilityType'] as String? ?? state.data.availabilityType,
        minimumNights:
            data['minimumNights'] as int? ?? state.data.minimumNights,
        maximumNights:
            data['maximumNights'] as int? ?? state.data.maximumNights,
        availableDates: data['availableDates'] != null
            ? (data['availableDates'] as List<DateTime>)
            : state.data.availableDates,
      ),
    ));
  }

  void setError(String error) {
    emit(state.copyWith(error: error));
  }

  void clearError() {
    emit(state.copyWith(clearError: true));
  }

  void startPublishing() {
    emit(state.copyWith(isPublishing: true, clearError: true));
  }

  void finishPublishing(String listingId) {
    emit(state.copyWith(isPublishing: false, publishedListingId: listingId));
  }

  void publishingFailed(String error) {
    emit(state.copyWith(isPublishing: false, error: error));
  }

  void startSavingDraft() {
    emit(state.copyWith(isSavingDraft: true));
  }

  void finishSavingDraft(String? draftId) {
    emit(state.copyWith(isSavingDraft: false, draftId: draftId));
  }

  void draftSaveFailed() {
    emit(state.copyWith(isSavingDraft: false));
  }

  void startUploadingPhotos() {
    emit(state.copyWith(isUploadingPhotos: true));
  }

  void finishUploadingPhotos(List<String> urls) {
    emit(state.copyWith(
      isUploadingPhotos: false,
      clearError: true,
      data: state.data.copyWith(photos: [...state.data.photos, ...urls]),
    ));
  }

  void removePhotoAt(int index) {
    if (index < 0 || index >= state.data.photos.length) return;

    final updatedPhotos = [...state.data.photos]..removeAt(index);
    emit(
      state.copyWith(
        clearError: true,
        data: state.data.copyWith(photos: updatedPhotos),
      ),
    );
  }

  void setCoverPhoto(String path) {
    emit(
      state.copyWith(
        clearError: true,
        data: state.data.copyWith(coverPhoto: path),
      ),
    );
  }

  void removeCoverPhoto() {
    emit(
      state.copyWith(
        data: state.data.copyWith(clearCoverPhoto: true),
      ),
    );
  }

  String? validateStepForContinue(int step) {
    switch (step) {
      case 0:
        if (state.data.propertyType == null) {
          return 'Property Type is required.';
        }
        break;
      case 1: // Location
        if (state.data.address == null || state.data.address!.isEmpty) {
          return 'Address is required.';
        }
        if (state.data.city == null || state.data.city!.isEmpty) {
          return 'City is required.';
        }
        break;
      case 2: // Basics
        if (state.data.maxGuests == null) {
          return 'Number of guests is required.';
        }
        if (state.data.bedrooms == null) {
          return 'Number of bedrooms is required.';
        }
        if (state.data.beds == null) {
          return 'Number of beds is required.';
        }
        if (state.data.bathrooms == null) {
          return 'Number of bathrooms is required.';
        }
        if (state.data.totalArea == null || state.data.totalArea! < 25 || state.data.totalArea! > 3000) {
          return 'Total area must be between 25 and 3000 m².';
        }
        break;
      case 3: // Amenities
        if (state.data.amenities.isEmpty) {
          return 'At least 1 amenity is required.';
        }
        break;
      case 4: // House Rules
        if (state.data.checkInTime == null || state.data.checkInTime!.isEmpty) {
          return 'Check-in time is required.';
        }
        if (state.data.checkOutTime == null || state.data.checkOutTime!.isEmpty) {
          return 'Check-out time is required.';
        }
        break;
      case 5: // Photos
        if (state.data.photos.length < 5) {
          final remaining = 5 - state.data.photos.length;
          return 'Please upload at least 5 photos. Add $remaining more to continue.';
        }
        break;
      case 6: // Title, Description & Highlights
        if (state.data.title == null || state.data.title!.trim().isEmpty) {
          return 'Title is required.';
        }
        if (state.data.description == null ||
            state.data.description!.trim().isEmpty) {
          return 'Description is required.';
        }
        if (state.data.highlights.isEmpty) {
          return 'At least 1 highlight is required.';
        }
        break;
      case 7: // Pricing (shifted)
        if (state.data.basePrice == null || state.data.basePrice! < 1000) {
          return 'Minimum base price is 1000 EGP.';
        }
        break;
    }
    return null;
  }

  void reset() {
    emit(ListingWizardState.initial());
  }

  /// Loads an existing property into the wizard for EDITING, mirroring the web
  /// edit flow: prefill from GET /api/properties/{id}, then save through the
  /// same POST /api/properties/draft (it upserts when a propertyId is present).
  /// Seeds [draftId] so every subsequent saveDraft/publish targets this
  /// property, and lands on the saved step (or the review step if unknown).
  Future<void> loadForEdit(String propertyId) async {
    emit(state.copyWith(isHydrating: true, draftId: propertyId, clearError: true));
    try {
      final raw = await _hostService.getPropertyForEdit(propertyId);
      final data = WizardData.fromApiJson(raw, base: state.data);

      // Backend step is 1-based (1..13); the UI is 0-based (0..12).
      final stepDraft = (raw['stepDraft'] as num?)?.toInt();
      final initialStep = (stepDraft != null && stepDraft > 0)
          ? (stepDraft - 1).clamp(0, state.totalSteps - 1)
          : state.totalSteps - 1; // jump to Review when the step is unknown

      emit(state.copyWith(
        data: data,
        draftId: propertyId,
        currentStep: initialStep,
        isHydrating: false,
      ));
    } catch (e) {
      // ignore: avoid_print
      print('[ListingWizardCubit.loadForEdit] error: $e');
      emit(state.copyWith(isHydrating: false));
      setError('Failed to load property for editing: $e');
    }
  }

  /// Auto-recovery: If we somehow lost the draftId (e.g., hot reload or caching),
  /// this creates a fresh draft silently to get a valid ID before proceeding.
  Future<String> _ensureDraftId(String hostId) async {
    if (state.draftId != null && state.draftId!.isNotEmpty) {
      return state.draftId!;
    }
    // ignore: avoid_print
    print('⚠️ AUTO-RECOVER: Creating initial draft to obtain PropertyId...');
    final initPayload =
        state.data.toApiMap(hostId: hostId, currentStep: 0, propertyId: null);
    final response = await _hostService.saveDraft(initPayload);
    final newId = _extractId(response);

    if (newId == null || newId.isEmpty) {
      throw Exception("Auto-recover failed: Backend didn't return an ID.");
    }
    // Quietly update the state so we have it permanently
    emit(state.copyWith(draftId: newId));
    return newId;
  }

  /// Returns true if the draft was saved successfully.
  Future<bool> saveDraft() async {
    startSavingDraft();
    try {
      final hostId = sl<houseiana_mobile_app.UserSession>().userId ?? '';

      // RADICAL FIX: Force creation of an ID if it's missing and we're past step 0
      String? safePropertyId = state.draftId;
      if (state.currentStep > 0 && safePropertyId == null) {
        safePropertyId = await _ensureDraftId(hostId);
      }

      final payload = state.data.toApiMap(
        hostId: hostId,
        currentStep: state.currentStep,
        propertyId: safePropertyId,
      );

      // --- Pretty print the payload as JSON ---
      final encoder = const JsonEncoder.withIndent('  ');
      final prettyJson = encoder.convert(payload);
      // ignore: avoid_print
      print('\n======================================================');
      // ignore: avoid_print
      print('🚀 [API REQUEST] POST /api/properties/draft');
      // ignore: avoid_print
      print(
          '📤 PAYLOAD (UI Step ${state.currentStep}, StepDraft: ${payload['stepDraft']}):\n$prettyJson');
      // ignore: avoid_print
      print('======================================================\n');

      final response = await _hostService.saveDraft(payload);

      // ignore: avoid_print
      print('[ListingWizardCubit.saveDraft] raw response: $response');

      final draftId = _extractId(response);

      // ignore: avoid_print
      print(
          '[ListingWizardCubit.saveDraft] extracted draftId=$draftId  (prev: $safePropertyId)');

      // Preserve existing draftId on subsequent steps if API doesn't return one
      finishSavingDraft(draftId ?? safePropertyId);
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('[ListingWizardCubit.saveDraft] error: $e');
      draftSaveFailed();
      setError('Failed to save draft: $e');
      return false;
    }
  }

  /// Extracts the ID from the response, handling various possible backend formats
  /// (nested 'data', top-level, camelCase, PascalCase, direct string).
  String? _extractId(Map<String, dynamic>? raw) {
    if (raw == null) return null;

    // Create a case-insensitive map
    final lowerRaw =
        raw.map((key, value) => MapEntry(key.toLowerCase(), value));

    // 1. Check if it's nested under 'data' (or 'Data')
    final nested = lowerRaw['data'];
    if (nested != null) {
      if (nested is String && nested.isNotEmpty) {
        // Backend returned { "data": "the-guid-id" }
        return nested;
      }
      if (nested is Map) {
        final lowerNested = nested
            .map((key, value) => MapEntry(key.toString().toLowerCase(), value));
        final id = lowerNested['id']?.toString() ??
            lowerNested['_id']?.toString() ??
            lowerNested['propertyid']?.toString();
        if (id != null && id.isNotEmpty) return id;
      }
    }

    // 2. Fallback to top-level fields
    return lowerRaw['id']?.toString() ??
        lowerRaw['_id']?.toString() ??
        lowerRaw['propertyid']?.toString();
  }

  Future<void> publishListing() async {
    final publishValidationError = validateStepForContinue(4);
    if (publishValidationError != null) {
      setError(publishValidationError);
      return;
    }

    startPublishing();
    try {
      final hostId = sl<houseiana_mobile_app.UserSession>().userId ?? '';

      // RADICAL FIX: Ensure we ALWAYS have an ID before publishing
      String? safePropertyId = state.draftId;
      safePropertyId ??= await _ensureDraftId(hostId);

      // ULTIMATE RADICAL FIX: The backend strictly enforces step progression and payload correctness.
      // We forcefully loop through all backend StepDrafts (1 to 13) sequentially.
      // ignore: avoid_print
      print(
          '🚀 [FORCE SYNC] Synchronizing all steps sequentially to satisfy backend...');

      for (int step = 0; step < 13; step++) {
        final payload = state.data.toApiMap(
            hostId: hostId, currentStep: step, propertyId: safePropertyId);

        if (step == 12) {
          // Final publish step (stepDraft 13)
          final encoder = const JsonEncoder.withIndent('  ');
          final prettyJson = encoder.convert(payload);
          // ignore: avoid_print
          print('\n======================================================');
          // ignore: avoid_print
          print(
              '🚀 [API REQUEST] POST /api/properties/draft (FINAL PUBLISH STEP)');
          // ignore: avoid_print
          print('📤 PAYLOAD:\n$prettyJson');
          // ignore: avoid_print
          print('======================================================\n');
        } else {
          // ignore: avoid_print
          print('🔄 Syncing UI Step $step (stepDraft: ${step + 1})...');
        }

        final response = await _hostService.saveDraft(payload);
        final newId = _extractId(response);
        if (newId != null && newId.isNotEmpty) {
          safePropertyId = newId;
        }
      }

      finishPublishing(safePropertyId ?? '');
    } catch (e) {
      publishingFailed(e.toString());
    }
  }

  Future<void> uploadPhoto(String filePath) async {
    finishUploadingPhotos([filePath]);
  }
}
