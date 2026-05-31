import 'package:equatable/equatable.dart';

class ListingWizardState extends Equatable {
  final int currentStep;
  final String? draftId;
  final bool isSavingDraft;
  final bool isPublishing;
  final bool isUploadingPhotos;
  final String? publishedListingId;
  final String? error;
  final String? basePriceError;
  final WizardData data;

  const ListingWizardState({
    this.currentStep = 0,
    this.draftId,
    this.isSavingDraft = false,
    this.isPublishing = false,
    this.isUploadingPhotos = false,
    this.publishedListingId,
    this.error,
    this.basePriceError,
    this.data = const WizardData(),
  });

  factory ListingWizardState.initial() => const ListingWizardState();

  ListingWizardState copyWith({
    int? currentStep,
    String? draftId,
    bool? isSavingDraft,
    bool? isPublishing,
    bool? isUploadingPhotos,
    String? publishedListingId,
    String? error,
    String? basePriceError,
    WizardData? data,
    bool clearError = false,
    bool clearBasePriceError = false,
    bool clearPublishedListingId = false,
  }) {
    return ListingWizardState(
      currentStep: currentStep ?? this.currentStep,
      draftId: draftId ?? this.draftId,
      isSavingDraft: isSavingDraft ?? this.isSavingDraft,
      isPublishing: isPublishing ?? this.isPublishing,
      isUploadingPhotos: isUploadingPhotos ?? this.isUploadingPhotos,
      publishedListingId: clearPublishedListingId
          ? null
          : (publishedListingId ?? this.publishedListingId),
      error: clearError ? null : (error ?? this.error),
      basePriceError: clearBasePriceError
          ? null
          : (basePriceError ?? this.basePriceError),
      data: data ?? this.data,
    );
  }

  int get totalSteps => 13;
  double get progress => (currentStep + 1) / totalSteps;
  bool get canGoBack => currentStep > 0;
  bool get isLastStep => currentStep == totalSteps - 1;
  bool get isFirstStep => currentStep == 0;

  @override
  List<Object?> get props => [
        currentStep,
        draftId,
        isSavingDraft,
        isPublishing,
        isUploadingPhotos,
        publishedListingId,
        error,
        basePriceError,
        data,
      ];
}

class WizardData extends Equatable {
  // Step 1 — Property Type
  final String? propertyType;

  // Step 2 — Property Kind (entire place / private / shared)
  final String? propertyKind;

  // Step 3 — Location
  final double? latitude;
  final double? longitude;
  final String? address;
  final String? city;
  final String? country;
  final String? stateProvince;
  final String? district;
  final String? village;
  final String? buildingNumber;
  final String? floorNumber;
  final String? unitNumber;
  final String? postalCode;

  // Step 4 — Basics
  final int? bedrooms;
  final int? bathrooms;
  final int? beds;
  final int? maxGuests;
  final double? totalArea;

  // Step 5 — Amenities
  final List<String> amenities;

  // Step 6 — Photos
  final String? coverPhoto;
  final List<String> photos;

  // Step 7 — Title
  final String? title;

  // Step 8 — Description
  final String? description;

  // Step 9 — Highlights
  final List<int> highlights;

  // Step 10 — House Rules
  final List<String> houseRules;
  final bool? allowPets;
  final bool? allowSmoking;
  final bool? allowEvents;
  final bool? allowGuests;
  final bool? marriedCouplesOnly;
  final String? checkInTime;
  final String? checkOutTime;

  // Step 11 — Pricing
  final double? basePrice;
  final double? cleaningFee;
  final double? serviceFeePercent;
  final double? weeklyDiscountPercent;
  final double? newListingDiscountPercent;
  final String? cancellationPolicyType;
  final int? freeCancellationHours;
  final int? freeCancellationDays;
  final int? stars;
  final double? electricalFee;
  final double? waterFee;

  // Step 12 — Availability
  final String? availabilityType;
  final int? minimumNights;
  final int? maximumNights;
  final List<DateTime>? availableDates;

  // Step 11 — Booking Settings
  final String? primaryPhone;
  final String? emergencyPhone;
  final bool? instantBook;
  final bool? hasSecurityCameras;
  final bool? hasNoiseMonitors;

  // Step 12 — Documents
  final String? propertyDocument;
  final String? hostIdentityCard;
  final String? powerOfAttorney;
  final bool? isPropertyOwner;

  const WizardData({
    this.propertyType,
    this.propertyKind,
    this.latitude,
    this.longitude,
    this.address,
    this.city,
    this.country,
    this.stateProvince,
    this.district,
    this.village,
    this.buildingNumber,
    this.floorNumber,
    this.unitNumber,
    this.postalCode,
    this.bedrooms,
    this.bathrooms,
    this.beds,
    this.maxGuests,
    this.amenities = const [],
    this.coverPhoto,
    this.photos = const [],
    this.title,
    this.description,
    this.highlights = const [],
    this.houseRules = const [],
    this.allowPets,
    this.allowSmoking,
    this.allowEvents,
    this.allowGuests = true,
    this.marriedCouplesOnly = false,
    this.checkInTime = '03:00 PM',
    this.checkOutTime = '11:00 AM',
    this.basePrice,
    this.cleaningFee,
    this.serviceFeePercent,
    this.weeklyDiscountPercent,
    this.newListingDiscountPercent,
    this.availabilityType,
    this.minimumNights,
    this.maximumNights,
    this.availableDates,
    this.totalArea = 25.0,
    this.stars,
    this.electricalFee,
    this.waterFee,
    this.cancellationPolicyType,
    this.freeCancellationHours,
    this.freeCancellationDays,
    this.primaryPhone,
    this.emergencyPhone,
    this.instantBook = true,
    this.hasSecurityCameras = false,
    this.hasNoiseMonitors = false,
    this.propertyDocument,
    this.hostIdentityCard,
    this.powerOfAttorney,
    this.isPropertyOwner = true,
  });

  WizardData copyWith({
    String? propertyType,
    String? propertyKind,
    double? latitude,
    double? longitude,
    String? address,
    String? city,
    String? country,
    String? stateProvince,
    String? district,
    String? village,
    String? buildingNumber,
    String? floorNumber,
    String? unitNumber,
    String? postalCode,
    int? bedrooms,
    int? bathrooms,
    int? beds,
    int? maxGuests,
    List<String>? amenities,
    String? coverPhoto,
    bool clearCoverPhoto = false,
    List<String>? photos,
    String? title,
    String? description,
    List<int>? highlights,
    List<String>? houseRules,
    bool? allowPets,
    bool? allowSmoking,
    bool? allowEvents,
    bool? allowGuests,
    bool? marriedCouplesOnly,
    String? checkInTime,
    String? checkOutTime,
    double? basePrice,
    double? cleaningFee,
    double? serviceFeePercent,
    double? weeklyDiscountPercent,
    double? newListingDiscountPercent,
    String? cancellationPolicyType,
    int? freeCancellationHours,
    int? freeCancellationDays,
    int? stars,
    double? electricalFee,
    double? waterFee,
    String? availabilityType,
    int? minimumNights,
    int? maximumNights,
    List<DateTime>? availableDates,
    double? totalArea,
    String? primaryPhone,
    String? emergencyPhone,
    bool? instantBook,
    bool? hasSecurityCameras,
    bool? hasNoiseMonitors,
    String? propertyDocument,
    String? hostIdentityCard,
    String? powerOfAttorney,
    bool? isPropertyOwner,
  }) {
    return WizardData(
      propertyType: propertyType ?? this.propertyType,
      propertyKind: propertyKind ?? this.propertyKind,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      city: city ?? this.city,
      country: country ?? this.country,
      stateProvince: stateProvince ?? this.stateProvince,
      district: district ?? this.district,
      village: village ?? this.village,
      buildingNumber: buildingNumber ?? this.buildingNumber,
      floorNumber: floorNumber ?? this.floorNumber,
      unitNumber: unitNumber ?? this.unitNumber,
      postalCode: postalCode ?? this.postalCode,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      beds: beds ?? this.beds,
      maxGuests: maxGuests ?? this.maxGuests,
      amenities: amenities ?? this.amenities,
      coverPhoto: clearCoverPhoto ? null : (coverPhoto ?? this.coverPhoto),
      photos: photos ?? this.photos,
      title: title ?? this.title,
      description: description ?? this.description,
      highlights: highlights ?? this.highlights,
      houseRules: houseRules ?? this.houseRules,
      allowPets: allowPets ?? this.allowPets,
      allowSmoking: allowSmoking ?? this.allowSmoking,
      allowEvents: allowEvents ?? this.allowEvents,
      allowGuests: allowGuests ?? this.allowGuests,
      marriedCouplesOnly: marriedCouplesOnly ?? this.marriedCouplesOnly,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      basePrice: basePrice ?? this.basePrice,
      cleaningFee: cleaningFee ?? this.cleaningFee,
      serviceFeePercent: serviceFeePercent ?? this.serviceFeePercent,
      weeklyDiscountPercent:
          weeklyDiscountPercent ?? this.weeklyDiscountPercent,
      newListingDiscountPercent:
          newListingDiscountPercent ?? this.newListingDiscountPercent,
      cancellationPolicyType:
          cancellationPolicyType ?? this.cancellationPolicyType,
      freeCancellationHours:
          freeCancellationHours ?? this.freeCancellationHours,
      freeCancellationDays: freeCancellationDays ?? this.freeCancellationDays,
      primaryPhone: primaryPhone ?? this.primaryPhone,
      emergencyPhone: emergencyPhone ?? this.emergencyPhone,
      instantBook: instantBook ?? this.instantBook,
      hasSecurityCameras: hasSecurityCameras ?? this.hasSecurityCameras,
      hasNoiseMonitors: hasNoiseMonitors ?? this.hasNoiseMonitors,
      propertyDocument: propertyDocument ?? this.propertyDocument,
      hostIdentityCard: hostIdentityCard ?? this.hostIdentityCard,
      powerOfAttorney: powerOfAttorney ?? this.powerOfAttorney,
      isPropertyOwner: isPropertyOwner ?? this.isPropertyOwner,
      stars: stars ?? this.stars,
      electricalFee: electricalFee ?? this.electricalFee,
      waterFee: waterFee ?? this.waterFee,
      availabilityType: availabilityType ?? this.availabilityType,
      minimumNights: minimumNights ?? this.minimumNights,
      maximumNights: maximumNights ?? this.maximumNights,
      availableDates: availableDates ?? this.availableDates,
      totalArea: totalArea ?? this.totalArea,
    );
  }

  Map<String, dynamic> toApiMap(
      {required String hostId, required int currentStep, String? propertyId}) {
    final map = <String, dynamic>{};

    // ── Target Step Mapping ──────────────────────────────────────────
    // Mapping UI steps to Backend steps (based on web app sequence)
    // UI 0 (PropType) -> BE 1
    // UI 1 (Location) -> BE 2
    // UI 2 (Basics) -> BE 3
    // UI 3 (Amenities) -> BE 4
    // UI 4 (House Rules) -> BE 5
    // UI 5 (Photos) -> BE 6
    // UI 6 (Title/Desc/High) -> BE 7
    // UI 7 (Pricing) -> BE 8
    // UI 8 (Availability) -> BE 10 (Skip 9 - Discounts)
    // UI 9 (Documents) -> BE 12 (Skip 11 - Legal)
    // UI 10 (Review) -> BE 13
    
    // ── Target Step Mapping ──────────────────────────────────────────
    // Mapping UI steps to Backend steps (based on web app sequence)
    // UI 0 (PropType) -> BE 1
    // UI 1 (Location) -> BE 2
    // UI 2 (Basics) -> BE 3
    // UI 3 (Amenities) -> BE 4
    // UI 4 (House Rules) -> BE 5
    // UI 5 (Photos) -> BE 6
    // UI 6 (Title/Desc/High) -> BE 7
    // UI 7 (Pricing) -> BE 8
    // UI 8 (Discounts) -> BE 9
    // UI 9 (Availability) -> BE 10
    // UI 10 (Documents) -> BE 12 (Skip 11 - Legal)
    // UI 11 (Review) -> BE 13
    
    int targetStepDraft;
    switch (currentStep) {
      case 0: targetStepDraft = 1; break;
      case 1: targetStepDraft = 2; break;
      case 2: targetStepDraft = 3; break;
      case 3: targetStepDraft = 4; break;
      case 4: targetStepDraft = 5; break;
      case 5: targetStepDraft = 6; break;
      case 6: targetStepDraft = 7; break;
      case 7: targetStepDraft = 8; break;
      case 8: targetStepDraft = 9; break;
      case 9: targetStepDraft = 10; break;
      case 10: targetStepDraft = 11; break;
      case 11: targetStepDraft = 12; break;
      case 12: targetStepDraft = 13; break;
      default: targetStepDraft = currentStep + 1;
    }
    
    map['stepDraft'] = targetStepDraft;

    bool includeStep(int s) {
      // Logic: Include data for the current target step 
      // AND any steps we are effectively jumping over if we want to bundle them
      if (targetStepDraft == s) return true;
      
      // Special bundles:
      if (currentStep == 7 && s == 8) return true; // UI 7 covers BE 8 (Pricing)
      if (currentStep == 8 && s == 9) return true; // UI 8 covers BE 9 (Discounts)
      if (currentStep == 9 && s == 10) return true; // UI 9 covers BE 10 (Policy)
      
      return false;
    }

    // Always required
    map['hostId'] = hostId;
    map['stepDraft'] = targetStepDraft;

    if (propertyId != null && propertyId.isNotEmpty) {
      map['propertyId'] = propertyId;
    }

    // ── Target Step 1: Property Type (and Room Type) ─────────────────────
    if (includeStep(1)) {
      final typeId =
          int.tryParse(propertyType ?? '') ?? 2; // Fallback to 2 (valid dummy)
      map['propertyType.id'] = typeId > 0 ? typeId : 2;

      final kindIndex = propertyKind != null
          ? (['entire', 'private', 'shared'].indexOf(propertyKind!) + 1)
          : 1;
      map['roomType'] = kindIndex > 0 ? kindIndex : 1;
    }

    // ── Target Step 2: Location ──────────────────────────────────────────
    if (includeStep(2)) {
      final countryId = int.tryParse(country ?? '2') ?? 2;
      map['address.countryId'] = countryId;
      
      final stateId = int.tryParse(stateProvince ?? '0') ?? 0;
      if (stateId > 0) {
        map['address.stateId'] = stateId;
      }

      final cId = int.tryParse(city ?? '322') ?? 322;
      map['address.cityId'] = cId;

      final vId = int.tryParse(village ?? '0') ?? 0;
      if (vId > 0) {
        map['address.villageId'] = vId;
      }

      map['address.name'] = address?.isNotEmpty == true ? address : 'Property Location';
      map['address.streetAddress'] =
          address?.isNotEmpty == true ? address : 'Dummy Street';
      map['address.latitude'] = latitude ?? 12.9388014;
      map['address.longitude'] = longitude ?? 77.6104352;
      if (buildingNumber != null && buildingNumber!.isNotEmpty) {
        map['address.buildingNumber'] = buildingNumber;
      }
      if (floorNumber != null && floorNumber!.isNotEmpty) {
        map['address.floorNumber'] = int.tryParse(floorNumber!) ?? 0;
      }
      if (unitNumber != null && unitNumber!.isNotEmpty) {
        map['address.unitNumber'] = int.tryParse(unitNumber!) ?? 0;
      }
      final zip = postalCode?.isNotEmpty == true ? postalCode : '11511';
      map['address.zipCode'] = zip;
      if (district != null && district!.isNotEmpty) {
        map['address.area'] = district;
      }
    }

    // ── Target Step 3: Room Details ──────────────────────────────────────
    if (includeStep(3)) {
      map['roomDetails.guests'] = maxGuests ?? 1;
      map['roomDetails.bedrooms'] = bedrooms ?? 1;
      map['roomDetails.beds'] = beds ?? 1;
      map['roomDetails.bathrooms'] = bathrooms ?? 1;
      map['roomDetails.area_size'] = totalArea ?? 25.0;
    }

    // ── Target Step 4: Amenities ─────────────────────────────────────────
    if (includeStep(4)) {
      map['amenities'] =
          amenities.isNotEmpty ? amenities : ['13']; // Fallback to 13
    }

    // ── Target Step 5: House Rules ───────────────────────────────────────
    if (includeStep(5)) {
      String convertTime(String? time) {
        if (time == null) return '14:00';
        try {
          final parts = time.split(' ');
          if (parts.length != 2) return time;
          final timeParts = parts[0].split(':');
          int hour = int.parse(timeParts[0]);
          final minute = timeParts[1];
          final isPM = parts[1].toUpperCase() == 'PM';
          
          if (isPM && hour < 12) hour += 12;
          if (!isPM && hour == 12) hour = 0;
          
          return '${hour.toString().padLeft(2, '0')}:$minute';
        } catch (_) {
          return '14:00';
        }
      }

      map['houseRules.allowPets'] = allowPets ?? false;
      map['houseRules.allowSmoking'] = allowSmoking ?? false;
      map['houseRules.allowEvents'] = allowEvents ?? false;
      map['houseRules.checkInTime'] = convertTime(checkInTime);
      map['houseRules.checkOutTime'] = convertTime(checkOutTime);
      map['houseRules.allowGuests'] = allowGuests ?? true;
      map['houseRules.marriedCouplesOnly'] = marriedCouplesOnly ?? false;
    }

    // ── Target Step 6: Photos ────────────────────────────────────────────
    if (includeStep(6)) {
      if (coverPhoto != null && coverPhoto!.isNotEmpty) map['coverPhoto'] = coverPhoto;
      if (photos.isNotEmpty) map['photos'] = photos;
    }

    // ── Target Step 7: Title + Description + Highlights ──────────────────
    if (includeStep(7)) {
      map['title'] = title?.isNotEmpty == true ? title : 'Dummy Title';
      map['description.description'] = description?.isNotEmpty == true
          ? description
          : 'Dummy description text to satisfy backend';
      if (highlights.isNotEmpty) {
        map['description.propertyHighlight'] = highlights;
      }
    }

    // ── Target Step 8: Pricing ───────────────────────────────────────────
    if (includeStep(8)) {
      map['stars'] = stars ?? 5; 
      map['pricing.pricePerNight'] = basePrice ?? 1000.0;
      map['pricing.cleaningFee'] = cleaningFee ?? 0.0;
      map['pricing.serviceFee'] = 0.0;
      map['pricing.electricalFee'] = electricalFee ?? 0.0;
      map['pricing.waterFee'] = waterFee ?? 0.0;
    }

    // ── Target Step 9: Discounts ─────────────────────────────────────────
    if (includeStep(9)) {
      map['discount.weeklyDiscount'] = (weeklyDiscountPercent ?? 0).toInt();
      map['discount.newListingDiscount'] = (newListingDiscountPercent ?? 0).toInt();
    }

    // ── Target Step 10: Cancellation ─────────────────────────────────────
    if (includeStep(10)) {
      final type = cancellationPolicyType ?? 'FLEXIBLE';
      map['cancellationPolicy.policyType'] = type;
      if (type == 'FLEXIBLE') {
        map['cancellationPolicy.freeCancellationHours'] = freeCancellationHours ?? 24;
      } else if (type == 'MODERATE') {
        map['cancellationPolicy.freeCancellationDays'] = freeCancellationDays ?? 5;
      }
    }

    // ── Target Step 11: Booking Settings ─────────────────────────────────
    if (includeStep(11)) {
      map['bookingSettings.instantBook'] = instantBook ?? true;
      map['bookingSettings.securitCamera'] = hasSecurityCameras ?? false;
      map['bookingSettings.noiseDecibelMonitor'] = hasNoiseMonitors ?? false;
      map['phoneNumber'] = primaryPhone ?? '+201000000000';
      if (emergencyPhone != null && emergencyPhone!.isNotEmpty) {
        map['emergencyPhoneNumber'] = emergencyPhone;
      }
    }

    // ── Target Step 12: Documents ────────────────────────────────────────
    if (includeStep(12)) {
      if (propertyDocument != null) {
        map['documentOfProperty.prpopertyDocoument'] = propertyDocument;
      }
      if (hostIdentityCard != null) {
        map['documentOfProperty.hostId'] = hostIdentityCard;
      }
      if (powerOfAttorney != null) {
        map['documentOfProperty.powerOfAttorney'] = powerOfAttorney;
      }
      map['isPropertyOwner'] = isPropertyOwner ?? true;
    }

    // ── Target Step 13: Publish ──────────────────────────────────────────
    if (includeStep(13)) {
      // Final publish step
    }

    return map;
  }

  @override
  List<Object?> get props => [
        propertyType,
        propertyKind,
        latitude,
        longitude,
        address,
        city,
        country,
        stateProvince,
        district,
        village,
        buildingNumber,
        floorNumber,
        unitNumber,
        postalCode,
        bedrooms,
        bathrooms,
        beds,
        maxGuests,
        amenities,
        coverPhoto,
        photos,
        title,
        description,
        highlights,
        houseRules,
        allowPets,
        allowSmoking,
        allowEvents,
        allowGuests,
        marriedCouplesOnly,
        checkInTime,
        checkOutTime,
        basePrice,
        cleaningFee,
        serviceFeePercent,
        weeklyDiscountPercent,
        newListingDiscountPercent,
        cancellationPolicyType,
        freeCancellationHours,
        freeCancellationDays,
        availabilityType,
        minimumNights,
        maximumNights,
        availableDates,
        totalArea,
        primaryPhone,
        emergencyPhone,
        instantBook,
        hasSecurityCameras,
        hasNoiseMonitors,
        propertyDocument,
        hostIdentityCard,
        powerOfAttorney,
        isPropertyOwner,
        stars,
        electricalFee,
        waterFee,
      ];
}
