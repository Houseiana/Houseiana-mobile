import 'dart:convert';

import 'package:equatable/equatable.dart';

class ListingWizardState extends Equatable {
  final int currentStep;

  /// The earliest step the user is allowed to navigate back to.
  ///
  /// In CREATE mode this is 0 (Property Type). In EDIT mode it is 1 (Location):
  /// the Property Type step (stepDraft 1) is what *creates* a new unit on the
  /// backend, so an existing listing must never be able to step back onto it.
  final int minStep;

  final String? draftId;
  final bool isSavingDraft;
  final bool isPublishing;
  final bool isUploadingPhotos;
  final bool isHydrating;
  final String? publishedListingId;
  final String? error;
  final String? basePriceError;
  final WizardData data;

  /// The server snapshot the wizard was prefilled with in EDIT mode (via
  /// [ListingWizardCubit.loadForEdit]). Non-null **iff** the wizard is editing
  /// an existing listing, so it doubles as the edit-mode flag. Saves in edit
  /// mode diff [data] against this baseline and POST only the changed fields to
  /// `/api/properties/modify`; it is advanced to the latest saved data after a
  /// successful modify so already-saved edits aren't re-sent. Always null in
  /// CREATE mode (where saves go through `/api/properties/draft`).
  final WizardData? originalData;

  const ListingWizardState({
    this.currentStep = 0,
    this.minStep = 0,
    this.draftId,
    this.isSavingDraft = false,
    this.isPublishing = false,
    this.isUploadingPhotos = false,
    this.isHydrating = false,
    this.publishedListingId,
    this.error,
    this.basePriceError,
    this.data = const WizardData(),
    this.originalData,
  });

  factory ListingWizardState.initial() => const ListingWizardState();

  ListingWizardState copyWith({
    int? currentStep,
    int? minStep,
    String? draftId,
    bool? isSavingDraft,
    bool? isPublishing,
    bool? isUploadingPhotos,
    bool? isHydrating,
    String? publishedListingId,
    String? error,
    String? basePriceError,
    WizardData? data,
    WizardData? originalData,
    bool clearError = false,
    bool clearBasePriceError = false,
    bool clearPublishedListingId = false,
  }) {
    return ListingWizardState(
      currentStep: currentStep ?? this.currentStep,
      minStep: minStep ?? this.minStep,
      draftId: draftId ?? this.draftId,
      isSavingDraft: isSavingDraft ?? this.isSavingDraft,
      isPublishing: isPublishing ?? this.isPublishing,
      isUploadingPhotos: isUploadingPhotos ?? this.isUploadingPhotos,
      isHydrating: isHydrating ?? this.isHydrating,
      publishedListingId: clearPublishedListingId
          ? null
          : (publishedListingId ?? this.publishedListingId),
      error: clearError ? null : (error ?? this.error),
      basePriceError: clearBasePriceError
          ? null
          : (basePriceError ?? this.basePriceError),
      data: data ?? this.data,
      originalData: originalData ?? this.originalData,
    );
  }

  int get totalSteps => 13;
  double get progress => (currentStep + 1) / totalSteps;
  bool get canGoBack => currentStep > minStep;
  bool get isLastStep => currentStep == totalSteps - 1;
  bool get isFirstStep => currentStep == minStep;

  @override
  List<Object?> get props => [
        currentStep,
        minStep,
        draftId,
        isSavingDraft,
        isPublishing,
        isUploadingPhotos,
        isHydrating,
        publishedListingId,
        error,
        basePriceError,
        data,
        originalData,
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

  /// Builds wizard data from the editable property shape returned by
  /// GET /api/properties/{id}, mirroring the web edit-screen prefill
  /// (add-listing/page.tsx). Reads top-level fields first (the shape the web
  /// consumes) with nested-object fallbacks, and keeps existing defaults for
  /// anything missing by layering onto [base] via copyWith.
  ///
  /// IDs (propertyType, country/city/state/village, amenities) are stored as
  /// the numeric-id strings/ints the wizard expects, so re-saving through
  /// [toApiMap] round-trips them correctly. Existing photo/document URLs are
  /// preserved (they are http strings, which HostService re-sends as fields
  /// rather than re-uploading).
  factory WizardData.fromApiJson(
    Map<String, dynamic> raw, {
    WizardData? base,
  }) {
    final addr = _asMap(raw['address']);
    final rd = _asMap(raw['roomDetails']);
    final pricing = _asMap(raw['pricing']);
    final discount = _asMap(raw['discount']);
    final bs = _asMap(raw['bookingSettings']);
    final hr = _asMap(raw['houseRules']);
    final cp = _asMap(raw['propertyCancellationPolicy']) ??
        _asMap(raw['cancellationPolicy']);
    final doc = _asMap(raw['documentOfProperty']);

    // Room type (entire/private/shared) ← numeric roomType (1/2/3) when present.
    final rtId = _idInt(raw['roomType']);
    final propertyKind = (rtId != null && rtId >= 1 && rtId <= 3)
        ? const ['entire', 'private', 'shared'][rtId - 1]
        : null;

    final amenityIds = _idList(raw['amenities']);
    final highlightIds = _idList(raw['highlights'] ?? raw['propertyHighlights']);
    final photos = _photoList(raw['photos'] ?? raw['images']);

    return (base ?? const WizardData()).copyWith(
      // ── Step 1 ── Property type / kind
      propertyType: _idStr(raw['propertyTypeId']) ?? _idStr(raw['propertyType']),
      propertyKind: propertyKind,

      // ── Step 2 ── Location
      country: _idStr(addr?['countryId']) ??
          _idStr(raw['countryId']) ??
          _idStr(raw['country']),
      city: _idStr(raw['city']) ??
          _idStr(raw['cityId']) ??
          _idStr(addr?['cityId']) ??
          _idStr(addr?['city']),
      stateProvince: _idStr(addr?['stateId']) ??
          _idStr(raw['stateId']) ??
          _idStr(raw['state']) ??
          _idStr(addr?['state']),
      village: _idStr(addr?['villageId']) ?? _idStr(raw['villageId']),
      district: _str(addr?['area']) ?? _str(raw['area']),
      address: _str(addr?['streetAddress']) ??
          (raw['address'] is String ? _str(raw['address']) : null) ??
          _str(addr?['name']) ??
          _str(raw['streetAddress']),
      buildingNumber:
          _str(addr?['buildingNumber']) ?? _str(raw['buildingNumber']),
      floorNumber: _str(addr?['floorNumber']) ?? _str(raw['floorNumber']),
      unitNumber: _str(addr?['unitNumber']) ?? _str(raw['unitNumber']),
      postalCode: _str(raw['postalCode']) ??
          _str(raw['postal_code']) ??
          _str(addr?['zipCode']) ??
          _str(addr?['postalCode']),
      latitude: _dbl(raw['latitude']) ??
          _dbl(addr?['latitude']) ??
          _dbl(raw['lat']),
      longitude: _dbl(raw['longitude']) ??
          _dbl(addr?['longitude']) ??
          _dbl(raw['lng']) ??
          _dbl(raw['lon']),

      // ── Step 3 ── Basics
      maxGuests: _int(raw['guests']) ?? _int(rd?['guests']),
      bedrooms: _int(raw['bedrooms']) ?? _int(rd?['bedrooms']),
      beds: _int(raw['beds']) ?? _int(rd?['beds']),
      bathrooms: _int(raw['bathrooms']) ?? _int(rd?['bathrooms']),
      totalArea: _dbl(raw['sizeOfProperty']) ??
          _dbl(raw['area_size']) ??
          _dbl(raw['areaSize']) ??
          _dbl(rd?['area_size']) ??
          _dbl(rd?['areaSize']),

      // ── Step 4 ── Amenities (only amenities; safetyItems/guestFavorites are
      // left untouched on the backend since the wizard never sends them).
      amenities: amenityIds.isNotEmpty
          ? amenityIds.map((e) => e.toString()).toList()
          : null,

      // ── Step 5 ── House rules
      allowPets: _bool(raw['allowPets']) ??
          _bool(raw['allow_pets']) ??
          _bool(hr?['allowPets']),
      allowSmoking: _bool(raw['allowSmoking']) ??
          _bool(raw['allow_smoking']) ??
          _bool(hr?['allowSmoking']),
      allowEvents: _bool(raw['allowParties']) ??
          _bool(raw['allowEvents']) ??
          _bool(raw['allow_parties']) ??
          _bool(hr?['allowEvents']),
      allowGuests: _bool(raw['allowGuests']) ?? _bool(hr?['allowGuests']),
      marriedCouplesOnly: _bool(raw['allowMarriedOnly']) ??
          _bool(raw['marriedCouplesOnly']) ??
          _bool(hr?['marriedCouplesOnly']),
      checkInTime: _to12h(_str(raw['checkInTime']) ??
          _str(raw['check_in_time']) ??
          _str(hr?['checkInTime'])),
      checkOutTime: _to12h(_str(raw['checkOutTime']) ??
          _str(raw['check_out_time']) ??
          _str(hr?['checkOutTime'])),

      // ── Step 6 ── Photos
      coverPhoto: _str(raw['coverPhoto']),
      photos: photos.isNotEmpty ? photos : null,

      // ── Step 7 ── Title / description / highlights
      title: _str(raw['title']),
      description: _str(raw['description']),
      highlights: highlightIds.isNotEmpty ? highlightIds : null,

      // ── Step 8 ── Pricing
      basePrice: _dbl(raw['pricePerNight']) ??
          _dbl(raw['price']) ??
          _dbl(pricing?['pricePerNight']),
      cleaningFee: _dbl(raw['cleaningFee']) ??
          _dbl(raw['cleaning_fee']) ??
          _dbl(pricing?['cleaningFee']),
      electricalFee: _dbl(raw['electricalFee']) ??
          _dbl(raw['electrical_fee']) ??
          _dbl(pricing?['electricalFee']),
      waterFee: _dbl(raw['waterFee']) ??
          _dbl(raw['water_fee']) ??
          _dbl(pricing?['waterFee']),
      stars: _int(raw['stars']) ?? _int(raw['rating']),

      // ── Step 9 ── Discounts
      weeklyDiscountPercent: _dbl(raw['weeklyDiscount']) ??
          _dbl(raw['weekly_discount']) ??
          _dbl(discount?['weeklyDiscount']),
      newListingDiscountPercent: _dbl(raw['newListingDiscount']) ??
          _dbl(raw['new_listing_discount']) ??
          _dbl(discount?['newListingDiscount']),

      // ── Step 10 ── Cancellation policy
      cancellationPolicyType: _str(cp?['policyType']),
      freeCancellationHours: _int(cp?['freeCancellationHours']),
      freeCancellationDays: _int(cp?['freeCancellationDays']),

      // ── Step 11 ── Booking settings
      instantBook: _bool(raw['instantBook']) ??
          _bool(raw['instant_book']) ??
          _bool(bs?['instantBook']),
      hasSecurityCameras: _bool(raw['securityCamera']) ??
          _bool(raw['security_camera']) ??
          _bool(bs?['securitCamera']),
      hasNoiseMonitors: _bool(raw['noiseMonitor']) ??
          _bool(raw['noise_monitor']) ??
          _bool(bs?['noiseDecibelMonitor']),
      primaryPhone: _nationalPhone(
          _str(raw['phoneNumber']) ?? _str(raw['primaryPhone'])),
      emergencyPhone: _nationalPhone(
          _str(raw['emergencyPhoneNumber']) ?? _str(raw['emergencyPhone'])),

      // ── Step 12 ── Documents / ownership
      isPropertyOwner:
          _bool(raw['isPropertyOwner']) ?? _bool(raw['is_property_owner']),
      propertyDocument: _str(doc?['prpopertyDocoument']) ??
          _str(doc?['PrpopertyDocoument']) ??
          _str(raw['propertyDocument']),
      hostIdentityCard: _str(doc?['hostId']) ??
          _str(doc?['HostId']) ??
          _str(raw['hostIdDocument']),
      powerOfAttorney: _str(doc?['powerOfAttorney']) ??
          _str(doc?['PowerOfAttorney']) ??
          _str(raw['powerOfAttorney']),
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
    // Web parity: amenities are optional. The add-listing page only appends
    // `amenities` when the host has selected some, and the backend accepts an
    // empty list — so send nothing when empty instead of a phantom fallback.
    if (includeStep(4) && amenities.isNotEmpty) {
      map['amenities'] = amenities;
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
      // Web parity: phone is submitted as <dialCode><national> (e.g. +201012345678).
      // The wizard stores only the national part, so prepend the Egypt dial code.
      final primaryNational = primaryPhone?.trim() ?? '';
      map['phoneNumber'] =
          primaryNational.isNotEmpty ? '+20$primaryNational' : '+201000000000';
      final emergencyNational = emergencyPhone?.trim() ?? '';
      if (emergencyNational.isNotEmpty) {
        map['emergencyPhoneNumber'] = '+20$emergencyNational';
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

  /// Builds the multipart payload for `POST /api/properties/modify`, carrying
  /// ONLY the fields whose value differs from [original] (the server snapshot
  /// the wizard was prefilled with). [propertyId] and [hostId] are always
  /// included (the endpoint requires them); the returned map contains just
  /// those two keys when nothing changed, so callers can detect a no-op edit
  /// by checking whether any *other* key is present.
  ///
  /// Field keys follow the `/modify` schema, which differs from the draft
  /// schema in a few places: house rules use `allowMarriedOnly` (not
  /// `marriedCouplesOnly`), availability uses `maxNights` /
  /// `minimumDaysForBooking`, and there is no `countryId`/`stateId`/
  /// `isPropertyOwner` — those fields are not editable through this endpoint
  /// and are simply never sent. As a partial update, only non-null changed
  /// values are pushed (a field is never cleared to null here).
  Map<String, dynamic> toModifyMap({
    required String hostId,
    required String propertyId,
    required WizardData original,
  }) {
    final o = original;
    final map = <String, dynamic>{
      'propertyId': propertyId,
      'hostId': hostId,
    };

    // ── Property type / room type (locked in edit; kept for completeness) ──
    if (propertyType != o.propertyType) {
      final id = int.tryParse(propertyType ?? '');
      if (id != null && id > 0) map['propertyType.id'] = id;
    }
    if (propertyKind != o.propertyKind && propertyKind != null) {
      final idx = const ['entire', 'private', 'shared'].indexOf(propertyKind!) + 1;
      if (idx > 0) map['roomType'] = idx;
    }

    // ── Title / description / highlights ──
    if (title != o.title && (title?.trim().isNotEmpty ?? false)) {
      map['title'] = title!.trim();
    }
    if (description != o.description && (description?.trim().isNotEmpty ?? false)) {
      map['description.description'] = description!.trim();
    }
    if (!_sameList(highlights, o.highlights)) {
      map['description.propertyHighlight'] = highlights;
    }

    // ── Address (countryId/stateId are not part of the modify schema) ──
    if (address != o.address && (address?.trim().isNotEmpty ?? false)) {
      map['address.name'] = address!.trim();
      map['address.streetAddress'] = address!.trim();
    }
    if (city != o.city) {
      final id = int.tryParse(city ?? '');
      if (id != null && id > 0) map['address.cityId'] = id;
    }
    if (village != o.village) {
      final id = int.tryParse(village ?? '');
      if (id != null && id > 0) map['address.villageId'] = id;
    }
    if (district != o.district && (district?.isNotEmpty ?? false)) {
      map['address.area'] = district;
    }
    if (postalCode != o.postalCode && (postalCode?.isNotEmpty ?? false)) {
      map['address.zipCode'] = postalCode;
    }
    if (latitude != o.latitude && latitude != null) {
      map['address.latitude'] = latitude;
    }
    if (longitude != o.longitude && longitude != null) {
      map['address.longitude'] = longitude;
    }
    if (buildingNumber != o.buildingNumber &&
        (buildingNumber?.isNotEmpty ?? false)) {
      map['address.buildingNumber'] = buildingNumber;
    }
    if (floorNumber != o.floorNumber && (floorNumber?.isNotEmpty ?? false)) {
      final f = int.tryParse(floorNumber!);
      if (f != null) map['address.floorNumber'] = f;
    }
    if (unitNumber != o.unitNumber && (unitNumber?.isNotEmpty ?? false)) {
      final u = int.tryParse(unitNumber!);
      if (u != null) map['address.unitNumber'] = u;
    }

    // ── Room details (Basics) ──
    if (maxGuests != o.maxGuests && maxGuests != null) {
      map['roomDetails.guests'] = maxGuests;
    }
    if (bedrooms != o.bedrooms && bedrooms != null) {
      map['roomDetails.bedrooms'] = bedrooms;
    }
    if (beds != o.beds && beds != null) map['roomDetails.beds'] = beds;
    if (bathrooms != o.bathrooms && bathrooms != null) {
      map['roomDetails.bathrooms'] = bathrooms;
    }
    if (totalArea != o.totalArea && totalArea != null) {
      map['roomDetails.area_size'] = totalArea;
    }

    // ── Amenities ──
    if (!_sameList(amenities, o.amenities)) map['amenities'] = amenities;

    // ── House rules (note: modify uses `allowMarriedOnly`) ──
    if (allowPets != o.allowPets && allowPets != null) {
      map['houseRules.allowPets'] = allowPets;
    }
    if (allowSmoking != o.allowSmoking && allowSmoking != null) {
      map['houseRules.allowSmoking'] = allowSmoking;
    }
    if (allowEvents != o.allowEvents && allowEvents != null) {
      map['houseRules.allowEvents'] = allowEvents;
    }
    if (marriedCouplesOnly != o.marriedCouplesOnly &&
        marriedCouplesOnly != null) {
      map['houseRules.allowMarriedOnly'] = marriedCouplesOnly;
    }
    if (allowGuests != o.allowGuests && allowGuests != null) {
      map['houseRules.allowGuests'] = allowGuests;
    }
    if (checkInTime != o.checkInTime && checkInTime != null) {
      map['houseRules.checkInTime'] = _hhmm24(checkInTime);
    }
    if (checkOutTime != o.checkOutTime && checkOutTime != null) {
      map['houseRules.checkOutTime'] = _hhmm24(checkOutTime);
    }

    // ── Photos / cover ── The cover is derived from the photo set, so send the
    // full current photo list + cover together whenever either one changes.
    final photosChanged = !_sameList(photos, o.photos);
    final coverChanged = coverPhoto != o.coverPhoto;
    if (photosChanged || coverChanged) {
      if (photos.isNotEmpty) map['photos'] = photos;
      if (coverPhoto != null && coverPhoto!.isNotEmpty) {
        map['coverPhoto'] = coverPhoto;
      }
    }

    // ── Pricing ──
    if (basePrice != o.basePrice && basePrice != null) {
      map['pricing.pricePerNight'] = basePrice;
    }
    if (cleaningFee != o.cleaningFee && cleaningFee != null) {
      map['pricing.cleaningFee'] = cleaningFee;
    }
    if (electricalFee != o.electricalFee && electricalFee != null) {
      map['pricing.electricalFee'] = electricalFee;
    }
    if (waterFee != o.waterFee && waterFee != null) {
      map['pricing.waterFee'] = waterFee;
    }
    if (stars != o.stars && stars != null) map['stars'] = stars;

    // ── Discounts ──
    if (weeklyDiscountPercent != o.weeklyDiscountPercent &&
        weeklyDiscountPercent != null) {
      map['discount.weeklyDiscount'] = weeklyDiscountPercent!.toInt();
    }
    if (newListingDiscountPercent != o.newListingDiscountPercent &&
        newListingDiscountPercent != null) {
      map['discount.newListingDiscount'] = newListingDiscountPercent!.toInt();
    }

    // ── Cancellation policy ──
    if (cancellationPolicyType != o.cancellationPolicyType &&
        cancellationPolicyType != null) {
      map['cancellationPolicy.policyType'] = cancellationPolicyType;
    }
    if (freeCancellationHours != o.freeCancellationHours &&
        freeCancellationHours != null) {
      map['cancellationPolicy.freeCancellationHours'] = freeCancellationHours;
    }
    if (freeCancellationDays != o.freeCancellationDays &&
        freeCancellationDays != null) {
      map['cancellationPolicy.freeCancellationDays'] = freeCancellationDays;
    }

    // ── Booking settings ──
    if (instantBook != o.instantBook && instantBook != null) {
      map['bookingSettings.instantBook'] = instantBook;
    }
    if (hasSecurityCameras != o.hasSecurityCameras &&
        hasSecurityCameras != null) {
      map['bookingSettings.securitCamera'] = hasSecurityCameras;
    }
    if (hasNoiseMonitors != o.hasNoiseMonitors && hasNoiseMonitors != null) {
      map['bookingSettings.noiseDecibelMonitor'] = hasNoiseMonitors;
    }

    // ── Availability (not currently wired into the edit flow; diff-guarded) ──
    if (minimumNights != o.minimumNights && minimumNights != null) {
      map['minimumDaysForBooking'] = minimumNights;
    }
    if (maximumNights != o.maximumNights && maximumNights != null) {
      map['maxNights'] = maximumNights;
    }

    // ── Documents (local file paths uploaded by HostService; URLs preserved) ──
    if (propertyDocument != o.propertyDocument &&
        (propertyDocument?.isNotEmpty ?? false)) {
      map['documentOfProperty.prpopertyDocoument'] = propertyDocument;
    }
    if (hostIdentityCard != o.hostIdentityCard &&
        (hostIdentityCard?.isNotEmpty ?? false)) {
      map['documentOfProperty.hostId'] = hostIdentityCard;
    }
    if (powerOfAttorney != o.powerOfAttorney &&
        (powerOfAttorney?.isNotEmpty ?? false)) {
      map['documentOfProperty.powerOfAttorney'] = powerOfAttorney;
    }

    // ── Phones (stored as the national part; submitted as +20<national>) ──
    if (primaryPhone != o.primaryPhone &&
        (primaryPhone?.trim().isNotEmpty ?? false)) {
      map['phoneNumber'] = '+20${primaryPhone!.trim()}';
    }
    if (emergencyPhone != o.emergencyPhone &&
        (emergencyPhone?.trim().isNotEmpty ?? false)) {
      map['emergencyPhoneNumber'] = '+20${emergencyPhone!.trim()}';
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

// ── Edit-prefill parsing helpers ────────────────────────────────────────────
// Tolerant readers used by WizardData.fromApiJson to map the loose JSON shape
// returned by GET /api/properties/{id} (values may be numbers, strings,
// objects, or JSON-encoded strings) into the wizard's typed fields.

Map<String, dynamic>? _asMap(dynamic v) {
  if (v is Map) return Map<String, dynamic>.from(v);
  if (v is String && v.isNotEmpty) {
    try {
      final decoded = jsonDecode(v);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
  }
  return null;
}

List<dynamic> _asList(dynamic v) {
  if (v is List) return v;
  if (v is String && v.isNotEmpty) {
    try {
      final decoded = jsonDecode(v);
      if (decoded is List) return decoded;
    } catch (_) {}
  }
  return const [];
}

String? _str(dynamic v) {
  if (v == null) return null;
  final s = v.toString().trim();
  return s.isEmpty ? null : s;
}

/// Normalizes a stored phone number to its national part (no dial code).
/// Phones are submitted as `<dialCode><national>` (e.g. +201012345678), but the
/// wizard UI shows only the 10-digit national number beside a fixed "+20"
/// prefix. Strips non-digits and a leading Egypt country code (+20 / 20) so
/// that editing a web- or mobile-created listing prefills cleanly.
String? _nationalPhone(String? v) {
  if (v == null) return null;
  var digits = v.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('20') && digits.length > 10) {
    digits = digits.substring(2);
  }
  return digits.isEmpty ? null : digits;
}

double? _dbl(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

int? _int(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toInt();
  final s = v.toString();
  return int.tryParse(s) ?? double.tryParse(s)?.toInt();
}

bool? _bool(dynamic v) {
  if (v == null) return null;
  if (v is bool) return v;
  final s = v.toString().toLowerCase();
  if (s == 'true' || s == '1') return true;
  if (s == 'false' || s == '0') return false;
  return null;
}

/// Extracts a numeric id from a number, numeric string, or object
/// ({id|amenityId|itemId}). Mirrors the web `extractIds` element logic.
int? _idInt(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toInt();
  if (v is Map) {
    return _idInt(v['id'] ?? v['amenityId'] ?? v['itemId']);
  }
  return int.tryParse(v.toString());
}

/// Same as [_idInt] but returns the id as a string (the form some wizard
/// fields store ids in, e.g. propertyType, country, city).
String? _idStr(dynamic v) => _idInt(v)?.toString();

/// Maps an array (or JSON-string array) of ids/objects to a list of int ids.
List<int> _idList(dynamic v) {
  final out = <int>[];
  for (final item in _asList(v)) {
    final id = _idInt(item);
    if (id != null) out.add(id);
  }
  return out;
}

/// Maps a photos value (array of url strings / objects, or a JSON string) to a
/// flat list of url strings. Mirrors the web photo-parsing fallbacks.
List<String> _photoList(dynamic v) {
  final out = <String>[];
  for (final p in _asList(v)) {
    if (p is String) {
      if (p.isNotEmpty) out.add(p);
    } else if (p is Map) {
      final u = p['url'] ?? p['fileUrl'] ?? p['path'];
      if (u is String && u.isNotEmpty) out.add(u);
    }
  }
  // A bare http string that wasn't a JSON array.
  if (out.isEmpty && v is String && v.startsWith('http')) out.add(v);
  return out;
}

/// Converts the wizard's 12h display time ("03:00 PM") to the 24h "HH:mm"
/// format the backend expects ("15:00"). Mirrors the `convertTime` closure in
/// [WizardData.toApiMap]; falls back to "14:00" on null/unparseable input.
String _hhmm24(String? time) {
  if (time == null || time.trim().isEmpty) return '14:00';
  try {
    final parts = time.trim().split(' ');
    if (parts.length != 2) return time.trim();
    final tp = parts[0].split(':');
    int hour = int.parse(tp[0]);
    final minute = tp[1];
    final isPM = parts[1].toUpperCase() == 'PM';
    if (isPM && hour < 12) hour += 12;
    if (!isPM && hour == 12) hour = 0;
    return '${hour.toString().padLeft(2, '0')}:$minute';
  } catch (_) {
    return '14:00';
  }
}

/// Order-sensitive value equality for the wizard's list fields (amenities,
/// highlights, photos). Two nulls are equal. A false positive (different order,
/// same members) only causes the list to be re-sent as an unchanged whole,
/// which is harmless for the modify endpoint.
bool _sameList(List<dynamic>? a, List<dynamic>? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null) return a == b;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Converts a 24h time ("14:00") to the wizard's 12h display format
/// ("02:00 PM"). Returns values that already contain AM/PM unchanged, and
/// null/empty as null so the wizard keeps its default check-in/out time.
String? _to12h(String? raw) {
  if (raw == null) return null;
  final s = raw.trim();
  if (s.isEmpty) return null;
  final upper = s.toUpperCase();
  if (upper.contains('AM') || upper.contains('PM')) return s;
  final parts = s.split(':');
  if (parts.length < 2) return s;
  final h = int.tryParse(parts[0]);
  if (h == null) return s;
  var minute = parts[1].replaceAll(RegExp(r'[^0-9]'), '');
  if (minute.length < 2) minute = minute.padLeft(2, '0');
  minute = minute.substring(0, 2);
  final period = h >= 12 ? 'PM' : 'AM';
  var hour12 = h % 12;
  if (hour12 == 0) hour12 = 12;
  return '${hour12.toString().padLeft(2, '0')}:$minute $period';
}
