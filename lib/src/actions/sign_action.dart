// Copyright (c) Silence Laboratories Pte. Ltd.
// This software is licensed under the Silence Laboratories License Agreement.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:sodium/sodium.dart';

import '../ctss_bindings_generated.dart';
import '../sessions/party_2_sessions/p2_sign_session.dart';
import '../types/keyshare.dart';
import '../types/pairing_data.dart';
import '../transport/shared_database.dart';
import '../transport/messages/sign_message.dart';

class SignAction {
  final Sodium _sodium;
  final CTSSBindings _ctss;

  final SharedDatabase _sharedDatabase;
  final PairingData _pairingData;
  final Keyshare2 _keyshare;
  final String messageHash;

  var _expectedRound = 1;
  final _completer = Completer<String>();

  P2SignSession? _p2SignSession;
  StreamSubscription<SignMessage>? _streamSubscription;

  SignAction(this._sodium, this._ctss, this._sharedDatabase, this._pairingData, this._keyshare, this.messageHash);

  Future<String> start() async {
    _expectedRound = 1;
    _p2SignSession = null;

    _streamSubscription = _sharedDatabase.signUpdates(_pairingData.pairingId).timeout(const Duration(seconds: 60)).listen(_handleMessage, onError: _handleError, cancelOnError: true);

    return _completer.future;
  }

  void cancel() {
    _streamSubscription?.cancel();
  }

  void _completeWithResult(String result) {
    _streamSubscription?.cancel();
    _completer.complete(result);
    // _cleanup();
  }

  void _completeWithError(Object error) {
    _streamSubscription?.cancel();
    _completer.completeError(error);
    _cleanup();
  }

  void _handleMessage(SignMessage message) {
    if (message.payload.party != 1 || message.payload.round != _expectedRound) return; // ignore own messages and incorrect rounds

    final validationError = _validateMessage(message);
    if (validationError != null) {
      return _completeWithError(validationError);
    }

    var (decryptionError, decrypted) = _decryptPayload(message.payload);
    if (decryptionError != null) {
      return _completeWithError(decryptionError);
    }

    _p2SignSession ??= P2SignSession(_ctss, message.sessionId, _keyshare, messageHash);

    try {
      _handleRound(message, decrypted!);
      ++_expectedRound;
    } catch (error) {
      _completeWithError(error);
    }
  }

  void _handleRound(SignMessage message, String decrypted) {
    switch (message.payload.round) {
      case 1:
        _processMessage1(message, decrypted);
      case 2:
        _processMessage3(message, decrypted);
      case 3:
        _processMessage5(decrypted);
      default:
        _completeWithError(StateError('Unexpected message in round ${message.payload.round} from party ${message.payload.party}'));
    }
  }

  void _handleError(Object error) {
    _completer.completeError(error);
  }

  Error? _validateMessage(SignMessage message) {
    final now = DateTime.now();
    if (message.createdAt.isAfter(now)) {
      return StateError('Keygen message on round ${message.payload.round} of party ${message.payload.party} has incorrect creation date');
    } else if (message.createdAt.add(message.expirationTimeout).isBefore(now)) {
      return StateError('Keygen message on round ${message.payload.round} of party ${message.payload.party} expired');
    } else {
      return null;
    }
  }

  (Object?, String?) _decryptPayload(SignPayload payload) {
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

  void _sendMessage(String payload, SignMessage message, int round) {
    var (encryptedPayload, nonce) = _encryptPayload(payload);
    final signMessage2 = SignMessage(
      message.sessionId,
      message.accountId,
      message.hashAlg,
      message.signMetadata,
      message.pubicKey,
      SignPayload(encryptedPayload, nonce, round, 2),
      message.messageToSign,
      message.messageHash,
      true,
    );
    _sharedDatabase.setSignMessage(_pairingData.pairingId, signMessage2);
  }

  void _processMessage1(SignMessage message, String payload1) {
    final message2 = _p2SignSession!.processMessage1(payload1);
    _sendMessage(message2, message, 1);
  }

  void _processMessage3(SignMessage message, String payload1) {
    final message4 = _p2SignSession!.processMessage3(payload1);
    _sendMessage(message4, message, 2);
  }

  void _processMessage5(String message3) {
    final result = _p2SignSession!.processMessage5(message3);
    _completeWithResult(result);
  }

  void _cleanup() {
    // Delete last message to prevent future signature generation
    // failures over previous locally cached outdated messages
    _sharedDatabase.deleteSignMessage(_pairingData.pairingId);
  }
}
