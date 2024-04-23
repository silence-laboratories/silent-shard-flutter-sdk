// Copyright (c) Silence Laboratories Pte. Ltd.
// This software is licensed under the Silence Laboratories License Agreement.

final class QRMessage {
  final String pairingId;
  final String webEncPublicKey;
  final String signPublicKey;
  final String walletName;
  final bool isDemo;

  QRMessage.fromJson(Map<String, dynamic> json)
      : pairingId = json['pairingId'],
        webEncPublicKey = json['webEncPublicKey'],
        signPublicKey = json['signPublicKey'],
        walletName = json['walletName'] ?? "snap",
        isDemo = json['SLADemo'] ?? false;
}
