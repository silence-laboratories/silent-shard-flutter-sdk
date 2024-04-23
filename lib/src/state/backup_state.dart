// Copyright (c) Silence Laboratories Pte. Ltd.
// This software is licensed under the Silence Laboratories License Agreement.

import 'package:flutter/foundation.dart';

import '../storage/local_database.dart';
import '../types/wallet_backup.dart';
import '../types/account_backup.dart';

class BackupState extends ChangeNotifier {
  final LocalDatabase _database;

  BackupState(this._database);

  WalletBackup get walletBackup => _database.walletBackup;

  set walletBackup(WalletBackup? backup) {
    _database.walletBackup = backup;
    notifyListeners();
  }

  void addAccount(String walletName, AccountBackup backup) {
    _database.walletBackup = walletBackup..addAccount(walletName, backup);
    notifyListeners();
  }

  void addAccounts(String walletName, Iterable<AccountBackup> backups) {
    _database.walletBackup = walletBackup..addAccounts(walletName, backups);
    notifyListeners();
  }

  void removeAccountAt(String walletName, int index) {
    _database.walletBackup = walletBackup..removeAccountAt(walletName, index);
    notifyListeners();
  }

  void clearAccounts() {
    _database.walletBackup = walletBackup..clearAccounts();
    notifyListeners();
  }
}
