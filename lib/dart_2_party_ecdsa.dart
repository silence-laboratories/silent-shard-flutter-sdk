// Copyright (c) Silence Laboratories Pte. Ltd.
// This software is licensed under the Silence Laboratories License Agreement.

import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:dart_2_party_ecdsa/src/transport/messages/backup_message.dart';
import 'package:meta/meta.dart';
import 'package:async/async.dart';
import 'package:sodium/sodium.dart';
import 'package:sodium_libs/sodium_libs.dart' as sodium_libs;
import 'package:stream_transform/stream_transform.dart';

import 'src/ctss_bindings_generated.dart';
import 'src/types/account_backup.dart';
import 'src/types/pairing_data.dart';
import 'src/types/qr_message.dart';
import 'src/types/keyshare.dart';
import 'src/actions/keygen_action.dart';
import 'src/actions/pairing_action.dart';
import 'src/state/keygen_state.dart';
import 'src/state/pairing_state.dart';
import 'src/storage/prefs_storage.dart';
import 'src/storage/storage.dart';
import 'src/storage/local_database.dart';
import 'src/transport/transport.dart';
import 'src/transport/shared_database.dart';
import 'src/actions/remote_backup_action.dart';
import 'src/actions/sign_listener.dart';
import 'src/state/backup_state.dart';
import 'src/types/user_data.dart';
import 'src/types/wallet_backup.dart';
import 'src/extensions/listenable_stream.dart';

export 'src/types/qr_message.dart';
export 'src/transport/transport.dart';
export 'src/state/pairing_state.dart';
export 'src/state/keygen_state.dart';
export 'src/state/backup_state.dart';
export 'src/types/pairing_data.dart';
export 'src/types/keyshare.dart';
export 'src/types/account_backup.dart';
export 'src/types/wallet_backup.dart';
export 'src/types/user_data.dart';
export 'src/actions/sign_listener.dart';
export 'src/transport/messages/sign_message.dart';
export 'src/transport/messages/backup_message.dart';

const METAMASK_WALLET_ID = 'metamask';

enum SdkState {
  loaded,
  initialized,
  paired,
  readyToSign,
}

final class Dart2PartySDK {
  SdkState _state = SdkState.loaded;

  SdkState get state => _state;

  /// The dynamic library in which the symbols for [CTSSBindings] can be found.
  late final DynamicLibrary _ctssDylib = () {
    const libName = 'ctss';
    if (Platform.isMacOS || Platform.isIOS) {
      return DynamicLibrary.open('$libName.framework/$libName');
    }
    if (Platform.isAndroid || Platform.isLinux) {
      return DynamicLibrary.open('lib$libName.so');
    }
    throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
  }();

  /// The bindings to the native functions in [_ctssDylib].
  @visibleForTesting
  late final CTSSBindings ctss = CTSSBindings(_ctssDylib);

  late final Sodium sodium;

  final Transport _transport;
  late final _sharedDatabase = SharedDatabase(_transport);

  final Storage _storage;
  late final localDatabase = LocalDatabase.fromStorage(sodium, ctss, _storage);

  Dart2PartySDK(this._transport, [Storage? storage]) : _storage = storage ?? PrefsStorage();

  Future<void> init() async {
    if (_state != SdkState.loaded) throw StateError('Cannot init SDK in $_state state');

    await _storage.init();
    sodium = await sodium_libs.SodiumInit.init();

    _initState();
  }

  void _initState() {
    switch ((pairingState.pairingDataMap.isEmpty, keygenState.keysharesMap.isEmpty)) {
      case (false, false):
        _state = SdkState.readyToSign;
      case (false, true):
        _state = SdkState.paired;
      default:
        _state = SdkState.initialized;
    }
  }

  void remove(String walletId, String address) {
    if (_state == SdkState.loaded) throw StateError('Cannot cleanup SDK in $_state state');
    deleteBackup(walletId, address);
    deleteKeyshare(walletId, address);
    unpair(address);
  }

  // --- Pairing ---

  CancelableOperation<PairingData>? _pairingOperation;

  late PairingState pairingState = PairingState(localDatabase);

  CancelableOperation<PairingData> startPairing(QRMessage message, String userId, [WalletBackup? walletBackup]) {
    final pairingAction = PairingAction(sodium, _sharedDatabase, message, userId);
    final walletId = message.walletId;
    _pairingOperation = CancelableOperation.fromFuture(
      pairingAction.start(walletBackup?.combinedRemoteData),
      onCancel: () {
        pairingAction.cancel();
        _state = SdkState.initialized;
      },
    ).then((pairingData) {
      if (walletBackup != null) {
        try {
          List<Keyshare2> keyshareList = walletBackup.accounts.map((accountBackup) => Keyshare2.fromBytes(ctss, accountBackup.keyshareData)).toList();
          assert(keyshareList.isNotEmpty, 'Backup doesn\'t contain keyshares');
          keygenState.upsertKeyshares(walletId, keyshareList);
          backupState.upsertBackupAccounts(walletId, walletBackup.accounts);
          pairingState.setPairingData(keyshareList.first.ethAddress, pairingData);

          _state = SdkState.readyToSign;
        } catch (error) {
          _state = SdkState.initialized;
          throw StateError('Error recovering from backup: $error');
        }
      } else {
        pairingState.setPairingData(null, pairingData);
        _state = SdkState.paired;
      }
      return pairingData;
    }, onError: (error, __) {
      _state = SdkState.initialized;
      throw error;
    });

    return _pairingOperation!;
  }

  CancelableOperation<PairingData> startRePairing(QRMessage message, String address, String userId) {
    if (_state != SdkState.readyToSign) CancelableOperation.fromFuture(Future.error(StateError('Cannot start re-pairing SDK in $_state state')));

    final walletBackup = backupState.walletBackupsMap[message.walletId];
    if (walletBackup == null) {
      return CancelableOperation.fromFuture(Future.error(StateError('NO_BACKUP_DATA_WHILE_REPAIRING')));
    }
    if (walletBackup.accounts.isEmpty) {
      return CancelableOperation.fromFuture(Future.error(StateError('Cannot start re-pairing SDK without remote backup data')));
    }

    final accounts = walletBackup.accounts.where((e) => e.address == address).toList();
    final repairBackup = WalletBackup(accounts);
    final pairingAction = PairingAction(sodium, _sharedDatabase, message, userId);

    _pairingOperation = CancelableOperation.fromFuture(
      pairingAction.start(repairBackup.combinedRemoteData),
      onCancel: pairingAction.cancel,
    ).then((pairingData) {
      // TODO: invalidate old sign listener
      pairingState.setPairingData(address, pairingData);
      return pairingData;
    });

    return _pairingOperation!;
  }

  void unpair(String address) {
    _pairingOperation?.cancel();
    pairingState.removePairingDataBy(address);
  }

  // --- Keygen ---

  late KeygenState keygenState = KeygenState(localDatabase);

  CancelableOperation<Keyshare2> startKeygen(String walletId, String userId, PairingData pairingData) {
    if (_state.index < SdkState.paired.index) {
      return CancelableOperation.fromFuture(Future.error(StateError('Cannot start keygen when SDK in $_state state')));
    }

    final keygenAction = KeygenAction(sodium, ctss, _sharedDatabase, pairingData, userId);
    final keygenOperation = CancelableOperation.fromFuture(keygenAction.start(), onCancel: keygenAction.cancel);

    return keygenOperation.then((keyshare) {
      keygenState.addKeyshare(walletId, keyshare);
      pairingState.setPairingData(keyshare.ethAddress, pairingData);
      _state = SdkState.readyToSign;
      return keyshare;
    });
  }

  void deleteKeyshare(String walletId, String address) {
    if (_state != SdkState.readyToSign && _state != SdkState.initialized) return;
    keygenState.removeKeyshareBy(walletId, address);
  }

  // --- Sign ---

  SignListener? _signListener;

  SignListener? _updateSignListener(Map<String, PairingData> pairingDataMap, Map<String, List<Keyshare2>> keyshares, String userId) {
    if (pairingDataMap.isEmpty || keyshares.isEmpty) {
      _signListener = null;
    } else {
      _signListener = SignListener(pairingDataMap, userId, keyshares, _sharedDatabase, sodium, ctss);
    }
    return _signListener;
  }

  Stream<SignRequest> signRequests(String userId) {
    final pairingStream = pairingState.toStream((p) => p.pairingDataMap);
    final keysharesStream = keygenState.toStream((p) => p.keysharesMap);
    return pairingStream //
        .combineLatest(
          keysharesStream,
          (pairingData, keyshares) => _updateSignListener(pairingData, keyshares, userId),
        )
        .map((listener) => listener?.signRequests() ?? const Stream<SignRequest>.empty())
        .switchLatest();
  }

  CancelableOperation<String> approve(SignRequest request) =>
      _signListener?.approve(request) ?? CancelableOperation.fromFuture(Future.error(StateError('No active signing listener')));

  void decline(SignRequest request) => _signListener?.decline(request);

  // -- Remote Backup --

  late final BackupState backupState = BackupState(localDatabase);

  Stream<BackupMessage> listenRemoteBackup(String userId) {
    if (_state != SdkState.readyToSign) {
      throw StateError('Cannot start backup when SDK in $_state state');
    }

    final remoteBackupListener = RemoteBackupListener(_sharedDatabase, userId, keygenState, backupState);
    return remoteBackupListener.start();
  }

  void deleteBackup(String walletId, String address) {
    if (_state == SdkState.loaded) throw StateError('Cannot delete backup when SDK in $_state state');
    backupState.removeBackupAccountBy(walletId, address);
  }

  CancelableOperation<WalletBackup> walletBackup(String walletId, String address) {
    if (_state != SdkState.readyToSign) CancelableOperation.fromFuture(Future.error(StateError('Cannot start backup when SDK in $_state state')));

    final keyshares = keygenState.keysharesMap[walletId];
    if (keyshares == null || keyshares.isEmpty) return CancelableOperation.fromFuture(Future.error(StateError('No keys to backup')));
    final walletBackup = backupState.walletBackupsMap[walletId];
    if (walletBackup == null) return CancelableOperation.fromFuture(Future.error(StateError('No backup data for $walletId')));

    if (walletId == METAMASK_WALLET_ID) {
      assert(keyshares.length == walletBackup.accounts.length, 'Part of backup is not fetched');
    }

    final backupAccounts = walletBackup.accounts.where((accountBackup) {
      return accountBackup.address == address;
    });

    final fetchedWalletBackup = WalletBackup(backupAccounts);

    return CancelableOperation.fromValue(fetchedWalletBackup);
  }

  // --- Users ---

  void updateMessagingToken(String userId, String token) {
    _sharedDatabase.setUserData(userId, UserData(FCMData(token), null), true);
  }

  Stream<UserData> snapVersionListener(String userId) {
    return _sharedDatabase.userUpdates(userId);
  }
}
