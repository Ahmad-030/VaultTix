// lib/services/auth_service.dart
import 'encryption_service.dart';

class AuthService {
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