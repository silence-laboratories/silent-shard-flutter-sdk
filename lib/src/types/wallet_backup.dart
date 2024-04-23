// Copyright (c) Silence Laboratories Pte. Ltd.
// This software is licensed under the Silence Laboratories License Agreement.

import 'dart:collection';
import 'dart:convert';

import 'account_backup.dart';

final class WalletBackup {
  Map<String, List<AccountBackup>> _accounts = {};

  WalletBackup([accountsToAdd = const <AccountBackup>[]]) {
    _accounts.addAll(accountsToAdd);
  }

  Map<String, List<AccountBackup>> get accounts => Map.unmodifiable(_accounts.map((key, value) => MapEntry(key, List.unmodifiable(value))));

  set accounts(Map<String, List<AccountBackup>> backups) => _accounts = Map.of(backups);

  void addAccount(String walletName, AccountBackup backup) {
    if (_accounts.containsKey(walletName)) {
      _accounts[walletName]!.add(backup);
    } else {
      _accounts[walletName] = [backup];
    }
  }

  void addAccounts(String walletName, Iterable<AccountBackup> backups) {
    if (_accounts.containsKey(walletName)) {
      _accounts[walletName]!.addAll(backups);
    } else {
      _accounts[walletName] = List.of(backups);
    }
  }

  void removeAccountAt(String walletName, int index) {
    if (_accounts.containsKey(walletName)) {
      _accounts[walletName]!.removeAt(index);
    }
  }

  void clearAccounts() => _accounts.clear();

  String combinedRemoteData(String walletName) => _accounts[walletName]?.map((account) => account.remoteData).join(';') ?? "";

  @override
  String toString() => jsonEncode(toJson());

  String toCanonicalJsonString(String walletName) =>
      _accounts[walletName] != null ? "[${_accounts[walletName]!.map((e) => e.toCanonicalJsonString).join(',')}]" : "";

  List<dynamic> toJson() => _accounts.entries.map((e) => e.value.map((a) => a.toJson()).toList()).toList();

  factory WalletBackup.fromJson(Map<String, dynamic> json) {
    var accountsToAdd = json.map((key, value) => MapEntry(key, value.map((e) => AccountBackup.fromJson(e)).toList()));
    return WalletBackup(accountsToAdd);
  }
}
