// Copyright (c) Silence Laboratories Pte. Ltd.
// This software is licensed under the Silence Laboratories License Agreement.

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

  bool get isTransaction => this == SignType.legacyTransaction || this == SignType.ethTransaction;

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
  final String publicKey;
  SignPayload payload;
  final String signMessage;
  final String messageHash;
  final String? walletId;
  bool? isApproved;
  final Duration expirationTimeout;
  final DateTime createdAt;

  SignMessage({
    required this.sessionId,
    required this.accountId,
    required this.hashAlg,
    required this.signMetadata,
    required this.publicKey,
    required this.payload,
    required this.signMessage,
    required this.messageHash,
    this.isApproved,
    this.walletId,
    this.expirationTimeout = const Duration(seconds: 60),
    DateTime? created,
  }) : createdAt = created ?? DateTime.now();

  factory SignMessage.fromJson(Map<String, dynamic> json) {
    final payload = SignPayload.fromJson(json['message']);
    final expirationTimeout = Duration(milliseconds: json['expiry']);
    final createdAt = DateTime.fromMillisecondsSinceEpoch(json['createdAt']);
    return SignMessage(
      sessionId: json['sessionId'],
      accountId: json['accountId'],
      hashAlg: json['hashAlg'],
      signMetadata: SignType.fromString(json['signMetadata']),
      publicKey: json['publicKey'],
      payload: payload,
      signMessage: json['signMessage'],
      messageHash: json['messageHash'],
      isApproved: json['isApproved'],
      walletId: json['walletId'] ?? "snap",
      expirationTimeout: expirationTimeout,
      created: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'accountId': accountId,
        'hashAlg': hashAlg,
        'signMetadata': signMetadata.toString(),
        'publicKey': publicKey,
        'message': payload.toJson(),
        'signMessage': signMessage,
        'messageHash': messageHash,
        'isApproved': isApproved ?? false,
        'expiry': expirationTimeout.inMilliseconds,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'walletId': walletId ?? "snap"
      };
}
