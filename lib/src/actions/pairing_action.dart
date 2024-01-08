import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:sodium/sodium.dart';
import 'package:convert/convert.dart';

import '../types/pairing_data.dart';
import '../transport/messages/pairing_message.dart';
import '../types/qr_message.dart';
import '../transport/shared_database.dart';

class PairingAction {
  static const expirationInMs = 60000;

  final Sodium _sodium;
  final SharedDatabase _sharedDatabase;
  final QRMessage _qrMessage;
  final String _userId;
  final _completer = Completer<PairingData>();
  late final keyPair = _sodium.crypto.box.keyPair();

  bool _isCancelled = false;
  StreamSubscription<PairingResponse>? _streamSubscription;

  PairingAction(this._sodium, this._sharedDatabase, this._qrMessage, this._userId);

  Future<PairingData> start([String? backupData]) async {
    final phonePublicKey = hex.encode(keyPair.publicKey);

    final pairingMessage = PairingMessage(
      _qrMessage.pairingId,
      _userId,
      _qrMessage.signPublicKey,
      phonePublicKey,
      expirationInMs,
      "SilentShard: ${Platform.operatingSystem}, ${Platform.operatingSystemVersion}",
      null,
      backupData,
    );

    await _sharedDatabase.setPairingMessage(pairingMessage);
    if (_isCancelled) return Completer<Never>().future;

    _streamSubscription =
        _sharedDatabase.pairingUpdates(pairingMessage.pairingId).timeout(const Duration(milliseconds: expirationInMs)).listen(_handleResponse, onError: _handleError, cancelOnError: true);

    return _completer.future;
  }

  void cancel() {
    _streamSubscription?.cancel();
    _isCancelled = true;
  }

  void _handleResponse(PairingResponse response) {
    if (response.isPaired == null) return;

    _streamSubscription?.cancel();

    if (response.isPaired == false) {
      _handleError(StateError('Something went wrong'));
      return;
    }

    final webPublicKey = Uint8List.fromList(hex.decode(_qrMessage.webEncPublicKey));
    final pairingData = PairingData(_qrMessage.pairingId, webPublicKey, keyPair);
    _completer.complete(pairingData);
  }

  void _handleError(Object error) {
    _completer.completeError(error);
  }
}
