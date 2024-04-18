// Copyright (c) Silence Laboratories Pte. Ltd.
// This software is licensed under the Silence Laboratories License Agreement.

import 'dart:async';

import '../transport/messages/backup_message.dart';
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
    cancel();
    _sharedDatabase.deleteBackupMessage(_userId);
    _completer.complete(message.backupData);
  }

  void _handleError(Object error) {
    _completer.completeError(error);
  }
}

class RemoteBackupListener {
  final SharedDatabase _sharedDatabase;
  final PairingData _pairingData;

  RemoteBackupListener(this._sharedDatabase, this._pairingData);

  Stream<BackupMessage> remoteBackupRequests() {
    return _sharedDatabase.backupUpdates(_pairingData.pairingId).map(_handleMessage);
  }

  BackupMessage _handleMessage(BackupMessage message) {
    if (message.backupData.isEmpty) {
      return message;
    } else {
      _sharedDatabase.deleteBackupMessage(_pairingData.pairingId);
      return message;
    }
  }
}
