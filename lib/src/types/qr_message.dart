// Copyright (c) Silence Laboratories Pte. Ltd.
// This software is licensed under the Silence Laboratories License Agreement.

import 'package:dart_2_party_ecdsa/dart_2_party_ecdsa.dart';

final class QRMessage {
  final String pairingId;
  final String webEncPublicKey;
  final String signPublicKey;
  final String walletId;
  final bool isDemo;

  QRMessage.fromJson(Map<String, dynamic> json)
      : pairingId = json['pairingId'],
        webEncPublicKey = json['webEncPublicKey'],
        signPublicKey = json['signPublicKey'],
        walletId = json['walletId'] ?? METAMASK_WALLET_ID,
        isDemo = json['SLADemo'] ?? false;
}
