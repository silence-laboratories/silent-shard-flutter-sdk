// Copyright (c) Silence Laboratories Pte. Ltd.
// This software is licensed under the Silence Laboratories License Agreement.

import 'dart:convert';

final class AccountBackup {
  final String address;
  final String keyshareData;
  final String remoteData;

  AccountBackup(this.address, this.keyshareData, this.remoteData);

  @override
  String toString() => jsonEncode(toJson());

  String get toCanonicalJsonString => '{"address":"$address","keyshare":"$keyshareData","remote":"$remoteData"}';

  Map<String, dynamic> toJson() => {
        'address': address,
        'keyshare': keyshareData,
        'remote': remoteData,
      };

  AccountBackup.fromJson(Map<String, dynamic> json)
      : address = json['address'],
        keyshareData = json['keyshare'],
        remoteData = json['remote'];
}
