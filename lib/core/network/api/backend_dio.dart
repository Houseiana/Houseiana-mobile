import 'package:dio/dio.dart';
import 'package:houseiana_mobile_app/core/config/app_config.dart';
import 'package:houseiana_mobile_app/core/network/api/retry_interceptor.dart';

/// Per-attempt network timeouts for every call to the Houseiana backend.
///
/// The production API runs on Azure Container Apps with scale-to-zero: the
/// first request after an idle period pays a cold start — measured at ~31s to
/// first byte, with every request after it answering in under half a second.
/// The old 30s receive timeout sat just *below* that, so the first request of a
/// session reliably failed (the "search tab never loads" bug). The window below
/// leaves headroom for the cold start; [RetryInterceptor] covers the rest.
const Duration apiConnectTimeout = Duration(seconds: 20);
const Duration apiReceiveTimeout = Duration(seconds: 45);
const Duration apiSendTimeout = Duration(seconds: 45);

/// Standard [BaseOptions] for any Dio pointed at the backend.
BaseOptions backendBaseOptions() => BaseOptions(
      baseUrl: AppConfig.backendApiUrl,
      responseType: ResponseType.json,
      // Serialize list query params as repeated keys (e.g. amenities=1&amenities=2)
      // to match the web backend contract (PropertyAPI.publicSearchFilter).
      listFormat: ListFormat.multi,
      connectTimeout: apiConnectTimeout,
      receiveTimeout: apiReceiveTimeout,
      sendTimeout: apiSendTimeout,
    );

/// A backend client with the standard timeouts and the cold-start retry
/// attached. For the services that build their own Dio instead of taking the
/// shared one from the service locator — without this they would each drift
/// back to their own timeout values and lose the retry.
Dio buildBackendDio() =>
    Dio(backendBaseOptions())..interceptors.add(const RetryInterceptor());
