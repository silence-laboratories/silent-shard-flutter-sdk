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

  void addAccount(String walletName, AccountBackup backup) {
    _database.addAccount(walletName, backup);
    notifyListeners();
  }

  void addAccounts(String walletName, Iterable<AccountBackup> backups) {
    _database.addAccounts(walletName, backups);
    notifyListeners();
  }

  void removeAccount(String walletName, AccountBackup backup) {
    _database.removeAccount(walletName, backup);
    notifyListeners();
  }

  void removeAccountAt(String walletName, int index) {
    _database.removeAccountAt(walletName, index);
    notifyListeners();
  }

  void clearAccounts() {
    _database.removeAllBackups();
    notifyListeners();
  }
}
