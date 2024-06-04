// Copyright (c) Silence Laboratories Pte. Ltd.
// This software is licensed under the Silence Laboratories License Agreement.

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:dart_2_party_ecdsa/dart_2_party_ecdsa.dart';
import 'package:stream_transform/stream_transform.dart';

import '../transport/shared_database.dart';

class FetchRemoteBackupAction {
  final SharedDatabase _sharedDatabase;
  final String _userId;
  StreamSubscription<BackupMessage>? _streamSubscription;

  final _completer = Completer<String>();

  FetchRemoteBackupAction(this._sharedDatabase, this._userId);

  Future<String> start() async {
    _streamSubscription = _sharedDatabase
        .backupUpdates(_userId)
        .timeout(const Duration(seconds: 60))
        .listen(_handleMessage, onError: _handleError, cancelOnError: true);
    return _completer.future;
  }

  void cancel() {
    _streamSubscription?.cancel();
  }

  void _handleMessage(BackupMessage message) {
    if (!_validateMessageDate(message)) {
      return;
    }
    cancel();
    _sharedDatabase.deleteBackupMessage(_userId);
    _completer.complete(message.backupData);
  }

  void _handleError(Object error) {
    _completer.completeError(error);
  }

  bool _validateMessageDate(BackupMessage message) {
    final now = DateTime.now();
    if (message.createdAt.add(message.expirationTimeout).isBefore(now)) {
      return false;
    } else {
      return true;
    }
  }
}

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
    if (message.address != null && message.walletId != null && message.backupData.isNotEmpty) {
      final accountAddress = message.address ?? "";
      final walletId = message.walletId ?? "";

      if (accountAddress.isNotEmpty && walletId.isNotEmpty) {
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
}
