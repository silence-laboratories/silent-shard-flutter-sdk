// Copyright (c) Silence Laboratories Pte. Ltd.
// This software is licensed under the Silence Laboratories License Agreement.

final class FCMData {
  final String token;
  final DateTime createdAt;
  final Duration expirationTimeout;

  FCMData(
    this.token, [
    this.expirationTimeout = const Duration(milliseconds: 60000),
    DateTime? created,
  ]) : createdAt = created ?? DateTime.now();

  factory FCMData.fromJson(Map<String, dynamic> json) {
    final expirationTimeout = Duration(milliseconds: json['expiry']);
    final createdAt = DateTime.fromMillisecondsSinceEpoch(json['createdAt']);
    return FCMData(json['token'], expirationTimeout, createdAt);
  }

  Map<String, dynamic> toJson() => {
        'token': token,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'expiry': expirationTimeout.inMilliseconds,
      };
}

final class UserData {
  final FCMData fcmData;

  UserData(this.fcmData);

  UserData.fromJson(Map<String, dynamic> json) : fcmData = FCMData.fromJson(json['fcm']);

  Map<String, dynamic> toJson() => {
        'fcm': fcmData.toJson(),
      };
}
