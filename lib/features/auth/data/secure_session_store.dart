import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:helios_auth_contract/helios_auth_contract.dart';

const _kToken = 'helios_jwt';
const _kUser = 'helios_user_json';

/// Persists Helios JWT and minimal user JSON.
///
/// **Mobile:** `flutter_secure_storage` uses Keychain / EncryptedSharedPreferences.
/// **Web:** Uses Web Crypto when available; values are still more exposed than on
/// mobile — see `AGENTS.md`. Do not treat web storage as hardware-backed.
class SecureSessionStore {
  SecureSessionStore({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
              webOptions: WebOptions(
                dbName: 'HeliosSecureStorage',
                publicKey: 'HeliosWebEncryption',
              ),
            );

  final FlutterSecureStorage _storage;

  Future<void> writeSession({required String token, required HeliosUser user}) async {
    await _storage.write(key: _kToken, value: token);
    await _storage.write(key: _kUser, value: jsonEncode(user.toJson()));
  }

  Future<StoredSession?> readSession() async {
    final token = await _storage.read(key: _kToken);
    final raw = await _storage.read(key: _kUser);
    if (token == null || token.isEmpty) return null;
    if (raw == null || raw.isEmpty) {
      debugPrint('Helios: JWT present but user JSON missing; clearing session');
      await clear();
      return null;
    }
    try {
      final user = HeliosUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      return StoredSession(token: token, user: user);
    } catch (e) {
      debugPrint('Helios: corrupt user cache: $e');
      await clear();
      return null;
    }
  }

  Future<void> clear() async {
    await _storage.delete(key: _kToken);
    await _storage.delete(key: _kUser);
  }
}

class StoredSession {
  StoredSession({required this.token, required this.user});

  final String token;
  final HeliosUser user;
}
