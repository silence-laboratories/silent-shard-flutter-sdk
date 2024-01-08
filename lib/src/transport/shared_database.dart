import 'package:dart_2_party_ecdsa/src/transport/messages/backup_message.dart';

import 'transport.dart';
import 'messages/pairing_message.dart';
import 'messages/keygen_message.dart';
import 'messages/sign_message.dart';
import 'messages/user_data.dart';

class SharedDatabase {
  final Transport _transport;

  SharedDatabase(this._transport);

  // --- Pairing ---

  Future<void> setPairingMessage(PairingMessage message) => _transport.set("pairing", message.pairingId, message.toJson());

  Future<void> deletePairingMessage(String pairingId) => _transport.delete("pairing", pairingId);

  Stream<PairingResponse> pairingUpdates(String pairingId) =>
      _transport.updates("pairing", pairingId).where((event) => event != null).map((event) => PairingResponse.fromJson(event!));

  // --- Keygen ---

  Future<void> setKeygenMessage(String pairingId, KeygenMessage message) => _transport.set("keygen", pairingId, message.toJson());

  Future<void> deleteKeygenMessage(String pairingId) => _transport.delete("keygen", pairingId);

  Stream<KeygenMessage> keygenUpdates(String pairingId) =>
      _transport.updates("keygen", pairingId).where((event) => event != null).map((event) => KeygenMessage.fromJson(event!));

  // --- Signing ---

  Future<void> setSignMessage(String pairingId, SignMessage message) => _transport.set("sign", pairingId, message.toJson());

  Future<void> deleteSignMessage(String pairingId) => _transport.delete("sign", pairingId);

  Stream<SignMessage> signUpdates(String pairingId) =>
      _transport.updates("sign", pairingId).where((event) => event != null).map((event) => SignMessage.fromJson(event!));

  // -- Backup --

  Future<void> setBackupMessage(String pairingId, BackupMessage message) => _transport.set("backup", pairingId, message.toJson());

  Future<void> deleteBackupMessage(String pairingId) => _transport.delete("backup", pairingId);

  Stream<BackupMessage> backupUpdates(String pairingId) =>
      _transport.updates("backup", pairingId).where((event) => event != null).map((event) => BackupMessage.fromJson(event!));

  // --- Users ---

  Future<void> setUserData(String userId, UserData data) => _transport.set("users", userId, data.toJson());

  Future<void> deleteUserData(String userId) => _transport.delete("users", userId);

  Stream<UserData> userUpdates(String userId) =>
      _transport.updates("users", userId).where((event) => event != null).map((event) => UserData.fromJson(event!));
}
