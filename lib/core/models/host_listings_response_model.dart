import 'package:houseiana_mobile_app/core/models/property_model.dart';

class HostListingsResponse {
  final List<PropertyModel> properties;
  final PaginationData pagination;
  final StatusCounts statusCounts;

  HostListingsResponse({
    required this.properties,
    required this.pagination,
    required this.statusCounts,
  });

  factory HostListingsResponse.fromJson(Map<String, dynamic> json) {
    return HostListingsResponse(
      properties: (json['data'] as List<dynamic>?)
              ?.map((e) => PropertyModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      pagination: PaginationData.fromJson(
          json['pagination'] as Map<String, dynamic>? ?? {}),
      statusCounts: StatusCounts.fromJson(
          json['statusCounts'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class PaginationData {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  PaginationData({
    this.page = 1,
    this.limit = 20,
    this.total = 0,
    this.totalPages = 0,
  });

  factory PaginationData.fromJson(Map<String, dynamic> json) {
    return PaginationData(
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 20,
      total: json['total'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 0,
    );
  }
}

class StatusCounts {
  final int allCount;
  final int activeCount;
  final int pendingCount;
  final int draftCount;
  final int inactiveCount;
  final int actionRequiredCount;
  final int rejectedCount;

  StatusCounts({
    this.allCount = 0,
    this.activeCount = 0,
    this.pendingCount = 0,
    this.draftCount = 0,
    this.inactiveCount = 0,
    this.actionRequiredCount = 0,
    this.rejectedCount = 0,
  });

  factory StatusCounts.fromJson(Map<String, dynamic> json) {
    return StatusCounts(
      allCount: json['allCount'] as int? ?? 0,
      activeCount: json['activeCount'] as int? ?? 0,
      pendingCount: json['pendingCount'] as int? ?? 0,
      draftCount: json['draftCount'] as int? ?? 0,
      inactiveCount: json['inactiveCount'] as int? ?? 0,
      actionRequiredCount: json['actionRequiredCount'] as int? ?? 0,
      rejectedCount: json['rejectedCount'] as int? ?? 0,
    );
  }
}
