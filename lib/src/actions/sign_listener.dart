// Copyright (c) Silence Laboratories Pte. Ltd.
// This software is licensed under the Silence Laboratories License Agreement.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:convert/convert.dart';
import 'package:dart_2_party_ecdsa/src/utils/utils.dart';
import 'package:hashlib/hashlib.dart';
import 'package:sodium/sodium.dart';
import 'package:stream_transform/stream_transform.dart';

import '../ctss_bindings_generated.dart';
import '../types/keyshare.dart';
import '../types/pairing_data.dart';
import '../transport/shared_database.dart';
import '../transport/messages/sign_message.dart';
import '../actions/sign_action.dart';
import '../utils/rlp/bigint.dart';
import '../utils/rlp/rlp.dart';

final class SignRequest {
  final SignMessage _originalMessage;
  final int accountId;
  final SignType signType;
  final String hashAlg;
  final String message;
  final String? to;
  final BigInt? value;
  final String readableMessage;
  final DateTime createdAt;
  final String? messageHash;
  final int? chainId;
  final String? walletId;
  final String from;

  SignRequest._fromMessage(this._originalMessage, this.to, this.value, this.readableMessage, this.messageHash, this.chainId)
      : accountId = _originalMessage.accountId,
        signType = _originalMessage.signMetadata,
        hashAlg = _originalMessage.hashAlg,
        message = _originalMessage.payload.message,
        walletId = _originalMessage.walletId,
        from = pubKeyToEthAddress(_originalMessage.publicKey),
        createdAt = _originalMessage.createdAt;
}

typedef SignRequestApprover = void Function(SignRequest request);

class SignListener {
  final Map<String, PairingData> _pairingData;
  final String _userId;
  final Map<String, List<Keyshare2>> _keyshares;
  final SharedDatabase _sharedDatabase;
  final Sodium _sodium;
  final CTSSBindings _ctss;

  SignListener(this._pairingData, this._userId, this._keyshares, this._sharedDatabase, this._sodium, this._ctss);

  Stream<SignRequest> signRequests() {
    return _sharedDatabase
        .signUpdates(_userId)
        .map(_filter) //
        .whereNotNull()
        .distinct((prev, curr) => prev.sessionId == curr.sessionId)
        .map(_request);
  }

  CancelableOperation<String> approve(SignRequest request) {
    if (request.accountId > _keyshares.length) {
      final error = StateError('Incorrect account index ${request.accountId}, total keyshares: ${_keyshares.length}');
      return CancelableOperation.fromFuture(Future.error(error));
    }

    if (request.messageHash != null && request.messageHash != request._originalMessage.messageHash) {
      final error = StateError('Incorrect hash');
      return CancelableOperation.fromFuture(Future.error(error));
    }

    if (_keyshares[request.walletId] == null) {
      final error = StateError('No keyshares for wallet ${request.walletId}');
      return CancelableOperation.fromFuture(Future.error(error));
    }
    final keyshare = _keyshares[request.walletId]!.firstWhere((element) => element.ethAddress == request.from);
    final signAction =
        SignAction(_sodium, _ctss, _sharedDatabase, _pairingData, _userId, keyshare, request.messageHash ?? request._originalMessage.messageHash);

    return CancelableOperation.fromFuture(signAction.start(), onCancel: signAction.cancel);
  }

  void decline(SignRequest request) {
    _sendDeclineMessage(request._originalMessage);
  }

  void _sendDeclineMessage(SignMessage message) {
    message.isApproved = false;
    _sharedDatabase.setSignMessage(_userId, message);
  }

  bool _validateMessageDate(SignMessage message) {
    final now = DateTime.now();
    // if (message.createdAt.isAfter(now)) {
    //   return false;
    // } else
    if (message.createdAt.add(message.expirationTimeout).isBefore(now)) {
      return false;
    } else {
      return true;
    }
  }

  (Object?, String?) _decryptPayload(String address, SignPayload payload) {
    try {
      if (_pairingData[address] == null) {
        throw (StateError('No pairing data for address $address'), null);
      }
      final plainText = _sodium.crypto.box.openEasy(
        cipherText: base64.decode(payload.message),
        nonce: Uint8List.fromList(hex.decode(payload.nonce)),
        publicKey: _pairingData[address]!.webPublicKey,
        secretKey: _pairingData[address]!.encKeyPair.secretKey,
      );
      return (null, utf8.decode(plainText));
    } catch (e) {
      return (e, null);
    }
  }

  SignMessage? _filter(SignMessage message) {
    if (message.payload.party != 1 || message.payload.round != 1 || message.isApproved != null) return null;
    print("1st ${message.walletId}");
    if (_keyshares[message.walletId] == null) return null;
    print("2st ${message.walletId}");
    if (message.accountId > _keyshares[message.walletId]!.length || !_validateMessageDate(message)) {
      _sendDeclineMessage(message);
      return null;
    }
    print("3rd ${message.walletId}");

    var (decryptionError, decrypted) = _decryptPayload(pubKeyToEthAddress(message.publicKey), message.payload);
    print("decryptionError $decryptionError");
    if (decryptionError != null || decrypted == null) {
      return null;
    }
    print("4th $message");

    message.payload = SignPayload(decrypted, message.payload.nonce, message.payload.round, message.payload.party);
    return message;
  }

  SignRequest _request(SignMessage message) {
    switch (message.signMetadata) {
      case SignType.legacyTransaction:
        {
          final (to, value, chainId) = _parseTransaction(message.signMessage, true);
          final readableMessage = to == null || value == null ? "Cannot decode transaction" : "Ethereum transaction";
          return SignRequest._fromMessage(message, to, value, readableMessage, null, chainId);
        }
      case SignType.ethTransaction:
        {
          final (to, value, chainId) = _parseTransaction(message.signMessage, false);
          final messageHash = _ethTransactionHash(message.signMessage, message.hashAlg);
          final readableMessage = to == null || value == null ? "Cannot decode transaction" : "Ethereum transaction";
          return SignRequest._fromMessage(message, to, value, readableMessage, messageHash, chainId);
        }

      case SignType.ethSign:
        {
          final messageHash = _ethTransactionHash(message.signMessage, message.hashAlg);
          return SignRequest._fromMessage(message, null, null, message.signMessage, messageHash, null);
        }
      case SignType.personalSign:
        {
          final messageHash = _personalSignHash(message.signMessage, message.hashAlg);
          return SignRequest._fromMessage(message, null, null, message.signMessage, messageHash, null);
        }

      default:
        return SignRequest._fromMessage(message, null, null, message.signMessage, null, null);
    }
  }

  String? _personalSignHash(String signMessage, String hashAlg) {
    if (hashAlg != 'keccak256') throw StateError('Invalid hash algorithm');

    Uint8List messageToSignBytes = Uint8List.fromList(hex.decode(signMessage));
    final prefix = '\u0019Ethereum Signed Message:\n${messageToSignBytes.length}';
    Uint8List prefixBytes = utf8.encode(prefix);
    final hash = keccak256.convert(prefixBytes + messageToSignBytes);
    return hash.hex();
  }

  String? _ethTransactionHash(String signMessage, String hashAlg) {
    if (hashAlg != 'keccak256') throw StateError('Invalid hash algorithm');

    Uint8List messageToSignBytes = Uint8List.fromList(hex.decode(signMessage));
    final hash = keccak256.convert(messageToSignBytes);
    return hash.hex();
  }

  (String?, BigInt?, int?) _parseTransaction(String transaction, bool isLegacyTransaction) {
    if (isLegacyTransaction) {
      final bytes = Uint8List.fromList(hex.decode(transaction));
      final parsed = decode(bytes);
      if (parsed is! List || parsed.length < 7 || parsed[3] is! List || parsed[4] is! List || parsed[6] is! List) return (null, null, null);
      final to = hex.encode(parsed[3]);
      final value = decodeBigInt(parsed[4]);
      final chainId = int.parse(hex.encode(parsed[6]), radix: 16);
      return ('0x$to', value, chainId);
    } else {
      final bytes = Uint8List.fromList(hex.decode(transaction.substring(2)));
      final parsed = decode(bytes);
      if (parsed is! List || parsed.length < 7 || parsed[5] is! List || parsed[6] is! List || parsed[0] is! List) return (null, null, null);
      final to = hex.encode(parsed[5]);
      final chainId = decodeBigInt(parsed[0]).toInt();
      final value = decodeBigInt(parsed[6]);
      return ('0x$to', value, chainId);
    }
  }
}
