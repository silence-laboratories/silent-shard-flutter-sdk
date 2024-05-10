import 'package:dart_2_party_ecdsa/dart_2_party_ecdsa.dart';
import 'package:dart_2_party_ecdsa/src/ctss_bindings_generated.dart';

Map<String, dynamic> migrateFromV0ToV1(CTSSBindings ctss, dynamic keysharesJson, dynamic walletBackupJson) {
  Map<String, List<Keyshare2>> keyshares = {};
  Map<String, WalletBackup> walletBackups = {};

  if (keysharesJson != null) {
    List<Keyshare2> v0Keyshares = keysharesJson.map<Keyshare2>((e) => Keyshare2.fromBytes(ctss, e)).toList();
    keyshares[METAMASK_WALLET_ID] = v0Keyshares;
  }

  if (walletBackupJson != null) {
    WalletBackup v0Backup = WalletBackup.fromJson(walletBackupJson);
    walletBackups[METAMASK_WALLET_ID] = v0Backup;
  }

  return {
    'keyshares': keyshares.map((key, value) => MapEntry(key, value.map((e) => e.toBytes()).toList())),
    'backup': walletBackups.map((key, value) => MapEntry(key, value.toJson())),
    'version': 1
  };
}
