import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';

class VaultCryptoService {
  static String deriveKey(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return base64.encode(digest.bytes).substring(0, 32);
  }

  static String hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static String encryptSecret(String secret, String pin) {
    final key = encrypt.Key.fromUtf8(deriveKey(pin));
    final iv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
    final encrypted = encrypter.encrypt(secret, iv: iv);
    return '${base64.encode(iv.bytes)}:${encrypted.base64}';
  }

  static String decryptSecret(String encryptedData, String pin) {
    final parts = encryptedData.split(':');
    if (parts.length != 2) return '';
    final iv = encrypt.IV.fromBase64(parts[0]);
    final encrypted = encrypt.Encrypted.fromBase64(parts[1]);
    final key = encrypt.Key.fromUtf8(deriveKey(pin));
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
    return encrypter.decrypt(encrypted, iv: iv);
  }
}
