import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage service for non-biometric data.
class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
    iOptions: IOSOptions(
      accountName: 'smriti_secure_storage',
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Storage keys
  static const _encryptionKeyKey = 'smriti_enc_key_v2';
  static const _openaiKeyKey = 'smriti_openai_key';
  static const _anthropicKeyKey = 'smriti_anthropic_key';
  static const _googleKeyKey = 'smriti_google_key';
  static const _activeProviderKey = 'smriti_active_provider';

  // ── Initialization ────────────────────────────────────────────────────────

  static Future<void> initialize() async {
    final existing = await _storage.read(key: _encryptionKeyKey);
    if (existing == null) {
      final key = _secureRandomBytes(32);
      await _storage.write(key: _encryptionKeyKey, value: base64Encode(key));
    }
  }

  static Uint8List _secureRandomBytes(int count) {
    final rng = Random.secure();
    return Uint8List.fromList(
      List.generate(count, (_) => rng.nextInt(256)),
    );
  }

  static Future<Uint8List> getEncryptionKey() async {
    final str = await _storage.read(key: _encryptionKeyKey);
    if (str == null) throw StateError('Encryption key not initialized');
    return base64Decode(str);
  }

  // ── API Key Management ──────────────────────────────────────────────────

  static Future<void> setOpenAIKey(String key) => _storage.write(key: _openaiKeyKey, value: key);
  static Future<String?> getOpenAIKey() => _storage.read(key: _openaiKeyKey);

  static Future<void> setAnthropicKey(String key) => _storage.write(key: _anthropicKeyKey, value: key);
  static Future<String?> getAnthropicKey() => _storage.read(key: _anthropicKeyKey);

  static Future<void> setGoogleKey(String key) => _storage.write(key: _googleKeyKey, value: key);
  static Future<String?> getGoogleKey() => _storage.read(key: _googleKeyKey);

  static Future<void> setActiveProvider(String provider) =>
      _storage.write(key: _activeProviderKey, value: provider);
  static Future<String> getActiveProvider() async =>
      (await _storage.read(key: _activeProviderKey)) ?? 'local';

  // ── Biometric / App Lock (Deprecated - returns false) ────────────────────

  static Future<bool> isBiometricEnabled() async => false;
  static Future<bool> isAppLockEnabled() async => false;
  static Future<bool> canAuthenticateWithBiometrics() async => false;
  static Future<bool> authenticateWithBiometrics({String reason = ''}) async => true;

  // ── Generic Secure Store ─────────────────────────────────────────────────


  static Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  static Future<String?> read(String key) => _storage.read(key: key);

  static Future<void> delete(String key) => _storage.delete(key: key);

  static Future<void> clearAllSecureData() => _storage.deleteAll();
}
