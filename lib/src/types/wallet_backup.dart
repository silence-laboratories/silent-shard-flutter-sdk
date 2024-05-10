// Copyright (c) Silence Laboratories Pte. Ltd.
// This software is licensed under the Silence Laboratories License Agreement.

import 'dart:convert';

import 'account_backup.dart';

final class WalletBackup {
  List<AccountBackup> _accounts = [];

  WalletBackup([accountsToAdd = const <AccountBackup>[]]) {
    _accounts.addAll(accountsToAdd);
  }

  List<AccountBackup> get accounts => List.from(_accounts);

  set accounts(Iterable<AccountBackup> backups) => _accounts = List.of(backups);

  void setAccount(int index, AccountBackup backup) => _accounts[index] = backup;

  void addAccount(AccountBackup backup) => _accounts.add(backup);

  void addAccounts(Iterable<AccountBackup> backups) => _accounts.addAll(backups);

  void removeAccount(AccountBackup backup) => _accounts.remove(backup);

  void removeAccountAt(int index) => _accounts.removeAt(index);

  void clearAccounts() => _accounts.clear();

  String get combinedRemoteData => _accounts.map((account) => account.remoteData).join(';');

  @override
  String toString() => jsonEncode(toJson());

  String get toCanonicalJsonString => "[${accounts.map((e) => e.toCanonicalJsonString).join(',')}]";

  List<dynamic> toJson() => _accounts.map((e) => e.toJson()).toList();

  factory WalletBackup.fromJson(List<dynamic> json) {
    var accountsToAdd = json.map((e) => AccountBackup.fromJson(e)).toList();
    return WalletBackup(accountsToAdd);
  }
}
