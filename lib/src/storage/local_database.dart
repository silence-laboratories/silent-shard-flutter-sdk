// Copyright (c) Silence Laboratories Pte. Ltd.
// This software is licensed under the Silence Laboratories License Agreement.

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
  Map<String, List<Keyshare2>> _keyshares;
  WalletBackup _walletBackup;

  LocalDatabase(this._storage, this._pairingData, this._keyshares, this._walletBackup, [bool saveOnCreation = true]) {
    if (saveOnCreation) {
      saveToStorage();
    }
  }

  // --- Serialization / Deserialization ---

  factory LocalDatabase.fromStorage(Sodium sodium, CTSSBindings ctss, Storage storage) {
    PairingData? pairingData;
    Map<String, List<Keyshare2>> keyshares = {};
    WalletBackup? walletBackup;

    final data = storage.getString(storageKey);
    if (data != null) {
      try {
        final json = jsonDecode(data);
        pairingData = PairingData.fromJson(sodium, json['pairingData']);
        keyshares =
            json['keyshares']?.map<Keyshare2>((key, value) => MapEntry(key, (value as List).map((e) => Keyshare2.fromBytes(ctss, e)).toList()));
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
      'keyshares': _keyshares.map((key, value) => MapEntry(key, value.map((e) => e.toBytes()).toList())),
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

  Map<String, List<Keyshare2>> get keyshares => Map.unmodifiable(_keyshares.map((key, value) => MapEntry(key, List.unmodifiable(value))));

  set keyshares(Map<String, List<Keyshare2>> newKeyshares) {
    _keyshares = Map.of(newKeyshares);
    saveToStorage();
  }

  void addKeyshare(String walletName, Keyshare2 newKeyshare) {
    if (_keyshares.containsKey(walletName)) {
      _keyshares[walletName]!.add(newKeyshare);
    } else {
      _keyshares[walletName] = [newKeyshare];
    }
    saveToStorage();
  }

  void addKeyshares(String walletName, Iterable<Keyshare2> newKeyshares) {
    if (_keyshares.containsKey(walletName)) {
      _keyshares[walletName]!.addAll(newKeyshares);
    } else {
      _keyshares[walletName] = List.of(newKeyshares);
    }
    saveToStorage();
  }

  void removeKeyshareAt(String walletName, int index) {
    if (_keyshares.containsKey(walletName)) {
      _keyshares[walletName]!.removeAt(index);
    }
    saveToStorage();
  }

  void removeAllKeyshares() {
    _keyshares.clear();
    saveToStorage();
  }

  // --- Wallet Backup ---

  WalletBackup get walletBackup => _walletBackup;

  set walletBackup(WalletBackup? backup) {
    _walletBackup = backup ?? WalletBackup();
    saveToStorage();
  }
}
