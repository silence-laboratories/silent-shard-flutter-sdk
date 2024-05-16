// Copyright (c) Silence Laboratories Pte. Ltd.
// This software is licensed under the Silence Laboratories License Agreement.

import 'package:flutter/foundation.dart';

import '../storage/local_database.dart';
import '../types/wallet_backup.dart';
import '../types/account_backup.dart';

class BackupState extends ChangeNotifier {
  final LocalDatabase _database;

  BackupState(this._database);

  Map<String, WalletBackup> get walletBackupsMap => _database.walletBackupsMap;

  set walletBackupMap(Map<String, WalletBackup> backups) {
    _database.walletBackups = backups;
    notifyListeners();
  }

  void upsertBackupAccount(String walletId, AccountBackup backup) {
    _database.upsertBackupAccount(walletId, backup);
    notifyListeners();
  }

  void upsertBackupAccounts(String walletId, Iterable<AccountBackup> backups) {
    _database.upsertBackupAccounts(walletId, backups);
    notifyListeners();
  }

  void removeBackupAccountBy(String walletId, String address) {
    _database.removeBackupAccountBy(walletId, address);
    notifyListeners();
  }
}
