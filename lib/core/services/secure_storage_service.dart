import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

/// Secure storage and biometric authentication service.
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

  static final _localAuth = LocalAuthentication();

  // Storage keys
  static const _encryptionKeyKey = 'smriti_enc_key_v2';
  static const _biometricEnabledKey = 'smriti_biometric_enabled';
  static const _appLockEnabledKey = 'smriti_app_lock_enabled';
  static const _pinHashKey = 'smriti_pin_hash';
  static const _pinSaltKey = 'smriti_pin_salt';

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

  // ── Biometric / App Lock ─────────────────────────────────────────────────

  static Future<void> setBiometricEnabled(bool enabled) async =>
      _storage.write(key: _biometricEnabledKey, value: enabled.toString());

  static Future<bool> isBiometricEnabled() async =>
      (await _storage.read(key: _biometricEnabledKey)) == 'true';

  static Future<void> setAppLockEnabled(bool enabled) async =>
      _storage.write(key: _appLockEnabledKey, value: enabled.toString());

  static Future<bool> isAppLockEnabled() async =>
      (await _storage.read(key: _appLockEnabledKey)) == 'true';

  static Future<bool> canAuthenticateWithBiometrics() async {
    try {
      final available = await _localAuth.canCheckBiometrics;
      final supported = await _localAuth.isDeviceSupported();
      return available && supported;
    } catch (e) {
      debugPrint('Biometric check error: $e');
      return false;
    }
  }

  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  /// Returns true if authentication succeeded or is not required.
  static Future<bool> authenticateWithBiometrics({
    String reason = 'Authenticate to access Smriti',
  }) async {
    try {
      final lockEnabled = await isAppLockEnabled();
      if (!lockEnabled) return true;

      final biometricEnabled = await isBiometricEnabled();
      final canBiometric = await canAuthenticateWithBiometrics();

      if (biometricEnabled && canBiometric) {
        return await _localAuth.authenticate(
          localizedReason: reason,
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: false, // allow PIN fallback
          ),
        );
      }

      // App lock on but biometric not configured — allow access
      return true;
    } catch (e) {
      debugPrint('Authentication error: $e');
      return false;
    }
  }

  // ── PIN Management ────────────────────────────────────────────────────────

  /// Hash a PIN using SHA-256 with a unique salt (prevents rainbow-table attacks).
  static Future<void> setPin(String pin) async {
    final salt = base64Encode(_secureRandomBytes(16));
    final hash = _hashWithSalt(pin, salt);
    await _storage.write(key: _pinSaltKey, value: salt);
    await _storage.write(key: _pinHashKey, value: hash);
  }

  static Future<bool> verifyPin(String pin) async {
    final salt = await _storage.read(key: _pinSaltKey);
    final stored = await _storage.read(key: _pinHashKey);
    if (salt == null || stored == null) return false;
    return _hashWithSalt(pin, salt) == stored;
  }

  static Future<bool> hasPin() async =>
      (await _storage.read(key: _pinHashKey)) != null;

  static String _hashWithSalt(String input, String salt) {
    final bytes = utf8.encode('$salt:$input');
    return sha256.convert(bytes).toString();
  }

  // ── Generic Secure Store ─────────────────────────────────────────────────

  static Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  static Future<String?> read(String key) => _storage.read(key: key);

  static Future<void> delete(String key) => _storage.delete(key: key);

  static Future<void> clearAllSecureData() => _storage.deleteAll();
}
