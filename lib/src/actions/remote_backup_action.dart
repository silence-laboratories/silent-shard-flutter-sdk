// Copyright (c) Silence Laboratories Pte. Ltd.
// This software is licensed under the Silence Laboratories License Agreement.

import 'dart:async';

import '../types/pairing_data.dart';
import '../transport/messages/backup_message.dart';
import '../transport/shared_database.dart';

class RemoteBackupListener {
  final SharedDatabase _sharedDatabase;
  final PairingData _pairingData;

  RemoteBackupListener(this._sharedDatabase, this._pairingData);

  Stream<BackupMessage> remoteBackupRequests() {
    return _sharedDatabase.backupUpdates(_pairingData.pairingId);
  }
}
