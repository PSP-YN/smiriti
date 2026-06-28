import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

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

  static final LocalAuthentication _localAuth = LocalAuthentication();

  static const _encryptionKeyKey = 'smriti_enc_key_v2';
  static const _openaiKeyKey = 'smriti_openai_key';
  static const _anthropicKeyKey = 'smriti_anthropic_key';
  static const _googleKeyKey = 'smriti_google_key';
  static const _activeProviderKey = 'smriti_active_provider';
  static const _appLockEnabledKey = 'smriti_app_lock';
  static const _appPinKey = 'smriti_app_pin';

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

  static Future<void> setAppLockEnabled(bool enabled) async {
    await _storage.write(key: _appLockEnabledKey, value: enabled.toString());
  }

  static Future<bool> isAppLockEnabled() async {
    final val = await _storage.read(key: _appLockEnabledKey);
    return val == 'true';
  }

  static Future<bool> canAuthenticateWithBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics ||
             await _localAuth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  static Future<bool> isBiometricEnabled() async {
    return await isAppLockEnabled() && await canAuthenticateWithBiometrics();
  }

  static Future<bool> authenticateWithBiometrics({String reason = ''}) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: reason.isNotEmpty ? reason : 'Authenticate to unlock Smriti',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  static Future<void> setAppPin(String pin) async {
    final bytes = _secureRandomBytes(32);
    final key = base64Encode(bytes);
    final iv = _secureRandomBytes(16);
    final encrypted = _encryptPin(pin, key, iv);
    await _storage.write(key: _appPinKey, value: '$key:${base64Encode(iv)}:$encrypted');
  }

  static Future<bool> verifyAppPin(String pin) async {
    final stored = await _storage.read(key: _appPinKey);
    if (stored == null) return false;
    final parts = stored.split(':');
    if (parts.length != 3) return false;
    final decrypted = _decryptPin(parts[2], parts[0], base64Decode(parts[1]));
    return decrypted == pin;
  }

  static Future<bool> hasAppPin() async {
    final val = await _storage.read(key: _appPinKey);
    return val != null;
  }

  static Future<void> removeAppPin() async {
    await _storage.delete(key: _appPinKey);
  }

  static String _encryptPin(String pin, String keyB64, List<int> iv) {
    final key = base64Decode(keyB64);
    final encrypted = <int>[];
    for (var i = 0; i < pin.codeUnits.length; i++) {
      encrypted.add(pin.codeUnits[i] ^ key[i % key.length] ^ iv[i % iv.length]);
    }
    return base64Encode(encrypted);
  }

  static String _decryptPin(String encryptedB64, String keyB64, List<int> iv) {
    final key = base64Decode(keyB64);
    final encrypted = base64Decode(encryptedB64);
    final decrypted = <int>[];
    for (var i = 0; i < encrypted.length; i++) {
      decrypted.add(encrypted[i] ^ key[i % key.length] ^ iv[i % iv.length]);
    }
    return String.fromCharCodes(decrypted);
  }

  static Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  static Future<String?> read(String key) => _storage.read(key: key);

  static Future<void> delete(String key) => _storage.delete(key: key);

  static Future<void> clearAllSecureData() => _storage.deleteAll();
}
