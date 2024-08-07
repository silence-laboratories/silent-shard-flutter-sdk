// Copyright (c) Silence Laboratories Pte. Ltd.
// This software is licensed under the Silence Laboratories License Agreement.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:dart_2_party_ecdsa/src/utils/utils.dart';
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
  final Map<String, PairingData> _pairingData;
  final String _userId;
  final Keyshare2 _keyshare;
  final String messageHash;

  var _expectedRound = 1;
  final _completer = Completer<String>();

  P2SignSession? _p2SignSession;
  StreamSubscription<SignMessage>? _streamSubscription;

  SignAction(this._sodium, this._ctss, this._sharedDatabase, this._pairingData, this._userId, this._keyshare, this.messageHash);

  Future<String> start() async {
    _expectedRound = 1;
    _p2SignSession = null;

    _streamSubscription = _sharedDatabase //
        .signUpdates(_userId)
        .timeout(const Duration(seconds: 60))
        .listen(_handleMessage, onError: _handleError, cancelOnError: true);

    return _completer.future;
  }

  void cancel() {
    _streamSubscription?.cancel();
  }

  void _completeWithResult(String result) {
    _streamSubscription?.cancel();
    _completer.complete(result);
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

    try {
      final address = pubKeyToEthAddress(message.publicKey);
      final pairingData = _pairingData[address];
      if (pairingData == null) {
        throw (StateError('No pairing data for address $address'), null);
      }
      final decrypted = decryptPayload(_sodium, pairingData, message.payload);
      _p2SignSession ??= P2SignSession(_ctss, message.sessionId, _keyshare, messageHash);
      _handleRound(message, decrypted);
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
    if (message.createdAt.add(message.expirationTimeout).isBefore(now)) {
      return StateError('Sign message on round ${message.payload.round} of party ${message.payload.party} expired');
    } else {
      return null;
    }
  }

  (String, String) _encryptPayload(String address, String message) {
    if (_pairingData[address] == null) {
      throw StateError('No pairing data for address $address');
    }
    final nonce = _sodium.randombytes.buf(_sodium.crypto.box.nonceBytes);
    final encryptedMessageBytes = _sodium.crypto.box.easy(
      message: Uint8List.fromList(message.codeUnits),
      nonce: nonce,
      publicKey: _pairingData[address]!.webPublicKey,
      secretKey: _pairingData[address]!.encKeyPair.secretKey,
    );
    return (base64Encode(encryptedMessageBytes), hex.encode(nonce));
  }

  void _sendMessage(String payload, SignMessage message, int round) {
    var (encryptedPayload, nonce) = _encryptPayload(pubKeyToEthAddress(message.publicKey), payload);
    final signMessage2 = SignMessage(
      sessionId: message.sessionId,
      accountId: message.accountId,
      hashAlg: message.hashAlg,
      signMetadata: message.signMetadata,
      publicKey: message.publicKey,
      payload: SignPayload(encryptedPayload, nonce, round, 2),
      signMessage: message.signMessage,
      messageHash: message.messageHash,
      isApproved: true,
      walletId: message.walletId,
    );
    _sharedDatabase.setSignMessage(_userId, signMessage2);
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
    _sharedDatabase.deleteSignMessage(_userId);
  }
}

String decryptPayload(Sodium sodium, PairingData pairingData, SignPayload payload) {
  final plainText = sodium.crypto.box.openEasy(
    cipherText: base64.decode(payload.message),
    nonce: Uint8List.fromList(hex.decode(payload.nonce)),
    publicKey: pairingData.webPublicKey,
    secretKey: pairingData.encKeyPair.secretKey,
  );
  return utf8.decode(plainText);
}
