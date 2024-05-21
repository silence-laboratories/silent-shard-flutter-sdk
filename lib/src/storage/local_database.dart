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

  Map<String, PairingData> _pairingDataMap;
  Map<String, List<Keyshare2>> _keysharesMap;
  Map<String, WalletBackup> _walletBackupsMap;

  LocalDatabase(this._storage, this._pairingDataMap, this._keysharesMap, this._walletBackupsMap, [bool saveOnCreation = true]) {
    if (saveOnCreation) {
      saveToStorage();
    }
  }

  // --- Serialization / Deserialization ---

  factory LocalDatabase.fromStorage(Sodium sodium, CTSSBindings ctss, Storage storage) {
    final data = storage.getString(storageKey);
    if (data != null) {
      try {
        var json = jsonDecode(data);
        var version = json['version'] ?? 0;
        bool migrated = false;

        if (version < 1) {
          json = migrateFromV0ToV1(sodium, ctss, json);
          migrated = true;
        }

        if (migrated) {
          storage.setString(storageKey, jsonEncode(json));
        }

        return deserializeStorage(sodium, ctss, storage, json);
      } catch (e) {
        print('Failed to load local state: $e');
      }
    }
    return LocalDatabase(storage, {}, {}, {}, false);
  }

  static LocalDatabase deserializeStorage(Sodium sodium, CTSSBindings ctss, Storage storage, Map<String, dynamic> json) {
    Map<String, PairingData> pairingDataMap = {};
    Map<String, List<Keyshare2>> keysharesMap = {};
    Map<String, WalletBackup> walletBackupsMap = {};
    try {
      final pairingDataJson = json['pairingData'];
      if (pairingDataJson != null) {
        pairingDataJson.forEach((key, value) {
          pairingDataMap[key] = PairingData.fromJson(sodium, value);
        });
      }

      final keysharesJson = json['keyshares'];
      if (keysharesJson != null) {
        keysharesJson.forEach((key, value) {
          keysharesMap[key] = (value as List).map((e) => Keyshare2.fromBytes(ctss, e)).toList();
        });
      }

      final walletBackupJson = json['backup'];
      if (walletBackupJson != null) {
        walletBackupJson.forEach((key, value) {
          walletBackupsMap[key] = WalletBackup.fromJson(value);
        });
      }
    } catch (e) {
      rethrow;
    }
    return LocalDatabase(storage, pairingDataMap, keysharesMap, walletBackupsMap, false);
  }

  void saveToStorage() {
    final json = {
      'pairingData': _pairingDataMap.map((key, value) => MapEntry(key, value.toJson())),
      'keyshares': _keysharesMap.map((key, value) => MapEntry(key, value.map((e) => e.toBytes()).toList())),
      'backup': _walletBackupsMap.map((key, value) => MapEntry(key, value.toJson())),
      'version': currentVersion
    };
    _storage.setString(storageKey, jsonEncode(json));
  }

  // --- Pairing Data ---

  Map<String, PairingData> get pairingDataMap => _pairingDataMap;

  void setPairingData(String? address, PairingData data) {
    if (address == null) {
      _pairingDataMap[data.pairingId] = data;
    } else {
      _pairingDataMap.remove(data.pairingId); // Remove old pairing data (if any
      _pairingDataMap[address] = data;
    }
    saveToStorage();
  }

  void removePairingDataBy(String address) {
    if (_pairingDataMap.containsKey(address)) {
      _pairingDataMap.remove(address);
    }
    saveToStorage();
  }

  // --- Keyshares ---

  Map<String, List<Keyshare2>> get keysharesMap => _keysharesMap.map((key, value) => MapEntry(key, List<Keyshare2>.from(value)));

  set keyshares(Map<String, List<Keyshare2>> newKeyshares) {
    _keysharesMap = Map.of(newKeyshares);
    saveToStorage();
  }

  void addKeyshare(String walletId, Keyshare2 newKeyshare) {
    if (_keysharesMap.containsKey(walletId)) {
      _keysharesMap[walletId]!.add(newKeyshare);
    } else {
      _keysharesMap[walletId] = [newKeyshare];
    }
    saveToStorage();
  }

  void upsertKeyshares(String walletId, Iterable<Keyshare2> newKeyshares) {
    if (_keysharesMap.containsKey(walletId)) {
      for (Keyshare2 keyshare in newKeyshares) {
        final index = _keysharesMap[walletId]!.indexWhere((element) => element.ethAddress == keyshare.ethAddress);
        if (index != -1) {
          _keysharesMap[walletId]![index] = keyshare;
        } else {
          _keysharesMap[walletId]!.add(keyshare);
        }
      }
    } else {
      _keysharesMap[walletId] = List.of(newKeyshares);
    }
    saveToStorage();
  }

  void removeKeyshareBy(String walletId, String address) {
    if (_keysharesMap.containsKey(walletId)) {
      final index = _keysharesMap[walletId]!.indexWhere((element) => element.ethAddress == address);
      if (index != -1) {
        _keysharesMap[walletId]!.removeAt(index);
        if (_keysharesMap[walletId]!.isEmpty) {
          _keysharesMap.remove(walletId);
        }
      }
    }
    saveToStorage();
  }

  // --- Wallet Backup ---

  Map<String, WalletBackup> get walletBackupsMap => _walletBackupsMap;

  set walletBackups(Map<String, WalletBackup> backups) {
    _walletBackupsMap = backups;
    saveToStorage();
  }

  void upsertBackupAccount(String walletId, AccountBackup backup) {
    if (_walletBackupsMap.containsKey(walletId)) {
      final index = _walletBackupsMap[walletId]!.accounts.indexWhere((element) => element.address == backup.address);
      if (index != -1) {
        _walletBackupsMap[walletId]!.setAccount(index, backup);
      } else {
        _walletBackupsMap[walletId]!.addAccount(backup);
      }
    } else {
      _walletBackupsMap[walletId] = WalletBackup([backup]);
    }
    saveToStorage();
  }

  void upsertBackupAccounts(String walletId, Iterable<AccountBackup> backups) {
    if (_walletBackupsMap.containsKey(walletId)) {
      for (AccountBackup backup in backups) {
        final index = _walletBackupsMap[walletId]!.accounts.indexWhere((element) => element.address == backup.address);
        if (index != -1) {
          _walletBackupsMap[walletId]!.setAccount(index, backup);
        } else {
          _walletBackupsMap[walletId]!.addAccount(backup);
        }
      }
    } else {
      _walletBackupsMap[walletId] = WalletBackup(backups);
    }
    saveToStorage();
  }

  void removeBackupAccountBy(String walletId, String address) {
    if (_walletBackupsMap.containsKey(walletId)) {
      final index = _walletBackupsMap[walletId]!.accounts.indexWhere((element) => element.address == address);
      if (index != -1) {
        _walletBackupsMap[walletId]!.removeAccountAt(index);
        if (_walletBackupsMap[walletId]!.accounts.isEmpty) {
          _walletBackupsMap.remove(walletId);
        }
      }
    }
    saveToStorage();
  }
}
