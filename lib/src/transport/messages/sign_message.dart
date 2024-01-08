final class SignPayload {
  final String message;
  final String nonce;
  final int round;
  final int party;

  SignPayload(
    this.message,
    this.nonce,
    this.round,
    this.party,
  );

  factory SignPayload.fromJson(Map<String, dynamic> json) => SignPayload(
        json['message'],
        json['nonce'],
        json['round'],
        json['party'],
      );

  Map<String, dynamic> toJson() => {
        'message': message,
        'nonce': nonce,
        'round': round,
        'party': party,
      };
}

enum SignType {
  legacyTransaction,
  ethTransaction,
  ethSign,
  personalSign,
  ethSignTypedData,
  ethSignTypedDataV1,
  ethSignTypedDataV2,
  ethSignTypedDataV3,
  ethSignTypedDataV4;

  @override
  String toString() => switch (this) {
        SignType.legacyTransaction => 'legacy_transaction',
        SignType.ethTransaction => 'eth_transaction',
        SignType.ethSign => 'eth_sign',
        SignType.personalSign => 'personal_sign',
        SignType.ethSignTypedData => 'eth_signTypedData',
        SignType.ethSignTypedDataV1 => 'eth_signTypedData_v1',
        SignType.ethSignTypedDataV2 => 'eth_signTypedData_v2',
        SignType.ethSignTypedDataV3 => 'eth_signTypedData_v3',
        SignType.ethSignTypedDataV4 => 'eth_signTypedData_v4',
      };

  factory SignType.fromString(String input) => switch (input) {
        'legacy_transaction' => SignType.legacyTransaction,
        'eth_transaction' => SignType.ethTransaction,
        'eth_sign' => SignType.ethSign,
        'personal_sign' => SignType.personalSign,
        'eth_signTypedData' => SignType.ethSignTypedData,
        'eth_signTypedData_v1' => SignType.ethSignTypedDataV1,
        'eth_signTypedData_v2' => SignType.ethSignTypedDataV2,
        'eth_signTypedData_v3' => SignType.ethSignTypedDataV3,
        'eth_signTypedData_v4' => SignType.ethSignTypedDataV4,
        _ => throw ArgumentError('Cannot instantiate SignType from $input'),
      };
}

final class SignMessage {
  final String sessionId;
  final int accountId;
  final String hashAlg;
  final SignType signMetadata;
  final String pubicKey;
  SignPayload payload;
  final String messageToSign;
  final String messageHash;
  bool? isApproved;
  final Duration expirationTimeout;
  final DateTime createdAt;

  SignMessage(
    this.sessionId,
    this.accountId,
    this.hashAlg,
    this.signMetadata,
    this.pubicKey,
    this.payload,
    this.messageToSign,
    this.messageHash,
    this.isApproved, {
    this.expirationTimeout = const Duration(seconds: 60),
    DateTime? created,
  }) : createdAt = created ?? DateTime.now();

  factory SignMessage.fromJson(Map<String, dynamic> json) {
    final payload = SignPayload.fromJson(json['message']);
    final expirationTimeout = Duration(milliseconds: json['expiry']);
    final createdAt = DateTime.fromMillisecondsSinceEpoch(json['createdAt']);
    return SignMessage(
      json['sessionId'],
      json['accountId'],
      json['hashAlg'],
      SignType.fromString(json['signMetadata']),
      json['publicKey'],
      payload,
      json['signMessage'],
      json['messageHash'],
      json['isApproved'],
      expirationTimeout: expirationTimeout,
      created: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'accountId': accountId,
        'hashAlg': hashAlg,
        'signMetadata': signMetadata.toString(),
        'publicKey': pubicKey,
        'message': payload.toJson(),
        'signMessage': messageToSign,
        'messageHash': messageHash,
        'isApproved': isApproved ?? false,
        'expiry': expirationTimeout.inMilliseconds,
        'createdAt': createdAt.millisecondsSinceEpoch
      };
}
