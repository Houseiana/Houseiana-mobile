import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/models/region_category_model.dart';
import 'package:houseiana_mobile_app/core/services/property_service.dart';
import 'package:houseiana_mobile_app/core/services/user_service.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/features/bottom_nav/presentation/cubit/cubit.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';
import 'package:houseiana_mobile_app/shared/widgets/skeletons/list_skeleton.dart';
import 'package:houseiana_mobile_app/shared/widgets/cards/property_card_v2.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// Selected region category id from `/api/Lookups/RegionCategory`, sent to
  /// the search endpoint as `villageId`. Null means "All" (no filter).
  int? _selectedVillageId;
  Set<String> _favoriteProperties = {};

  List<RegionCategory> _regionCategories = [];
  bool _categoriesLoading = true;

  List<Map<String, dynamic>> _properties = [];
  List<CityPropertyGroup> _cityGroups = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  static const int _pageLimit = 20;

  static const List<String> _cityHeadingKeys = [
    'home.popularHomesIn',
    'home.stayIn',
    'home.availableIn',
    'home.placesToStayIn',
  ];

  final _propertyService = sl<PropertyService>();
  final _userService = sl<UserService>();
  final _session = sl<UserSession>();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadCategories();
    _loadData();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await _propertyService.getRegionCategories();
      if (mounted) {
        setState(() {
          _regionCategories = cats;
          _categoriesLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _categoriesLoading = false);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _currentPage = 1;
      _hasMore = true;
    });

    final params = PropertySearchParams(
      page: 1,
      limit: _pageLimit,
      villageId: _selectedVillageId,
      isSorted: true,
    );

    final page = await _propertyService.searchPropertiesGrouped(
      params,
      userId: _session.userId,
    );

    Set<String> favIds = {};
    if (_session.isLoggedIn) {
      final favs = await _userService.getFavorites(_session.userId!);
      favIds = favs
          .map((f) => (f['propertyId'] ?? f['id'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toSet();
    }

    if (mounted) {
      setState(() {
        _cityGroups = page.groups;
        _properties = _flatten(page.groups);
        _favoriteProperties = favIds;
        _isLoading = false;
        _hasMore = page.hasMore;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);

    final nextPage = _currentPage + 1;
    final params = PropertySearchParams(
      page: nextPage,
      limit: _pageLimit,
      villageId: _selectedVillageId,
      isSorted: true,
    );
    final page = await _propertyService.searchPropertiesGrouped(
      params,
      userId: _session.userId,
    );

    if (mounted) {
      setState(() {
        _currentPage = nextPage;
        _cityGroups = _mergeGroups(_cityGroups, page.groups);
        _properties = _flatten(_cityGroups);
        _hasMore = page.hasMore;
        _isLoadingMore = false;
      });
    }
  }

  List<Map<String, dynamic>> _flatten(List<CityPropertyGroup> groups) {
    return [
      for (final g in groups) ...g.properties,
    ];
  }

  /// Merge new groups into existing ones — match by regionId when available,
  /// otherwise by name. Appends new properties and dedupes by id.
  /// Mirrors `mergeGroups` in the web HomeClient.
  List<CityPropertyGroup> _mergeGroups(
    List<CityPropertyGroup> prev,
    List<CityPropertyGroup> next,
  ) {
    String keyOf(CityPropertyGroup g) =>
        g.regionId != null ? 'id:${g.regionId}' : 'name:${g.name}';

    final indexByKey = <String, int>{};
    final merged = <CityPropertyGroup>[];
    for (var i = 0; i < prev.length; i++) {
      indexByKey[keyOf(prev[i])] = i;
      merged.add(prev[i]);
    }

    for (final g in next) {
      final key = keyOf(g);
      final existingIdx = indexByKey[key];
      if (existingIdx != null) {
        final existing = merged[existingIdx];
        final seen = existing.properties
            .map((p) => (p['id'] ?? p['_id'] ?? '').toString())
            .toSet();
        final newProps = g.properties.where((p) {
          final id = (p['id'] ?? p['_id'] ?? '').toString();
          return id.isEmpty || !seen.contains(id);
        }).toList();
        merged[existingIdx] = CityPropertyGroup(
          regionId: existing.regionId,
          name: existing.name,
          nameAr: existing.nameAr,
          totalCount: existing.totalCount,
          properties: [...existing.properties, ...newProps],
        );
      } else {
        indexByKey[key] = merged.length;
        merged.add(g);
      }
    }
    return merged;
  }

  Future<void> _toggleFavorite(String propertyId) async {
    if (!_session.isLoggedIn) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (sheetCtx) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 28),
              Container(width: 72, height: 72, decoration: const BoxDecoration(color: Color(0xFFFFF9E6), shape: BoxShape.circle), child: const Icon(Icons.favorite_border, size: 38, color: Color(0xFFFCC519))),
              const SizedBox(height: 16),
              Text(context.tr('home.signInToSaveFavorites'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1D242B))),
              const SizedBox(height: 8),
              Text(context.tr('home.signInToSaveFavoritesDescription'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280), height: 1.5)),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  onPressed: () { Navigator.pop(sheetCtx); Navigator.pushNamed(context, Routes.login); },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFCC519), foregroundColor: const Color(0xFF1D242B), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: Text(context.tr('auth.signIn'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity, height: 50,
                child: OutlinedButton(
                  onPressed: () { Navigator.pop(sheetCtx); Navigator.pushNamed(context, Routes.signUp); },
                  style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF1D242B), side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: Text(context.tr('bottomNav.createAccountAction'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }
    setState(() {
      if (_favoriteProperties.contains(propertyId)) {
        _favoriteProperties.remove(propertyId);
      } else {
        _favoriteProperties.add(propertyId);
      }
    });
    await _userService.toggleFavorite(userId: _session.userId!, propertyId: propertyId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryColor,
          onRefresh: _loadData,
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 16),
                      _buildHeroSection(),
                      const SizedBox(height: 16),
                      _buildSearchBar(),
                      const SizedBox(height: 20),
                      _buildCategoryFilters(),
                      const SizedBox(height: 20),
                      _buildPropertyList(),
                      if (_isLoadingMore)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: CircularProgressIndicator(color: AppColors.primaryColor),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _buildTrustBadges(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Image.asset(
              'assets/images/logo_icon.png',
              width: 28,
              height: 38,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            Text(
              context.tr('app.name'),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 20,
                height: 1.25,
                color: Color(0xFF1D242B),
              ),
            ),
          ],
        ),
        Row(
          children: [
            GestureDetector(
              onTap: () {
                if (!_session.isLoggedIn) {
                  _showSignInPrompt();
                  return;
                }
                Navigator.pushNamed(context, Routes.listProperty);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.bioYellow,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  context.tr('home.listYourHome'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    color: Color(0xFF1D242B),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _buildIconButton(Icons.notifications_none_outlined, () {
              Navigator.pushNamed(context, Routes.notifications);
            }),
            const SizedBox(width: 8),
            _buildIconButton(Icons.person_outline, () {
              if (_session.isLoggedIn) {
                context.read<BottomNavCubit>().changeIndex(4);
              } else {
                _showSignInPrompt();
              }
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFFF9F9FA),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          icon,
          size: 18,
          color: const Color(0xFF6B7280),
        ),
      ),
    );
  }

  void _showSignInPrompt() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 28),
            Container(
              width: 72, height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF9E6), shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_outline_rounded,
                  size: 38, color: Color(0xFFFCC519)),
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('bottomNav.signInToViewProfile'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                  color: Color(0xFF1D242B)),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('bottomNav.signInDescription'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280), height: 1.5),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(sheetCtx);
                  Navigator.pushNamed(context, Routes.login);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFCC519),
                  foregroundColor: const Color(0xFF1D242B),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(context.tr('auth.signIn'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity, height: 50,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(sheetCtx);
                  Navigator.pushNamed(context, Routes.signUp);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1D242B),
                  side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(context.tr('bottomNav.createAccountAction'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openSearch() {
    Navigator.pushNamed(context, Routes.searchModal);
  }

  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1D242B),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('home.heroTitle'),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.15,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('home.heroDescription'),
            style: const TextStyle(
              fontSize: 13,
              height: 1.45,
              color: Color(0xFFE5E7EB),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildHeroStat(
                  context.tr('home.heroStaysPerPageValue'),
                  context.tr('home.heroStaysPerPage'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildHeroStat(
                  context.tr('home.heroSupportValue'),
                  context.tr('home.heroSupport'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildHeroStat(
                  context.tr('home.heroPaymentsValue'),
                  context.tr('home.heroPayments'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStat(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.primaryColor,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFFE5E7EB), fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: _openSearch,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsetsDirectional.only(start: 16),
                decoration: const BoxDecoration(
                  border: BorderDirectional(
                    end: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      context.tr('home.where'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        height: 1.25,
                        color: Color(0xFF000000),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: const BoxDecoration(
                  border: BorderDirectional(
                    end: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      context.tr('home.checkIn'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 11,
                        height: 1.25,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: const BoxDecoration(
                  border: BorderDirectional(
                    end: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      context.tr('home.checkOut'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 11,
                        height: 1.25,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsetsDirectional.only(start: 10, end: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          context.tr('home.who'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: 11,
                            height: 1.25,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.search,
                        size: 16,
                        color: Color(0xFF1D242B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    if (_categoriesLoading) {
      return const SizedBox(
        height: 92,
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primaryColor,
            ),
          ),
        ),
      );
    }

    if (_regionCategories.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: _regionCategories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildCategoryChip(
              id: null,
              label: context.tr('home.categories.all'),
              photoUrl: null,
            );
          }
          final category = _regionCategories[index - 1];
          return _buildCategoryChip(
            id: category.id,
            label: category.name,
            photoUrl: category.photo,
          );
        },
      ),
    );
  }

  Widget _buildCategoryChip({
    required int? id,
    required String label,
    String? photoUrl,
  }) {
    final isSelected = _selectedVillageId == id;
    return GestureDetector(
      onTap: () {
        if (_selectedVillageId == id) return;
        setState(() => _selectedVillageId = id);
        _loadData();
      },
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF3F4F6),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryColor
                      : const Color(0xFFE5E7EB),
                  width: isSelected ? 2.5 : 1,
                ),
              ),
              child: ClipOval(
                child: (photoUrl != null && photoUrl.isNotEmpty)
                    ? Image.network(
                        photoUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.place_outlined,
                          size: 24,
                          color: Color(0xFF9CA3AF),
                        ),
                      )
                    : const Icon(
                        Icons.apps_rounded,
                        size: 26,
                        color: Color(0xFF6B7280),
                      ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 11,
                height: 1.2,
                color: isSelected
                    ? const Color(0xFF1D242B)
                    : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyList() {
    if (_isLoading) {
      return ListSkeletonLoader(
        itemCount: 4,
        showSearchBar: false,
        showCategories: false,
      );
    }

    if (_properties.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.home_outlined, size: 64, color: AppColors.neutral400),
              const SizedBox(height: 16),
              Text(
                context.tr('property.noPropertiesFound'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.charcoal),
              ),
              const SizedBox(height: 8),
              Text(
                context.tr('property.noPropertiesFoundDescription'),
                style: const TextStyle(fontSize: 14, color: AppColors.neutral600),
              ),
            ],
          ),
        ),
      );
    }

    if (_cityGroups.isEmpty) {
      return Column(
        children: [
          for (int i = 0; i < _properties.length; i++) ...[
            if (i > 0) const SizedBox(height: 16),
            _buildPropertyCardFromData(_properties[i]),
          ],
        ],
      );
    }

    return _buildCityGroups();
  }

  Widget _buildCityGroups() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int gi = 0; gi < _cityGroups.length; gi++) ...[
          if (gi > 0) const SizedBox(height: 32),
          _buildCityGroupSection(_cityGroups[gi], gi),
        ],
      ],
    );
  }

  Widget _buildCityGroupSection(CityPropertyGroup group, int index) {
    final headingPrefix = context.tr(_cityHeadingKeys[index % _cityHeadingKeys.length]);
    final displayName = group.localizedName(isArabic: context.isRtl);
    final heading = '$headingPrefix $displayName';
    final totalInRegion = group.totalCount ?? group.properties.length;
    final showSeeAll =
        totalInRegion >= 6 || group.properties.length >= 6 || group.regionId != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                heading,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  height: 1.25,
                  color: Color(0xFF1D242B),
                ),
              ),
            ),
            if (showSeeAll)
              GestureDetector(
                onTap: () => Navigator.pushNamed(
                  context,
                  Routes.searchProperties,
                  arguments: {
                    'location': displayName,
                    'regionId': group.regionId,
                  },
                ),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Icon(
                    context.isRtl ? Icons.arrow_back : Icons.arrow_forward,
                    size: 16,
                    color: const Color(0xFF1D242B),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 260,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: group.properties.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final p = group.properties[i];
              final cid =
                  (p['id'] ?? p['_id'] ?? p['propertyId'] ?? '').toString();
              return SizedBox(
                width: 200,
                child: CompactPropertyCard(
                  imageUrl: _extractImage(p),
                  title: (p['title'] ?? p['name'] ?? '').toString(),
                  location: _extractLocation(p),
                  price: (double.tryParse(_extractPrice(p)) ?? 0),
                  rating: (p['averageRating'] ?? p['rating'] ?? 0.0).toDouble(),
                  currency: (p['currency'] ?? 'EGP').toString(),
                  bedrooms: _asInt(p['bedrooms']),
                  beds: _asInt(p['beds']),
                  bathrooms: _asInt(p['bathrooms']),
                  isFavorite: _favoriteProperties.contains(cid),
                  onFavoriteToggle: () => _toggleFavorite(cid),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      Routes.propertyDetails,
                      arguments: {
                        'propertyId': (p['id'] ?? p['_id'] ?? '').toString(),
                        'property': p,
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPropertyCardFromData(Map<String, dynamic> p) {
    final propertyId = (p['id'] ?? p['_id'] ?? p['propertyId'] ?? '').toString();
    final title = (p['title'] ?? p['name'] ?? 'Property').toString();
    final location = _extractLocation(p);
    final price = _extractPrice(p);
    final rating = (p['averageRating'] ?? p['rating'] ?? p['ratingAverage'] ?? 0.0);
    final reviewCount = (p['reviewsCount'] ?? p['reviewCount'] ?? p['totalReviews'] ?? 0);
    final imageUrl = _extractImage(p);
    final isGuestFavorite = (p['isGuestFavorite'] ?? p['guestFavorite'] ?? false) == true;

    final currency = (p['currency'] ?? 'QAR').toString();

    final weeklyDiscount = (p['weeklyDiscount'] ?? 0);
    final smallDiscount = (p['smallBookingDiscount'] ?? 0);
    final discountPct = weeklyDiscount > 0 ? weeklyDiscount : (smallDiscount > 0 ? smallDiscount : 0);

    final priceWithoutDiscount = p['priceWithoutDiscount'] ?? p['originalPrice'];
    final originalPriceStr = (priceWithoutDiscount != null && discountPct > 0)
        ? '${(priceWithoutDiscount as num).toStringAsFixed(0)} $currency'
        : null;

    final bedrooms = p['bedrooms'] as int?;
    final beds = p['beds'] as int?;
    final bathrooms = p['bathrooms'] as int?;

    return _buildPropertyCard(
      propertyId: propertyId.isEmpty ? title : propertyId,
      propertyData: p,
      imageUrl: imageUrl,
      badge: isGuestFavorite ? context.tr('home.guestFavorite') : null,
      rating: rating is num ? rating.toStringAsFixed(1) : rating.toString(),
      reviewCount: reviewCount.toString(),
      title: title,
      location: location,
      originalPrice: originalPriceStr,
      price: '${(double.tryParse(price) ?? 0).toStringAsFixed(0)} $currency',
      discount: discountPct > 0 ? '-$discountPct%' : null,
      bedrooms: bedrooms,
      beds: beds,
      bathrooms: bathrooms,
    );
  }

  String _extractLocation(Map<String, dynamic> p) {
    if (p['city'] is Map) {
      final city = p['city'] as Map;
      final cityName = city['name'] ?? city['cityName'] ?? '';
      final country = p['country']?['name'] ?? '';
      return country.isNotEmpty ? '$cityName, $country' : cityName.toString();
    }
    return (p['location'] ?? p['city'] ?? p['address'] ?? 'Qatar').toString();
  }

  String _extractPrice(Map<String, dynamic> p) {
    final price = p['pricePerNight'] ?? p['price'] ?? p['basePrice'] ?? p['nightlyPrice'] ?? 0;
    return price.toString();
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  String _extractImage(Map<String, dynamic> p) {
    final photos = p['photos'] ?? p['images'] ?? p['coverPhoto'];
    if (photos is List && photos.isNotEmpty) {
      final first = photos.first;
      if (first is String) return first;
      if (first is Map) return (first['url'] ?? first['photoUrl'] ?? '').toString();
    }
    if (photos is String) return photos;
    return '';
  }

  Widget _buildPropertyCard({
    required String propertyId,
    required Map<String, dynamic> propertyData,
    required String imageUrl,
    String? badge,
    required String rating,
    String? reviewCount,
    required String title,
    required String location,
    String? originalPrice,
    required String price,
    String? discount,
    int? bedrooms,
    int? beds,
    int? bathrooms,
  }) {
    final isFavorite = _favoriteProperties.contains(propertyId);
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          Routes.propertyDetails,
          arguments: {'propertyId': propertyId, 'property': propertyData},
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.network(
                      imageUrl,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: double.infinity,
                          height: 200,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFE8E8E8), Color(0xFFD4D4D4)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (badge != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                            height: 1.2,
                            color: Color(0xFF1D242B),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: () => _toggleFavorite(propertyId),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          size: 16,
                          color: isFavorite ? const Color(0xFFEF4444) : const Color(0xFF9CA3AF),
                        ),
                      ),
                    ),
                  ),
                  if (discount != null)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD00416),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          discount,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                            height: 1.2,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: Color(0xFFFCC519)),
                      const SizedBox(width: 4),
                      Text(
                        rating,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          height: 1.25,
                          color: Color(0xFF000000),
                        ),
                      ),
                      if (reviewCount != null) ...[
                        const SizedBox(width: 4),
                        Text(
                          context.tr('home.reviewsCount', args: {'n': reviewCount}),
                          style: const TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: 12,
                            height: 1.25,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      height: 1.27,
                      color: Color(0xFF1D242B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    location,
                    style: const TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 11,
                      height: 1.27,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  if ((bedrooms ?? 0) > 0 || (beds ?? 0) > 0 || (bathrooms ?? 0) > 0) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if ((bedrooms ?? 0) > 0) ...[
                          const Icon(Icons.door_front_door_outlined, size: 13, color: Color(0xFF6B7280)),
                          const SizedBox(width: 3),
                          Text('$bedrooms', style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                          const SizedBox(width: 8),
                        ],
                        if ((beds ?? 0) > 0) ...[
                          const Icon(Icons.bed_outlined, size: 13, color: Color(0xFF6B7280)),
                          const SizedBox(width: 3),
                          Text('$beds', style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                          const SizedBox(width: 8),
                        ],
                        if ((bathrooms ?? 0) > 0) ...[
                          const Icon(Icons.bathtub_outlined, size: 13, color: Color(0xFF6B7280)),
                          const SizedBox(width: 3),
                          Text('$bathrooms', style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                        ],
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (originalPrice != null) ...[
                        Text(
                          originalPrice,
                          style: const TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: 13,
                            height: 1.23,
                            color: Color(0xFF9CA3AF),
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        price,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          height: 1.25,
                          color: Color(0xFF000000),
                        ),
                      ),
                      Text(
                        context.tr('home.perNight'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 13,
                          height: 1.23,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrustBadges() {
    final badges = [
      {'icon': Icons.credit_card, 'labelKey': 'home.trustVisa'},
      {'icon': Icons.verified_outlined, 'labelKey': 'home.trustVerifiedHost'},
      {'icon': Icons.lock_outline, 'labelKey': 'home.trustEncryption'},
      {'icon': Icons.security_outlined, 'labelKey': 'home.trustSecureSsl'},
      {'icon': Icons.support_agent_outlined, 'labelKey': 'home.trustSupport'},
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      decoration: const BoxDecoration(
        color: Color(0xFFF9F9FA),
      ),
      child: Column(
        children: [
          Text(
            context.tr('home.safeAndSecure'),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Color(0xFF1D242B),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: badges.map((badge) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    badge['icon'] as IconData,
                    size: 22,
                    color: AppColors.charcoal,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.tr(badge['labelKey'] as String),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6B7280),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Text(
            context.tr('home.copyright'),
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF9CA3AF),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

