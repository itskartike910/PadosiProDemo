import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../storage/token_storage.dart';

class ApiClient {
  final Dio dio;
  final TokenStorage _tokenStorage;
  String _currentBaseUrl = AppConfig.backendBaseUrl;

  String get baseUrl => _currentBaseUrl;

  ApiClient(this.dio, this._tokenStorage) {
    dio.options.baseUrl = _currentBaseUrl;
    dio.options.connectTimeout = const Duration(seconds: 15);
    dio.options.receiveTimeout = const Duration(seconds: 15);
    dio.options.headers['Content-Type'] = 'application/json';

    _loadCustomUrl();

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final customUrl = await _tokenStorage.getServerUrl();
          if (customUrl != null && customUrl.isNotEmpty) {
            _currentBaseUrl = customUrl;
            dio.options.baseUrl = customUrl;
            options.baseUrl = customUrl;
          }
          final accessToken = await _tokenStorage.getAccessToken();
          if (accessToken != null) {
            options.headers['Authorization'] = 'Bearer $accessToken';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          if (error.response?.statusCode == 401) {
            final refreshToken = await _tokenStorage.getRefreshToken();
            if (refreshToken != null) {
              try {
                final refreshResponse = await Dio().post(
                  '$_currentBaseUrl/auth/refresh',
                  data: {'refresh_token': refreshToken},
                );
                if (refreshResponse.statusCode == 200) {
                  final data = refreshResponse.data['data'];
                  final newAccess  = data['access_token']  as String;
                  final newRefresh = data['refresh_token'] as String;

                  await _tokenStorage.saveTokens(
                    accessToken: newAccess,
                    refreshToken: newRefresh,
                  );

                  final original = error.requestOptions;
                  original.headers['Authorization'] = 'Bearer $newAccess';
                  final retryResponse = await dio.fetch(original);
                  return handler.resolve(retryResponse);
                }
              } catch (_) {
                await _tokenStorage.clearTokens();
              }
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<void> _loadCustomUrl() async {
    try {
      final customUrl = await _tokenStorage.getServerUrl();
      if (customUrl != null && customUrl.isNotEmpty) {
        _currentBaseUrl = customUrl;
        dio.options.baseUrl = customUrl;
      }
    } catch (_) {}
  }

  Future<void> updateBaseUrl(String newUrl) async {
    _currentBaseUrl = newUrl.trim();
    dio.options.baseUrl = _currentBaseUrl;
    await _tokenStorage.saveServerUrl(_currentBaseUrl);
  }

  Future<Response<T>> get<T>(String path,
          {Map<String, dynamic>? queryParameters}) =>
      dio.get<T>(path, queryParameters: queryParameters);

  Future<Response<T>> post<T>(String path,
          {dynamic data, Map<String, dynamic>? queryParameters}) =>
      dio.post<T>(path, data: data, queryParameters: queryParameters);

  Future<Response<T>> put<T>(String path,
          {dynamic data, Map<String, dynamic>? queryParameters}) =>
      dio.put<T>(path, data: data, queryParameters: queryParameters);

  Future<Response<T>> delete<T>(String path,
          {dynamic data, Map<String, dynamic>? queryParameters}) =>
      dio.delete<T>(path, data: data, queryParameters: queryParameters);
}

final dioProvider = Provider<Dio>((ref) => Dio());

final apiClientProvider = Provider<ApiClient>((ref) {
  final dio          = ref.watch(dioProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  return ApiClient(dio, tokenStorage);
});
