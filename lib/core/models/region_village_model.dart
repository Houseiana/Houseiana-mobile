/// A village inside a destination region, from
/// `GET /api/Lookups/region-villages?regionId={id}` →
/// `{ success, data: [{ id, name, propertyCount }] }` (no photo field).
///
/// [id] is what `/api/property-search` expects as the `villageId` query param
/// — village ids (224–595…) live in a different id space than the
/// RegionCategory region ids (18–28…), so the two must never be mixed.
/// [name] localizes via the `lang` QUERY param (the `lang` header is ignored).
class RegionVillage {
  final int id;
  final String name;
  final int propertyCount;

  const RegionVillage({
    required this.id,
    required this.name,
    this.propertyCount = 0,
  });

  factory RegionVillage.fromJson(Map<String, dynamic> json) {
    final idRaw = json['id'];
    final countRaw = json['propertyCount'];
    return RegionVillage(
      id: idRaw is int ? idRaw : int.tryParse(idRaw?.toString() ?? '') ?? 0,
      name: (json['name'] ?? '').toString().trim(),
      propertyCount: countRaw is int
          ? countRaw
          : int.tryParse(countRaw?.toString() ?? '') ?? 0,
    );
  }
}
