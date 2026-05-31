import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/services/property_service.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/features/properties/presentation/cubit/properties_state.dart';

class PropertiesCubit extends Cubit<PropertiesState> {
  final PropertyService _propertyService;
  final UserSession _session;

  int _currentPage = 1;
  static const int _pageLimit = 20;
  bool _hasMore = true;

  PropertiesCubit(this._propertyService, this._session)
      : super(PropertiesInitial());

  Future<void> getProperties({
    String? location,
    String? checkIn,
    String? checkOut,
    int? guests,
  }) async {
    emit(PropertiesLoading());
    _currentPage = 1;
    _hasMore = true;

    try {
      final properties = await _propertyService.getProperties(
        location: location,
        checkIn: checkIn,
        checkOut: checkOut,
        guests: guests,
        userId: _session.userId,
        page: 1,
        limit: _pageLimit,
      );

      _hasMore = properties.length >= _pageLimit;
      emit(PropertiesLoaded(
        properties: properties,
        hasMore: _hasMore,
        currentPage: 1,
      ));
    } catch (e) {
      emit(PropertiesError(message: e.toString()));
    }
  }

  Future<void> loadMore({
    String? location,
    String? checkIn,
    String? checkOut,
    int? guests,
  }) async {
    final current = state;
    if (current is! PropertiesLoaded || !current.hasMore || current.isLoadingMore) return;

    emit(current.copyWith(isLoadingMore: true));

    try {
      final nextPage = _currentPage + 1;
      final more = await _propertyService.getProperties(
        location: location,
        checkIn: checkIn,
        checkOut: checkOut,
        guests: guests,
        userId: _session.userId,
        page: nextPage,
        limit: _pageLimit,
      );

      if (more.isEmpty) {
        _hasMore = false;
        emit(current.copyWith(hasMore: false, isLoadingMore: false));
      } else {
        _currentPage = nextPage;
        _hasMore = more.length >= _pageLimit;
        emit(PropertiesLoaded(
          properties: [...current.properties, ...more],
          hasMore: _hasMore,
          currentPage: _currentPage,
        ));
      }
    } catch (e) {
      emit(current.copyWith(isLoadingMore: false));
    }
  }

  Future<void> searchProperties(String query) async {
    await getProperties(location: query);
  }
}