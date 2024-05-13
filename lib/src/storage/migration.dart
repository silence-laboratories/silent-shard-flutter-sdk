import 'package:dart_2_party_ecdsa/dart_2_party_ecdsa.dart';
import 'package:dart_2_party_ecdsa/src/ctss_bindings_generated.dart';
import 'package:sodium/sodium.dart';

Map<String, dynamic> migrateFromV0ToV1(Sodium sodium, CTSSBindings ctss, dynamic json) {
  Map<String, List<Keyshare2>> keyshares = {};
  Map<String, WalletBackup> walletBackups = {};
  Map<String, PairingData> pairingData = {};

  final keysharesJson = json['keyshares'];
  final walletBackupJson = json['backup'];
  final pairingDataJson = json['pairingData'];

  if (keysharesJson != null) {
    List<Keyshare2> v0Keyshares = keysharesJson.map<Keyshare2>((e) => Keyshare2.fromBytes(ctss, e)).toList();
    if (v0Keyshares.isNotEmpty) {
      keyshares[METAMASK_WALLET_ID] = v0Keyshares;
      if (pairingDataJson != null) {
        PairingData? v0PairingData = PairingData.fromJson(sodium, pairingDataJson);
        String address = v0Keyshares.first.ethAddress;
        pairingData[address] = v0PairingData;
      }
    }
  }

  if (walletBackupJson != null) {
    WalletBackup v0Backup = WalletBackup.fromJson(walletBackupJson);
    walletBackups[METAMASK_WALLET_ID] = v0Backup;
  }

  json['version'] = 1;
  json['pairingData'] = pairingData.map((key, value) => MapEntry(key, value.toJson()));
  json['keyshares'] = keyshares.map((key, value) => MapEntry(key, value.map((e) => e.toBytes()).toList()));
  json['backup'] = walletBackups.map((key, value) => MapEntry(key, value.toJson()));

  return json;
}
