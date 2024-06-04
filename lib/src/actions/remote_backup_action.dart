// Copyright (c) Silence Laboratories Pte. Ltd.
// This software is licensed under the Silence Laboratories License Agreement.

import 'dart:async';

import 'package:dart_2_party_ecdsa/dart_2_party_ecdsa.dart';

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
