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

  void replaceAccount(String walletId, AccountBackup backup) {
    _database.replaceAccount(walletId, backup);
    notifyListeners();
  }

  void replaceAccounts(String walletId, Iterable<AccountBackup> backups) {
    _database.replaceAccounts(walletId, backups);
    notifyListeners();
  }

  void removeAccount(String walletId, AccountBackup backup) {
    _database.removeAccount(walletId, backup);
    notifyListeners();
  }

  void removeAccountAt(String walletId, int index) {
    _database.removeAccountAt(walletId, index);
    notifyListeners();
  }

  void clearAccounts(String walletId) {
    _database.removeAllBackups(walletId);
    notifyListeners();
  }
}
