// Copyright (c) Silence Laboratories Pte. Ltd.
// This software is licensed under the Silence Laboratories License Agreement.

import 'dart:async';

import 'package:dart_2_party_ecdsa/dart_2_party_ecdsa.dart';

import '../transport/shared_database.dart';
import 'package:collection/collection.dart';
import 'package:stream_transform/stream_transform.dart';

class RemoteBackupListener {
  final SharedDatabase _sharedDatabase;
  final String _userId;
  final KeygenState _keygenState;
  final BackupState _backupState;

  RemoteBackupListener(this._sharedDatabase, this._userId, this._keygenState, this._backupState);

  Stream<BackupMessage> start() {
    return _sharedDatabase
        .backupUpdates(_userId) //
        .whereNotNull()
        .tap(_handleMessage)
        .handleError((error) {
      print('Error listening remote backup: $error');
    });
  }

  void _handleMessage(BackupMessage message) {
    final accountAddress = message.address;
    final walletId = message.walletId;
    if (accountAddress != null && walletId != null && message.backupData.isNotEmpty) {
      if (_keygenState.keysharesMap[walletId] == null) {
        throw StateError('No keyshares for $walletId');
      }
      final keyshare = _keygenState.keysharesMap[walletId]!.firstWhereOrNull((keyshare) => keyshare.ethAddress == accountAddress);
      if (keyshare == null) {
        throw StateError('Cannot find keyshare for $accountAddress of $walletId provider');
      }
      final accountBackup = AccountBackup(accountAddress, keyshare.toBytes(), message.backupData);
      _backupState.upsertBackupAccount(walletId, accountBackup);
    }
  }
}
