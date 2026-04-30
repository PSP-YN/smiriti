import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_PKCS1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
    iOptions: IOSOptions(
      accountName: 'smriti_secure_storage',
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static final LocalAuthentication _localAuth = LocalAuthentication();

  static const String _encryptionKeyKey = 'smriti_encryption_key';
  static const String _biometricEnabledKey = 'smriti_biometric_enabled';
  static const String _appLockEnabledKey = 'smriti_app_lock_enabled';

  static Future<void> initialize() async {
    // Check if encryption key exists, generate if not
    final existingKey = await _storage.read(key: _encryptionKeyKey);
    if (existingKey == null) {
      final key = _generateEncryptionKey();
      await _storage.write(key: _encryptionKeyKey, value: base64Encode(key));
    }
  }

  static Uint8List _generateEncryptionKey() {
    final random = SecureRandom();
    return random.nextBytes(32); // 256-bit key
  }

  static Future<Uint8List> getEncryptionKey() async {
    final keyString = await _storage.read(key: _encryptionKeyKey);
    if (keyString == null) {
      throw StateError('Encryption key not initialized');
    }
    return base64Decode(keyString);
  }

  static Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(
      key: _biometricEnabledKey,
      value: enabled.toString(),
    );
  }

  static Future<bool> isBiometricEnabled() async {
    final value = await _storage.read(key: _biometricEnabledKey);
    return value == 'true';
  }

  static Future<void> setAppLockEnabled(bool enabled) async {
    await _storage.write(
      key: _appLockEnabledKey,
      value: enabled.toString(),
    );
  }

  static Future<bool> isAppLockEnabled() async {
    final value = await _storage.read(key: _appLockEnabledKey);
    return value == 'true';
  }

  static Future<bool> canAuthenticateWithBiometrics() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> authenticateWithBiometrics({
    String localizedReason = 'Authenticate to access Smriti',
  }) async {
    try {
      final isEnabled = await isBiometricEnabled();
      if (!isEnabled) return true;

      final canAuth = await canAuthenticateWithBiometrics();
      if (!canAuth) return true;

      return await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } catch (e) {
      debugPrint('Biometric authentication error: $e');
      return false;
    }
  }

  static Future<void> storeSecureValue(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  static Future<String?> getSecureValue(String key) async {
    return await _storage.read(key: key);
  }

  static Future<void> deleteSecureValue(String key) async {
    await _storage.delete(key: key);
  }

  static Future<void> clearAllSecureData() async {
    await _storage.deleteAll();
  }

  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  static bool verifyPassword(String password, String hash) {
    return hashPassword(password) == hash;
  }
}

class SecureRandom {
  final _random = Random.secure();

  Uint8List nextBytes(int length) {
    final result = Uint8List(length);
    for (var i = 0; i < length; i++) {
      result[i] = _random.nextInt(256);
    }
    return result;
  }
}
