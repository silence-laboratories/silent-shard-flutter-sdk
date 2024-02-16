// Copyright (c) Silence Laboratories Pte. Ltd.
// This software is licensed under the Silence Laboratories License Agreement.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:dart_2_party_ecdsa/src/ctss_bindings_generated.dart';
import 'package:dart_2_party_ecdsa/src/sessions/party_2_sessions/p2_keygen_session.dart';
import 'package:sodium/sodium.dart';

import '../types/keyshare.dart';
import '../types/pairing_data.dart';
import '../transport/shared_database.dart';
import '../transport/messages/keygen_message.dart';

class KeygenAction {
  final Sodium _sodium;
  final CTSSBindings _ctss;

  final SharedDatabase _sharedDatabase;
  final PairingData _pairingData;

  var _expectedRound = 1;
  final _completer = Completer<Keyshare2>();

  P2KeygenSession? _p2KeygenSession;
  StreamSubscription<KeygenMessage>? _streamSubscription;

  KeygenAction(this._sodium, this._ctss, this._sharedDatabase, this._pairingData);

  Future<Keyshare2> start() async {
    _expectedRound = 1;
    _p2KeygenSession = null;

    _streamSubscription = _sharedDatabase.keygenUpdates(_pairingData.pairingId).timeout(const Duration(seconds: 60)).listen(_handleMessage, onError: _handleError, cancelOnError: true);

    return _completer.future;
  }

  void cancel() {
    _streamSubscription?.cancel();
  }

  void _completeWithResult(Keyshare2 keyshare) {
    _streamSubscription?.cancel();
    _completer.complete(keyshare);
    _cleanup();
  }

  void _completeWithError(Object error) {
    _streamSubscription?.cancel();
    _completer.completeError(error);
    _cleanup();
  }

  void _handleMessage(KeygenMessage message) {
    if (message.payload.party != 1 || message.payload.round != _expectedRound) return; // ignore own messages and incorrect rounds

    final validationError = _validateMessage(message);
    if (validationError != null) {
      return _completeWithError(validationError);
    }

    var (decryptionError, decrypted) = _decryptPayload(message.payload);
    if (decryptionError != null) {
      return _completeWithError(decryptionError);
    }

    _p2KeygenSession ??= P2KeygenSession(_ctss, message.sessionId);

    try {
      _handleRound(message, decrypted!);
      ++_expectedRound;
    } catch (error) {
      _completeWithError(error);
    }
  }

  void _handleRound(KeygenMessage message, String decrypted) {
    switch (message.payload.round) {
      case 1:
        _processMessage1(message.accountId, decrypted);
      case 2:
        _processMessage3(decrypted);
      default:
        _completeWithError(StateError('Unexpected message in round ${message.payload.round} from party ${message.payload.party}'));
    }
  }

  void _handleError(Object error) {
    _completer.completeError(error);
  }

  Error? _validateMessage(KeygenMessage message) {
    final now = DateTime.now();

    // print('Time');
    // print(now);
    // print(now.millisecondsSinceEpoch);
    // print(message.createdAt);
    // print(message.createdAt.millisecondsSinceEpoch);
    // print(now.millisecondsSinceEpoch < message.createdAt.millisecondsSinceEpoch);
    // print(message.createdAt.add(message.expirationTimeout).toString());
    // print(message.createdAt.add(message.expirationTimeout).isBefore(now));

    // if (now.isAfter(message.createdAt)) {
    //   return StateError('Keygen message on round ${message.payload.round} of party ${message.payload.party} has incorrect creation date');
    // } else
    if (message.createdAt.add(message.expirationTimeout).isBefore(now)) {
      return StateError('Keygen message on round ${message.payload.round} of party ${message.payload.party} expired');
    } else {
      return null;
    }
  }

  (Object?, String?) _decryptPayload(KeygenPayload payload) {
    try {
      final plainText = _sodium.crypto.box.openEasy(
        cipherText: base64.decode(payload.message),
        nonce: Uint8List.fromList(hex.decode(payload.nonce)),
        publicKey: _pairingData.webPublicKey,
        secretKey: _pairingData.encKeyPair.secretKey,
      );
      return (null, utf8.decode(plainText));
    } catch (e) {
      return (e, null);
    }
  }

  (String, String) _encryptPayload(String message) {
    final nonce = _sodium.randombytes.buf(_sodium.crypto.box.nonceBytes);
    final encryptedMessageBytes = _sodium.crypto.box.easy(
      message: Uint8List.fromList(message.codeUnits),
      nonce: nonce,
      publicKey: _pairingData.webPublicKey,
      secretKey: _pairingData.encKeyPair.secretKey,
    );
    return (base64Encode(encryptedMessageBytes), hex.encode(nonce));
  }

  void _processMessage1(int accountId, String message1) {
    final message2 = _p2KeygenSession!.processMessage1(message1);
    var (encryptedMessage2, nonce) = _encryptPayload(message2);
    final keygenMessage2 = KeygenMessage(
      _p2KeygenSession!.id,
      accountId,
      KeygenPayload(encryptedMessage2, nonce, 1, 2),
    );
    _sharedDatabase.setKeygenMessage(_pairingData.pairingId, keygenMessage2);
  }

  void _processMessage3(String message3) {
    final keyshare = _p2KeygenSession!.processMessage3(message3);
    _completeWithResult(keyshare);
  }

  void _cleanup() {
    // Delete last message to prevent future signature generation
    // failures over previous locally cached outdated messages
    _sharedDatabase.deleteKeygenMessage(_pairingData.pairingId);
  }
}
