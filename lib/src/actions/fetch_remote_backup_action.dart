import 'dart:async';

import '../types/pairing_data.dart';
import '../transport/messages/backup_message.dart';
import '../transport/shared_database.dart';

class FetchRemoteBackupAction {
  final SharedDatabase _sharedDatabase;
  final PairingData _pairingData;
  StreamSubscription<BackupMessage>? _streamSubscription;

  final _completer = Completer<String>();

  FetchRemoteBackupAction(this._sharedDatabase, this._pairingData);

  Future<String> start() async {
    _streamSubscription = _sharedDatabase
        .backupUpdates(_pairingData.pairingId)
        .timeout(const Duration(seconds: 60))
        .listen(_handleMessage, onError: _handleError, cancelOnError: true);
    return _completer.future;
  }

  void cancel() {
    _streamSubscription?.cancel();
  }

  void _handleMessage(BackupMessage message) {
    cancel();
    _sharedDatabase.deleteBackupMessage(_pairingData.pairingId);
    _completer.complete(message.backupData);
  }

  void _handleError(Object error) {
    _completer.completeError(error);
  }
}
