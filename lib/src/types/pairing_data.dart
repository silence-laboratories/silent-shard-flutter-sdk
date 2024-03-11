// Copyright (c) Silence Laboratories Pte. Ltd.
// This software is licensed under the Silence Laboratories License Agreement.

import 'dart:convert';
import 'dart:typed_data';

import 'package:sodium/sodium.dart';

class PairingData {
  final String pairingId;
  final Uint8List webPublicKey;
  final KeyPair encKeyPair;
  final String? remark;

  PairingData(this.pairingId, this.webPublicKey, this.encKeyPair, this.remark);

  factory PairingData.fromJson(Sodium sodium, Map<String, dynamic> json) {
    final pairingId = json['pairingId'];
    final webPublicKey = base64Decode(json['webPublicKey']);
    final publicKey = base64Decode(json['encPublicKey']);
    final privateKey = base64Decode(json['encPrivateKey']);
    final remark = json['pairingRemark'];
    final keyPair = KeyPair(publicKey: publicKey, secretKey: SecureKey.fromList(sodium, privateKey));
    return PairingData(pairingId, webPublicKey, keyPair, remark);
  }

  Map<String, dynamic> toJson() {
    return {
      'pairingId': pairingId,
      'webPublicKey': base64Encode(webPublicKey),
      'encPublicKey': base64Encode(encKeyPair.publicKey),
      'encPrivateKey': base64Encode(encKeyPair.secretKey.extractBytes()),
      'remark': remark
    };
  }
}
