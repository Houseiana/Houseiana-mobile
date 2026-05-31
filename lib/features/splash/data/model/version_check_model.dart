class VersionCheckModel {
  final bool forceUpdate;
  final String updateUrl;

  const VersionCheckModel({
    required this.forceUpdate,
    required this.updateUrl,
  });

  factory VersionCheckModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;
    return VersionCheckModel(
      forceUpdate: data['forceUpdate'] == true,
      updateUrl: data['updateUrl']?.toString() ?? '',
    );
  }
}
