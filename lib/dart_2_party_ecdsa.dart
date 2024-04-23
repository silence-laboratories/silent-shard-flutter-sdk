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
export 'src/types/pairing_data.dart';
export 'src/types/keyshare.dart';
export 'src/types/account_backup.dart';
export 'src/types/wallet_backup.dart';
export 'src/types/user_data.dart';
export 'src/actions/sign_listener.dart';
export 'src/transport/messages/sign_message.dart';
export 'src/transport/messages/backup_message.dart';

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
    switch ((pairingState.pairingData, keygenState.keyshares.isEmpty)) {
      case (_?, false):
        _state = SdkState.readyToSign;
      case (_?, true):
        _state = SdkState.paired;
      default:
        _state = SdkState.initialized;
    }
  }

  void reset() {
    if (_state == SdkState.loaded) throw StateError('Cannot cleanup SDK in $_state state');
    deleteBackup();
    deleteKeyshares();
    unpairIfNoKeyshares();
  }

  // --- Pairing ---

  CancelableOperation<PairingData>? _pairingOperation;

  late PairingState pairingState = PairingState(localDatabase);

  CancelableOperation<PairingData> startPairing(QRMessage message, String userId, [WalletBackup? walletBackup]) {
    if (_state != SdkState.initialized) return CancelableOperation.fromFuture(Future.error(StateError('Cannot start pairing SDK in $_state state')));

    final pairingAction = PairingAction(sodium, _sharedDatabase, message, userId);
    final walletName = message.walletName;
    _pairingOperation = CancelableOperation.fromFuture(
      pairingAction.start(walletBackup?.combinedRemoteData(walletName)),
      onCancel: () {
        pairingAction.cancel();
        _state = SdkState.initialized;
      },
    ).then((pairingData) {
      pairingState.pairingData = pairingData;
      _state = SdkState.paired;
      if (walletBackup != null) {
        try {
          // TODO: Make walletBackup also hold a map of list of backup accounts
          if (walletBackup.accounts[walletName] == null) {
            throw StateError('No backup data for wallet $walletName');
          }
          keygenState.keyshares[walletName] =
              walletBackup.accounts[walletName]!.map((accountBackup) => Keyshare2.fromBytes(ctss, accountBackup.keyshareData)).toList();
          backupState.walletBackup = walletBackup;
          _state = SdkState.readyToSign;
        } catch (error) {
          _state = SdkState.initialized;
          throw StateError('Error recovering from backup: $error');
        }
      } else {
        _state = SdkState.paired;
      }
      return pairingData;
    }, onError: (error, __) {
      _state = SdkState.initialized;
      throw error;
    });

    return _pairingOperation!;
  }

  CancelableOperation<PairingData> startRePairing(QRMessage message, String userId) {
    if (_state != SdkState.readyToSign) CancelableOperation.fromFuture(Future.error(StateError('Cannot start re-pairing SDK in $_state state')));

    final walletBackup = backupState.walletBackup;
    if (walletBackup.accounts.isEmpty) {
      CancelableOperation.fromFuture(Future.error(StateError('Cannot start re-pairing SDK without remote backup data')));
    }

    final pairingAction = PairingAction(sodium, _sharedDatabase, message, userId);

    _pairingOperation = CancelableOperation.fromFuture(
      pairingAction.start(walletBackup.combinedRemoteData(message.walletName)),
      onCancel: pairingAction.cancel,
    ).then((pairingData) {
      // TODO: invalidate old sign listener
      pairingState.pairingData = pairingData;
      return pairingData;
    });

    return _pairingOperation!;
  }

  void cancelPairing() {
    _pairingOperation?.cancel();
  }

  void unpairIfNoKeyshares() {
    if (_state != SdkState.paired) return cancelPairing();
    pairingState.pairingData = null;
    _state = SdkState.initialized;
  }

  // --- Keygen ---

  late KeygenState keygenState = KeygenState(localDatabase);

  CancelableOperation<Keyshare2> startKeygen(String walletName, String userId) {
    if (_state.index < SdkState.paired.index) {
      return CancelableOperation.fromFuture(Future.error(StateError('Cannot start keygen when SDK in $_state state')));
    }

    final pairingData = pairingState.pairingData;
    if (pairingData == null) return CancelableOperation.fromFuture(Future.error(StateError('Must be paired before key generation')));

    final keygenAction = KeygenAction(sodium, ctss, _sharedDatabase, pairingData, userId);
    final keygenOperation = CancelableOperation.fromFuture(keygenAction.start(), onCancel: keygenAction.cancel);

    return keygenOperation.then((keyshare) {
      keygenState.addKeyshare(walletName, keyshare);
      _state = SdkState.readyToSign;
      return keyshare;
    });
  }

  void deleteKeyshares() {
    if (_state != SdkState.readyToSign) return;
    keygenState.removeAllKeyshares();
    _state = SdkState.paired;
  }

  // --- Sign ---

  SignListener? _signListener;

  SignListener? _updateSignListener(PairingData? pairingData, Map<String, List<Keyshare2>> keyshares, String userId) {
    if (pairingData == null || keyshares.isEmpty) {
      _signListener = null;
    } else {
      _signListener = SignListener(pairingData, userId, keyshares, _sharedDatabase, sodium, ctss);
    }
    return _signListener;
  }

  Stream<SignRequest> signRequests(String userId) {
    final pairingStream = pairingState.toStream((p) => p.pairingData);
    final keysharesStream = keygenState.toStream((p) => p.keyshares);
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

  Stream<BackupMessage> listenRemoteBackup(String accountAddress, {String walletName = "snap"}) {
    if (_state != SdkState.readyToSign) {
      throw StateError('Cannot start backup when SDK in $_state state');
    }

    final pairingData = pairingState.pairingData;
    if (pairingData == null) throw StateError('Must be paired before backup');

    if (keygenState.keyshares[walletName] == null) {
      throw StateError('No keyshares for $walletName');
    }

    final keyshare = keygenState.keyshares[walletName]!.firstWhereOrNull((keyshare) => keyshare.ethAddress == accountAddress);
    if (keyshare == null) {
      throw StateError('Cannot find keyshare for $accountAddress');
    }

    final remoteBackupListener = RemoteBackupListener(_sharedDatabase, pairingData);
    return remoteBackupListener.remoteBackupRequests().tap((remoteBackup) {
      if (remoteBackup.backupData.isNotEmpty) {
        final accountBackup = AccountBackup(accountAddress, keyshare.toBytes(), remoteBackup.backupData);
        backupState.addAccount(walletName, accountBackup);
        _sharedDatabase.setBackupMessage(
            pairingData.pairingId,
            BackupMessage(
                backupData: '', //
                isBackedUp: true,
                pairingId: pairingData.pairingId));
      }
    });
  }

  void deleteBackup() {
    if (_state == SdkState.loaded) throw StateError('Cannot delete backup when SDK in $_state state');
    backupState.clearAccounts();
  }

  CancelableOperation<WalletBackup> walletBackup() {
    if (_state != SdkState.readyToSign) CancelableOperation.fromFuture(Future.error(StateError('Cannot start backup when SDK in $_state state')));

    final keyshares = keygenState.keyshares;
    if (keyshares.isEmpty) return CancelableOperation.fromFuture(Future.error(StateError('No keys to backup')));

    final walletBackup = backupState.walletBackup;
    assert(keyshares.length == walletBackup.accounts.length, 'Part of backup is not fetched');

    return CancelableOperation.fromValue(walletBackup);
  }

  // --- Users ---

  void updateMessagingToken(String userId, String token) {
    _sharedDatabase.setUserData(userId, UserData(FCMData(token), null), true);
  }

  Stream<UserData> snapVersionListener(String userId) {
    return _sharedDatabase.userUpdates(userId);
  }
}
