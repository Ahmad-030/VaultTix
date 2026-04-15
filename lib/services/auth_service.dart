// lib/services/auth_service.dart
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'encryption_service.dart';

class AuthService {
  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<bool> isBiometricAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      return canCheck && isDeviceSupported;
    } on PlatformException {
      return false;
    }
  }

  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException {
      return [];
    }
  }

  static Future<bool> authenticateWithBiometrics() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Authenticate to access VaultTix',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } on PlatformException {
      return false;
    }
  }

  /// Returns: 'real', 'fake', or null (wrong pin)
  static Future<String?> verifyPinAndGetVaultMode(String pin) async {
    if (await EncryptionService.verifyPin(pin)) {
      await EncryptionService.setVaultMode(false);
      return 'real';
    }
    if (await EncryptionService.verifyFakePin(pin)) {
      await EncryptionService.setVaultMode(true);
      return 'fake';
    }
    return null;
  }
}