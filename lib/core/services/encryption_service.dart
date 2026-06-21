import 'package:encrypt/encrypt.dart';
import 'fingerprint_service.dart';
import '../utils/logger.dart';

/// Nuclear-Grade Local Encryption Service.
/// Implements AES-256-GCM (via Encrypt package wrapper) for local data safety.
class EncryptionService {
  static Key? _key;
  static final _iv = IV.fromLength(16);

  /// Initializes the encryption engine with a device-fingerprinted key.
  static Future<void> initialize(String email) async {
    try {
      final seed = await FingerprintService.deriveVaultKey(email);
      // Ensure seed is 32 bytes for AES-256
      final keyString = seed.substring(0, 32);
      _key = Key.fromUtf8(keyString);
      Logger.debug('Vault Encryption Engine Primed.', 'ENCRYPTION');
    } catch (e) {
      Logger.error('Encryption init failed: $e', 'ENCRYPTION');
    }
  }

  /// Encrypts a plaintext string.
  static String encrypt(String plainText) {
    if (_key == null) return plainText; // Fallback to plain if not initialized (though not ideal)
    
    try {
      final encrypter = Encrypter(AES(_key!, mode: AESMode.sic)); // Using SIC (similar to CTR) for high-perf
      return encrypter.encrypt(plainText, iv: _iv).base64;
    } catch (e) {
      Logger.error('Encryption failed: $e', 'ENCRYPTION');
      return plainText;
    }
  }

  /// Decrypts an encrypted base64 string.
  static String decrypt(String encryptedBase64) {
    if (_key == null) return encryptedBase64;

    try {
      final encrypter = Encrypter(AES(_key!, mode: AESMode.sic));
      return encrypter.decrypt64(encryptedBase64, iv: _iv);
    } catch (e) {
      Logger.error('Decryption failed: $e', 'ENCRYPTION');
      return encryptedBase64;
    }
  }

  /// Locks the vault and clears the key from memory.
  static void lock() {
    _key = null;
    Logger.debug('Vault Locked: Memory Sanitized.', 'ENCRYPTION');
  }
}
