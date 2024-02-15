// Copyright (c) Silence Laboratories Pte. Ltd.
// This software is licensed under the Silence Laboratories License Agreement.

final class PairingMessage {
  final String pairingId;
  final String userId;
  final String signPublicKey;
  final String phoneEncPublicKey;
  final DateTime createdAt;
  final int expirationTimeout;
  final String deviceName;
  final bool? isPaired;
  final String? backupData;

  PairingMessage(
    this.pairingId,
    this.userId,
    this.signPublicKey,
    this.phoneEncPublicKey,
    this.expirationTimeout,
    this.deviceName,
    this.isPaired,
    this.backupData,
  ) : createdAt = DateTime.now();

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'signPublicKey': signPublicKey,
        'phoneEncPublicKey': phoneEncPublicKey,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'expiry': expirationTimeout,
        'deviceName': deviceName,
        'isPaired': isPaired,
        if (backupData != null) 'backupData': backupData,
      };
}

final class PairingResponse {
  final bool? isPaired;
  final bool isBackedUpDataUsed;

  PairingResponse.fromJson(Map<String, dynamic> json)
      : isPaired = json['isPaired'] as bool?,
        isBackedUpDataUsed = (json['isBackedUpDataUsed'] is bool) ? json['isBackedUpDataUsed'] : false;
}
