/// A home destination category from `GET /api/Lookups/RegionCategory`.
///
/// The backend returns `{ success, data: [{ id, name, propertyCount, photo }] }`.
/// [name] is localized by the backend per the `lang` request header. On the home
/// the chosen [id] is sent to `/api/property-search` as `featuredRegionId` (the
/// in-place chip filter); drilling into a region sends it as `villageId`.
class RegionCategory {
  final int id;
  final String name;
  final int propertyCount;
  final String photo;

  const RegionCategory({
    required this.id,
    required this.name,
    this.propertyCount = 0,
    this.photo = '',
  });

  factory RegionCategory.fromJson(Map<String, dynamic> json) {
    final idRaw = json['id'];
    final id = idRaw is int ? idRaw : int.tryParse(idRaw?.toString() ?? '') ?? 0;
    final countRaw = json['propertyCount'];
    final count =
        countRaw is int ? countRaw : int.tryParse(countRaw?.toString() ?? '') ?? 0;
    return RegionCategory(
      id: id,
      name: (json['name'] ?? '').toString(),
      propertyCount: count,
      photo: (json['photo'] ?? '').toString(),
    );
  }
}
