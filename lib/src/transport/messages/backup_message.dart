// Copyright (c) Silence Laboratories Pte. Ltd.
// This software is licensed under the Silence Laboratories License Agreement.

final class BackupMessage {
  final String backupData;
  final String? address;
  final String? walletId;
  final bool isBackedUp;
  final Duration expirationTimeout;
  final DateTime createdAt;

  BackupMessage({
    required this.backupData,
    required this.isBackedUp,
    this.address,
    this.walletId,
    this.expirationTimeout = const Duration(seconds: 60),
    DateTime? created,
  }) : createdAt = created ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'backupData': backupData,
        'address': address,
        'walletId': walletId,
        'isBackedUp': isBackedUp,
        'expiry': expirationTimeout.inMilliseconds,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  factory BackupMessage.fromJson(Map<String, dynamic> json) {
    final expirationTimeout = Duration(milliseconds: json['expiry']);
    final createdAt = DateTime.fromMillisecondsSinceEpoch(json['createdAt']);
    return BackupMessage(
      backupData: json['backupData'] as String,
      address: json['address'] as String?,
      walletId: json['walletId'] as String?,
      isBackedUp: (json['isBackedUp'] ?? false) as bool,
      expirationTimeout: expirationTimeout,
      created: createdAt,
    );
  }
}
