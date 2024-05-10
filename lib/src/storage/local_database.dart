// Copyright (c) Silence Laboratories Pte. Ltd.
// This software is licensed under the Silence Laboratories License Agreement.

import 'dart:convert';

import 'package:dart_2_party_ecdsa/dart_2_party_ecdsa.dart';
import 'package:dart_2_party_ecdsa/src/storage/migration.dart';
import 'package:sodium/sodium.dart';

import 'storage.dart';
import '../ctss_bindings_generated.dart';

class LocalDatabase {
  static const storageKey = "silentshard.storage";
  static const currentVersion = 1;

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
    final data = storage.getString(storageKey);
    if (data != null) {
      try {
        final json = jsonDecode(data);
        var version = json['version'] ?? 0;
        var migrated = false;
        Map<String, dynamic> migratedJson = {};

        if (version < 1) {
          migratedJson = migrateFromV0ToV1(ctss, json['keyshares'], json['backup']);
          migrated = true;
        }

        if (migrated) {
          saveMigration(migratedJson, storage);
        }
        return deserializeStorage(sodium, ctss, storage);
      } catch (e) {
        print('Failed to load local state: $e');
      }
    }
    return LocalDatabase(storage, null, {}, {}, false);
  }

  static LocalDatabase deserializeStorage(Sodium sodium, CTSSBindings ctss, Storage storage) {
    PairingData? pairingData;
    Map<String, List<Keyshare2>> keyshares = {};
    Map<String, WalletBackup> walletBackup = {};
    final data = storage.getString(storageKey);
    if (data != null) {
      try {
        final json = jsonDecode(data);
        if (json['pairingData'] != null) {
          pairingData = PairingData.fromJson(sodium, json['pairingData']);
        }

        final keysharesJson = json['keyshares'];
        if (keysharesJson != null) {
          keysharesJson.forEach((key, value) {
            keyshares[key] = (value as List).map((e) => Keyshare2.fromBytes(ctss, e)).toList();
          });
        }

        final walletBackupJson = json['backup'];
        if (walletBackupJson != null) {
          walletBackupJson.forEach((key, value) {
            walletBackup[key] = WalletBackup.fromJson(value);
          });
        }
      } catch (e) {
        rethrow;
      }
    }
    return LocalDatabase(storage, pairingData, keyshares, walletBackup, false);
  }

  void saveToStorage() {
    final json = {
      'pairingData': _pairingData?.toJson(),
      'keyshares': _keyshares.map((key, value) => MapEntry(key, value.map((e) => e.toBytes()).toList())),
      'backup': _walletBackups.map((key, value) => MapEntry(key, value.toJson())),
      'version': currentVersion
    };
    print('Saving to storage: $json');
    _storage.setString(storageKey, jsonEncode(json));
  }

  static void saveMigration(Map<String, dynamic> json, Storage storage) {
    print('Saving migration to storage: $json');
    storage.setString(storageKey, jsonEncode(json));
  }

  // --- Pairing Data ---

  PairingData? get pairingData => _pairingData;

  set pairingData(PairingData? data) {
    _pairingData = data;
    saveToStorage();
  }

  // --- Keyshares ---

  Map<String, List<Keyshare2>> get keyshares => _keyshares.map((key, value) => MapEntry(key, List<Keyshare2>.from(value)));

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

  void upsertKeyshares(String walletId, Iterable<Keyshare2> newKeyshares) {
    if (_keyshares.containsKey(walletId)) {
      for (Keyshare2 keyshare in newKeyshares) {
        final index = _keyshares[walletId]!.indexWhere((element) => element.ethAddress == keyshare.ethAddress);
        if (index != -1) {
          _keyshares[walletId]![index] = keyshare;
        } else {
          _keyshares[walletId]!.add(keyshare);
        }
      }
    } else {
      _keyshares[walletId] = List.of(newKeyshares);
    }
    saveToStorage();
  }

  void removeKeyshareBy(String walletId, String address) {
    if (_keyshares.containsKey(walletId)) {
      final index = _keyshares[walletId]!.indexWhere((element) => element.ethAddress == address);
      _keyshares[walletId]!.removeAt(index);
      if (_keyshares[walletId]!.isEmpty) {
        _keyshares.remove(walletId);
      }
    }
    saveToStorage();
  }

  void removeAllKeyshares(String walletId) {
    _keyshares.remove(walletId);
    saveToStorage();
  }

  // --- Wallet Backup ---

  Map<String, WalletBackup> get walletBackups => _walletBackups;

  set walletBackups(Map<String, WalletBackup> backups) {
    _walletBackups = backups;
    saveToStorage();
  }

  void upsertBackupAccount(String walletId, AccountBackup backup) {
    if (_walletBackups.containsKey(walletId)) {
      final index = _walletBackups[walletId]!.accounts.indexWhere((element) => element.address == backup.address);
      if (index != -1) {
        _walletBackups[walletId]!.setAccount(index, backup);
      } else {
        _walletBackups[walletId]!.addAccount(backup);
      }
    } else {
      _walletBackups[walletId] = WalletBackup([backup]);
    }
    saveToStorage();
  }

  void upsertBackupAccounts(String walletId, Iterable<AccountBackup> backups) {
    if (_walletBackups.containsKey(walletId)) {
      for (AccountBackup backup in backups) {
        final index = _walletBackups[walletId]!.accounts.indexWhere((element) => element.address == backup.address);
        if (index != -1) {
          _walletBackups[walletId]!.setAccount(index, backup);
        } else {
          _walletBackups[walletId]!.addAccount(backup);
        }
      }
    } else {
      _walletBackups[walletId] = WalletBackup(backups);
    }
    saveToStorage();
  }

  void removeBackupAccountBy(String walletId, String address) {
    if (_walletBackups.containsKey(walletId)) {
      final index = _walletBackups[walletId]!.accounts.indexWhere((element) => element.address == address);
      _walletBackups[walletId]!.removeAccountAt(index);
      if (_walletBackups[walletId]!.accounts.isEmpty) {
        _walletBackups.remove(walletId);
      }
    }
    saveToStorage();
  }

  void removeAllBackups(String walletId) {
    _walletBackups.remove(walletId);
    saveToStorage();
  }
}
