import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/services/user_service.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/features/property_details/presentation/cubit/property_details_cubit.dart';
import 'package:houseiana_mobile_app/features/property_details/presentation/cubit/property_details_state.dart';
import 'package:houseiana_mobile_app/features/property_details/presentation/screens/amenities_screen.dart';
import 'package:houseiana_mobile_app/features/property_details/presentation/screens/location_map_screen.dart';
import 'package:houseiana_mobile_app/features/property_details/presentation/screens/photo_gallery_screen.dart';
import 'package:houseiana_mobile_app/features/property_details/presentation/screens/reviews_screen.dart';
import 'package:houseiana_mobile_app/features/property_details/presentation/widgets/hosted_by_widget.dart';
import 'package:houseiana_mobile_app/features/property_details/presentation/widgets/things_to_know_widget.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:houseiana_mobile_app/features/property_details/presentation/widgets/property_details_skeleton.dart';

import '../../../../core/models/property_model.dart';

class PropertyDetailsScreen extends StatefulWidget {
  final String? propertyIdToLoad;

  const PropertyDetailsScreen({super.key, this.propertyIdToLoad});

  @override
  State<PropertyDetailsScreen> createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends State<PropertyDetailsScreen> {
  final _session = sl<UserSession>();
  final _pageController = PageController();
  final _scrollController = ScrollController();
  int _currentPage = 0;
  bool _descriptionExpanded = false;
  double? _lat;
  double? _lng;
  bool _isFavorite = false;
  bool _didInit = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _init();
    });
  }

  Future<void> _init() async {
    if (_didInit) return;
    _didInit = true;
    if (widget.propertyIdToLoad != null &&
        widget.propertyIdToLoad!.isNotEmpty) {
      final cubit = context.read<PropertyDetailsCubit>();
      await cubit.getPropertyDetails(
            widget.propertyIdToLoad!,
            userId: _session.userId,
          );
      await cubit.loadRatings(widget.propertyIdToLoad!);
      if (mounted) {
        final loaded = cubit.state;
        if (loaded is PropertyDetailsLoaded) {
          setState(() => _isFavorite = loaded.property.isFavourited ?? false);
        }
      }
    }
    if (!mounted) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      final passed = args['property'] as Map<String, dynamic>?;
      if (passed != null) {
        _resolveCoordinates(passed);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _resolveCoordinates(Map<String, dynamic> property) async {
    double? lat = (property['latitude'] as num?)?.toDouble() ??
        (property['lat'] as num?)?.toDouble();
    double? lng = (property['longitude'] as num?)?.toDouble() ??
        (property['lng'] as num?)?.toDouble();

    if (lat == null || lng == null) {
      final locationStr = _getLocation(property);
      if (locationStr.isNotEmpty) {
        try {
          final locations = await locationFromAddress(locationStr);
          if (locations.isNotEmpty) {
            lat = locations.first.latitude;
            lng = locations.first.longitude;
          }
        } catch (_) {}
      }
    }

    if (mounted && lat != null && lng != null) {
      setState(() {
        _lat = lat;
        _lng = lng;
      });
    }
  }

  String _getLocation(Map<String, dynamic> p) {
    if (p['city'] is Map) {
      final city = p['city'] as Map;
      final country = (p['country'] as Map?)?['name'] ?? '';
      final cityName = city['name'] ?? city['cityName'] ?? '';
      return country.toString().isNotEmpty
          ? '$cityName, $country'
          : cityName.toString();
    }
    return (p['location'] ?? p['city'] ?? p['address'] ?? '').toString();
  }

  List<String> _getPhotos(Map<String, dynamic> p) {
    final photos = p['photos'] ?? p['images'];
    if (photos is List) {
      return photos
          .map<String>((ph) {
            if (ph is String) return ph;
            if (ph is Map) {
              return (ph['url'] ?? ph['photoUrl'] ?? '').toString();
            }
            return '';
          })
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return [];
  }

  List<String> _getAmenities(Map<String, dynamic> p) {
    final ams = p['amenities'];
    if (ams is List) {
      return ams
          .map<String>((a) {
            if (a is String) return a;
            if (a is Map) {
              return (a['name'] ?? a['amenityName'] ?? '').toString();
            }
            return '';
          })
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return [];
  }

  String _getTitle(Map<String, dynamic> p) =>
      (p['title'] ?? p['name'] ?? AppLocalizations.of(context).tr('property.untitled')).toString();

  String _getDescription(Map<String, dynamic> p) =>
      (p['description'] ?? p['about'] ?? '').toString();

  double _getPrice(Map<String, dynamic> p) =>
      ((p['pricePerNight'] ?? p['price'] ?? p['basePrice'] ?? 0) as num)
          .toDouble();

  double _getRating(Map<String, dynamic> p) =>
      ((p['rating'] ?? p['averageRating'] ?? 0) as num).toDouble();

  int _getReviewCount(Map<String, dynamic> p) =>
      ((p['reviewsCount'] ?? p['reviewCount'] ?? p['totalReviews'] ?? 0) as num)
          .toInt();

  String _getPropertyType(Map<String, dynamic> p) =>
      (p['propertyType'] ?? p['type'] ?? p['category'] ?? '').toString();

  Future<void> _shareProperty(Map<String, dynamic> property) async {
    final title = _getTitle(property);
    final propertyId =
        (property['id'] ?? property['_id'] ?? property['propertyId'] ?? '')
            .toString();
    // Share the public website link — same URL the web shares
    // (https://houseiana.com/property/{id}) so recipients land on the listing.
    final url = propertyId.isNotEmpty
        ? 'https://houseiana.com/property/$propertyId'
        : 'https://houseiana.com';
    final message =
        AppLocalizations.of(context).tr('property.shareMessage');
    final shareText = '$title\n\n$message\n\n$url';

    // Origin rect for the share popover on iPad/macOS (ignored on iPhone/Android,
    // but required there to avoid the sheet failing to present).
    final box = context.findRenderObject() as RenderBox?;
    final origin =
        box != null ? box.localToGlobal(Offset.zero) & box.size : null;

    try {
      await Share.share(
        shareText,
        subject: title,
        sharePositionOrigin: origin,
      );
    } catch (_) {
      // Fallback mirrors the web: copy the link to the clipboard.
      await Clipboard.setData(ClipboardData(text: url));
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content:
              Text(AppLocalizations.of(context).tr('property.linkCopied')),
          duration: const Duration(milliseconds: 1500),
        ));
    }
  }

  int _getBedrooms(Map<String, dynamic> p) =>
      ((p['bedrooms'] ?? p['bedroomCount'] ?? 0) as num).toInt();

  int _getBeds(Map<String, dynamic> p) =>
      ((p['beds'] ?? p['bedsCount'] ?? p['bedCount'] ?? 0) as num).toInt();

  int _getBathrooms(Map<String, dynamic> p) =>
      ((p['bathrooms'] ?? p['bathroomCount'] ?? 0) as num).toInt();

  int _getMaxGuests(Map<String, dynamic> p) =>
      ((p['maxGuests'] ?? p['guestCapacity'] ?? p['capacity'] ?? 0) as num)
          .toInt();

  String _getHostName(Map<String, dynamic> p) {
    final host = p['host'];
    if (host is Map) {
      final first = (host['firstName'] ?? '').toString().trim();
      final last = (host['lastName'] ?? '').toString().trim();
      final full = '$first $last'.trim();
      if (full.isNotEmpty) return full;
      final name = (host['name'] ?? '').toString().trim();
      if (name.isNotEmpty) return name;
    }
    return (p['hostName'] ?? p['ownerName'] ?? '').toString();
  }

  String _getHostAvatar(Map<String, dynamic> p) {
    final host = p['host'];
    if (host is Map) {
      return (host['avatar'] ?? host['photo'] ?? host['profilePicture'] ?? '')
          .toString();
    }
    return '';
  }

  String _getArea(Map<String, dynamic> p) {
    final area = p['area'] ?? p['size'] ?? p['squareMeters'];
    if (area != null &&
        area.toString().isNotEmpty &&
        area.toString() != '0' &&
        area.toString() != '0.0') {
      return '${area}m\u00B2';
    }
    return '';
  }

  String _getCheckInTime(Map<String, dynamic> p) =>
      (p['checkInTime'] ?? p['checkIn'] ?? '').toString();

  String _getCheckOutTime(Map<String, dynamic> p) =>
      (p['checkOutTime'] ?? p['checkOut'] ?? '').toString();

  List<String> _getRules(Map<String, dynamic> p) {
    final rules = p['rules'] ?? p['houseRules'];
    if (rules is List) {
      return rules.map((r) => r.toString()).where((s) => s.isNotEmpty).toList();
    }
    if (rules is String && rules.isNotEmpty) return [rules];
    return [];
  }

  String _getCancellationPolicy(BuildContext context, Map<String, dynamic> p) {
    final raw = p['cancellationPolicy'] ?? p['cancelPolicy'];
    if (raw is Map) {
      final policyType = (raw['policyType'] ?? '').toString();
      final days = (raw['freeCancellationDays'] as num?)?.toInt() ?? 0;
      final hours = (raw['freeCancellationHours'] as num?)?.toInt() ?? 0;
      if (policyType.toLowerCase() == 'fixed') {
        return context.tr('propertyDetails.cancelFixedPolicy');
      }
      if (days > 0) {
        return context.tr('propertyDetails.cancelFreeDays', args: {'days': days});
      }
      if (hours > 0) {
        return context.tr('propertyDetails.cancelFreeHours', args: {'hours': hours});
      }
      if (policyType.isNotEmpty) {
        return context.tr('propertyDetails.cancelPolicyType', args: {'type': policyType});
      }
      return context.tr('propertyDetails.noCancellationPolicy');
    }
    if (raw is String && raw.isNotEmpty) return raw;
    return context.tr('propertyDetails.noCancellationPolicy');
  }

  bool _isSuperhost(Map<String, dynamic> p) => (p['isSuperhost'] ??
      p['host']?['isSuperhost'] ??
      p['host']?['superhost'] ??
      p['host']?['verified'] ??
      false) as bool;

  bool _hasEnhancedCleaning(Map<String, dynamic> p) =>
      (p['hasEnhancedCleaning'] ?? p['enhancedCleaning'] ?? true) as bool;

  bool _allowSmoking(Map<String, dynamic> p) =>
      (p['allowSmoking'] ?? p['smokingAllowed'] ?? false) as bool;

  bool _allowPets(Map<String, dynamic> p) =>
      (p['allowPets'] ?? p['petsAllowed'] ?? false) as bool;

  bool _allowEvents(Map<String, dynamic> p) =>
      (p['allowEvents'] ?? p['eventsAllowed'] ?? false) as bool;

  bool _allowGuests(Map<String, dynamic> p) =>
      (p['allowGuests'] ?? p['guestsAllowed'] ?? true) as bool;

  bool _allowMarriedOnly(Map<String, dynamic> p) =>
      (p['allowMarriedOnly'] ?? p['marriedOnly'] ?? false) as bool;

  bool _hasSecurityCamera(Map<String, dynamic> p) =>
      (p['hasSecurityCamera'] ?? p['securityCamera'] ?? false) as bool;

  bool _hasSafetyKit(Map<String, dynamic> p) =>
      (p['hasSafetyKit'] ?? p['safetyKit'] ?? false) as bool;

  bool _hasCarbonMonoxideAlarm(Map<String, dynamic> p) =>
      (p['hasCarbonMonoxideAlarm'] ?? p['carbonMonoxideAlarm'] ?? false)
          as bool;

  bool _hasSmokeAlarm(Map<String, dynamic> p) =>
      (p['hasSmokeAlarm'] ?? p['smokeAlarm'] ?? true) as bool;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PropertyDetailsCubit, PropertyDetailsState>(
      builder: (context, state) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light,
          child: Scaffold(
            backgroundColor: Colors.white,
            body: _buildBody(state),
          ),
        );
      },
    );
  }

  Widget _buildBody(PropertyDetailsState state) {
    if (state is PropertyDetailsLoading) {
      return const PropertyDetailsSkeleton();
    }

    if (state is PropertyDetailsError) {
      // state.message may be a translation key (client-side errors) or a plain
      // server/exception string; tr() falls back to the input when not a key.
      return _buildErrorState(context.tr(state.message));
    }

    if (state is PropertyDetailsLoaded) {
      final property = state.property.toJson();
      final photos = _getPhotos(property);
      final title = _getTitle(property);
      final location = _getLocation(property);
      final price = _getPrice(property);
      final rating = _getRating(property);
      final reviewCount = _getReviewCount(property);
      final bedrooms = _getBedrooms(property);
      final beds = _getBeds(property);
      final bathrooms = _getBathrooms(property);
      final maxGuests = _getMaxGuests(property);
      final area = _getArea(property);
      final hostName = _getHostName(property);
      final hostAvatar = _getHostAvatar(property);
      final hostMap = property['host'] is Map ? property['host'] as Map : const {};
      final hostId = (hostMap['id'] ?? hostMap['_id'] ?? '').toString();
      final propertyType = _getPropertyType(property);
      final description = _getDescription(property);
      final amenities = _getAmenities(property);
      final checkInTime = _getCheckInTime(property);
      final checkOutTime = _getCheckOutTime(property);
      final rules = _getRules(property);
      final cancellationPolicy = _getCancellationPolicy(context, property);
      final ratings = state.ratings;

      return Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPhotoHeader(photos, property),
                  if (photos.isNotEmpty) _buildThumbnailStrip(photos),
                  _buildPropertyInfo(propertyType, title, rating, reviewCount,
                      location, bedrooms, beds, bathrooms, maxGuests, area),
                  const _SectionDivider(),
                  if (hostId.isNotEmpty) ...[
                    HostedByWidget(
                      hostName: hostName,
                      hostAvatar: hostAvatar,
                      isSuperhost: _isSuperhost(property),
                      onTap: () => Navigator.pushNamed(
                        context,
                        Routes.ownerProfile,
                        arguments: {'userId': hostId},
                      ),
                    ),
                    const _SectionDivider(),
                  ],
                  if (description.isNotEmpty) ...[
                    _buildAboutSection(description),
                    const _SectionDivider(),
                  ],
                  if (bedrooms > 0 ||
                      beds > 0 ||
                      bathrooms > 0 ||
                      maxGuests > 0 ||
                      area.isNotEmpty) ...[
                    _buildPropertyDetailsSection(
                        bedrooms, beds, bathrooms, maxGuests, area),
                    const _SectionDivider(),
                  ],
                  if (amenities.isNotEmpty) ...[
                    _buildAmenitiesSection(amenities),
                    const _SectionDivider(),
                  ],
                  ThingsToKnowWidget(
                    checkInTime: checkInTime,
                    checkOutTime: checkOutTime,
                    allowSmoking: _allowSmoking(property),
                    allowPets: _allowPets(property),
                    allowEvents: _allowEvents(property),
                    allowGuests: _allowGuests(property),
                    allowMarriedOnly: _allowMarriedOnly(property),
                    houseRules: rules,
                    hasEnhancedCleaning: _hasEnhancedCleaning(property),
                    hasSecurityCamera: _hasSecurityCamera(property),
                    hasSafetyKit: _hasSafetyKit(property),
                    hasCarbonMonoxideAlarm: _hasCarbonMonoxideAlarm(property),
                    hasSmokeAlarm: _hasSmokeAlarm(property),
                    cancellationPolicy: cancellationPolicy,
                  ),
                  const _SectionDivider(),
                  _buildLocationSection(property, location),
                  if (ratings.isNotEmpty || reviewCount > 0) ...[
                    const _SectionDivider(),
                    // _buildReviewsSection(
                    //     ratings, reviewCount, rating, hasMoreRatings, property),
                  ],
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          _buildBottomBar(price, state.property),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildPhotoHeader(List<String> photos, Map<String, dynamic> property) {
    return SizedBox(
      height: 300,
      child: Stack(
        children: [
          photos.isNotEmpty
              ? PageView.builder(
                  controller: _pageController,
                  physics: const ClampingScrollPhysics(),
                  itemCount: photos.length,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (_, i) => GestureDetector(
                    onTap: () => _openGallery(photos, i),
                    child: CachedNetworkImage(
                      imageUrl: photos[i],
                      width: double.infinity,
                      height: 300,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: AppColors.neutral100,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.bioYellow,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => _photoPlaceholder(),
                    ),
                  ),
                )
              : _photoPlaceholder(),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 100,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withValues(alpha: 0.4), Colors.transparent],
                ),
              ),
            ),
          ),
          if (photos.length > 1 && _currentPage > 0)
            Positioned(
              left: 12,
              top: 0,
              bottom: 0,
              child: Center(
                child: _CircleButton(
                  icon: Icons.chevron_left,
                  onTap: () => _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
                  backgroundColor: Colors.black.withValues(alpha: 0.45),
                  iconColor: Colors.white,
                ),
              ),
            ),
          if (photos.length > 1 && _currentPage < photos.length - 1)
            Positioned(
              right: 12,
              top: 0,
              bottom: 0,
              child: Center(
                child: _CircleButton(
                  icon: Icons.chevron_right,
                  onTap: () => _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
                  backgroundColor: Colors.black.withValues(alpha: 0.45),
                  iconColor: Colors.white,
                ),
              ),
            ),
          Positioned(
            left: 16,
            top: 12 + MediaQuery.of(context).padding.top,
            child: _CircleButton(
              icon: Icons.arrow_back,
              onTap: () => Navigator.pop(context),
            ),
          ),
          Positioned(
            right: 16,
            top: 12 + MediaQuery.of(context).padding.top,
            child: Row(
              children: [
                _CircleButton(
                  icon: Icons.share_outlined,
                  onTap: () => _shareProperty(property),
                ),
                const SizedBox(width: 8),
                _CircleButton(
                  icon: _isFavorite ? Icons.favorite : Icons.favorite_border,
                  iconColor: _isFavorite ? Colors.red : AppColors.charcoal,
                  onTap: () {
                    if (!_session.isLoggedIn) return;
                    final cubitState =
                        context.read<PropertyDetailsCubit>().state;
                    final propId = cubitState is PropertyDetailsLoaded
                        ? cubitState.property.id
                        : '';
                    final newVal = !_isFavorite;
                    setState(() => _isFavorite = newVal);
                    if (propId.isNotEmpty) {
                      sl<UserService>()
                          .toggleFavorite(
                            userId: _session.userId ?? '',
                            propertyId: propId,
                          )
                          .catchError((_) {
                        if (mounted) setState(() => _isFavorite = !newVal);
                        return false;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          if (photos.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  photos.length > 10 ? 10 : photos.length,
                  (i) {
                    final active = i == _currentPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: active ? 20 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: active
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  },
                ),
              ),
            ),
          if (photos.isNotEmpty)
            Positioned(
              right: 16,
              bottom: 14,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_currentPage + 1} / ${photos.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _photoPlaceholder() {
    return Container(
      width: double.infinity,
      height: 300,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE5E5E5), Color(0xFFD0D0D0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child:
            Icon(Icons.home_work_outlined, size: 64, color: Color(0xFFB0B0B0)),
      ),
    );
  }

  Widget _buildThumbnailStrip(List<String> photos) {
    return Container(
      height: 68,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: photos.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = index == _currentPage;
          return GestureDetector(
            onTap: () {
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color:
                      isSelected ? AppColors.bioYellow : AppColors.neutral200,
                  width: isSelected ? 2.5 : 1.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: CachedNetworkImage(
                  imageUrl: photos[index],
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) =>
                      Container(color: const Color(0xFFD0D0D0)),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPropertyInfo(
    String propertyType,
    String title,
    double rating,
    int reviewCount,
    String location,
    int bedrooms,
    int beds,
    int bathrooms,
    int maxGuests,
    String area,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (propertyType.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF9E6),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Text(
                  propertyType,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFB45309),
                  ),
                ),
              ),
            ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (rating > 0) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.bioYellow,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, size: 14, color: Colors.white),
                      const SizedBox(width: 3),
                      Text(
                        rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (reviewCount > 0) ...[
                Text(
                  reviewCount == 1
                      ? context.tr('propertyDetails.reviewSingular', args: {'n': reviewCount})
                      : context.tr('propertyDetails.reviewPlural', args: {'n': reviewCount}),
                  style:
                      const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                ),
                const SizedBox(width: 8),
              ],
              if (location.isNotEmpty) ...[
                const Text(
                  '\u00B7',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.location_on_outlined,
                    size: 15, color: Color(0xFF6B7280)),
                const SizedBox(width: 2),
                Flexible(
                  child: Text(
                    location,
                    style:
                        const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
          if (bedrooms > 0 || beds > 0 || bathrooms > 0 || maxGuests > 0)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (bedrooms > 0) ...[
                      _QuickStat(
                          icon: Icons.meeting_room_outlined,
                          label: _bedroomsLabel(bedrooms)),
                      const _StatDot(),
                    ],
                    if (beds > 0) ...[
                      _QuickStat(
                          icon: Icons.bed_outlined,
                          label: _bedsLabel(beds)),
                      const _StatDot(),
                    ],
                    if (bathrooms > 0) ...[
                      _QuickStat(
                          icon: Icons.bathtub_outlined,
                          label: _bathroomsLabel(bathrooms)),
                      const _StatDot(),
                    ],
                    if (maxGuests > 0) ...[
                      _QuickStat(
                          icon: Icons.people_outline,
                          label: _guestsLabel(maxGuests)),
                      if (area.isNotEmpty) const _StatDot(),
                    ],
                    if (area.isNotEmpty)
                      _QuickStat(icon: Icons.square_foot, label: area),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAboutSection(String description) {
    const maxLines = 4;
    final showToggle = description.length > 200;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('propertyDetails.aboutThisPlace'),
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 10),
          AnimatedCrossFade(
            firstChild: Text(
              description,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 14, color: Color(0xFF6B7280), height: 1.6),
            ),
            secondChild: Text(
              description,
              style: const TextStyle(
                  fontSize: 14, color: Color(0xFF6B7280), height: 1.6),
            ),
            crossFadeState: _descriptionExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
          if (showToggle)
            GestureDetector(
              onTap: () =>
                  setState(() => _descriptionExpanded = !_descriptionExpanded),
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _descriptionExpanded
                      ? context.tr('propertyDetails.showLess')
                      : context.tr('propertyDetails.readMore'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.charcoal,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _bedroomsLabel(int n) => context.tr(
      n == 1 ? 'propertyDetails.bedroomSingular' : 'propertyDetails.bedrooms',
      args: {'n': n});

  String _bedsLabel(int n) => context.tr(
      n == 1 ? 'propertyDetails.bedSingular' : 'propertyDetails.beds',
      args: {'n': n});

  String _bathroomsLabel(int n) => context.tr(
      n == 1 ? 'propertyDetails.bathroomSingular' : 'propertyDetails.bathrooms',
      args: {'n': n});

  String _guestsLabel(int n) => context.tr(
      n == 1 ? 'propertyDetails.guestSingular' : 'propertyDetails.guests',
      args: {'n': n});

  String _guestsUpToLabel(int n) => context.tr(
      n == 1
          ? 'propertyDetails.guestUpToSingular'
          : 'propertyDetails.guestsUpTo',
      args: {'n': n});

  String _areaLabel(String value) =>
      context.tr('propertyDetails.areaLabel', args: {'value': value});

  Widget _buildPropertyDetailsSection(
      int bedrooms, int beds, int bathrooms, int maxGuests, String area) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('propertyDetails.propertyDetailsSection'),
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.charcoal),
          ),
          const SizedBox(height: 14),
          if (bedrooms > 0)
            _buildDetailRow(
                Icons.meeting_room_outlined, _bedroomsLabel(bedrooms)),
          if (beds > 0)
            _buildDetailRow(Icons.bed_outlined, _bedsLabel(beds)),
          if (bathrooms > 0)
            _buildDetailRow(
                Icons.bathtub_outlined, _bathroomsLabel(bathrooms)),
          if (maxGuests > 0)
            _buildDetailRow(
                Icons.people_outline, _guestsUpToLabel(maxGuests)),
          if (area.isNotEmpty)
            _buildDetailRow(Icons.square_foot, _areaLabel(area)),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.ghostWhite,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.neutral200),
            ),
            child: Icon(icon, size: 20, color: AppColors.charcoal),
          ),
          const SizedBox(width: 14),
          Text(
            label,
            style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF374151),
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildAmenitiesSection(List<String> amenities) {
    final showAll = amenities.length <= 6;
    final displayed = showAll ? amenities : amenities.sublist(0, 6);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('propertyDetails.whatThisPlaceOffers'),
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.charcoal),
          ),
          const SizedBox(height: 14),
          ...displayed.map(
            (name) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.ghostWhite,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(_amenityIcon(name),
                        size: 20, color: AppColors.charcoal),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                          fontSize: 14, color: Color(0xFF374151)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!showAll)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AmenitiesScreen(
                          categories: [
                            AmenityCategory(
                              title: context.tr('propertyDetails.allAmenities'),
                              amenities: amenities
                                  .map((name) => Amenity(
                                      name: name, icon: _amenityIcon(name)))
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.charcoal,
                    side: const BorderSide(color: AppColors.charcoal),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    context.tr('propertyDetails.showAllAmenities', args: {'count': amenities.length}),
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _amenityIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('wifi')) return Icons.wifi;
    if (lower.contains('pool')) return Icons.pool;
    if (lower.contains('parking')) return Icons.local_parking;
    if (lower.contains('gym') || lower.contains('fitness')) {
      return Icons.fitness_center;
    }
    if (lower.contains('kitchen')) return Icons.kitchen;
    if (lower.contains('ac') || lower.contains('air')) return Icons.ac_unit;
    if (lower.contains('washer') || lower.contains('laundry')) {
      return Icons.local_laundry_service;
    }
    if (lower.contains('tv')) return Icons.tv;
    if (lower.contains('balcony') || lower.contains('terrace')) {
      return Icons.balcony;
    }
    if (lower.contains('bed')) return Icons.bed;
    return Icons.check_circle_outline;
  }

  Widget _buildLocationSection(Map<String, dynamic> property, String location) {
    final hasCoords = _lat != null && _lng != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('propertyDetails.locationSection'),
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.charcoal),
          ),
          if (location.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on,
                    size: 16, color: AppColors.bioYellow),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    location,
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF6B7280), height: 1.5),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 200,
              child: hasCoords
                  ? GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(_lat!, _lng!),
                        zoom: 14,
                      ),
                      markers: {
                        Marker(
                          markerId: const MarkerId('property'),
                          position: LatLng(_lat!, _lng!),
                          infoWindow: InfoWindow(title: _getTitle(property)),
                        ),
                      },
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      scrollGesturesEnabled: false,
                      rotateGesturesEnabled: false,
                      tiltGesturesEnabled: false,
                      onTap: (_) => _openFullMap(property),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F0FE),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_searching,
                                size: 40, color: AppColors.neutral400),
                            const SizedBox(height: 8),
                            Text(
                              location.isNotEmpty
                                  ? 'Loading map...'
                                  : context.tr('propertyDetails.locationNotAvailable'),
                              style: const TextStyle(
                                  fontSize: 13, color: AppColors.neutral400),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 14),
          if (hasCoords)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _openDirections,
                icon: const Icon(Icons.directions, size: 18),
                label: Text(context.tr('propertyDetails.getDirections')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.charcoal,
                  side: const BorderSide(color: AppColors.charcoal),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildReviewsSection(
    List<Map<String, dynamic>> ratings,
    int reviewCount,
    double rating,
    bool hasMoreRatings,
    Map<String, dynamic> property,
  ) {
    final displayedReviews =
        ratings.length > 3 ? ratings.sublist(0, 3) : ratings;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.tr('propertyDetails.reviewsSection'),
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.charcoal),
                ),
              ),
              if (ratings.length > 3)
                GestureDetector(
                  onTap: () => _openAllReviews(property),
                  child: Text(
                    context.tr('propertyDetails.seeAll'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.charcoal,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              children: [
                Column(
                  children: [
                    Text(
                      rating > 0 ? rating.toStringAsFixed(1) : '--',
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        color: AppColors.charcoal,
                      ),
                    ),
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          Icons.star,
                          size: 16,
                          color: i < rating.round()
                              ? AppColors.bioYellow
                              : AppColors.neutral200,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      reviewCount == 1
                          ? context.tr('propertyDetails.reviewSingular', args: {'n': reviewCount})
                          : context.tr('propertyDetails.reviewPlural', args: {'n': reviewCount}),
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
                const Spacer(),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...displayedReviews.map((r) {
            final guestName =
                (r['guestName'] ?? r['userName'] ?? r['name'] ?? context.tr('propertyDetails.guestFallback'))
                    .toString();
            final comment =
                (r['comment'] ?? r['review'] ?? r['text'] ?? '').toString();
            final ratingVal =
                ((r['rating'] ?? r['overallRating'] ?? 5) as num).toInt();
            final date = _formatDate(r['createdAt'] ?? r['date'] ?? '');
            return _buildReviewCard(
                name: guestName,
                date: date,
                rating: ratingVal,
                comment: comment);
          }),
          if (hasMoreRatings)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    final state = context.read<PropertyDetailsCubit>().state;
                    if (state is PropertyDetailsLoaded) {
                      final propertyId = state.property.id;
                      if (propertyId.isNotEmpty) {
                        context
                            .read<PropertyDetailsCubit>()
                            .loadRatings(propertyId, loadMore: true);
                      }
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.charcoal,
                    side: const BorderSide(color: AppColors.charcoal),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    context.tr('propertyDetails.showAllReviews', args: {'n': reviewCount}),
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateStr);
      final months = context.tr('common.monthsShort').split(',');
      return '${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }

  Widget _buildReviewCard({
    required String name,
    required String date,
    required int rating,
    required String comment,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.ghostWhite,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'G',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, color: AppColors.charcoal),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.charcoal),
                    ),
                    if (date.isNotEmpty)
                      Text(
                        date,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.neutral400),
                      ),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  rating.clamp(0, 5),
                  (_) => const Icon(Icons.star,
                      size: 12, color: AppColors.bioYellow),
                ),
              ),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              comment,
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF6B7280), height: 1.6),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomBar(double price, PropertyModel property) {
    final isInstant = property.instantBook ?? false;

    final String buttonText = isInstant
        ? context.tr('propertyDetails.reserve')
        : context.tr('propertyDetails.requestToBook');

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: AppColors.neutral200)),
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
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  price > 0
                      ? '${price.toStringAsFixed(0)} ${property.currency ?? 'EGP'}'
                      : '--',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.charcoal,
                  ),
                ),
                Text(
                  context.tr('propertyDetails.perNight'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 2),
                Text(
                  isInstant
                      ? context.tr('propertyDetails.instantBooking')
                      : context.tr('propertyDetails.requiresConfirmation'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isInstant ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 120, maxWidth: 170),
            child: SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: () => _onReserve(property),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.bioYellow,
                  foregroundColor: AppColors.charcoal,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25)),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    buttonText,
                    maxLines: 1,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.charcoal),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_outlined,
                size: 64, color: AppColors.neutral400),
            const SizedBox(height: 16),
            Text(
              context.tr('common.errorOccurred'),
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.charcoal),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.bioYellow,
                foregroundColor: AppColors.charcoal,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(context.tr('propertyDetails.goBack'),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  void _onReserve(PropertyModel property) async {
    if (!_session.isLoggedIn) {
      _showSignInPrompt();
      return;
    }
    final propertyId = property.id;
    final propertyJson = property.toJson();
    final result = await Navigator.pushNamed<Map<String, DateTime>>(
      context,
      Routes.nightlyPricesCalendar,
      arguments: {
        'propertyId': propertyId,
        'currency': property.currency ?? 'EGP',
      },
    );
    if (!mounted || result == null) return;
    Navigator.pushNamed(
      context,
      Routes.bookingRequest,
      arguments: {
        'propertyId': propertyId,
        'property': propertyJson,
        'price': property.displayPrice,
        'title': property.displayTitle,
        'checkIn': result['checkIn']!.toIso8601String(),
        'checkOut': result['checkOut']!.toIso8601String(),
      },
    );
  }

  void _showSignInPrompt() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.neutral200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF9E6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_outline_rounded,
                  size: 32, color: AppColors.bioYellow),
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('propertyDetails.signInToReserve'),
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.charcoal),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('propertyDetails.signInToReserveDescription'),
              style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, Routes.login);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.bioYellow,
                  foregroundColor: AppColors.charcoal,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25)),
                ),
                child: Text(context.tr('auth.signIn'),
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.tr('common.cancel'),
                  style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
            ),
          ],
        ),
      ),
    );
  }

  void _openGallery(List<String> photos, int initialIndex) {
    if (photos.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => PhotoGalleryScreen(
          photos: photos,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  void _openFullMap(Map<String, dynamic> property) {
    if (_lat != null && _lng != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LocationMapScreen(
            lat: _lat!,
            lng: _lng!,
            title: _getTitle(property),
          ),
        ),
      );
    }
  }

  Future<void> _openDirections() async {
    if (_lat != null && _lng != null) {
      final url = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=$_lat,$_lng');
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    }
  }

  void _openAllReviews(Map<String, dynamic> property) {
    final propertyId = (property['id'] ?? property['_id'] ?? '').toString();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<PropertyDetailsCubit>(),
          child: ReviewsScreen(propertyId: propertyId),
        ),
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Divider(color: AppColors.neutral200, height: 1),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final Color? iconColor;

  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 18, color: iconColor ?? AppColors.charcoal),
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  final IconData icon;
  final String label;

  const _QuickStat({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.charcoal),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.charcoal),
        ),
      ],
    );
  }
}

class _StatDot extends StatelessWidget {
  const _StatDot();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Text('\u00B7',
          style: TextStyle(fontSize: 16, color: AppColors.neutral400)),
    );
  }
}
