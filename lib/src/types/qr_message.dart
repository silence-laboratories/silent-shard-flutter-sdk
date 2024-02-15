// Copyright (c) Silence Laboratories Pte. Ltd.
// This software is licensed under the Silence Laboratories License Agreement.

final class QRMessage {
  final String pairingId;
  final String webEncPublicKey;
  final String signPublicKey;
  final bool isDemo;

  QRMessage.fromJson(Map<String, dynamic> json)
      : pairingId = json['pairingId'],
        webEncPublicKey = json['webEncPublicKey'],
        signPublicKey = json['signPublicKey'],
        isDemo = json['SLADemo'] ?? false;
}
