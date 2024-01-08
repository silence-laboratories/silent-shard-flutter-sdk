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
