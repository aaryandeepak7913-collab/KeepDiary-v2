import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'crypto_service.dart';

class EntryRecord {
  final String date;
  final EncryptedPayload payload;

  EntryRecord({required this.date, required this.payload});

  Map<String, dynamic> toMap() => {'date': date, ...payload.toJson()};

  factory EntryRecord.fromMap(Map<dynamic, dynamic> map) {
    return EntryRecord(
      date: map['date'] as String,
      payload: EncryptedPayload.fromJson(map),
    );
  }
}

class VaultMeta {
  final String salt;
  final EncryptedPayload verifier;
  String? driveFileId;

  VaultMeta({required this.salt, required this.verifier, this.driveFileId});

  Map<String, dynamic> toMap() => {
        'salt': salt,
        'verifier': verifier.toJson(),
        'driveFileId': driveFileId,
      };

  factory VaultMeta.fromMap(Map<dynamic, dynamic> map) {
    return VaultMeta(
      salt: map['salt'] as String,
      verifier: EncryptedPayload.fromJson(map['verifier'] as Map),
      driveFileId: map['driveFileId'] as String?,
    );
  }
}

class StorageService {
  static const _metaBoxName = 'vault_meta';
  static const _entriesBoxName = 'vault_entries';
  static const _bioBoxName = 'vault_bio';

  late Box _metaBox;
  late Box _entriesBox;
  late Box _bioBox;

  static final StorageService instance = StorageService._();
  StorageService._();

  Future<void> init() async {
    await Hive.initFlutter();
    _metaBox = await Hive.openBox(_metaBoxName);
    _entriesBox = await Hive.openBox(_entriesBoxName);
    _bioBox = await Hive.openBox(_bioBoxName);
  }

  bool get hasVault => _metaBox.containsKey('meta');

  Future<void> saveVaultMeta(VaultMeta meta) async {
    await _metaBox.put('meta', jsonEncode(meta.toMap()));
  }

  VaultMeta? loadVaultMeta() {
    final raw = _metaBox.get('meta');
    if (raw == null) return null;
    return VaultMeta.fromMap(jsonDecode(raw as String) as Map);
  }

  Future<void> saveEntry(EntryRecord entry) async {
    await _entriesBox.put(entry.date, jsonEncode(entry.toMap()));
  }

  Future<void> deleteEntry(String date) async {
    await _entriesBox.delete(date);
  }

  EntryRecord? loadEntry(String date) {
    final raw = _entriesBox.get(date);
    if (raw == null) return null;
    return EntryRecord.fromMap(jsonDecode(raw as String) as Map);
  }

  List<String> allEntryDates() {
    return _entriesBox.keys.cast<String>().toList()..sort();
  }

  Future<void> wipeEverything() async {
    await _metaBox.clear();
    await _entriesBox.clear();
    await _bioBox.clear();
  }

  Future<void> saveBiometricWrap(Map<String, dynamic> data) async {
    await _bioBox.put('bio', jsonEncode(data));
  }

  Map<String, dynamic>? loadBiometricWrap() {
    final raw = _bioBox.get('bio');
    if (raw == null) return null;
    return jsonDecode(raw as String) as Map<String, dynamic>;
  }

  Future<void> clearBiometricWrap() async {
    await _bioBox.delete('bio');
  }
}
