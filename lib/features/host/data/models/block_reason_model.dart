import 'package:equatable/equatable.dart';

/// A reason a host can pick when blocking dates.
/// Sourced from `GET /api/Lookups/ReasonBlockProperty` ([{ id, name }]).
class BlockReason extends Equatable {
  final int id;
  final String name;

  const BlockReason({required this.id, required this.name});

  factory BlockReason.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] ?? json['reasonId'] ?? json['value'];
    final id = rawId is int
        ? rawId
        : int.tryParse(rawId?.toString() ?? '') ?? 0;
    final name =
        (json['name'] ?? json['title'] ?? json['label'] ?? '').toString();
    return BlockReason(id: id, name: name);
  }

  /// Used when the lookup endpoint fails or returns nothing, so the host can
  /// still block dates. IDs mirror the common backend ordering.
  static const List<BlockReason> fallback = [
    BlockReason(id: 1, name: 'Owner Use'),
    BlockReason(id: 2, name: 'Maintenance'),
    BlockReason(id: 3, name: 'Renovation'),
    BlockReason(id: 4, name: 'Booked Elsewhere'),
    BlockReason(id: 5, name: 'Other'),
  ];

  @override
  List<Object?> get props => [id, name];
}
