import 'dart:io';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:device_info_plus/device_info_plus.dart';
import '../utils/logger.dart';

/// Professional Device Fingerprinting Service.
/// Extracts unique hardware identifiers to anchor the application state.
class FingerprintService {
  static String? _cachedFingerprint;

  /// Generates a unique SHA-256 fingerprint for the current device.
  static Future<String> getFingerprint() async {
    if (_cachedFingerprint != null) return _cachedFingerprint!;

    try {
      final deviceInfo = DeviceInfoPlugin();
      String rawData = '';

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        rawData = '${androidInfo.brand}|${androidInfo.model}|${androidInfo.id}|${androidInfo.hardware}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        rawData = '${iosInfo.name}|${iosInfo.model}|${iosInfo.systemName}|${iosInfo.utsname.machine}';
      } else {
        rawData = 'web-or-other|${Platform.operatingSystem}';
      }

      final bytes = utf8.encode(rawData);
      final digest = sha256.convert(bytes);
      _cachedFingerprint = digest.toString();
      
      Logger.debug('Device Identity Anchored: [${_cachedFingerprint!.substring(0, 8)}...]', 'FINGERPRINT');
      return _cachedFingerprint!;
    } catch (e) {
      Logger.error('Fingerprinting failed: $e', 'FINGERPRINT');
      return 'anonymous_vault_identity';
    }
  }

  /// Derives an application-specific encryption salt from the fingerprint.
  static Future<String> deriveVaultKey(String email) async {
    final fingerprint = await getFingerprint();
    final combined = '$email:$fingerprint:vault_salt_v1';
    final bytes = utf8.encode(combined);
    return sha256.convert(bytes).toString();
  }
}
