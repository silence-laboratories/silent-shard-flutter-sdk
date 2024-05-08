// Copyright (c) Silence Laboratories Pte. Ltd.
// This software is licensed under the Silence Laboratories License Agreement.

import 'package:flutter/foundation.dart';

import '../storage/local_database.dart';
import '../types/wallet_backup.dart';
import '../types/account_backup.dart';

class BackupState extends ChangeNotifier {
  final LocalDatabase _database;

  BackupState(this._database);

  Map<String, WalletBackup> get walletBackupMap => _database.walletBackups;

  set walletBackupMap(Map<String, WalletBackup> backups) {
    _database.walletBackups = backups;
    notifyListeners();
  }

  void addBackupAccount(String walletId, AccountBackup backup) {
    _database.addBackupAccount(walletId, backup);
    notifyListeners();
  }

  void replaceAccounts(String walletId, Iterable<AccountBackup> backups) {
    _database.replaceAllBackupAccounts(walletId, backups);
    notifyListeners();
  }

  void removeBackupAccountBy(String walletId, String address) {
    _database.removeBackupAccountBy(walletId, address);
    notifyListeners();
  }

  void clearAccounts(String walletId) {
    _database.removeAllBackups(walletId);
    notifyListeners();
  }
}
