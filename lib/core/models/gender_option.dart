import 'package:equatable/equatable.dart';

/// A gender option returned by `GET /api/Lookups/Gender` → `{ id, name }`.
///
/// Drives the Personal Information gender dropdown and, crucially, supplies the
/// integer `genderId` that `POST /users/{id}/profile` expects (the backend
/// binds `genderId`, not a gender name string).
class GenderOption extends Equatable {
  final int id;
  final String name;

  const GenderOption({required this.id, required this.name});

  factory GenderOption.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final id = rawId is int
        ? rawId
        : (rawId is num
            ? rawId.toInt()
            : int.tryParse(rawId?.toString() ?? '') ?? 0);
    return GenderOption(
      id: id,
      name: (json['name'] ?? json['label'] ?? '').toString(),
    );
  }

  /// Used when the lookup endpoint is unavailable. Mirrors the backend payload
  /// (`Male = 1`, `Female = 2`) so the dropdown still works offline.
  static const List<GenderOption> fallback = [
    GenderOption(id: 1, name: 'Male'),
    GenderOption(id: 2, name: 'Female'),
  ];

  @override
  List<Object?> get props => [id, name];
}
