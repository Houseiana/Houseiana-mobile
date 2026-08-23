import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/utils/money.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/constants/errors/exceptions.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/models/hotel/hotel_summary.dart';
import 'package:houseiana_mobile_app/core/models/region_category_model.dart';
import 'package:houseiana_mobile_app/core/services/cache_service.dart';
import 'package:houseiana_mobile_app/core/services/favorites_notifier.dart';
import 'package:houseiana_mobile_app/core/services/hotel_favorites_notifier.dart';
import 'package:houseiana_mobile_app/core/services/hotel_service.dart';
import 'package:houseiana_mobile_app/core/services/lookups_cache.dart';
import 'package:houseiana_mobile_app/core/services/property_service.dart';
import 'package:houseiana_mobile_app/core/services/user_service.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/features/chat/data/firestore_chat_service.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';
import 'package:houseiana_mobile_app/i18n/locale_aware_state.dart';
import 'package:houseiana_mobile_app/shared/widgets/common/sign_in_prompt_sheet.dart';
import 'package:houseiana_mobile_app/shared/widgets/empty_state/empty_state_widget.dart';
import 'package:houseiana_mobile_app/shared/widgets/skeletons/list_skeleton.dart';
import 'package:houseiana_mobile_app/core/utils/discount_utils.dart';
import 'package:houseiana_mobile_app/shared/widgets/cards/compact_hotel_card.dart';
import 'package:houseiana_mobile_app/shared/widgets/cards/property_card_v2.dart';
import 'package:houseiana_mobile_app/shared/widgets/favorite_heart_button.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// The two content sections the home page switches between (web parity:
/// an "Apartments | Hotels" pill sitting under the search bar).
enum _HomeSegment { apartments, hotels }

class HomeScreen extends StatefulWidget {
  HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with LocaleAwareState<HomeScreen> {
  /// Selected region category id from `/api/Lookups/RegionCategory`, sent to
  /// the search endpoint as `featuredRegionId` to filter the home in place.
  /// Null means "All" (no filter). Drilling into a region (See All) uses
  /// `regionId` instead — see [_buildCityGroupSection].
  int? _selectedFeaturedRegionId;

  List<RegionCategory> _regionCategories = [];
  bool _categoriesLoading = true;

  List<Map<String, dynamic>> _properties = [];
  List<CityPropertyGroup> _cityGroups = [];

  /// Translation key describing why the last API load failed, or null when it
  /// succeeded. Only reached on a cache miss — a cache hit still renders
  /// instantly without touching the network.
  String? _loadErrorKey;
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

  // ── Hotels segment ────────────────────────────────────────────────────
  _HomeSegment _segment = _HomeSegment.apartments;

  /// Lazy-load guard: the hotels request fires only the first time the Hotels
  /// segment is opened, so the apartments cold start costs exactly what it
  /// costs today.
  bool _hotelsRequested = false;

  /// Set when the backend answered 404 — hotels are not deployed on this host.
  bool _hotelsUnavailable = false;

  List<HotelGroup> _hotelGroups = [];
  List<HotelSummary> _hotels = [];
  String? _hotelsLoadErrorKey;
  bool _hotelsLoading = true;
  bool _hotelsLoadingMore = false;
  bool _hotelsHasMore = true;
  int _hotelsPage = 1;

  final _hotelService = sl<HotelService>();
  final _propertyService = sl<PropertyService>();
  final _userService = sl<UserService>();
  final _session = sl<UserSession>();
  final _cache = sl<CacheService>();
  final _scrollController = ScrollController();

  /// Live unread-message count driving BOTH home alerts (header badge + inbox
  /// banner). A notifier — not a `StreamBuilder` — because the underlying
  /// Firestore stream is single-subscription and has two consumers here.
  final ValueNotifier<int> _unreadMessages = ValueNotifier<int>(0);
  StreamSubscription<int>? _unreadSub;
  bool _watchingUnread = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _watchUnreadMessages();
    _loadCategories();
    _loadData();
  }

  /// Home stays mounted for the whole session, so a language switch has to
  /// re-run both loads — the destination chips and the listing rails alike come
  /// back from the backend already localized. Both caches are keyed per
  /// language, so the previously-visited language renders straight from cache.
  @override
  void onLocaleChanged() {
    _loadCategories();
    _loadData();
    // Hotel rows are backend-localized through the same `lang` header. The
    // guard preserves the lazy-load contract: a user who never opened the
    // Hotels segment still pays no hotel request.
    if (_hotelsRequested) _loadHotels();
  }

  /// Attaches the realtime unread-message counter (idempotent).
  ///
  /// Also called from `build` on purpose: home stays mounted for the whole
  /// session inside the shell's lazy IndexedStack, so `initState` runs exactly
  /// once — if the watch could not be attached then (signed out, Firebase not
  /// ready yet, or a hot reload that skipped `initState`), the alerts would
  /// stay dead forever. Guarded by [_watchingUnread], so repeated calls are
  /// free and never open a second listener.
  void _watchUnreadMessages() {
    if (_watchingUnread) return;
    final userId = _session.userId;
    if (!_session.isLoggedIn || userId == null || userId.isEmpty) return;
    // Firebase failed to initialize (no `google-services.json`): the app is
    // designed to keep working without it, so just skip the alerts.
    if (Firebase.apps.isEmpty) return;
    try {
      _unreadSub = sl<FirestoreChatService>().watchTotalUnread(userId).listen(
            (count) => _unreadMessages.value = count,
            // Firestore rules can reject the read; silent alerts are the right
            // degradation, never a crash on the home screen.
            onError: (Object e) => debugPrint('[Home] unread messages: $e'),
          );
      _watchingUnread = true;
    } catch (e) {
      debugPrint('[Home] unread messages unavailable: $e');
    }
  }

  void _openMessages() {
    if (!_session.isLoggedIn) {
      _showSignInPrompt();
      return;
    }
    Navigator.pushNamed(context, Routes.messages);
  }

  Future<void> _loadCategories() async {
    // Cache-first: serve the chips from cache when present, fetch on a miss.
    // The key is locale-suffixed — a language switch resolves to a different
    // entry, so the chips can't get stuck in the previous language.
    final categoriesKey =
        HomeCache.categoriesKey(sl<LookupsCache>().activeLang);
    final cached = _cache.getJson<List>(categoriesKey);
    if (cached != null) {
      final cats = cached
          .whereType<Map>()
          .map((m) => RegionCategory.fromJson(Map<String, dynamic>.from(m)))
          .where((c) => c.id > 0 && c.name.isNotEmpty)
          .toList();
      if (cats.isNotEmpty) {
        setState(() {
          _regionCategories = cats;
          _categoriesLoading = false;
        });
        return;
      }
    }

    try {
      final cats = await _propertyService.getRegionCategories();
      await _cache.setJson(
        categoriesKey,
        [for (final c in cats) c.toJson()],
        ttl: HomeCache.categoriesTtl,
      );
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
    _unreadSub?.cancel();
    _unreadMessages.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels <
        _scrollController.position.maxScrollExtent - 200) {
      return;
    }
    // One controller drives both segments, so paginate whichever is on screen
    // — otherwise scrolling the hotels rail would page the apartments list.
    if (_segment == _HomeSegment.hotels) {
      if (!_hotelsLoadingMore && _hotelsHasMore) _loadMoreHotels();
      return;
    }
    if (!_isLoadingMore && _hasMore) _loadMore();
  }

  /// Loads the home listings with a **cache-first** (read-through) strategy:
  /// serve instantly from the cache when present, and only hit the API on a
  /// miss — then write the response back for next time. Pass
  /// [forceRefresh] (pull-to-refresh) to bypass the cache and re-fetch.
  ///
  /// The cache is invalidated whenever the user favourites any unit (see
  /// `UserService.toggleFavorite`), so after a favourite the next load misses
  /// the cache and fetches fresh — matching the product spec.
  Future<void> _loadData({bool forceRefresh = false}) async {
    final listKey = HomeCache.listKey(
      _selectedFeaturedRegionId,
      sl<LookupsCache>().activeLang,
    );
    final favKey = HomeCache.favKey(_session.userId);

    // ── Cache hit → render immediately, no network call. ──
    if (!forceRefresh) {
      final cached = _cache.getJson<Map>(listKey);
      if (cached != null) {
        final groups = _groupsFromCache(cached['groups']);
        final favs = _favsFromCache(_cache.getJson<List>(favKey));
        if (_session.isLoggedIn) sl<FavoritesNotifier>().seed(favs);
        if (mounted) {
          setState(() {
            _cityGroups = groups;
            _properties = _flatten(groups);
            _currentPage = 1;
            _hasMore = cached['hasMore'] == true;
            _isLoading = false;
          });
        }
        return;
      }
    }

    // ── Cache miss (or forced refresh) → fetch from the API. ──
    setState(() {
      _isLoading = true;
      _loadErrorKey = null;
      _currentPage = 1;
      _hasMore = true;
    });

    final params = PropertySearchParams(
      page: 1,
      limit: _pageLimit,
      featuredRegionId: _selectedFeaturedRegionId,
      isSorted: true,
    );

    // Listings and favourites are independent — fire both together so the
    // cold load costs max(listings, favourites) instead of their sum.
    final pageFuture = _propertyService.searchPropertiesGrouped(params);
    final favsFuture = _loadFavoriteIds();

    final GroupedPropertiesPage page;
    try {
      page = await pageFuture;
    } catch (e) {
      // The listings call failed (the backend cold start blows the receive
      // timeout on the first request of a session). Without this the exception
      // escaped and home sat on its skeleton forever.
      await favsFuture; // never throws — just don't leave it dangling
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadErrorKey = loadErrorKeyFor(e);
      });
      return;
    }
    final favIds = await favsFuture;

    // ── Write-through: cache the fresh response for the next visit. ──
    await _cache.setJson(
      listKey,
      {
        'hasMore': page.hasMore,
        'groups': [for (final g in page.groups) g.toCacheJson()],
      },
      ttl: HomeCache.listTtl,
    );
    // null = the favourites call failed; caching an empty list (and seeding it)
    // would wrongly clear every heart.
    if (favIds != null) {
      await _cache.setJson(favKey, favIds.toList(), ttl: HomeCache.favTtl);
      sl<FavoritesNotifier>().seed(favIds);
    }
    if (mounted) {
      setState(() {
        _cityGroups = page.groups;
        _properties = _flatten(page.groups);
        _isLoading = false;
        _hasMore = page.hasMore;
      });
    }
  }


  // ── Hotels segment ──────────────────────────────────────────────────────

  /// Mirrors [_loadData] (cache-first, write-through, page 1 only) with hotel
  /// keys. Only ever fires once the user actually opens the Hotels segment.
  Future<void> _loadHotels({bool forceRefresh = false}) async {
    _hotelsRequested = true;

    // Hotels are not deployed on this backend — never hit the network again.
    if (!HotelService.available.value) {
      if (!mounted) return;
      setState(() {
        _hotelsUnavailable = true;
        _hotelsLoading = false;
      });
      return;
    }

    final listKey = HotelCache.listKey(sl<LookupsCache>().activeLang);

    if (!forceRefresh) {
      final cached = _cache.getJson<Map>(listKey);
      if (cached != null) {
        final groups = _hotelGroupsFromCache(cached['groups']);
        // The cached rows carry their own `isFavorite`, and the notifier is
        // in-memory only — so without this a restart inside the 2h TTL renders
        // every saved hotel with a hollow heart, and the next tap UN-saves it.
        _seedHotelHeartsFrom([for (final g in groups) ...g.hotels]);
        if (!mounted) return;
        setState(() {
          _hotelGroups = groups;
          _hotels = [for (final g in groups) ...g.hotels];
          _hotelsPage = 1;
          _hotelsHasMore = cached['hasMore'] == true;
          _hotelsLoading = false;
          _hotelsUnavailable = false;
          _hotelsLoadErrorKey = null;
        });
        return;
      }
    }

    setState(() {
      _hotelsLoading = true;
      _hotelsLoadErrorKey = null;
      _hotelsUnavailable = false;
      _hotelsPage = 1;
      _hotelsHasMore = true;
    });

    final HotelSearchPage page;
    try {
      page = await _hotelService.searchHotels(
        HotelSearchParams(
          page: 1,
          limit: _pageLimit,
          userId: _hotelSearchUserId,
        ),
      );
    } on HotelsUnavailableException {
      if (!mounted) return;
      setState(() {
        _hotelsUnavailable = true;
        _hotelsLoading = false;
      });
      return;
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hotelsLoading = false;
        _hotelsLoadErrorKey = loadErrorKeyFor(e);
      });
      return;
    }

    await _cache.setJson(
      listKey,
      {
        'hasMore': page.hasMore,
        'groups': [for (final g in page.groups) g.toJson()],
      },
      ttl: HotelCache.listTtl,
    );

    _seedHotelHearts(page);

    if (!mounted) return;
    setState(() {
      _hotelGroups = page.groups;
      _hotels = page.flatHotels;
      _hotelsLoading = false;
      _hotelsHasMore = page.hasMore;
    });
  }

  /// Re-arms the availability latch and fetches again. Only ever reached from
  /// the guest tapping Retry — nothing calls it automatically, so a backend
  /// without hotels is still asked exactly once per session by default.
  Future<void> _retryHotels() async {
    HotelService.retryAvailability();
    if (!mounted) return;
    setState(() {
      _hotelsUnavailable = false;
      _hotelsLoading = true;
    });
    await _loadHotels(forceRefresh: true);
  }

  /// Sent only when signed in, and only so the rows come back with a truthful
  /// `isFavorite`: there is no "my favourite hotels" endpoint to seed hearts
  /// from, so the search rows are the only source.
  String? get _hotelSearchUserId =>
      _session.isLoggedIn ? _session.userId : null;

  /// Union, never seed: page two must not wipe page one's hearts. And only
  /// `isFavorite` — `isGuestFavorite` is the quality badge, and seeding from it
  /// lights up hotels the user never saved.
  void _seedHotelHearts(HotelSearchPage page) =>
      _seedHotelHeartsFrom(page.flatHotels);

  void _seedHotelHeartsFrom(List<HotelSummary> hotels) {
    sl<HotelFavoritesNotifier>().addAll(
      hotels.where((h) => h.isFavorite).map((h) => h.hotelId),
    );
  }

  List<HotelGroup> _hotelGroupsFromCache(dynamic raw) => raw is! List
      ? const []
      : raw
          .whereType<Map>()
          .map((e) => HotelGroup.fromJson(Map<String, dynamic>.from(e)))
          .toList();

  Future<void> _loadMoreHotels() async {
    if (_hotelsLoadingMore || !_hotelsHasMore || _hotelsUnavailable) return;
    setState(() => _hotelsLoadingMore = true);
    final nextPage = _hotelsPage + 1;
    try {
      final page = await _hotelService.searchHotels(
        HotelSearchParams(
          page: nextPage,
          limit: _pageLimit,
          userId: _hotelSearchUserId,
        ),
      );
      _seedHotelHearts(page);
      if (!mounted) return;
      setState(() {
        _hotelsPage = nextPage;
        _hotelGroups = _mergeHotelGroups(_hotelGroups, page.groups);
        _hotels = [for (final g in _hotelGroups) ...g.hotels];
        _hotelsHasMore = page.hasMore;
        _hotelsLoadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      // _hotelsHasMore is deliberately left alone so the next scroll retries
      // the same page rather than silently ending the list.
      setState(() => _hotelsLoadingMore = false);
    }
  }

  /// Same key rule as [_mergeGroups]: hotel-search flips between REGION groups
  /// (regionId present) and CITY groups (regionId absent), so the name fallback
  /// is load-bearing, not defensive. Dedupes on hotelId; page one's group
  /// metadata wins.
  List<HotelGroup> _mergeHotelGroups(
    List<HotelGroup> prev,
    List<HotelGroup> next,
  ) {
    String keyOf(HotelGroup g) =>
        g.regionId != null ? 'id:${g.regionId}' : 'name:${g.name}';

    final indexByKey = <String, int>{};
    final merged = <HotelGroup>[];
    for (var i = 0; i < prev.length; i++) {
      indexByKey[keyOf(prev[i])] = i;
      merged.add(prev[i]);
    }

    for (final g in next) {
      final key = keyOf(g);
      final existingIdx = indexByKey[key];
      if (existingIdx != null) {
        final existing = merged[existingIdx];
        final seen = existing.hotels.map((h) => h.hotelId).toSet();
        final newHotels =
            g.hotels.where((h) => !seen.contains(h.hotelId)).toList();
        merged[existingIdx] =
            existing.copyWith(hotels: [...existing.hotels, ...newHotels]);
      } else {
        indexByKey[key] = merged.length;
        merged.add(g);
      }
    }
    return merged;
  }

  /// Optimistic hotel favourite. Separate from [_toggleFavorite]: hotels have
  /// their own toggle endpoint and their own notifier (a property favourite
  /// replace-seeds the property set and would wipe every hotel heart).
  Future<void> _toggleHotelFavorite(String hotelId) async {
    if (!_session.isLoggedIn) {
      await showSignInToSaveFavoritesSheet(context);
      return;
    }
    final favorites = sl<HotelFavoritesNotifier>();
    favorites.toggle(hotelId);
    try {
      final isFavorite = await _hotelService.toggleFavorite(
        hotelId: hotelId,
        userId: _session.userId!,
      );
      // The endpoint TOGGLES and answers with the resulting state. If the
      // optimistic guess disagreed — the heart was drawn hollow from a stale
      // cache, say — settle on the server's answer instead of leaving the UI
      // showing the opposite of the truth.
      if (favorites.contains(hotelId) != isFavorite) favorites.toggle(hotelId);
    } catch (e) {
      favorites.toggle(hotelId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('hotels.favoriteFailed'))),
      );
    }
  }

  /// The signed-in user's favourite ids, or null when they can't be fetched —
  /// a favourites hiccup must not take the listings down with it.
  Future<Set<String>?> _loadFavoriteIds() async {
    if (!_session.isLoggedIn) return null;
    try {
      return await _userService.getFavoriteIds(_session.userId!);
    } catch (_) {
      return null;
    }
  }

  /// Rebuilds the city groups from a cached `groups` payload (see
  /// [CityPropertyGroup.toCacheJson]).
  List<CityPropertyGroup> _groupsFromCache(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((m) =>
            CityPropertyGroup.fromCacheJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  /// Rebuilds the favourite-id set from a cached list.
  Set<String> _favsFromCache(List? raw) {
    if (raw == null) return {};
    return raw.map((e) => e.toString()).where((s) => s.isNotEmpty).toSet();
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);

    final nextPage = _currentPage + 1;
    final params = PropertySearchParams(
      page: nextPage,
      limit: _pageLimit,
      featuredRegionId: _selectedFeaturedRegionId,
      isSorted: true,
    );
    final GroupedPropertiesPage page;
    try {
      page = await _propertyService.searchPropertiesGrouped(params);
    } catch (_) {
      // Release the flag (and keep `_hasMore`) so scrolling again retries the
      // same page instead of the spinner sticking forever.
      if (mounted) setState(() => _isLoadingMore = false);
      return;
    }

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
      showSignInToSaveFavoritesSheet(context);
      return;
    }
    // No setState: UserService flips the FavoritesNotifier optimistically
    // (and rolls back on failure), so only the tapped heart repaints — not
    // the whole home tree.
    try {
      await _userService.toggleFavorite(
          userId: _session.userId!, propertyId: propertyId);
    } catch (_) {
      // Rollback already handled by the notifier.
    }
  }

  @override
  Widget build(BuildContext context) {
    // Cheap no-op once attached — see [_watchUnreadMessages] for why the watch
    // cannot rely on initState alone.
    _watchUnreadMessages();
    // CustomScrollView + lazy slivers: only visible city sections/cards are
    // built (the old SingleChildScrollView→Column built every card eagerly).
    return Scaffold(
      backgroundColor: AppColors.cardBackground,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryColor,
          onRefresh: () => _segment == _HomeSegment.hotels
              ? _loadHotels(forceRefresh: true)
              : _loadData(forceRefresh: true),
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                sliver: SliverList.list(
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 16),
                    _buildHeroSection(),
                    const SizedBox(height: 16),
                    _buildSearchBar(),
                    const SizedBox(height: 16),
                    _buildSegmentedToggle(),
                    const SizedBox(height: 20),
                    _buildUnreadMessagesAlert(),
                    // The region-category chips send `featuredRegionId`, which
                    // /api/hotel-search does not accept — its regionId is a
                    // different id space with no guest lookup behind it.
                    if (_segment == _HomeSegment.apartments)
                      _buildCategoryFilters(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                sliver: _buildContentSliver(),
              ),
              if (_segment == _HomeSegment.hotels
                  ? _hotelsLoadingMore
                  : _isLoadingMore)
                const SliverPadding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  sliver: SliverToBoxAdapter(
                    child: Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primaryColor),
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
              SliverToBoxAdapter(child: _buildTrustBadges()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Image.asset(
          'assets/icons/full_logo.png',
          height: 28,
          fit: BoxFit.contain,
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.bioYellow,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  context.tr('home.listYourHome'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    color: AppColors.brandCharcoal,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _buildIconButton(Icons.notifications_none_outlined, () {
              Navigator.pushNamed(context, Routes.notifications);
            }),
            const SizedBox(width: 8),
            // Messages replaces the old profile shortcut here: Profile already
            // has a permanent bottom-nav tab, while the inbox was buried three
            // taps deep — users were missing incoming messages entirely.
            _buildMessagesButton(),
          ],
        ),
      ],
    );
  }

  /// Header inbox shortcut. With unread messages the whole button flips to the
  /// brand yellow with a filled icon (a lone 8px dot on a 32px button was too
  /// easy to miss) and carries the count badge.
  Widget _buildMessagesButton() {
    return ValueListenableBuilder<int>(
      valueListenable: _unreadMessages,
      builder: (context, count, _) {
        final hasUnread = count > 0;
        final button = GestureDetector(
          onTap: _openMessages,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: hasUnread ? AppColors.primaryColor : AppColors.ghostWhite,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              hasUnread
                  ? Icons.chat_bubble_rounded
                  : Icons.chat_bubble_outline_rounded,
              size: 18,
              color: hasUnread ? AppColors.brandCharcoal : AppColors.neutral500,
            ),
          ),
        );
        if (!hasUnread) return button;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            button,
            // Directional so the badge stays on the trailing corner in Arabic.
            PositionedDirectional(
              top: -3,
              end: -3,
              child: Container(
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(8),
                  // Ring separating the badge from whatever is behind it.
                  border:
                      Border.all(color: AppColors.cardBackground, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  count > 9 ? '9+' : '$count',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white, // dark-ok: text on the red badge
                    fontSize: 9,
                    height: 1.1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Self-clearing alert card above the fold: the header badge alone still
  /// relies on the user looking at a 32px corner icon, so unread messages also
  /// get a full-width row right under the search bar. It disappears on its own
  /// once the thread is opened (the unread counter drops to 0 in Firestore).
  Widget _buildUnreadMessagesAlert() {
    return ValueListenableBuilder<int>(
      valueListenable: _unreadMessages,
      builder: (context, count, _) {
        if (count <= 0) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: GestureDetector(
            onTap: _openMessages,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                // brand-yellow alert tint, light in both themes — its content
                // is pinned to the light palette to match.
                color: const Color(0xFFFFF9E6), // dark-ok
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primaryColor, width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.chat_bubble_rounded,
                        size: 18, color: AppColors.brandCharcoal),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          count == 1
                              ? context.tr('home.newMessageAlert')
                              : context.tr('home.newMessagesAlert',
                                  args: {'n': count}),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.brandCharcoal,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          context.tr('home.newMessagesAlertAction'),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColorsLight.neutral500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: AppColorsLight.neutral500,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.ghostWhite,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          icon,
          size: 18,
          color: AppColors.neutral500,
        ),
      ),
    );
  }

  void _showSignInPrompt() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => Padding(
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
            const SizedBox(height: 28),
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                // brand-yellow tint behind the yellow icon
                color: Color(0xFFFFF9E6), // dark-ok
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_outline_rounded,
                  size: 38, color: AppColors.primaryColor),
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('bottomNav.signInToViewProfile'),
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.charcoal),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('bottomNav.signInDescription'),
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14, color: AppColors.neutral500, height: 1.5),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(sheetCtx);
                  Navigator.pushNamed(context, Routes.login);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: AppColors.brandCharcoal,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(context.tr('auth.signIn'),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(sheetCtx);
                  Navigator.pushNamed(context, Routes.signUp);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.charcoal,
                  side: BorderSide(color: AppColors.neutral200, width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(context.tr('bottomNav.createAccountAction'),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
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
        // dark-ok: intentionally dark hero panel with light content on it
        color: AppColors.brandCharcoal,
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
              color: Colors.white, // dark-ok: on the dark hero panel
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('home.heroDescription'),
            style: const TextStyle(
              fontSize: 13,
              height: 1.45,
              color: AppColorsLight.neutral200,
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
        // dark-ok: translucent tile inside the always-dark hero panel
        color: Colors.white.withValues(alpha: 0.08), // dark-ok
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.14)), // dark-ok
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
            style:
                const TextStyle(color: AppColorsLight.neutral200, fontSize: 10),
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
          color: AppColors.cardBackground,
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
                decoration: BoxDecoration(
                  border: BorderDirectional(
                    end: BorderSide(color: AppColors.neutral200, width: 1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      context.tr('home.where'),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        height: 1.25,
                        color: AppColors.charcoal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  border: BorderDirectional(
                    end: BorderSide(color: AppColors.neutral200, width: 1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      context.tr('home.checkIn'),
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 11,
                        height: 1.25,
                        color: AppColors.neutral400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  border: BorderDirectional(
                    end: BorderSide(color: AppColors.neutral200, width: 1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      context.tr('home.checkOut'),
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 11,
                        height: 1.25,
                        color: AppColors.neutral400,
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
                          style: TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: 11,
                            height: 1.25,
                            color: AppColors.neutral400,
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
                        color: AppColors.brandCharcoal,
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
      return _buildCategoriesSkeleton();
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

  /// Skeleton for the region-category chips row: circular photo placeholder
  /// with a short label bar underneath, matching [_buildCategoryChip].
  Widget _buildCategoriesSkeleton() {
    return SizedBox(
      height: 92,
      child: Skeletonizer(
        containersColor: AppColors.skeletonBaseColor,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: 5,
          separatorBuilder: (_, __) => const SizedBox(width: 16),
          itemBuilder: (_, __) => SizedBox(
            width: 72,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.neutral200,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 48,
                  height: 11,
                  decoration: BoxDecoration(
                    color: AppColors.neutral200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip({
    required int? id,
    required String label,
    String? photoUrl,
  }) {
    final isSelected = _selectedFeaturedRegionId == id;
    return GestureDetector(
      onTap: () {
        if (_selectedFeaturedRegionId == id) return;
        setState(() => _selectedFeaturedRegionId = id);
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
                color: AppColors.neutral100,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryColor
                      : AppColors.neutral200,
                  width: isSelected ? 2.5 : 1,
                ),
              ),
              child: ClipOval(
                child: (photoUrl != null && photoUrl.isNotEmpty)
                    ? CachedNetworkImage(
                        imageUrl: photoUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        memCacheWidth: 180,
                        placeholder: (_, __) => const SizedBox(
                          width: 60,
                          height: 60,
                        ),
                        errorWidget: (_, __, ___) => Icon(
                          Icons.place_outlined,
                          size: 24,
                          color: AppColors.neutral400,
                        ),
                      )
                    : Icon(
                        Icons.apps_rounded,
                        size: 26,
                        color: AppColors.neutral500,
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
                color: isSelected ? AppColors.charcoal : AppColors.neutral500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The listings area as a sliver: skeleton/empty states are single
  /// adapters, and the grouped/flat lists are lazy [SliverList]s so only
  /// visible sections/cards get built.
  Widget _buildContentSliver() {
    if (_segment == _HomeSegment.hotels) return _buildHotelsContentSliver();
    if (_isLoading) {
      return SliverToBoxAdapter(
        child: ListSkeletonLoader(
          itemCount: 4,
          showSearchBar: false,
          showCategories: false,
        ),
      );
    }

    // A failed load with nothing cached to fall back on — offer a retry rather
    // than the "no properties" copy, which would blame the catalogue for a
    // network failure. Pull-to-refresh works here too.
    if (_loadErrorKey != null && _properties.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: ErrorStateWidget(
            message: context.tr(_loadErrorKey!),
            onRetry: () => _loadData(forceRefresh: true),
          ),
        ),
      );
    }

    if (_properties.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.home_outlined,
                    size: 64, color: AppColors.neutral400),
                const SizedBox(height: 16),
                Text(
                  context.tr('property.noPropertiesFound'),
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.charcoal),
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr('property.noPropertiesFoundDescription'),
                  style: TextStyle(fontSize: 14, color: AppColors.neutral600),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_cityGroups.isEmpty) {
      return SliverList.separated(
        itemCount: _properties.length,
        itemBuilder: (_, i) => _buildPropertyCardFromData(_properties[i]),
        separatorBuilder: (_, __) => const SizedBox(height: 16),
      );
    }

    return SliverList.separated(
      itemCount: _cityGroups.length,
      itemBuilder: (_, gi) => _buildCityGroupSection(_cityGroups[gi], gi),
      separatorBuilder: (_, __) => const SizedBox(height: 32),
    );
  }


  /// The Hotels segment's listings area. Deliberately a sibling of
  /// [_buildContentSliver] rather than more branches inside it — the apartments
  /// path stays byte-identical to what it was.
  Widget _buildHotelsContentSliver() {
    if (_hotelsUnavailable) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: EmptyStateWidget(
            icon: Icons.hotel_outlined,
            title: context.tr('hotels.unavailableHere'),
            subtitle: context.tr('hotels.unavailableHereDescription'),
            // The 404 verdict is cached for the session, so without this the
            // guest would have to restart the app to pick up a backend that
            // deployed hotels in the meantime.
            buttonText: context.tr('common.tryAgain'),
            onButtonPressed: _retryHotels,
          ),
        ),
      );
    }

    if (_hotelsLoading) {
      return SliverToBoxAdapter(
        child: ListSkeletonLoader(
          itemCount: 4,
          showSearchBar: false,
          showCategories: false,
        ),
      );
    }

    if (_hotelsLoadErrorKey != null && _hotels.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: ErrorStateWidget(
            message: context.tr(_hotelsLoadErrorKey!),
            onRetry: () => _loadHotels(forceRefresh: true),
          ),
        ),
      );
    }

    if (_hotels.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.hotel_outlined,
                    size: 64, color: AppColors.neutral400),
                const SizedBox(height: 16),
                Text(
                  context.tr('hotels.noHotelsFound'),
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.charcoal),
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr('hotels.noHotelsFoundDescription'),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: AppColors.neutral600),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverList.separated(
      itemCount: _hotelGroups.length,
      itemBuilder: (_, gi) => _buildHotelGroupSection(_hotelGroups[gi], gi),
      separatorBuilder: (_, __) => const SizedBox(height: 32),
    );
  }

  Widget _buildHotelGroupSection(HotelGroup group, int index) {
    final heading = context.tr('hotels.hotelsIn', args: {'place': group.name});

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                heading,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  height: 1.25,
                  color: AppColors.charcoal,
                ),
              ),
            ),
            // Only a REGION group can be drilled into — a city group carries no
            // id to send back as regionId.
            if (group.canDrillDown)
              GestureDetector(
                onTap: () => Navigator.pushNamed(
                  context,
                  Routes.hotelSearchResults,
                  arguments: {
                    'regionId': group.regionId,
                    'regionName': group.name,
                  },
                ),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.neutral200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: AppColors.charcoal,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 268,
          child: ListView.separated(
            // A different key namespace from 'home_rail_$index': a shared one
            // would let the two segments restore each other's rail offsets.
            key: PageStorageKey('home_hotel_rail_$index'),
            scrollDirection: Axis.horizontal,
            itemCount: group.hotels.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final hotel = group.hotels[i];
              return SizedBox(
                width: 200,
                child: CompactHotelCard(
                  hotel: hotel,
                  onTap: () => Navigator.pushNamed(
                    context,
                    Routes.hotelDetails,
                    arguments: {
                      'hotelId': hotel.hotelId,
                      'hotelName': hotel.name,
                    },
                  ),
                  onFavoriteToggle: () => _toggleHotelFavorite(hotel.hotelId),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// The Apartments | Hotels switch.
  ///
  /// It is ALWAYS rendered. A control that disappears on its own reads as a
  /// bug, and hiding it used to strand anyone standing in the Hotels segment
  /// when a call failed: stepping back to Apartments made the switch vanish for
  /// the rest of the session, with no way back to even read the reason. A
  /// failure is explained inside the Hotels segment instead, with a retry.
  Widget _buildSegmentedToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        // neutral100 + a border, not ghostWhite: ghostWhite is a hair off the
        // page background in light mode, so the rail read as nothing at all and
        // the unselected half looked like a stray line of text.
        color: AppColors.neutral100,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Row(
        children: [
          Expanded(
            child: _segmentTab(
              _HomeSegment.apartments,
              'hotels.toggleApartments',
              Icons.home_work_outlined,
            ),
          ),
          Expanded(
            child: _segmentTab(
              _HomeSegment.hotels,
              'hotels.toggleHotels',
              Icons.hotel_outlined,
            ),
          ),
        ],
      ),
    );
  }

  Widget _segmentTab(_HomeSegment target, String labelKey, IconData icon) {
    final selected = _segment == target;
    // The unselected half is the one that has to work harder: an icon, full
    // charcoal text and a press ripple are what make it read as a control
    // rather than a caption sitting next to the selected pill.
    final foreground =
        selected ? AppColors.brandCharcoal : AppColors.charcoal;

    return Material(
      type: MaterialType.transparency,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _selectSegment(target),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryColor : AppColors.transparent,
            borderRadius: BorderRadius.circular(20),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: foreground),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  context.tr(labelKey),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: foreground,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectSegment(_HomeSegment target) {
    if (_segment == target) return;
    setState(() => _segment = target);
    // Back to the top: the two segments have unrelated content heights, so a
    // deep apartments offset would land mid-nowhere in the hotels list.
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
    if (target == _HomeSegment.hotels && !_hotelsRequested) _loadHotels();
  }

  Widget _buildCityGroupSection(CityPropertyGroup group, int index) {
    final headingPrefix =
        context.tr(_cityHeadingKeys[index % _cityHeadingKeys.length]);
    final displayName = group.localizedName(isArabic: context.isRtl);
    final heading = '$headingPrefix $displayName';
    final totalInRegion = group.totalCount ?? group.properties.length;
    final showSeeAll = totalInRegion >= 6 ||
        group.properties.length >= 6 ||
        group.regionId != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                heading,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  height: 1.25,
                  color: AppColors.charcoal,
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
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.neutral200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: AppColors.charcoal,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 260,
          child: ListView.separated(
            // Keeps this rail's scroll offset when the section is scrolled
            // out of view and disposed by the lazy sliver list.
            key: PageStorageKey('home_rail_$index'),
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
                  originalPrice: originalNightlyPrice(p),
                  discountPercent: effectiveDiscountPercent(p),
                  rating: (p['averageRating'] ?? p['rating'] ?? 0.0).toDouble(),
                  currency: (p['currency'] ?? 'EGP').toString(),
                  bedrooms: _asInt(p['bedrooms']),
                  beds: _asInt(p['beds']),
                  bathrooms: _asInt(p['bathrooms']),
                  propertyId: cid,
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
    final propertyId =
        (p['id'] ?? p['_id'] ?? p['propertyId'] ?? '').toString();
    final title = (p['title'] ?? p['name'] ?? 'Property').toString();
    final location = _extractLocation(p);
    final price = _extractPrice(p);
    final rating =
        (p['averageRating'] ?? p['rating'] ?? p['ratingAverage'] ?? 0.0);
    final reviewCount =
        (p['reviewsCount'] ?? p['reviewCount'] ?? p['totalReviews'] ?? 0);
    final imageUrl = _extractImage(p);
    final isGuestFavorite =
        (p['isGuestFavorite'] ?? p['guestFavorite'] ?? false) == true;

    final currency = (p['currency'] ?? 'EGP').toString();

    final discountPct = effectiveDiscountPercent(p);
    final original = originalNightlyPrice(p);
    final effectivePrice = double.tryParse(price) ?? 0;
    final originalPriceStr =
        (discountPct > 0 && original != null && original > effectivePrice)
            ? Money.format(original, currency)
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
      price: Money.format(double.tryParse(price) ?? 0, currency),
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
    final price = p['pricePerNight'] ??
        p['price'] ??
        p['basePrice'] ??
        p['nightlyPrice'] ??
        0;
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
      if (first is Map) {
        return (first['url'] ?? first['photoUrl'] ?? '').toString();
      }
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
          color: AppColors.cardBackground,
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
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      memCacheWidth: 800,
                      placeholder: (context, url) => Container(
                        width: double.infinity,
                        height: 200,
                        color: AppColors.neutral100,
                      ),
                      errorWidget: (context, url, error) {
                        return Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.neutral200,
                                AppColors.neutral300,
                              ],
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
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
                            color: AppColors.brandCharcoal,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: FavoriteHeartButton(
                      propertyId: propertyId,
                      onPressed: () => _toggleFavorite(propertyId),
                    ),
                  ),
                  if (discount != null)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.discountRed,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          discount,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                            height: 1.2,
                            color: Colors.white, // dark-ok: on the red badge
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
                  // Rating hidden when there are no reviews yet (web parity)
                  if ((double.tryParse(rating) ?? 0) > 0) ...[
                    Row(
                      children: [
                        const Icon(Icons.star,
                            size: 14, color: AppColors.primaryColor),
                        const SizedBox(width: 4),
                        Text(
                          rating,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            height: 1.25,
                            color: AppColors.charcoal,
                          ),
                        ),
                        if (reviewCount != null) ...[
                          const SizedBox(width: 4),
                          Text(
                            context.tr('home.reviewsCount',
                                args: {'n': reviewCount}),
                            style: TextStyle(
                              fontWeight: FontWeight.w400,
                              fontSize: 12,
                              height: 1.25,
                              color: AppColors.neutral500,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      height: 1.27,
                      color: AppColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    location,
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 11,
                      height: 1.27,
                      color: AppColors.neutral500,
                    ),
                  ),
                  if ((bedrooms ?? 0) > 0 ||
                      (beds ?? 0) > 0 ||
                      (bathrooms ?? 0) > 0) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if ((bedrooms ?? 0) > 0) ...[
                          Icon(Icons.door_front_door_outlined,
                              size: 13, color: AppColors.neutral500),
                          const SizedBox(width: 3),
                          Text('$bedrooms',
                              style: TextStyle(
                                  fontSize: 11, color: AppColors.neutral500)),
                          const SizedBox(width: 8),
                        ],
                        if ((beds ?? 0) > 0) ...[
                          Icon(Icons.bed_outlined,
                              size: 13, color: AppColors.neutral500),
                          const SizedBox(width: 3),
                          Text('$beds',
                              style: TextStyle(
                                  fontSize: 11, color: AppColors.neutral500)),
                          const SizedBox(width: 8),
                        ],
                        if ((bathrooms ?? 0) > 0) ...[
                          Icon(Icons.bathtub_outlined,
                              size: 13, color: AppColors.neutral500),
                          const SizedBox(width: 3),
                          Text('$bathrooms',
                              style: TextStyle(
                                  fontSize: 11, color: AppColors.neutral500)),
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
                          style: TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: 13,
                            height: 1.23,
                            color: AppColors.neutral400,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        price,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          height: 1.25,
                          color: AppColors.charcoal,
                        ),
                      ),
                      Text(
                        context.tr('home.perNight'),
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 13,
                          height: 1.23,
                          color: AppColors.neutral500,
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
      decoration: BoxDecoration(
        color: AppColors.ghostWhite,
      ),
      child: Column(
        children: [
          Text(
            context.tr('home.safeAndSecure'),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppColors.charcoal,
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
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppColors.neutral500,
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
            style: TextStyle(
              fontSize: 10,
              color: AppColors.neutral400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
