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
        if (json['pairingData'] != null) {
          pairingData = PairingData.fromJson(sodium, json['pairingData']);
        }

        final keysharesJson = json['keyshares'];
        if (keysharesJson != null) {
          if (keysharesJson is! Map<String, dynamic> && keysharesJson is List<dynamic>) {
            List<Keyshare2> oldKeyshares = keysharesJson.map<Keyshare2>((e) => Keyshare2.fromBytes(ctss, e)).toList();
            keyshares['metamask'] = oldKeyshares;
          } else {
            keysharesJson.forEach((key, value) {
              keyshares[key] = (value as List).map((e) => Keyshare2.fromBytes(ctss, e)).toList();
            });
          }
        }

        final walletBackupJson = json['backup'];
        if (walletBackupJson != null) {
          if (walletBackupJson is! Map<String, dynamic> && walletBackupJson is List<dynamic>) {
            WalletBackup oldBackup = WalletBackup.fromJson(walletBackupJson);
            walletBackup['metamask'] = oldBackup;
          } else {
            walletBackupJson.forEach((key, value) {
              walletBackup[key] = WalletBackup.fromJson(value);
            });
          }
        }
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
    print('Saving to storage: $json');
    _storage.setString(storageKey, jsonEncode(json));
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

  void replaceKeyshares(String walletId, Iterable<Keyshare2> newKeyshares) {
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

  void addBackupAccount(String walletId, AccountBackup backup) {
    if (_walletBackups.containsKey(walletId)) {
      _walletBackups[walletId]!.addAccount(backup);
    } else {
      _walletBackups[walletId] = WalletBackup([backup]);
    }
    saveToStorage();
  }

  void replaceAllBackupAccounts(String walletId, Iterable<AccountBackup> backups) {
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
    }
    saveToStorage();
  }

  void removeAllBackups(String walletId) {
    _walletBackups.remove(walletId);
    saveToStorage();
  }
}
