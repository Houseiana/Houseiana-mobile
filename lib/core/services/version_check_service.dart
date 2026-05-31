import 'dart:io' show Platform;

import 'package:houseiana_mobile_app/core/network/api/api_consumer.dart';
import 'package:houseiana_mobile_app/core/network/api/end_points.dart';
import 'package:houseiana_mobile_app/features/splash/data/model/version_check_model.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Calls `/api/auth/version-check` to determine whether the current build
/// must be upgraded before the user is allowed to continue.
///
/// Platform encoding: 1 = iOS, 2 = Android.
class VersionCheckService {
  final ApiConsumer _api;

  VersionCheckService(this._api);

  Future<VersionCheckModel> checkVersion() async {
    final info = await PackageInfo.fromPlatform();
    final version = info.version;
    final platform = Platform.isIOS ? 1 : 2;

    final response = await _api.get(
      EndPoints.versionCheck,
      queryParameters: {
        'version': version,
        'platform': platform,
      },
    );

    if (response is Map<String, dynamic>) {
      return VersionCheckModel.fromJson(response);
    }
    return const VersionCheckModel(forceUpdate: false, updateUrl: '');
  }
}
