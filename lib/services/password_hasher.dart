import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

class PasswordHasher {
  PasswordHasher._();

  static const _algorithm = 'pbkdf2-sha256';
  static const _iterations = 600000;
  static const _saltLength = 16;
  static const _derivedKeyLength = 32;
  static const _yieldInterval = 8192;

  static Future<String> hash(String password) async {
    final random = Random.secure();
    final salt = List<int>.generate(
      _saltLength,
      (_) => random.nextInt(256),
    );
    final derivedKey = await _deriveKey(utf8.encode(password), salt);
    return '$_algorithm:$_iterations:${base64Encode(salt)}:${base64Encode(derivedKey)}';
  }

  static Future<bool> verify(String password, String encodedHash) async {
    final parts = encodedHash.split(':');
    if (parts.length != 4 ||
        parts[0] != _algorithm ||
        int.tryParse(parts[1]) != _iterations) {
      return false;
    }

    try {
      final salt = base64Decode(parts[2]);
      final expected = base64Decode(parts[3]);
      if (salt.length != _saltLength ||
          expected.length != _derivedKeyLength) {
        return false;
      }
      final actual = await _deriveKey(utf8.encode(password), salt);
      var difference = 0;
      for (var index = 0; index < expected.length; index++) {
        difference |= expected[index] ^ actual[index];
      }
      return difference == 0;
    } on FormatException {
      return false;
    }
  }

  static Future<List<int>> _deriveKey(List<int> password, List<int> salt) async {
    final hmac = Hmac(sha256, password);
    final firstBlock = hmac.convert([...salt, 0, 0, 0, 1]).bytes;
    var block = List<int>.from(firstBlock);
    final result = List<int>.from(firstBlock);

    for (var round = 1; round < _iterations; round++) {
      block = hmac.convert(block).bytes;
      for (var index = 0; index < result.length; index++) {
        result[index] ^= block[index];
      }
      if (round % _yieldInterval == 0) {
        await Future<void>.delayed(Duration.zero);
      }
    }
    return result;
  }
}