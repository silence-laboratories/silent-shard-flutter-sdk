// Copyright (c) Silence Laboratories Pte. Ltd.
// This software is licensed under the Silence Laboratories License Agreement.

import 'dart:convert';

import 'package:dart_2_party_ecdsa/dart_2_party_ecdsa.dart';
import 'package:sodium/sodium.dart';

import 'storage.dart';
import '../ctss_bindings_generated.dart';

class LocalDatabase {
  static const storageKey = "silentshard.storage";

  Storage _storage;

  PairingData? _pairingData;
  Map<String, List<Keyshare2>> _keyshares;
  Map<String, WalletBackup> _walletBackups;

  LocalDatabase(this._storage, this._pairingData, this._keyshares, this._walletBackups, [bool saveOnCreation = true]) {
    if (saveOnCreation) {
      saveToStorage();
    }
  }

  // --- Serialization / Deserialization ---

  factory LocalDatabase.fromStorage(Sodium sodium, CTSSBindings ctss, Storage storage) {
    PairingData? pairingData;
    Map<String, List<Keyshare2>> keyshares = {};
    Map<String, WalletBackup> walletBackup = {};

    final data = storage.getString(storageKey);
    if (data != null) {
      try {
        final json = jsonDecode(data);
        pairingData = PairingData.fromJson(sodium, json['pairingData']);
        keyshares =
            json['keyshares']?.map<Keyshare2>((key, value) => MapEntry(key, (value as List).map((e) => Keyshare2.fromBytes(ctss, e)).toList()));
        walletBackup = json['backup']?.map<WalletBackup>((key, value) => MapEntry(key, WalletBackup.fromJson(value)));
      } catch (e) {
        print('Failed to load local state: $e');
      }
    }

    return LocalDatabase(storage, pairingData, keyshares, walletBackup, false);
  }

  void saveToStorage() {
    final json = {
      'pairingData': _pairingData?.toJson(),
      'keyshares': _keyshares.map((key, value) => MapEntry(key, value.map((e) => e.toBytes()).toList())),
      'backup': _walletBackups.map((key, value) => MapEntry(key, value.toJson())),
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

  void addKeyshare(String walletId, Keyshare2 newKeyshare) {
    if (_keyshares.containsKey(walletId)) {
      _keyshares[walletId]!.add(newKeyshare);
    } else {
      _keyshares[walletId] = [newKeyshare];
    }
    saveToStorage();
  }

  void addKeyshares(String walletId, Iterable<Keyshare2> newKeyshares) {
    if (_keyshares.containsKey(walletId)) {
      _keyshares[walletId]!.addAll(newKeyshares);
    } else {
      _keyshares[walletId] = List.of(newKeyshares);
    }
    saveToStorage();
  }

  void removeKeyshareAt(String walletId, int index) {
    if (_keyshares.containsKey(walletId)) {
      _keyshares[walletId]!.removeAt(index);
    }
    saveToStorage();
  }

  void removeAllKeyshares() {
    _keyshares.clear();
    saveToStorage();
  }

  // --- Wallet Backup ---

  Map<String, WalletBackup> get walletBackups => _walletBackups;

  set walletBackups(Map<String, WalletBackup> backups) {
    _walletBackups = backups;
    saveToStorage();
  }

  void addAccount(String walletId, AccountBackup backup) {
    if (_walletBackups.containsKey(walletId)) {
      _walletBackups[walletId]!.addAccount(backup);
    } else {
      _walletBackups[walletId] = WalletBackup([backup]);
    }
    saveToStorage();
  }

  void addAccounts(String walletId, Iterable<AccountBackup> backups) {
    if (_walletBackups.containsKey(walletId)) {
      _walletBackups[walletId]!.addAccounts(backups);
    } else {
      _walletBackups[walletId] = WalletBackup(backups);
    }
    saveToStorage();
  }

  void removeAccount(String walletId, AccountBackup backup) {
    if (_walletBackups.containsKey(walletId)) {
      _walletBackups[walletId]!.removeAccount(backup);
    }
    saveToStorage();
  }

  void removeAccountAt(String walletId, int index) {
    if (_walletBackups.containsKey(walletId)) {
      _walletBackups[walletId]!.removeAccountAt(index);
    }
    saveToStorage();
  }

  void removeAllBackups() {
    _walletBackups.clear();
    saveToStorage();
  }
}
