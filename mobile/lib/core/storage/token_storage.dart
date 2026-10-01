import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  final FlutterSecureStorage _storage;

  static const _accessKey  = 'padosi_access_token';
  static const _refreshKey = 'padosi_refresh_token';

  static const _serverUrlKey = 'padosi_server_base_url';

  const TokenStorage(this._storage);

  Future<String?> getAccessToken()  => _storage.read(key: _accessKey);
  Future<String?> getRefreshToken() => _storage.read(key: _refreshKey);
  Future<String?> getServerUrl()    => _storage.read(key: _serverUrlKey);

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessKey,  value: accessToken);
    await _storage.write(key: _refreshKey, value: refreshToken);
  }

  Future<void> saveServerUrl(String url) async {
    await _storage.write(key: _serverUrlKey, value: url);
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }
}

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  const storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
  return TokenStorage(storage);
});
