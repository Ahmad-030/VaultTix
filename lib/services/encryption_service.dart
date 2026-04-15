// lib/services/encryption_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EncryptionService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _keyName = 'vault_encryption_key';
  static const _ivName = 'vault_encryption_iv';
  static const _pinKey = 'vault_real_pin';
  static const _fakePinKey = 'vault_fake_pin';
  static const _vaultModeKey = 'vault_mode_active';
  static const _autoLockKey = 'vault_auto_lock';

  // Generate or retrieve encryption key
  static Future<enc.Key> _getEncryptionKey() async {
    String? keyStr = await _storage.read(key: _keyName);
    if (keyStr == null) {
      final key = enc.Key.fromSecureRandom(32);
      await _storage.write(key: _keyName, value: base64.encode(key.bytes));
      return key;
    }
    return enc.Key(base64.decode(keyStr));
  }

  static Future<enc.IV> _getIV() async {
    String? ivStr = await _storage.read(key: _ivName);
    if (ivStr == null) {
      final iv = enc.IV.fromSecureRandom(16);
      await _storage.write(key: _ivName, value: base64.encode(iv.bytes));
      return iv;
    }
    return enc.IV(base64.decode(ivStr));
  }

  static Future<String> encrypt(String plainText) async {
    try {
      final key = await _getEncryptionKey();
      final iv = await _getIV();
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      return encrypter.encrypt(plainText, iv: iv).base64;
    } catch (e) {
      return plainText; // fallback
    }
  }

  static Future<String> decrypt(String encryptedText) async {
    try {
      final key = await _getEncryptionKey();
      final iv = await _getIV();
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      return encrypter.decrypt64(encryptedText, iv: iv);
    } catch (e) {
      return encryptedText; // fallback
    }
  }

  // PIN Management
  static String _hashPin(String pin) {
    final bytes = utf8.encode(pin + 'vaulttix_salt_2024');
    return sha256.convert(bytes).toString();
  }

  static Future<void> savePin(String pin) async {
    await _storage.write(key: _pinKey, value: _hashPin(pin));
  }

  static Future<void> saveFakePin(String pin) async {
    await _storage.write(key: _fakePinKey, value: _hashPin(pin));
  }

  static Future<bool> verifyPin(String pin) async {
    final stored = await _storage.read(key: _pinKey);
    return stored == _hashPin(pin);
  }

  static Future<bool> verifyFakePin(String pin) async {
    final stored = await _storage.read(key: _fakePinKey);
    if (stored == null) return false;
    return stored == _hashPin(pin);
  }

  static Future<bool> hasFakePin() async {
    return await _storage.read(key: _fakePinKey) != null;
  }

  static Future<bool> hasPin() async {
    return await _storage.read(key: _pinKey) != null;
  }

  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  // Vault mode (fake vs real)
  static Future<void> setVaultMode(bool isFake) async {
    await _storage.write(key: _vaultModeKey, value: isFake ? 'fake' : 'real');
  }

  static Future<bool> isFakeVaultMode() async {
    final mode = await _storage.read(key: _vaultModeKey);
    return mode == 'fake';
  }

  // Auto-lock
  static Future<void> saveAutoLockDuration(int seconds) async {
    await _storage.write(key: _autoLockKey, value: seconds.toString());
  }

  static Future<int> getAutoLockDuration() async {
    final val = await _storage.read(key: _autoLockKey);
    return int.tryParse(val ?? '30') ?? 30;
  }

  // Biometric
  static const _biometricKey = 'vault_biometric_enabled';

  static Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: _biometricKey, value: enabled ? '1' : '0');
  }

  static Future<bool> isBiometricEnabled() async {
    final val = await _storage.read(key: _biometricKey);
    return val == '1';
  }
}
