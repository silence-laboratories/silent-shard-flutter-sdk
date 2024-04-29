// Copyright (c) Silence Laboratories Pte. Ltd.
// This software is licensed under the Silence Laboratories License Agreement.

import 'package:dart_2_party_ecdsa/src/transport/messages/backup_message.dart';

import 'transport.dart';
import 'messages/pairing_message.dart';
import 'messages/keygen_message.dart';
import 'messages/sign_message.dart';
import '../types/user_data.dart';

class SharedDatabase {
  final Transport _transport;

  SharedDatabase(this._transport);

  // --- Pairing ---

  Future<void> setPairingMessage(PairingMessage message) => _transport.set("pairing", message.pairingId, message.toJson());

  Future<void> deletePairingMessage(String pairingId) => _transport.delete("pairing", pairingId);

  Stream<PairingResponse> pairingUpdates(String pairingId) =>
      _transport.updates("pairing", pairingId).where((event) => event != null).map((event) => PairingResponse.fromJson(event!));

  // --- Keygen ---

  Future<void> setKeygenMessage(String userId, KeygenMessage message) => _transport.set("keygen", userId, message.toJson());

  Future<void> deleteKeygenMessage(String userId) => _transport.delete("keygen", userId);

  Stream<KeygenMessage> keygenUpdates(String userId) =>
      _transport.updates("keygen", userId).where((event) => event != null).map((event) => KeygenMessage.fromJson(event!));

  // --- Signing ---

  Future<void> setSignMessage(String userId, SignMessage message) => _transport.set("sign", userId, message.toJson());

  Future<void> deleteSignMessage(String userId) => _transport.delete("sign", userId);

  Stream<SignMessage> signUpdates(String userId) =>
      _transport.updates("sign", userId).where((event) => event != null).map((event) => SignMessage.fromJson(event!));

  // -- Backup --

  Future<void> setBackupMessage(String userId, BackupMessage message) => _transport.set("backup", userId, message.toJson());

  Future<void> deleteBackupMessage(String userId) => _transport.delete("backup", userId);

  Stream<BackupMessage> backupUpdates(String userId) =>
      _transport.updates("backup", userId).where((event) => event != null).map((event) => BackupMessage.fromJson(event!));

  // --- Users ---

  Future<void> setUserData(String userId, UserData data, bool? mergeData) => _transport.set("users", userId, data.toJson(), mergeData ?? false);

  Future<void> deleteUserData(String userId) => _transport.delete("users", userId);

  Stream<UserData> userUpdates(String userId) =>
      _transport.updates("users", userId).where((event) => event != null).map((event) => UserData.fromJson(event!));
}
