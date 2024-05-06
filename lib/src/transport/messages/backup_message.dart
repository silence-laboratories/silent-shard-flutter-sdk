// Copyright (c) Silence Laboratories Pte. Ltd.
// This software is licensed under the Silence Laboratories License Agreement.

final class BackupMessage {
  final String backupData;
  final bool isBackedUp;

  BackupMessage({required this.backupData, required this.isBackedUp});

  Map<String, dynamic> toJson() => {
        'backupData': backupData,
        'isBackedUp': isBackedUp,
      };

  factory BackupMessage.fromJson(Map<String, dynamic> json) {
    return BackupMessage(
      backupData: json['backupData'] as String,
      isBackedUp: (json['isBackedUp'] ?? false) as bool,
    );
  }
}
