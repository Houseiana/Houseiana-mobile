/// A country from `GET /api/lookups/country` → `{ success, data: [{ id, name }] }`.
///
/// [name] localizes via the `lang` QUERY param (the `lang` header is ignored
/// by the Lookups controller). Ids are stable (1 = Qatar, 2 = Egypt,
/// 3 = Bahrain) — UI decorations (flag emoji) must key off [id], never the
/// localized name.
class CountryOption {
  final int id;
  final String name;

  const CountryOption({required this.id, required this.name});

  factory CountryOption.fromJson(Map<String, dynamic> json) {
    final idRaw = json['id'];
    return CountryOption(
      id: idRaw is int ? idRaw : int.tryParse(idRaw?.toString() ?? '') ?? 0,
      name: (json['name'] ?? '').toString().trim(),
    );
  }
}
