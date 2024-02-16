// Copyright (c) Silence Laboratories Pte. Ltd.
// This software is licensed under the Silence Laboratories License Agreement.

final class BackupMessage {
  final String backupData;
  final bool isBackedUp;
  final String pairingId;

  BackupMessage({required this.backupData, required this.isBackedUp, required this.pairingId});

  Map<String, dynamic> toJson() => {
        'backupData': backupData,
        'isBackedUp': isBackedUp,
        'pairingId': pairingId,
      };

  factory BackupMessage.fromJson(Map<String, dynamic> json) {
    return BackupMessage(
      backupData: json['backupData'] as String,
      isBackedUp: (json['isBackedUp'] ?? false) as bool,
      pairingId: json['pairingId'] as String,
    );
  }
}
