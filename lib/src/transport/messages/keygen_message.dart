final class KeygenPayload {
  final String message;
  final String nonce;
  final int round;
  final int party;

  KeygenPayload(
    this.message,
    this.nonce,
    this.round,
    this.party,
  );

  factory KeygenPayload.fromJson(Map<String, dynamic> json) => KeygenPayload(
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

final class KeygenMessage {
  final String sessionId;
  final int accountId;
  final KeygenPayload payload;
  final bool isApproved;
  final Duration expirationTimeout;
  final DateTime createdAt;

  KeygenMessage(
    this.sessionId,
    this.accountId,
    this.payload, {
    this.isApproved = true,
    this.expirationTimeout = const Duration(seconds: 60),
    DateTime? created,
  }) : createdAt = created ?? DateTime.now();

  factory KeygenMessage.fromJson(Map<String, dynamic> json) {
    final payload = KeygenPayload.fromJson(json['message']);
    final expirationTimeout = Duration(milliseconds: json['expiry']);
    final createdAt = DateTime.fromMillisecondsSinceEpoch(json['createdAt']);
    return KeygenMessage(
      json['sessionId'],
      json['accountId'],
      payload,
      isApproved: json['isApproved'] ?? false,
      expirationTimeout: expirationTimeout,
      created: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'accountId': accountId,
        'message': payload.toJson(),
        'isApproved': isApproved,
        'expiry': expirationTimeout.inMilliseconds,
        'createdAt': createdAt.millisecondsSinceEpoch
      };
}
