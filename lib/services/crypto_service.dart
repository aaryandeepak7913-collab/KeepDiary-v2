import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

class EncryptedPayload {
  final String ivB64;
  final String ctB64;
  final int? updatedAt;

  EncryptedPayload({
    required this.ivB64,
    required this.ctB64,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'iv': ivB64,
        'ct': ctB64,
        if (updatedAt != null) 'updatedAt': updatedAt,
      };

  factory EncryptedPayload.fromJson(Map<dynamic, dynamic> json) {
    return EncryptedPayload(
      ivB64: json['iv'] as String,
      ctB64: json['ct'] as String,
      updatedAt: json['updatedAt'] as int?,
    );
  }
}

class CryptoService {
  static const _pbkdf2Iterations = 250000;
  static const _macLengthBytes = 16;
  static final _algorithm = AesGcm.with256bits();
  static final _random = Random.secure();

  static Uint8List randomBytes(int length) {
    return Uint8List.fromList(
      List<int>.generate(length, (_) => _random.nextInt(256)),
    );
  }

  static String bytesToB64(List<int> bytes) => base64Encode(bytes);
  static Uint8List b64ToBytes(String b64) => base64Decode(b64);

  static Future<SecretKey> deriveKey(String password, Uint8List salt) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: _pbkdf2Iterations,
      bits: 256,
    );
    return pbkdf2.deriveKeyFromPassword(password: password, nonce: salt);
  }

  static Future<EncryptedPayload> encrypt(SecretKey key, String plaintext) async {
    final nonce = _algorithm.newNonce();
    final secretBox = await _algorithm.encrypt(
      utf8.encode(plaintext),
      secretKey: key,
      nonce: nonce,
    );
    final combined = Uint8List.fromList([...secretBox.cipherText, ...secretBox.mac.bytes]);
    return EncryptedPayload(
      ivB64: bytesToB64(secretBox.nonce),
      ctB64: bytesToB64(combined),
    );
  }

  static Future<String> decrypt(SecretKey key, EncryptedPayload payload) async {
    final combined = b64ToBytes(payload.ctB64);
    final splitPoint = combined.length - _macLengthBytes;
    final cipherText = combined.sublist(0, splitPoint);
    final macBytes = combined.sublist(splitPoint);

    final secretBox = SecretBox(
      cipherText,
      nonce: b64ToBytes(payload.ivB64),
      mac: Mac(macBytes),
    );
    final plainBytes = await _algorithm.decrypt(secretBox, secretKey: key);
    return utf8.decode(plainBytes);
  }

  static Future<Uint8List> exportKeyRaw(SecretKey key) async {
    final data = await key.extractBytes();
    return Uint8List.fromList(data);
  }

  static SecretKey importKeyRaw(Uint8List raw) => SecretKey(raw);
}
