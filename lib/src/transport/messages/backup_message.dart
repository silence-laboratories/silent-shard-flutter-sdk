// Copyright (c) Silence Laboratories Pte. Ltd.
// This software is licensed under the Silence Laboratories License Agreement.

final class BackupMessage {
  final String backupData;
  final String? address;
  final String? walletId;
  final bool isBackedUp;

  BackupMessage({required this.backupData, required this.isBackedUp, this.address, this.walletId});

  Map<String, dynamic> toJson() => {
        'backupData': backupData,
        'address': address,
        'walletId': walletId,
        'isBackedUp': isBackedUp,
      };

  factory BackupMessage.fromJson(Map<String, dynamic> json) {
    return BackupMessage(
      backupData: json['backupData'] as String,
      address: json['address'] as String?,
      walletId: json['walletId'] as String?,
      isBackedUp: (json['isBackedUp'] ?? false) as bool,
    );
  }
}
