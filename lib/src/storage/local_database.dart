import 'dart:collection';
import 'dart:convert';

import 'package:sodium/sodium.dart';

import 'storage.dart';
import '../types/pairing_data.dart';
import '../types/keyshare.dart';
import '../types/wallet_backup.dart';
import '../ctss_bindings_generated.dart';

class LocalDatabase {
  static const storageKey = "silentshard.storage";

  Storage _storage;

  PairingData? _pairingData;
  List<Keyshare2> _keyshares;
  WalletBackup _walletBackup;

  LocalDatabase(this._storage, this._pairingData, this._keyshares, this._walletBackup, [bool saveOnCreation = true]) {
    if (saveOnCreation) {
      saveToStorage();
    }
  }

  // --- Serialization / Deserialization ---

  factory LocalDatabase.fromStorage(Sodium sodium, CTSSBindings ctss, Storage storage) {
    PairingData? pairingData;
    List<Keyshare2> keyshares = [];
    WalletBackup? walletBackup;

    final data = storage.getString(storageKey);
    if (data != null) {
      try {
        final json = jsonDecode(data);
        pairingData = PairingData.fromJson(sodium, json['pairingData']);
        keyshares = json['keyshares']?.map<Keyshare2>((e) => Keyshare2.fromBytes(ctss, e)).toList();
        walletBackup = WalletBackup.fromJson(json['backup']);
      } catch (e) {
        print('Failed to load local state: $e');
      }
    }

    return LocalDatabase(storage, pairingData, keyshares, walletBackup ?? WalletBackup(), false);
  }

  void saveToStorage() {
    final json = {
      'pairingData': _pairingData?.toJson(),
      'keyshares': _keyshares.map((e) => e.toBytes()).toList(),
      'backup': _walletBackup.toJson(),
    };
    _storage.setString(storageKey, jsonEncode(json));
  }

  // --- Pairing Data ---

  PairingData? get pairingData => _pairingData;

  set pairingData(PairingData? data) {
    _pairingData = data;
    saveToStorage();
  }

  // --- Keyshares ---

  List<Keyshare2> get keyshares => UnmodifiableListView(_keyshares);

  set keyshares(Iterable<Keyshare2> newKeyshares) {
    _keyshares = List.of(newKeyshares);
    saveToStorage();
  }

  void addKeyshare(Keyshare2 newKeyshare) {
    _keyshares.add(newKeyshare);
    saveToStorage();
  }

  void addKeyshares(Iterable<Keyshare2> newKeyshares) {
    _keyshares.addAll(newKeyshares);
    saveToStorage();
  }

  void removeKeyshareAt(int index) {
    _keyshares.removeAt(index);
    saveToStorage();
  }

  void removeAllKeyshares() {
    _keyshares = [];
    saveToStorage();
  }

  // --- Wallet Backup ---

  WalletBackup get walletBackup => _walletBackup;

  set walletBackup(WalletBackup? backup) {
    _walletBackup = backup ?? WalletBackup();
    saveToStorage();
  }
}
